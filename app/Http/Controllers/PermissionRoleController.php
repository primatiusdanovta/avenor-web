<?php

namespace App\Http\Controllers;

use App\Models\PermissionRole;
use App\Support\PermissionCatalog;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class PermissionRoleController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'roles.view');

        $roles = PermissionRole::query()
            ->orderBy('name')
            ->get()
            ->map(fn (PermissionRole $role) => [
                'id' => $role->id,
                'key' => $role->key,
                'name' => $role->name,
                'legacy_role' => $role->legacy_role,
                'description' => $role->description,
                'permissions' => $role->permissions ?? [],
                'is_locked' => $role->is_locked,
                'users_count' => $role->users()->count(),
            ])
            ->values();

        return Inertia::render('Roles/Index', [
            'roles' => $roles,
            'permissionGroups' => PermissionCatalog::groups(),
            'legacyRoleOptions' => [
                ['value' => 'superadmin', 'label' => 'Superadmin'],
                ['value' => 'admin', 'label' => 'Admin'],
                ['value' => 'marketing', 'label' => 'Marketing'],
                ['value' => 'sales_field_executive', 'label' => 'Sales Field Executive'],
                ['value' => 'owner', 'label' => 'Owner'],
                ['value' => 'karyawan', 'label' => 'Karyawan'],
            ],
            'canManage' => $request->user()->role === 'superadmin' && $request->user()->hasPermission('roles.manage'),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless($request->user()?->role === 'superadmin', 403);
        $this->authorizePermission($request, 'roles.manage');

        PermissionRole::query()->create($this->validatePayload($request));

        return redirect()->route('roles.index')->with('success', 'Role checklist berhasil ditambahkan.');
    }

    public function update(Request $request, PermissionRole $role): RedirectResponse
    {
        abort_unless($request->user()?->role === 'superadmin', 403);
        $this->authorizePermission($request, 'roles.manage');

        $role->update($this->validatePayload($request, $role));

        return redirect()->route('roles.index')->with('success', 'Role checklist berhasil diperbarui.');
    }

    public function destroy(Request $request, PermissionRole $role): RedirectResponse
    {
        abort_unless($request->user()?->role === 'superadmin', 403);
        $this->authorizePermission($request, 'roles.manage');
        abort_if($role->is_locked, 422, 'Role sistem tidak dapat dihapus.');
        abort_if($role->users()->exists(), 422, 'Role masih dipakai user dan belum bisa dihapus.');

        $role->delete();

        return redirect()->route('roles.index')->with('success', 'Role checklist berhasil dihapus.');
    }

    private function validatePayload(Request $request, ?PermissionRole $role = null): array
    {
        $validated = $request->validate([
            'key' => ['required', 'string', 'max:255', Rule::unique('permission_roles', 'key')->ignore($role?->id)],
            'name' => ['required', 'string', 'max:255'],
            'legacy_role' => ['required', Rule::in(['superadmin', 'admin', 'marketing', 'sales_field_executive', 'owner', 'karyawan'])],
            'description' => ['nullable', 'string'],
            'permissions' => ['required', 'array', 'min:1'],
            'permissions.*' => ['required', Rule::in(array_map(fn (array $item) => $item['key'], PermissionCatalog::flat()))],
        ]);

        $validated['permissions'] = array_values(array_unique($validated['permissions']));

        return $validated;
    }
}
