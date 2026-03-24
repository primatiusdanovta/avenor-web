<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class UserIndexController extends Controller
{
    public function __invoke(Request $request): Response
    {
        abort_unless(in_array($request->user()->role, ['superadmin', 'admin'], true), 403);

        $search = trim((string) $request->string('search'));
        $role = trim((string) $request->string('role'));

        $users = User::query()
            ->when($search !== '', fn ($query) => $query->where('nama', 'like', "%{$search}%"))
            ->when($role !== '', fn ($query) => $query->where('role', $role))
            ->orderBy('id_user')
            ->paginate(10)
            ->withQueryString()
            ->through(fn (User $user) => [
                'id_user' => $user->id_user,
                'nama' => $user->nama,
                'status' => $user->status,
                'role' => $user->role,
                'created_at' => optional($user->created_at)->format('Y-m-d H:i:s'),
            ]);

        return Inertia::render('Users/Index', [
            'filters' => [
                'search' => $search,
                'role' => $role,
            ],
            'users' => $users,
            'roles' => ['superadmin', 'admin', 'marketing', 'reseller'],
        ]);
    }
}