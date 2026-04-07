-- SQL tambahan untuk import MariaDB
-- Fokus: sinkronisasi role Field Team dan target penjualan setelah migrasi reseller -> sales_field_executive.
-- Tanggal: 2026-04-08
-- Jalankan setelah memilih database target di client MariaDB Anda.

START TRANSACTION;

-- 1. Pastikan enum users.role mendukung sales_field_executive.
SET @users_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'users'
);

SET @users_role_is_enum := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'users'
      AND COLUMN_NAME = 'role'
      AND COLUMN_TYPE LIKE 'enum(%'
);

SET @users_role_has_sfe := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'users'
      AND COLUMN_NAME = 'role'
      AND COLUMN_TYPE LIKE '%sales_field_executive%'
);

SET @sql := IF(
    @users_table_exists = 0,
    'SELECT ''Table users does not exist'';',
    IF(
        @users_role_is_enum = 0,
        'SELECT ''Column users.role is not ENUM; skip alter'';',
        IF(
            @users_role_has_sfe > 0,
            'SELECT ''Role sales_field_executive already exists'';',
            'ALTER TABLE `users` MODIFY `role` ENUM(''superadmin'',''admin'',''marketing'',''sales_field_executive'') NOT NULL;'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Migrasikan role reseller lama menjadi sales_field_executive.
UPDATE `users`
SET `role` = 'sales_field_executive'
WHERE `role` = 'reseller';

-- 3. Jika ada akun placeholder reseller lama, ubah namanya agar konsisten dengan seed terbaru.
UPDATE `users`
SET `nama` = 'field executive'
WHERE `nama` = 'reseller'
  AND `role` = 'sales_field_executive';

-- 4. Pastikan sales target untuk sales_field_executive tersedia.
UPDATE `sales_targets`
SET `role` = 'sales_field_executive'
WHERE `role` = 'reseller';

INSERT INTO `sales_targets` (
    `role`, `daily_target_qty`, `daily_bonus`, `weekly_target_qty`, `weekly_bonus`, `monthly_target_qty`, `monthly_bonus`, `created_at`, `updated_at`
)
SELECT 'sales_field_executive', 0, 0.00, 0, 0.00, 0, 0.00, NOW(), NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM `sales_targets` WHERE `role` = 'sales_field_executive'
);

COMMIT;
