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

    public function update(Request $request, SalesTarget $salesTarget): RedirectResponse
    {
        $this->authorizeSuperadmin($request);

        $validated = $request->validate([
            'daily_target_qty' => ['required', 'integer', 'min:0'],
            'daily_bonus' => ['required', 'numeric', 'min:0'],
            'weekly_target_qty' => ['required', 'integer', 'min:0'],
            'weekly_bonus' => ['required', 'numeric', 'min:0'],
            'monthly_target_qty' => ['required', 'integer', 'min:0'],
            'monthly_bonus' => ['required', 'numeric', 'min:0'],
        ]);

        $salesTarget->update($validated);

        return redirect()->route('sales-targets.index')->with('success', 'Target penjualan berhasil diperbarui.');
    }

    private function authorizeSuperadmin(Request $request): void
    {
        abort_unless($request->user()->role === 'superadmin', 403);
    }

    private function targetsForView()
    {
        return collect(['marketing', 'reseller'])
            ->map(function (string $role) {
                $target = SalesTarget::query()->firstOrCreate(
                    ['role' => $role],
                    [
                        'daily_target_qty' => 0,
                        'daily_bonus' => 0,
                        'weekly_target_qty' => 0,
                        'weekly_bonus' => 0,
                        'monthly_target_qty' => 0,
                        'monthly_bonus' => 0,
                    ]
                );

                return [
                    'id' => $target->id,
                    'role' => $target->role,
                    'daily_target_qty' => (int) $target->daily_target_qty,
                    'daily_bonus' => (float) $target->daily_bonus,
                    'weekly_target_qty' => (int) $target->weekly_target_qty,
                    'weekly_bonus' => (float) $target->weekly_bonus,
                    'monthly_target_qty' => (int) $target->monthly_target_qty,
                    'monthly_bonus' => (float) $target->monthly_bonus,
                ];
            })
            ->values();
    }
}
