<?php

use App\Http\Controllers\ApprovalController;
use App\Http\Controllers\AccountPayableController;
use App\Http\Controllers\ArticleController;
use App\Http\Controllers\ArticleLandingController;
use App\Http\Controllers\ArticlesLandingController;
use App\Http\Controllers\ApplicantController;
use App\Http\Controllers\CareerApplicationController;
use App\Http\Controllers\CarrersController;
use App\Http\Controllers\Auth\AuthenticatedSessionController;
use App\Http\Controllers\ContentCreatorController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\GlobalSettingController;
use App\Http\Controllers\HppController;
use App\Http\Controllers\MasterGatewayController;
use App\Http\Controllers\LandingPageBuilderController;
use App\Http\Controllers\LandingPageManagerController;
use App\Http\Controllers\MarketingAttendanceController;
use App\Http\Controllers\MarketingManagementController;
use App\Http\Controllers\MarketingNotificationController;
use App\Http\Controllers\OfflineSaleController;
use App\Http\Controllers\OnlineSaleController;
use App\Http\Controllers\ProductLandingController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ProductKnowledgeController;
use App\Http\Controllers\ProductOnhandManagementController;
use App\Http\Controllers\PromoController;
use App\Http\Controllers\RawMaterialController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SalesTargetController;
use App\Http\Controllers\SeoSettingController;
use App\Http\Controllers\SuperAdminUserController;
use App\Http\Controllers\TechnicalSeoController;
use App\Support\ProductLandingData;
use Illuminate\Support\Facades\Route;

/** @var string $administratorPrefix */
$administratorPrefix = trim((string) env('ADMIN_ROUTE_PREFIX', 'administrator'), '/');

Route::get('/', MasterGatewayController::class)->name('landing-page');
Route::get('/robots.txt', [TechnicalSeoController::class, 'robots'])->name('seo.robots');
Route::get('/sitemap.xml', [TechnicalSeoController::class, 'sitemap'])->name('seo.sitemap');
Route::get('/product', function () {
    $product = ProductLandingData::firstActiveProduct();
    abort_if(! $product, 404);

    return redirect()->route('product.landing', ['slug' => $product->landing_slug]);
})->name('product.index');
Route::get('/master-hero-video', [GlobalSettingController::class, 'showMasterHeroVideo'])->name('global-settings.master-hero-video');
Route::get('/sales-app-apk', [GlobalSettingController::class, 'showSalesAppApk'])->middleware('auth')->name('global-settings.sales-app-apk');
Route::get('/sales-qr-image', [GlobalSettingController::class, 'showSalesQrImage'])->name('global-settings.sales-qr-image');
Route::get('/product-image/{product}', [ProductController::class, 'showPublicImage'])->name('products.public-image');
Route::get('/product-bottle-image/{product}', [ProductController::class, 'showPublicBottleImage'])->name('products.public-bottle-image');
Route::get('/product-gallery-image/{image}', [ProductController::class, 'showPublicGalleryImage'])->name('product-images.public');
Route::get('/careers', fn () => redirect('/carrers'))->name('careers.redirect');
Route::get('/carrers', CarrersController::class)->name('carrers.index');
Route::post('/carrers/apply', [CareerApplicationController::class, 'store'])->name('carrers.apply');
Route::get('/articles', ArticlesLandingController::class)->name('articles.index');
Route::get('/article-image/{article}', [ArticleController::class, 'showPublicImage'])->name('articles.public-image');
Route::get('/article/{slug}', ArticleLandingController::class)->name('articles.show');
Route::get('/product/{slug}', ProductLandingController::class)
    ->middleware(\App\Http\Middleware\InjectProductLandingSeo::class)
    ->name('product.landing');

Route::redirect('/login', '/' . $administratorPrefix . '/login');

Route::prefix($administratorPrefix)->group(function () {
    Route::get('/', function () {
        return auth()->check()
            ? redirect()->route('dashboard')
            : redirect()->route('login');
    });

    Route::middleware('guest')->group(function () {
        Route::get('/login', [AuthenticatedSessionController::class, 'create'])->name('login');
        Route::get('/login/captcha', [AuthenticatedSessionController::class, 'captcha'])->name('login.captcha');
        Route::post('/login', [AuthenticatedSessionController::class, 'store'])->name('login.store');
    });

    Route::middleware('auth')->group(function () {
        Route::get('/dashboard', DashboardController::class)->name('dashboard');
        Route::get('/users', [SuperAdminUserController::class, 'index'])->name('users.manage');
        Route::post('/users', [SuperAdminUserController::class, 'store'])->name('users.store');
        Route::put('/users/{user}', [SuperAdminUserController::class, 'update'])->name('users.update');
        Route::delete('/users/{user}', [SuperAdminUserController::class, 'destroy'])->name('users.destroy');

        Route::get('/marketing', [MarketingManagementController::class, 'index'])->name('marketing.index');
        Route::get('/marketing/{user}/detail', [MarketingManagementController::class, 'show'])->name('marketing.show');
        Route::post('/marketing', [MarketingManagementController::class, 'store'])->name('marketing.store');
        Route::put('/marketing/{user}', [MarketingManagementController::class, 'update'])->name('marketing.update');
        Route::put('/marketing/{user}/return-policy', [MarketingManagementController::class, 'updateReturnPolicy'])->name('marketing.return-policy.update');
        Route::delete('/marketing/{user}', [MarketingManagementController::class, 'destroy'])->name('marketing.destroy');
        Route::post('/marketing/{user}/manual-bonuses', [MarketingManagementController::class, 'storeManualBonus'])->name('marketing.manual-bonuses.store');

        Route::middleware('superadmin')->group(function () {
            Route::get('/landing-page-manager', [LandingPageManagerController::class, 'index'])->name('landing-page-manager.index');
            Route::put('/landing-page-manager/sections/{section}', [LandingPageManagerController::class, 'updateSection'])->name('landing-page-manager.sections.update');
            Route::post('/landing-page-manager/ingredients', [LandingPageManagerController::class, 'storeIngredient'])->name('landing-page-manager.ingredients.store');
            Route::put('/landing-page-manager/ingredients/{ingredient}', [LandingPageManagerController::class, 'updateIngredient'])->name('landing-page-manager.ingredients.update');
            Route::delete('/landing-page-manager/ingredients/{ingredient}', [LandingPageManagerController::class, 'destroyIngredient'])->name('landing-page-manager.ingredients.destroy');
            Route::put('/landing-page-manager/visibility', [LandingPageManagerController::class, 'updateVisibility'])->name('landing-page-manager.visibility.update');
            Route::get('/landing-page-builder', [LandingPageBuilderController::class, 'index'])->name('landing-page-builder.index');
            Route::put('/landing-page-builder/{product}', [LandingPageBuilderController::class, 'update'])->name('landing-page-builder.update');
            Route::get('/global-settings', [GlobalSettingController::class, 'index'])->name('global-settings.index');
            Route::put('/global-settings/master-social-hub', [GlobalSettingController::class, 'updateMasterSocialHub'])->name('global-settings.master-social-hub.update');
            Route::get('/seo-settings', [SeoSettingController::class, 'index'])->name('seo-settings.index');
            Route::put('/seo-settings', [SeoSettingController::class, 'update'])->name('seo-settings.update');
            Route::get('/applicants', [ApplicantController::class, 'index'])->name('applicants.index');
            Route::get('/applicants/{application}/files/{fileKey}', [ApplicantController::class, 'showFile'])->name('applicants.files.show');
            Route::post('/applicants/connect-content-creators', [ApplicantController::class, 'connectToContentCreator'])->name('applicants.connect-content-creators');
            Route::get('/articles', [ArticleController::class, 'index'])->name('articles.manage');
            Route::post('/articles', [ArticleController::class, 'store'])->name('articles.store');
            Route::put('/articles/{article}', [ArticleController::class, 'update'])->name('articles.update');
            Route::delete('/articles/{article}', [ArticleController::class, 'destroy'])->name('articles.destroy');
            Route::get('/notifications', [MarketingNotificationController::class, 'index'])->name('notifications.index');
            Route::post('/notifications', [MarketingNotificationController::class, 'store'])->name('notifications.store');
            Route::put('/notifications/{notification}', [MarketingNotificationController::class, 'update'])->name('notifications.update');
            Route::post('/notifications/{notification}/publish', [MarketingNotificationController::class, 'publish'])->name('notifications.publish');
            Route::delete('/notifications/{notification}', [MarketingNotificationController::class, 'destroy'])->name('notifications.destroy');
        });

        Route::get('/approvals', [ApprovalController::class, 'index'])->name('approvals.index');
        Route::get('/hpp', [HppController::class, 'index'])->name('hpp.index');
        Route::post('/hpp', [HppController::class, 'store'])->name('hpp.store');
        Route::delete('/hpp/{hppCalculation}', [HppController::class, 'destroy'])->name('hpp.destroy');
        Route::get('/raw-materials', [RawMaterialController::class, 'index'])->name('raw-materials.index');
        Route::post('/raw-materials', [RawMaterialController::class, 'store'])->name('raw-materials.store');
        Route::post('/raw-materials/restock', [RawMaterialController::class, 'restock'])->name('raw-materials.restock');
        Route::put('/raw-materials/{rawMaterial}', [RawMaterialController::class, 'update'])->name('raw-materials.update');
        Route::delete('/raw-materials/{rawMaterial}', [RawMaterialController::class, 'destroy'])->name('raw-materials.destroy');

        Route::get('/sales-targets', [SalesTargetController::class, 'index'])->name('sales-targets.index');
        Route::put('/sales-targets/{role}', [SalesTargetController::class, 'update'])->name('sales-targets.update');

        Route::get('/online-sales', [OnlineSaleController::class, 'index'])->name('online-sales.index');
        Route::post('/online-sales/import', [OnlineSaleController::class, 'import'])->name('online-sales.import');
        Route::post('/online-sales/debug-import', [OnlineSaleController::class, 'debugImport'])->name('online-sales.debug-import');

        Route::get('/reports', [ReportController::class, 'index'])->name('reports.index');
        Route::get('/reports/export-pdf', [ReportController::class, 'exportPdf'])->name('reports.export-pdf');
        Route::get('/expenses', [ExpenseController::class, 'index'])->name('expenses.index');
        Route::post('/expenses', [ExpenseController::class, 'store'])->name('expenses.store');
        Route::put('/expenses/{expense}', [ExpenseController::class, 'update'])->name('expenses.update');
        Route::delete('/expenses/{expense}', [ExpenseController::class, 'destroy'])->name('expenses.destroy');
        Route::get('/account-payables', [AccountPayableController::class, 'index'])->name('account-payables.index');
        Route::post('/account-payables', [AccountPayableController::class, 'store'])->name('account-payables.store');
        Route::put('/account-payables/{accountPayable}', [AccountPayableController::class, 'update'])->name('account-payables.update');
        Route::delete('/account-payables/{accountPayable}', [AccountPayableController::class, 'destroy'])->name('account-payables.destroy');

        Route::get('/marketing/attendance', [MarketingAttendanceController::class, 'index'])->name('marketing.attendance.index');
        Route::post('/marketing/attendance/check-in', [MarketingAttendanceController::class, 'checkIn'])->name('marketing.attendance.check-in');
        Route::post('/marketing/attendance/check-out', [MarketingAttendanceController::class, 'checkOut'])->name('marketing.attendance.check-out');
        Route::post('/marketing/location', [MarketingAttendanceController::class, 'storeLocation'])->name('marketing.location.store');

        Route::get('/products', [ProductController::class, 'index'])->name('products.index');
        Route::get('/product-onhands', [ProductOnhandManagementController::class, 'index'])->name('product-onhands.index');
        Route::post('/product-onhands', [ProductOnhandManagementController::class, 'store'])->name('product-onhands.store');
        Route::put('/product-onhands/{onhand}', [ProductOnhandManagementController::class, 'update'])->name('product-onhands.update');
        Route::delete('/product-onhands/{onhand}', [ProductOnhandManagementController::class, 'destroy'])->name('product-onhands.destroy');
        Route::get('/products/{product}/image', [ProductController::class, 'showImage'])->name('products.image');
        Route::get('/product-knowledge', [ProductKnowledgeController::class, 'index'])->name('products.knowledge');
        Route::post('/products', [ProductController::class, 'store'])->name('products.store');
        Route::put('/products/{product}', [ProductController::class, 'update'])->name('products.update');
        Route::delete('/products/{product}', [ProductController::class, 'destroy'])->name('products.destroy');
        Route::post('/products/take', [ProductController::class, 'take'])->name('products.take');
        Route::post('/products/onhand/{onhand}/take-approve', [ProductController::class, 'approveTake'])->name('products.onhand.take-approve');
        Route::post('/products/onhand/{onhand}/take-reject', [ProductController::class, 'rejectTake'])->name('products.onhand.take-reject');
        Route::put('/products/onhand/{onhand}/return', [ProductController::class, 'requestReturn'])->name('products.onhand.return');
        Route::post('/products/onhand/{onhand}/approve', [ProductController::class, 'approveReturn'])->name('products.onhand.approve');
        Route::post('/products/onhand/{onhand}/reject', [ProductController::class, 'rejectReturn'])->name('products.onhand.reject');

        Route::get('/promos', [PromoController::class, 'index'])->name('promos.index');
        Route::post('/promos', [PromoController::class, 'store'])->name('promos.store');
        Route::put('/promos/{promo}', [PromoController::class, 'update'])->name('promos.update');
        Route::delete('/promos/{promo}', [PromoController::class, 'destroy'])->name('promos.destroy');

        Route::get('/customers', [CustomerController::class, 'index'])->name('customers.index');
        Route::post('/customers', [CustomerController::class, 'store'])->name('customers.store');
        Route::put('/customers/{customer}', [CustomerController::class, 'update'])->name('customers.update');
        Route::delete('/customers/{customer}', [CustomerController::class, 'destroy'])->name('customers.destroy');

        Route::get('/content-creators', [ContentCreatorController::class, 'index'])->name('content-creators.index');
        Route::post('/content-creators', [ContentCreatorController::class, 'store'])->name('content-creators.store');
        Route::put('/content-creators/{contentCreator}', [ContentCreatorController::class, 'update'])->name('content-creators.update');
        Route::delete('/content-creators/{contentCreator}', [ContentCreatorController::class, 'destroy'])->name('content-creators.destroy');

        Route::get('/offline-sales', [OfflineSaleController::class, 'index'])->name('offline-sales.index');
        Route::post('/offline-sales', [OfflineSaleController::class, 'store'])->name('offline-sales.store');
        Route::put('/offline-sales/{sale}', [OfflineSaleController::class, 'update'])->name('offline-sales.update');
        Route::delete('/offline-sales/{sale}', [OfflineSaleController::class, 'destroy'])->name('offline-sales.destroy');
        Route::post('/offline-sales/{sale}/approve', [OfflineSaleController::class, 'approve'])->name('offline-sales.approve');
        Route::post('/offline-sales/{sale}/reject', [OfflineSaleController::class, 'reject'])->name('offline-sales.reject');
        Route::get('/offline-sales/{sale}/proof', [OfflineSaleController::class, 'showProof'])->name('offline-sales.proof');

        Route::post('/logout', [AuthenticatedSessionController::class, 'destroy'])->name('logout');
    });
});
