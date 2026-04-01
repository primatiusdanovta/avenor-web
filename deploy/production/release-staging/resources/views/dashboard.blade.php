@extends('adminlte::page')

@section('title', 'Dashboard')

@section('content_header')
    <div class="d-flex justify-content-between align-items-center">
        <h1 class="m-0">Dashboard Utama</h1>
        <form action="{{ route('logout') }}" method="POST">
            @csrf
            <button type="submit" class="btn btn-outline-danger btn-sm">
                <i class="fas fa-sign-out-alt mr-1"></i>
                Logout
            </button>
        </form>
    </div>
@stop

@section('content')
    <div class="row">
        <div class="col-12">
            <div class="card card-primary card-outline">
                <div class="card-body">
                    <h4 class="mb-1">Selamat datang, {{ auth()->user()->nama }}</h4>
                    <p class="text-muted mb-0">
                        Anda login sebagai <strong>{{ strtoupper(auth()->user()->role) }}</strong>
                        dengan status <strong>{{ ucfirst(auth()->user()->status) }}</strong>.
                    </p>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-md-4">
            <div class="small-box bg-info">
                <div class="inner">
                    <h3>Laravel 12</h3>
                    <p>Framework berhasil terpasang</p>
                </div>
                <div class="icon">
                    <i class="fas fa-cubes"></i>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="small-box bg-success">
                <div class="inner">
                    <h3>AdminLTE</h3>
                    <p>Layout admin siap dipakai</p>
                </div>
                <div class="icon">
                    <i class="fas fa-tachometer-alt"></i>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="small-box bg-warning">
                <div class="inner">
                    <h3>Next Step</h3>
                    <p>Tambahkan auth, menu, dan modul aplikasi</p>
                </div>
                <div class="icon">
                    <i class="fas fa-layer-group"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-header">
            <h3 class="card-title">Status Instalasi</h3>
        </div>
        <div class="card-body">
            <p class="mb-0">
                Login sudah memakai session auth Laravel, password hash, CSRF
                protection, dan rate limiting untuk percobaan login.
            </p>
        </div>
    </div>
@stop
