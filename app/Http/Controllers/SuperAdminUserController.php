<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Support\SalesRole;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class SuperAdminUserController extends Controller
{
    public function index(Request $request): Response
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $search = trim((string) $request->string('search'));
        $role = trim((string) $request->string('role'));

        $users = User::query()
            ->when($search !== '', fn ($query) => $query->where('nama', 'like', "%{$search}%"))
            ->when($role !== '', fn ($query) => $query->where('role', $role))
            ->orderBy('id_user')
            ->get(['id_user', 'nama', 'status', 'role', 'created_at'])
            ->map(fn (User $user) => [
                'id_user' => $user->id_user,
                'nama' => $user->nama,
                'status' => $user->status,
                'role' => $user->role,
                'role_label' => SalesRole::label($user->role),
                'created_at' => optional($user->created_at)->format('Y-m-d H:i:s'),
            ]);

        return Inertia::render('Users/Manage', [
            'filters' => ['search' => $search, 'role' => $role ?: null],
            'users' => $users,
            'roles' => ['superadmin', 'admin', 'marketing', SalesRole::SALES_FIELD_EXECUTIVE],
            'roleOptions' => [
                ['value' => 'superadmin', 'label' => 'Superadmin'],
                ['value' => 'admin', 'label' => 'Admin'],
                ['value' => 'marketing', 'label' => 'Marketing'],
                ['value' => SalesRole::SALES_FIELD_EXECUTIVE, 'label' => 'Sales Field Executive'],
            ],
            'statuses' => ['aktif', 'nonaktif'],
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', 'unique:users,nama'],
            'role' => ['required', Rule::in(['superadmin', 'admin', 'marketing', SalesRole::SALES_FIELD_EXECUTIVE])],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        User::create($validated + [
            'created_at' => now(),
            'require_return_before_checkout' => SalesRole::defaultRequireReturnBeforeCheckout($validated['role']),
        ]);

        return redirect()->route('users.manage')->with('success', 'User baru berhasil ditambahkan.');
    }

    public function update(Request $request, User $user): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);

        $validated = $request->validate([
            'nama' => ['required', 'string', 'max:255', Rule::unique('users', 'nama')->ignore($user->id_user, 'id_user')],
            'role' => ['required', Rule::in(['superadmin', 'admin', 'marketing', SalesRole::SALES_FIELD_EXECUTIVE])],
            'status' => ['required', Rule::in(['aktif', 'nonaktif'])],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ]);

        if (empty($validated['password'])) {
            unset($validated['password']);
        }

        $validated['require_return_before_checkout'] = SalesRole::defaultRequireReturnBeforeCheckout($validated['role']);

        $user->update($validated);

        return redirect()->route('users.manage')->with('success', 'User berhasil diperbarui.');
    }

    public function destroy(Request $request, User $user): RedirectResponse
    {
        abort_unless($request->user()->role === 'superadmin', 403);
        abort_if($request->user()->is($user), 422, 'Superadmin yang sedang login tidak dapat dihapus.');

        $user->delete();

        return redirect()->route('users.manage')->with('success', 'User berhasil dihapus.');
    }
}
