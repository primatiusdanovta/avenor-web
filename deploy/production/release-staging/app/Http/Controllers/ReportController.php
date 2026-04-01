<?php

namespace App\Http\Controllers;

use App\Models\OfflineSale;
use App\Models\OnlineSaleItem;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;
use Symfony\Component\HttpFoundation\Response as BaseResponse;

class ReportController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        [$dateFrom, $dateTo] = $this->resolveDateRange($request);
        $type = $request->string('type')->toString() ?: 'offline';
        $report = $this->buildReportData($dateFrom, $dateTo);

        return Inertia::render('Reports/Index', [
            'filters' => [
                'date_from' => $dateFrom->toDateString(),
                'date_to' => $dateTo->toDateString(),
                'type' => $type,
            ],
            'reportOptions' => [
                ['value' => 'offline', 'label' => 'Offline Selling'],
                ['value' => 'online', 'label' => 'Online Selling'],
                ['value' => 'revenue_netprofit', 'label' => 'Revenue and Netprofit'],
            ],
            'reportData' => $report,
        ]);
    }

    public function exportPdf(Request $request): BaseResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        [$dateFrom, $dateTo] = $this->resolveDateRange($request);
        $report = $this->buildReportData($dateFrom, $dateTo);

        $lines = [
            'Tanggal: ' . $dateFrom->toDateString() . ' s/d ' . $dateTo->toDateString(),
            '',
            'Offline Selling',
            'Total Quantity: ' . $report['offline']['total_quantity'],
            'Gross Profit Offline: ' . $this->formatCurrency($report['offline']['gross_profit']),
            'Net Profit Offline: ' . $this->formatCurrency($report['offline']['net_profit']),
            '',
            'Online Selling',
            'Total Quantity: ' . $report['online']['total_quantity'],
            'Gross Profit Online: ' . $this->formatCurrency($report['online']['gross_profit']),
            'Net Profit Online: ' . $this->formatCurrency($report['online']['net_profit']),
            '',
            'Revenue and Netprofit',
            'Revenue: ' . $this->formatCurrency($report['summary']['revenue']),
            'Net Profit: ' . $this->formatCurrency($report['summary']['net_profit']),
            'NPM Base: ' . $this->formatCurrency($report['summary']['npm_base']),
            'NPM Percent: ' . number_format($report['summary']['npm_percent'], 2, '.', '') . '%',
        ];

        $pdf = $this->buildSimplePdf('Avenor Report', $lines);

        return response($pdf, 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="report-' . $dateFrom->toDateString() . '-to-' . $dateTo->toDateString() . '.pdf"',
        ]);
    }

    private function buildReportData(Carbon $dateFrom, Carbon $dateTo): array
    {
        $offlineSales = OfflineSale::query()
            ->with('product.hppCalculation')
            ->where('approval_status', '!=', 'ditolak')
            ->whereBetween('created_at', [$dateFrom->copy()->startOfDay(), $dateTo->copy()->endOfDay()])
            ->get();

        $onlineItems = OnlineSaleItem::query()
            ->with('product.hppCalculation')
            ->whereBetween('created_at', [$dateFrom->copy()->startOfDay(), $dateTo->copy()->endOfDay()])
            ->get();

        $offlineGross = round((float) $offlineSales->sum('harga'), 2);
        $offlineNet = round((float) $offlineSales->sum(fn (OfflineSale $sale) => $this->offlineNet($sale)), 2);
        $onlineGross = round((float) $onlineItems->sum('harga'), 2);
        $onlineNet = round((float) $onlineItems->sum(fn (OnlineSaleItem $item) => $this->onlineNet($item)), 2);
        $revenue = round($offlineGross + $onlineGross, 2);
        $netProfit = round($offlineNet + $onlineNet, 2);
        $npmBase = round($revenue - $netProfit, 2);

        return [
            'offline' => [
                'total_quantity' => (int) $offlineSales->sum('quantity'),
                'gross_profit' => $offlineGross,
                'net_profit' => $offlineNet,
            ],
            'online' => [
                'total_quantity' => (int) $onlineItems->sum('quantity'),
                'gross_profit' => $onlineGross,
                'net_profit' => $onlineNet,
            ],
            'summary' => [
                'revenue' => $revenue,
                'net_profit' => $netProfit,
                'npm_base' => $npmBase,
                'npm_percent' => $revenue > 0 ? round(($npmBase / $revenue) * 100, 2) : 0,
            ],
        ];
    }

    private function resolveDateRange(Request $request): array
    {
        $validated = $request->validate([
            'date_from' => ['nullable', 'date'],
            'date_to' => ['nullable', 'date', 'after_or_equal:date_from'],
            'type' => ['nullable', 'in:offline,online,revenue_netprofit'],
        ]);

        $dateFrom = ! empty($validated['date_from'])
            ? Carbon::parse($validated['date_from'])
            : now()->startOfMonth();

        $dateTo = ! empty($validated['date_to'])
            ? Carbon::parse($validated['date_to'])
            : now()->endOfMonth();

        return [$dateFrom, $dateTo];
    }

    private function offlineNet(OfflineSale $sale): float
    {
        $hpp = (float) ($sale->total_hpp ?? $sale->product?->hppCalculation?->total_hpp ?? $sale->product?->harga_modal ?? 0);
        return (float) $sale->harga - ($hpp * (int) $sale->quantity);
    }

    private function onlineNet(OnlineSaleItem $item): float
    {
        $hpp = (float) ($item->product?->hppCalculation?->total_hpp ?? $item->product?->harga_modal ?? 0);
        return (float) $item->harga - ($hpp * (int) $item->quantity);
    }

    private function formatCurrency(float $value): string
    {
        return 'Rp ' . number_format($value, 0, ',', '.');
    }

    private function buildSimplePdf(string $title, array $lines): string
    {
        $contentLines = [
            'BT',
            '/F1 16 Tf',
            '50 780 Td',
            '(' . $this->escapePdfText($title) . ') Tj',
            '/F1 11 Tf',
        ];

        $y = 760;
        foreach ($lines as $line) {
            $contentLines[] = sprintf('1 0 0 1 50 %d Tm', $y);
            $contentLines[] = '(' . $this->escapePdfText($line) . ') Tj';
            $y -= 18;
        }
        $contentLines[] = 'ET';

        $stream = implode("\n", $contentLines);

        $objects = [];
        $objects[] = '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj';
        $objects[] = '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj';
        $objects[] = '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj';
        $objects[] = '4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj';
        $objects[] = '5 0 obj << /Length ' . strlen($stream) . ' >> stream' . "\n" . $stream . "\nendstream endobj";

        $pdf = "%PDF-1.4\n";
        $offsets = [];
        foreach ($objects as $object) {
            $offsets[] = strlen($pdf);
            $pdf .= $object . "\n";
        }

        $xrefOffset = strlen($pdf);
        $pdf .= 'xref' . "\n";
        $pdf .= '0 ' . (count($objects) + 1) . "\n";
        $pdf .= "0000000000 65535 f \n";
        foreach ($offsets as $offset) {
            $pdf .= str_pad((string) $offset, 10, '0', STR_PAD_LEFT) . " 00000 n \n";
        }
        $pdf .= 'trailer << /Size ' . (count($objects) + 1) . ' /Root 1 0 R >>' . "\n";
        $pdf .= 'startxref' . "\n" . $xrefOffset . "\n%%EOF";

        return $pdf;
    }

    private function escapePdfText(string $value): string
    {
        return str_replace(['\\', '(', ')'], ['\\\\', '\\(', '\\)'], $value);
    }
}



