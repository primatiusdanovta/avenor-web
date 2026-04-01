<?php

namespace App\Http\Controllers;

use App\Models\AccountPayable;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class AccountPayableController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        return Inertia::render('AccountPayables/Index', [
            'accountPayables' => AccountPayable::query()
                ->latest('due_date')
                ->latest('id')
                ->get()
                ->map(fn (AccountPayable $payable) => [
                    'id' => $payable->id,
                    'account_payable' => $payable->account_payable,
                    'due_date' => optional($payable->due_date)->format('Y-m-d'),
                    'notes' => $payable->notes,
                    'created_at' => optional($payable->created_at)->format('Y-m-d H:i:s'),
                ])
                ->values(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        AccountPayable::create($this->validatePayload($request));

        return redirect()->route('account-payables.index')->with('success', 'Account payable berhasil ditambahkan.');
    }

    public function update(Request $request, AccountPayable $accountPayable): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $accountPayable->update($this->validatePayload($request));

        return redirect()->route('account-payables.index')->with('success', 'Account payable berhasil diperbarui.');
    }

    public function destroy(Request $request, AccountPayable $accountPayable): RedirectResponse
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $accountPayable->delete();

        return redirect()->route('account-payables.index')->with('success', 'Account payable berhasil dihapus.');
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'account_payable' => ['required', 'string', 'max:255'],
            'due_date' => ['required', 'date'],
            'notes' => ['nullable', 'string'],
        ]);
    }
}
