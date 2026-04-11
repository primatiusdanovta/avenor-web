<?php

namespace App\Services;

use App\Models\OnlineSale;
use App\Models\Product;
use App\Support\SpreadsheetRowReader;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class OnlineSaleImportService
{
    public function import(UploadedFile $ordersFile, UploadedFile $incomeFile, int $storeId): array
    {
        $orderRows = collect(SpreadsheetRowReader::read($ordersFile))
            ->map(fn (array $row) => $this->normalizeOrderRow($row))
            ->filter(fn (array $row) => $row['order_id'] !== '')
            ->groupBy('order_id');

        $incomeRows = collect(SpreadsheetRowReader::read($incomeFile))
            ->map(fn (array $row) => $this->normalizeIncomeRow($row))
            ->filter(fn (array $row) => $row['order_id'] !== '')
            ->groupBy('order_id')
            ->map(fn (Collection $rows) => round((float) $rows->sum('total_settlement_amount'), 2));

        if ($orderRows->isEmpty()) {
            throw ValidationException::withMessages([
                'orders_file' => 'File order tidak berisi data yang bisa dibaca. Pastikan header export TikTok sesuai dan file tidak kosong.',
            ]);
        }

        if ($incomeRows->isEmpty()) {
            throw ValidationException::withMessages([
                'income_file' => 'File income tidak berisi data settlement yang bisa dibaca. Pastikan header export TikTok sesuai dan file tidak kosong.',
            ]);
        }

        $products = Product::query()
            ->where('store_id', $storeId)
            ->orderByRaw('LENGTH(nama_product) DESC')
            ->get(['id_product', 'nama_product'])
            ->map(function (Product $product) {
                return [
                    'id_product' => $product->id_product,
                    'nama_product' => $product->nama_product,
                    'normalized' => $this->normalizeText($product->nama_product),
                ];
            });

        $summary = [
            'imported' => 0,
            'skipped' => 0,
            'missing_income' => 0,
            'total_orders' => $orderRows->count(),
        ];

        DB::transaction(function () use ($orderRows, $incomeRows, $products, $storeId, &$summary): void {
            OnlineSale::query()->where('store_id', $storeId)->delete();

            foreach ($orderRows as $orderId => $groupedRows) {
                $rowsForOrder = collect($groupedRows)->values();
                $firstRow = $rowsForOrder->first();

                if (! $this->isCompletedOrder($firstRow)) {
                    $summary['skipped']++;
                    continue;
                }

                $totalSettlement = (float) ($incomeRows->get($orderId) ?? 0);
                if ($totalSettlement <= 0) {
                    $summary['missing_income']++;
                    continue;
                }

                $paidAt = $firstRow['paid_time'] ?? $firstRow['created_time'] ?? now();
                $groupedItems = $rowsForOrder
                    ->groupBy(function (array $row) use ($products) {
                        $match = $this->matchProduct($products, $row['product_name']);
                        return $match['nama_product'] ?? $row['product_name'];
                    })
                    ->map(function (Collection $items) use ($products) {
                        $firstItem = $items->first();
                        $match = $this->matchProduct($products, $firstItem['product_name']);

                        return [
                            'id_product' => $match['id_product'] ?? null,
                            'raw_product_name' => $firstItem['product_name'],
                            'nama_product' => $match['nama_product'] ?? $firstItem['product_name'],
                            'quantity' => max((int) $items->sum('quantity'), 1),
                        ];
                    })
                    ->values();

                $totalQuantity = max((int) $groupedItems->sum('quantity'), 1);
                $unitPrice = round($totalSettlement / $totalQuantity, 2);
                $allocatedItems = $this->allocateSettlement($groupedItems, $unitPrice, $totalSettlement);

                $sale = OnlineSale::query()->create([
                    'store_id' => $storeId,
                    'order_id' => $orderId,
                    'order_status' => $firstRow['order_status'],
                    'order_substatus' => $firstRow['order_substatus'],
                    'cancelation' => $firstRow['cancelation'],
                    'province' => $firstRow['province'],
                    'regency_city' => $firstRow['regency_city'],
                    'paid_time' => $paidAt,
                    'total_amount' => $totalSettlement,
                    'created_at' => $paidAt,
                    'updated_at' => now(),
                ]);

                foreach ($allocatedItems as $item) {
                    $sale->items()->create([
                        'store_id' => $storeId,
                        'id_product' => $item['id_product'],
                        'raw_product_name' => $item['raw_product_name'],
                        'nama_product' => $item['nama_product'],
                        'quantity' => $item['quantity'],
                        'harga' => $item['harga'],
                        'created_at' => $paidAt,
                        'updated_at' => now(),
                    ]);
                }

                $summary['imported']++;
            }
        });

        return $summary;
    }

    public function debug(UploadedFile $ordersFile, UploadedFile $incomeFile): array
    {
        $orderRows = SpreadsheetRowReader::read($ordersFile);
        $incomeRows = SpreadsheetRowReader::read($incomeFile);

        $normalizedOrders = collect($orderRows)
            ->map(fn (array $row) => $this->normalizeOrderRow($row))
            ->filter(fn (array $row) => $row['order_id'] !== '')
            ->values();

        $normalizedIncome = collect($incomeRows)
            ->map(fn (array $row) => $this->normalizeIncomeRow($row))
            ->filter(fn (array $row) => $row['order_id'] !== '')
            ->values();

        return [
            'orders_file' => [
                'name' => $ordersFile->getClientOriginalName(),
                'row_count' => count($orderRows),
                'normalized_row_count' => $normalizedOrders->count(),
                'headers' => array_keys($orderRows[0] ?? []),
                'sample_raw' => $orderRows[0] ?? null,
                'sample_normalized' => $normalizedOrders->first(),
            ],
            'income_file' => [
                'name' => $incomeFile->getClientOriginalName(),
                'row_count' => count($incomeRows),
                'normalized_row_count' => $normalizedIncome->count(),
                'headers' => array_keys($incomeRows[0] ?? []),
                'sample_raw' => $incomeRows[0] ?? null,
                'sample_normalized' => $normalizedIncome->first(),
            ],
        ];
    }

    private function allocateSettlement(Collection $items, float $unitPrice, float $totalSettlement): array
    {
        $allocated = [];
        $remaining = round($totalSettlement, 2);
        $lastIndex = $items->keys()->last();

        foreach ($items as $index => $item) {
            $lineAmount = $index === $lastIndex
                ? $remaining
                : round($unitPrice * (int) $item['quantity'], 2);

            $lineAmount = max(min($lineAmount, $remaining), 0);
            $allocated[] = [
                ...$item,
                'harga' => $lineAmount,
            ];
            $remaining = round($remaining - $lineAmount, 2);
        }

        return $allocated;
    }

    private function normalizeOrderRow(array $row): array
    {
        $paidTime = $this->parseDate($this->valueByHeaders($row, ['Paid Time', 'Paid time', 'Payment Time', 'Waktu Dibayar', 'Order settled time', 'Order Settle Time']));
        $createdTime = $this->parseDate($this->valueByHeaders($row, ['Created Time', 'Created time', 'Order Created Time', 'Waktu Dibuat', 'Order created time', 'Order Create Time']));
        $quantityValue = $this->valueByHeaders($row, ['Quantity', 'Qty', 'Jumlah', 'SKU Quantity', 'Product Quantity'], '1');
        $quantity = (int) preg_replace('/[^0-9-]/', '', $quantityValue);

        return [
            'order_id' => trim($this->valueByHeaders($row, ['Order ID', 'Order Id', 'Order No', 'Order Number', 'Nomor Pesanan'])),
            'order_status' => trim($this->valueByHeaders($row, ['Order Status', 'Status Pesanan', 'Status'])),
            'order_substatus' => trim($this->valueByHeaders($row, ['Order Substatus', 'Order Sub Status', 'Substatus Pesanan', 'Substatus'])),
            'cancelation' => trim($this->valueByHeaders($row, ['Cancelation/Return Type', 'Cancellation/Return Type', 'Return Type', 'Cancellation Type'])),
            'product_name' => trim($this->valueByHeaders($row, ['Product Name', 'Product', 'Nama Produk', 'Product Name in SKU', 'SKU Name', 'Product(s)'])),
            'quantity' => max($quantity, 1),
            'paid_time' => $paidTime,
            'created_time' => $createdTime,
            'province' => trim($this->valueByHeaders($row, ['Province', 'Provinsi', 'Recipient Province', 'Destination Province'])),
            'regency_city' => trim($this->valueByHeaders($row, ['Regency and City', 'Regency & City', 'City', 'Kota/Kabupaten', 'Recipient City', 'Destination City'])),
        ];
    }

    private function normalizeIncomeRow(array $row): array
    {
        $orderId = trim($this->valueByHeaders($row, ['Order/adjustment ID', 'Order ID/adjustment ID', 'Order ID', 'Order Id', 'System.Xml.XmlElement']));
        $amount = $this->valueByHeaders($row, ['Total settlement amount', 'Total Settlement Amount', 'Total settlement amount (IDR)', 'Total settlement amount (Rp)', 'Settlement Amount', 'Net settlement amount'], '0');

        return [
            'order_id' => $orderId,
            'total_settlement_amount' => (float) preg_replace('/[^0-9.\-]/', '', str_replace(',', '', $amount)),
        ];
    }

    private function valueByHeaders(array $row, array $aliases, string $default = ''): string
    {
        $normalizedRow = [];
        foreach ($row as $key => $value) {
            $normalizedRow[$this->normalizeHeaderKey((string) $key)] = is_scalar($value) ? (string) $value : json_encode($value);
        }

        foreach ($aliases as $alias) {
            $normalizedAlias = $this->normalizeHeaderKey($alias);
            if (array_key_exists($normalizedAlias, $normalizedRow)) {
                return $normalizedRow[$normalizedAlias];
            }
        }

        return $default;
    }

    private function normalizeHeaderKey(string $value): string
    {
        $ascii = Str::lower(Str::ascii($value));
        $ascii = preg_replace('/[^a-z0-9]+/', ' ', $ascii) ?? '';
        return trim($ascii);
    }

    private function parseDate(string $value): ?Carbon
    {
        $value = trim($value);
        if ($value === '') {
            return null;
        }

        if (is_numeric($value)) {
            try {
                return Carbon::create(1899, 12, 30)->addDays((int) floor((float) $value));
            } catch (\Throwable) {
                return null;
            }
        }

        foreach (['d/m/Y H:i:s', 'd-m-Y H:i:s', 'Y-m-d H:i:s', 'd/m/Y', 'Y-m-d', 'd/m/Y H:i', 'Y-m-d H:i'] as $format) {
            try {
                return Carbon::createFromFormat($format, $value);
            } catch (\Throwable) {
            }
        }

        try {
            return Carbon::parse($value);
        } catch (\Throwable) {
            return null;
        }
    }

    private function isCompletedOrder(array $row): bool
    {
        $status = $this->normalizeText($row['order_status'] ?? '');
        $substatus = $this->normalizeText($row['order_substatus'] ?? '');
        $completedKeywords = ['selesai', 'completed', 'complete', 'delivered', 'finish', 'finished'];

        $statusMatch = collect($completedKeywords)->contains(fn (string $keyword) => $status !== '' && str_contains($status, $keyword));
        $substatusMatch = $substatus === '' || collect($completedKeywords)->contains(fn (string $keyword) => str_contains($substatus, $keyword));

        return $statusMatch && $substatusMatch;
    }

    private function matchProduct(Collection $products, string $importName): ?array
    {
        $normalizedImportName = $this->normalizeText($importName);

        return $products->first(function (array $product) use ($normalizedImportName) {
            return $product['normalized'] !== '' && Str::contains($normalizedImportName, $product['normalized']);
        });
    }

    private function normalizeText(string $value): string
    {
        $ascii = Str::lower(Str::ascii($value));
        $ascii = preg_replace('/[^a-z0-9]+/', ' ', $ascii) ?? '';

        return trim($ascii);
    }
}
