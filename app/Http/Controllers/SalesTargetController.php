<?php

namespace App\Http\Controllers;

use App\Models\SalesTarget;
use App\Support\SalesRole;
use App\Support\StoreFeature;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class SalesTargetController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorize($request);

        return Inertia::render('SalesTargets/Index', [
            'targets' => $this->targetsForView(),
        ]);
    }

    public function update(Request $request, string $role): RedirectResponse
    {
        $this->authorize($request);

        abort_unless(in_array($role, $this->availableRoles($request), true), 404);

        $isSmoothiesSweetie = StoreFeature::isSmoothiesSweetie($request);
        
        if ($isSmoothiesSweetie && $role === 'revenue_target') {
            // Revenue-based target with KPI and attendance requirements
            $validated = $request->validate([
                'monthly_target_revenue' => ['required', 'numeric', 'min:0'],
                'minimum_kpi_value' => ['required', 'numeric', 'min:0', 'max:100'],
                'maximum_late_days' => ['required', 'integer', 'min:0'],
                'minimum_attendance_percentage' => ['required', 'numeric', 'min:0', 'max:100'],
                'revenue_bonus' => ['required', 'numeric', 'min:0'],
            ]);
            
            SalesTarget::query()->updateOrCreate(
                ['role' => 'revenue_target'],
                $validated
            );
        } else {
            // Standard quantity-based targets
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
        }

        return redirect()->route('sales-targets.index')->with('success', 'Target penjualan berhasil diperbarui.');
    }

    private function authorize(Request $request): void
    {
        $isSmoothiesSweetie = StoreFeature::isSmoothiesSweetie($request);
        $isAllowed = $request->user()->role === 'superadmin' || ($isSmoothiesSweetie && $request->user()->role === SalesRole::OWNER);
        abort_unless($isAllowed, 403);
    }

    private function targetsForView()
    {
        $isSmoothiesSweetie = StoreFeature::isSmoothiesSweetie(request());
        
        return collect($this->availableRoles(request()))
            ->map(function (string $role) use ($isSmoothiesSweetie) {
                $target = SalesTarget::query()->firstWhere('role', $role);
                
                if ($isSmoothiesSweetie && $role === 'revenue_target') {
                    return [
                        'id' => $target?->id,
                        'role' => 'revenue_target',
                        'label' => 'Target Penjualan Karyawan (Berdasarkan Revenue)',
                        'type' => 'revenue',
                        'monthly_target_revenue' => (float) ($target?->monthly_target_revenue ?? 0),
                        'minimum_kpi_value' => (float) ($target?->minimum_kpi_value ?? 0),
                        'maximum_late_days' => (int) ($target?->maximum_late_days ?? 0),
                        'minimum_attendance_percentage' => (float) ($target?->minimum_attendance_percentage ?? 0),
                        'revenue_bonus' => (float) ($target?->revenue_bonus ?? 0),
                    ];
                }

                return [
                    'id' => $target?->id,
                    'role' => $role,
                    'label' => ucfirst($role),
                    'type' => 'quantity',
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

    private function availableRoles(Request $request): array
    {
        if (StoreFeature::isSmoothiesSweetie($request)) {
            return ['karyawan', 'revenue_target'];
        }

        return ['marketing', 'sales_field_executive'];
    }
}





