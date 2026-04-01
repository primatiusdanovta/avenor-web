<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\File;
use Illuminate\Validation\ValidationException;
use SimpleXMLElement;
use ZipArchive;

class SpreadsheetRowReader
{
    public static function read(UploadedFile $file): array
    {
        $extension = strtolower($file->getClientOriginalExtension());

        return match ($extension) {
            'csv', 'txt' => self::readCsv($file->getRealPath()),
            'xlsx' => self::readXlsx($file->getRealPath()),
            default => throw ValidationException::withMessages([
                'import_file' => 'Format file harus .csv atau .xlsx.',
            ]),
        };
    }

    private static function readCsv(string $path): array
    {
        $handle = fopen($path, 'rb');
        if (! $handle) {
            return [];
        }

        $headers = null;
        $rows = [];

        while (($row = fgetcsv($handle)) !== false) {
            if ($headers === null) {
                $headers = array_map(fn ($header) => self::sanitizeHeader((string) $header), $row);
                continue;
            }

            if (! array_filter($row, fn ($value) => trim((string) $value) !== '')) {
                continue;
            }

            $rows[] = self::combineRow($headers, $row);
        }

        fclose($handle);

        return $rows;
    }

    private static function readXlsx(string $path): array
    {
        if (class_exists(ZipArchive::class)) {
            return self::readXlsxWithZipArchive($path);
        }

        if (PHP_OS_FAMILY === 'Windows') {
            return self::readXlsxWithPowerShell($path);
        }

        throw ValidationException::withMessages([
            'import_file' => 'File XLSX tidak dapat dibaca di environment ini.',
        ]);
    }

    private static function readXlsxWithZipArchive(string $path): array
    {
        $zip = new ZipArchive();
        if ($zip->open($path) !== true) {
            throw ValidationException::withMessages(['import_file' => 'File XLSX tidak dapat dibaca.']);
        }

        $sharedStrings = self::readSharedStrings($zip);
        $sheetPath = self::firstWorksheetPath($zip);
        $sheetXml = $sheetPath ? $zip->getFromName($sheetPath) : false;
        $zip->close();

        if (! $sheetXml) {
            return [];
        }

        $xml = simplexml_load_string($sheetXml);
        if (! $xml instanceof SimpleXMLElement || ! isset($xml->sheetData)) {
            return [];
        }

        $rows = [];
        foreach ($xml->sheetData->row as $rowElement) {
            $cells = [];
            foreach ($rowElement->c as $cell) {
                $reference = (string) $cell['r'];
                $columnLetters = preg_replace('/\d+/', '', $reference) ?: 'A';
                $columnIndex = self::columnToIndex($columnLetters);
                $cells[$columnIndex] = self::cellValue($cell, $sharedStrings);
            }
            if ($cells !== []) {
                ksort($cells);
                $rows[] = array_values($cells);
            }
        }

        return self::rowsToAssociative($rows);
    }

    private static function readXlsxWithPowerShell(string $path): array
    {
        $scriptPath = storage_path('app/read_xlsx.ps1');
        File::put($scriptPath, <<<'PS1'
param([string]$WorkbookPath)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($WorkbookPath)
try {
    $sharedStrings = @()
    $sharedEntry = $zip.GetEntry('xl/sharedStrings.xml')
    if ($sharedEntry -ne $null) {
        $sharedReader = New-Object System.IO.StreamReader($sharedEntry.Open())
        $sharedXml = [xml]$sharedReader.ReadToEnd()
        $sharedReader.Close()
        foreach ($si in $sharedXml.sst.si) {
            if ($si.t) {
                $sharedStrings += [string]$si.t
            } else {
                $text = ''
                foreach ($run in $si.r) { $text += [string]$run.t }
                $sharedStrings += $text
            }
        }
    }

    $sheetPath = 'xl/worksheets/sheet1.xml'
    $workbookEntry = $zip.GetEntry('xl/workbook.xml')
    $relsEntry = $zip.GetEntry('xl/_rels/workbook.xml.rels')
    if ($workbookEntry -ne $null -and $relsEntry -ne $null) {
        $workbookReader = New-Object System.IO.StreamReader($workbookEntry.Open())
        $workbookXml = [xml]$workbookReader.ReadToEnd()
        $workbookReader.Close()

        $relsReader = New-Object System.IO.StreamReader($relsEntry.Open())
        $relsXml = [xml]$relsReader.ReadToEnd()
        $relsReader.Close()

        $firstSheet = $workbookXml.workbook.sheets.sheet | Select-Object -First 1
        if ($firstSheet -ne $null) {
            $sheetRelId = $firstSheet.GetAttribute('id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
            if (-not $sheetRelId) {
                $sheetRelId = [string]$firstSheet.Attributes['r:id'].Value
            }

            if ($sheetRelId) {
                foreach ($relationship in $relsXml.Relationships.Relationship) {
                    if ([string]$relationship.Id -eq $sheetRelId) {
                        $target = [string]$relationship.Target
                        if ($target) {
                            $sheetPath = 'xl/' + $target.TrimStart('/')
                        }
                        break
                    }
                }
            }
        }
    }

    $sheetEntry = $zip.GetEntry($sheetPath)
    if ($sheetEntry -eq $null) {
        throw "Worksheet '$sheetPath' tidak ditemukan."
    }

    $sheetReader = New-Object System.IO.StreamReader($sheetEntry.Open())
    $sheetXml = [xml]$sheetReader.ReadToEnd()
    $sheetReader.Close()

    $rows = @()
    foreach ($row in $sheetXml.worksheet.sheetData.row) {
        $cells = @{}
        foreach ($cell in $row.c) {
            $reference = [string]$cell.r
            $column = ($reference -replace '\d', '')
            $index = 0
            foreach ($ch in $column.ToCharArray()) { $index = ($index * 26) + ([int][char]$ch - 64) }
            $index--

            $value = ''
            if ($cell.t -eq 's') {
                $value = $sharedStrings[[int]$cell.v]
            } elseif ($cell.t -eq 'inlineStr') {
                if ($cell.is.t) {
                    $value = [string]$cell.is.t
                } else {
                    $text = ''
                    foreach ($run in $cell.is.r) { $text += [string]$run.t }
                    $value = $text
                }
            } else {
                $value = [string]$cell.v
            }

            $cells[$index] = $value
        }

        if ($cells.Count -gt 0) {
            $max = ($cells.Keys | Measure-Object -Maximum).Maximum
            $line = @()
            for ($i = 0; $i -le $max; $i++) {
                if ($cells.ContainsKey($i)) { $line += $cells[$i] } else { $line += '' }
            }
            $rows += ,$line
        }
    }

    $rows | ConvertTo-Json -Depth 6 -Compress
} finally {
    $zip.Dispose()
}
PS1);

        $command = 'powershell -NoProfile -ExecutionPolicy Bypass -File ' . escapeshellarg($scriptPath) . ' ' . escapeshellarg($path);
        $output = shell_exec($command);

        if (! is_string($output) || trim($output) === '') {
            throw ValidationException::withMessages(['import_file' => 'File XLSX tidak dapat dibaca.']);
        }

        $rows = json_decode($output, true);
        if (! is_array($rows)) {
            throw ValidationException::withMessages(['import_file' => 'Format XLSX tidak valid.']);
        }

        return self::rowsToAssociative($rows);
    }

    private static function rowsToAssociative(array $rows): array
    {
        if ($rows === []) {
            return [];
        }

        $normalizedRows = array_map(function ($row) {
            if (is_array($row) && array_key_exists('value', $row) && is_array($row['value'])) {
                return $row['value'];
            }

            return is_array($row) ? $row : [(string) $row];
        }, $rows);

        $headers = array_map(fn ($header) => self::sanitizeHeader((string) $header), array_shift($normalizedRows));

        return collect($normalizedRows)
            ->filter(fn (array $row) => array_filter($row, fn ($value) => trim((string) $value) !== ''))
            ->map(fn (array $row) => self::combineRow($headers, $row))
            ->values()
            ->all();
    }

    private static function readSharedStrings(ZipArchive $zip): array
    {
        $xml = $zip->getFromName('xl/sharedStrings.xml');
        if (! $xml) {
            return [];
        }

        $document = simplexml_load_string($xml);
        if (! $document instanceof SimpleXMLElement) {
            return [];
        }

        $strings = [];
        foreach ($document->si as $item) {
            $text = '';
            if (isset($item->t)) {
                $text = (string) $item->t;
            } else {
                foreach ($item->r as $run) {
                    $text .= (string) $run->t;
                }
            }
            $strings[] = $text;
        }

        return $strings;
    }

    private static function firstWorksheetPath(ZipArchive $zip): ?string
    {
        $relsXml = $zip->getFromName('xl/_rels/workbook.xml.rels');
        if (! $relsXml) {
            return 'xl/worksheets/sheet1.xml';
        }

        $rels = simplexml_load_string($relsXml);
        if (! $rels instanceof SimpleXMLElement) {
            return 'xl/worksheets/sheet1.xml';
        }

        foreach ($rels->Relationship as $relationship) {
            $target = (string) $relationship['Target'];
            if (str_contains($target, 'worksheets/')) {
                return 'xl/' . ltrim($target, '/');
            }
        }

        return 'xl/worksheets/sheet1.xml';
    }

    private static function cellValue(SimpleXMLElement $cell, array $sharedStrings): string
    {
        $type = (string) $cell['t'];
        $value = isset($cell->v) ? (string) $cell->v : '';

        if ($type === 's') {
            return $sharedStrings[(int) $value] ?? '';
        }

        if ($type === 'inlineStr') {
            if (isset($cell->is->t)) {
                return (string) $cell->is->t;
            }

            $text = '';
            foreach ($cell->is->r as $run) {
                $text .= (string) $run->t;
            }

            return $text;
        }

        return $value;
    }

    private static function combineRow(array $headers, array $row): array
    {
        $combined = [];
        foreach ($headers as $index => $header) {
            if ($header === '') {
                continue;
            }

            $combined[$header] = self::sanitizeValue((string) ($row[$index] ?? ''));
        }

        return $combined;
    }

    private static function sanitizeHeader($value): string
    {
        return self::sanitizeValue((string) preg_replace('/^\xEF\xBB\xBF/', '', (string) $value));
    }

    private static function sanitizeValue(string $value): string
    {
        return trim(str_replace(["\t", "\r", "\n"], '', $value));
    }

    private static function columnToIndex(string $letters): int
    {
        $index = 0;
        foreach (str_split(strtoupper($letters)) as $letter) {
            $index = ($index * 26) + (ord($letter) - 64);
        }

        return max($index - 1, 0);
    }
}
