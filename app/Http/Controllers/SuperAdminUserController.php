<?php

namespace App\Http\Controllers;

use App\Models\PermissionRole;
use App\Models\Store;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class SuperAdminUserController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorizePermission($request, 'users.view');

        $search = trim((string) $request->string('search'));
        $roleId = (int) $request->integer('role_id');

        $users = User::query()
            ->with(['permissionRole:id,name,legacy_role', 'stores:id,display_name'])
            ->when($search !== '', fn ($query) => $query->where('nama', 'like', "%{$search}%"))
            ->when($roleId > 0, fn ($query) => $query->where('permission_role_id', $roleId))
            ->where(function ($query) use ($request) {
                if ($request->user()->role === 'superadmin') {
                    return;
                }

                $query->whereHas('stores', fn ($storeQuery) => $storeQuery->where('stores.id', $this->currentStoreId($request)));
            })
            ->orderBy('id_user')
            ->get(['id_user', 'nama', 'status', 'role', 'permission_role_id', 'created_at'])
            ->map(fn (User $user) => [
                'id_user' => $user->id_user,
                'nama' => $user->nama,
                'status' => $user->status,
                'role' => $user->role,
                'role_id' => $user->permission_role_id,
                'role_label' => $user->permissionRole?->name ?? $user->role,
                'role_description' => $user->permissionRole?->description,
                'permissions' => $user->permissions(),
                'stores' => $user->stores->map(fn (Store $store) => [
                    'id' => $store->id,
                    'display_name' => $store->display_name,
                ])->values(),
                'created_at' => optional($user->created_at)->format('Y-m-d H:i:s'),
            ]);

        $roles = PermissionRole::query()
            ->orderBy('name')
            ->get(['id', 'name', 'legacy_role', 'description', 'permissions', 'is_locked']);

        return Inertia::render('Users/Manage', [
            'filters' => ['search' => $search, 'role_id' => $roleId ?: null],
            'users' => $users,
            'roles' => $roles->map(fn (PermissionRole $role) => [
                'id' => $role->id,
                'name' => $role->name,
                'legacy_role' => $role->legacy_role,
                'description' => $role->description,
                'permissions' => $role->permissions ?? [],
                'is_locked' => $role->is_locked,
            ])->values(),
            'roleOptions' => $roles->map(fn (PermissionRole $role) => [
                'value' => $role->id,
                'label' => $role->name . ' | ' . ucfirst(str_replace('_', ' ', $role->legacy_role)),
            ])->values(),
            'storeOptions' => Store::query()
                ->when($request->user()->role !== 'superadmin', fn ($query) => $query->where('id', $this->currentStoreId($request)))
                ->orderBy('display_name')
                ->get(['id', 'display_name'])
                ->map(fn (Store $store) => ['value' => $store->id, 'label' => $store->display_name])
                ->values(),
            'statuses' => ['aktif', 'nonaktif'],
            'canManageUsers' => $request->user()->hasPermission('users.manage'),
            'canAssignStores' => $request->user()->role === 'superadmin',
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorizePermission($request, 'users.manage');

        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', 'unique:users,nama'],
            'permission_role_id' => ['required', 'exists:permission_roles,id'],
            'store_ids' => ['required', 'array', 'min:1'],
            'store_ids.*' => ['required', 'integer', 'exists:stores,id'],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $role = PermissionRole::query()->findOrFail($validated['permission_role_id']);
        $storeIds = $this->filterAllowedStoreIds($request, $validated['store_ids']);

        $user = User::create([
            'nama' => $validated['nama'],
            'status' => $validated['status'],
            'role' => $role->legacy_role,
            'permission_role_id' => $role->id,
            'password' => $validated['password'],
            'created_at' => now(),
            'require_return_before_checkout' => $role->legacy_role === 'marketing',
        ]);

        $this->syncStores($user, $storeIds);

        return redirect()->route('users.manage')->with('success', 'User baru berhasil ditambahkan.');
    }

    public function update(Request $request, User $user): RedirectResponse
    {
        $this->authorizePermission($request, 'users.manage');
        $this->authorizeManagedUserScope($request, $user);

        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', Rule::unique('users', 'nama')->ignore($user->id_user, 'id_user')],
            'permission_role_id' => ['required', 'exists:permission_roles,id'],
            'store_ids' => ['required', 'array', 'min:1'],
            'store_ids.*' => ['required', 'integer', 'exists:stores,id'],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ]);

        $role = PermissionRole::query()->findOrFail($validated['permission_role_id']);
        $storeIds = $this->filterAllowedStoreIds($request, $validated['store_ids']);

        if (empty($validated['password'])) {
            unset($validated['password']);
        }

        $user->update([
            'nama' => $validated['nama'],
            'status' => $validated['status'],
            'role' => $role->legacy_role,
            'permission_role_id' => $role->id,
            'password' => $validated['password'] ?? $user->password,
            'require_return_before_checkout' => $role->legacy_role === 'marketing',
        ]);
        $this->syncStores($user, $storeIds);

        return redirect()->route('users.manage')->with('success', 'User berhasil diperbarui.');
    }

    public function destroy(Request $request, User $user): RedirectResponse
    {
        $this->authorizePermission($request, 'users.manage');
        $this->authorizeManagedUserScope($request, $user);
        abort_if($request->user()->is($user), 422, 'User yang sedang login tidak dapat dihapus.');

        $user->delete();

        return redirect()->route('users.manage')->with('success', 'User berhasil dihapus.');
    }

    private function filterAllowedStoreIds(Request $request, array $storeIds): array
    {
        $allowedStoreIds = $request->user()->role === 'superadmin'
            ? Store::query()->pluck('id')->all()
            : [$this->currentStoreId($request)];

        $filtered = array_values(array_intersect(array_map('intval', $storeIds), array_map('intval', $allowedStoreIds)));
        abort_if($filtered === [], 422, 'Store user tidak valid.');

        return $filtered;
    }

    private function syncStores(User $user, array $storeIds): void
    {
        $syncPayload = [];
        foreach ($storeIds as $index => $storeId) {
            $syncPayload[$storeId] = ['is_primary' => $index === 0];
        }

        $user->stores()->sync($syncPayload);
    }

    private function authorizeManagedUserScope(Request $request, User $user): void
    {
        if ($request->user()->role === 'superadmin') {
            return;
        }

        abort_unless(
            $user->stores()->where('stores.id', $this->currentStoreId($request))->exists(),
            404
        );
    }
}
