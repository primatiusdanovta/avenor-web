<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;
use Symfony\Component\Process\Process;
use Throwable;

class HeroVideoOptimizer
{
    public function optimizeAndStore(UploadedFile $file, string $directory = 'landing/hero-videos'): array
    {
        $disk = Storage::disk('public');
        $disk->makeDirectory($directory);

        $extension = strtolower($file->getClientOriginalExtension());

        if ($extension === '') {
            $extension = match ($file->getMimeType()) {
                'video/webm' => 'webm',
                'video/quicktime' => 'mov',
                default => 'mp4',
            };
        }

        $fallbackRelativePath = trim($directory, '/') . '/' . Str::uuid() . '.' . $extension;
        $outputRelativePath = trim($directory, '/') . '/' . Str::uuid() . '.mp4';
        $outputAbsolutePath = $disk->path($outputRelativePath);

        try {
            $process = new Process([
                $this->resolveBinary(),
                '-y',
                '-i',
                $file->getRealPath(),
                '-an',
                '-vf',
                'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black',
                '-c:v',
                'libx264',
                '-preset',
                'medium',
                '-profile:v',
                'high',
                '-level',
                '4.1',
                '-pix_fmt',
                'yuv420p',
                '-movflags',
                '+faststart',
                '-crf',
                '24',
                '-maxrate',
                '3500k',
                '-bufsize',
                '7000k',
                '-r',
                '24',
                $outputAbsolutePath,
            ]);

            $process->setTimeout(300);
            $process->run();

            if ($process->isSuccessful() && $disk->exists($outputRelativePath)) {
                return [
                    'path' => $outputRelativePath,
                    'mime' => 'video/mp4',
                ];
            }

            Log::warning('Hero video optimization failed, storing original file instead.', [
                'binary' => $this->resolveBinary(),
                'error' => $process->getErrorOutput(),
                'output' => $process->getOutput(),
                'original_name' => $file->getClientOriginalName(),
                'original_mime' => $file->getMimeType(),
            ]);
        } catch (Throwable $exception) {
            Log::warning('Hero video optimization crashed, storing original file instead.', [
                'message' => $exception->getMessage(),
                'original_name' => $file->getClientOriginalName(),
                'original_mime' => $file->getMimeType(),
            ]);
        }

        if (is_file($outputAbsolutePath)) {
            @unlink($outputAbsolutePath);
        }

        $storedPath = $disk->putFileAs(trim($directory, '/'), $file, basename($fallbackRelativePath));

        if (! is_string($storedPath) || $storedPath === '') {
            throw new RuntimeException('File hero video gagal disimpan ke storage.');
        }

        return [
            'path' => $storedPath,
            'mime' => $file->getMimeType() ?: 'application/octet-stream',
        ];
    }

    private function resolveBinary(): string
    {
        $configured = (string) config('services.ffmpeg.binary', '');
        $fallbackBinary = 'C:\\Users\\Sagita Priscilia R\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\\ffmpeg-8.1-full_build\\bin\\ffmpeg.exe';

        if ($configured !== '' && is_file($configured)) {
            return $configured;
        }

        if (is_file($fallbackBinary)) {
            return $fallbackBinary;
        }

        return 'ffmpeg';
    }
}
