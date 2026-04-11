<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ExpenseController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'expenses.view');
        $storeId = $this->currentStoreId($request);

        $expenses = Expense::query()
            ->where('store_id', $storeId)
            ->with('creator')
            ->orderByDesc('expense_date')
            ->orderByDesc('id')
            ->get()
            ->map(fn (Expense $expense) => [
                'id' => $expense->id,
                'category' => $expense->category,
                'category_label' => $this->categoryLabel($expense->category),
                'title' => $expense->title,
                'amount' => (float) $expense->amount,
                'notes' => $expense->notes,
                'expense_date' => optional($expense->expense_date)->format('Y-m-d'),
                'created_by_name' => $expense->creator?->nama ?? '-',
                'created_at' => optional($expense->created_at)->format('Y-m-d H:i:s'),
            ])
            ->values();

        return Inertia::render('Expenses/Index', [
            'expenses' => $expenses,
            'summary' => [
                'bahan_baku' => round((float) Expense::query()->where('store_id', $storeId)->where('category', 'bahan_baku')->sum('amount'), 2),
                'operasional' => round((float) Expense::query()->where('store_id', $storeId)->where('category', 'operasional')->sum('amount'), 2),
                'total' => round((float) Expense::query()->where('store_id', $storeId)->sum('amount'), 2),
            ],
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizePermission($request, 'expenses.manage');

        $validated = $this->validatePayload($request);

        Expense::query()->create([
            'store_id' => $this->currentStoreId($request),
            'category' => $validated['category'],
            'title' => $validated['title'],
            'amount' => $validated['amount'],
            'expense_date' => $validated['expense_date'],
            'notes' => $validated['notes'] ?? null,
            'created_by' => $request->user()->id_user,
        ]);

        return redirect()->route('expenses.index')->with('success', 'Pengeluaran berhasil disimpan.');
    }

    public function update(Request $request, Expense $expense): RedirectResponse
    {
        $this->authorizePermission($request, 'expenses.manage');
        $this->ensureStoreMatch($request, $expense);

        $validated = $this->validatePayload($request);

        $expense->update([
            'category' => $validated['category'],
            'title' => $validated['title'],
            'amount' => $validated['amount'],
            'expense_date' => $validated['expense_date'],
            'notes' => $validated['notes'] ?? null,
        ]);

        return redirect()->route('expenses.index')->with('success', 'Pengeluaran berhasil diperbarui.');
    }

    public function destroy(Request $request, Expense $expense): RedirectResponse
    {
        $this->authorizePermission($request, 'expenses.manage');
        $this->ensureStoreMatch($request, $expense);

        $expense->delete();

        return redirect()->route('expenses.index')->with('success', 'Pengeluaran berhasil dihapus.');
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'category' => ['required', 'in:bahan_baku,operasional'],
            'title' => ['required', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'min:0'],
            'expense_date' => ['required', 'date'],
            'notes' => ['nullable', 'string'],
        ]);
    }

    private function categoryLabel(string $category): string
    {
        return match ($category) {
            'bahan_baku' => 'Bahan Baku',
            default => 'Operasional',
        };
    }
}
