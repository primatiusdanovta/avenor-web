<?php

namespace App\Http\Controllers;

use App\Models\SalesTarget;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class SalesTargetController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizeSuperadmin($request);

        return Inertia::render('SalesTargets/Index', [
            'targets' => $this->targetsForView(),
        ]);
    }

    public function update(Request $request, string $role): RedirectResponse
    {
        $this->authorizeSuperadmin($request);

        abort_unless(in_array($role, ['marketing', 'sales_field_executive'], true), 404);

        $validated = $request->validate([
            'daily_target_qty' => ['required', 'integer', 'min:0'],
            'daily_bonus' => ['required', 'numeric', 'min:0'],
            'weekly_target_qty' => ['required', 'integer', 'min:0'],
            'weekly_bonus' => ['required', 'numeric', 'min:0'],
            'monthly_target_qty' => ['required', 'integer', 'min:0'],
            'monthly_bonus' => ['required', 'numeric', 'min:0'],
        ]);

        SalesTarget::query()->updateOrCreate(
            ['role' => $role],
            $validated
        );

        return redirect()->route('sales-targets.index')->with('success', 'Target penjualan berhasil diperbarui.');
    }

    private function authorizeSuperadmin(Request $request): void
    {
        abort_unless($request->user()->role === 'superadmin', 403);
    }

    private function targetsForView()
    {
        return collect(['marketing', 'sales_field_executive'])
            ->map(function (string $role) {
                $target = SalesTarget::query()->firstWhere('role', $role);

                return [
                    'id' => $target?->id,
                    'role' => $role,
                    'daily_target_qty' => (int) ($target?->daily_target_qty ?? 0),
                    'daily_bonus' => (float) ($target?->daily_bonus ?? 0),
                    'weekly_target_qty' => (int) ($target?->weekly_target_qty ?? 0),
                    'weekly_bonus' => (float) ($target?->weekly_bonus ?? 0),
                    'monthly_target_qty' => (int) ($target?->monthly_target_qty ?? 0),
                    'monthly_bonus' => (float) ($target?->monthly_bonus ?? 0),
                ];
            })
            ->values();
    }
}





