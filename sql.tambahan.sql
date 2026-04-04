-- SQL tambahan untuk MariaDB
-- Dibuat dari perubahan schema yang ditambahkan di project Avenor Web/mobile.
-- Tanggal: 2026-04-05
--
-- Aman dijalankan berulang untuk sebagian besar bagian karena memakai
-- pengecekan information_schema / IF NOT EXISTS.

START TRANSACTION;

-- =========================================================
-- 1. PRODUCT ONHANDS
-- Tambahan kolom untuk menyimpan total retur yang benar-benar sudah approve.
-- =========================================================

SET @approved_return_quantity_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'product_onhands'
      AND COLUMN_NAME = 'approved_return_quantity'
);

SET @sql := IF(
    @approved_return_quantity_exists = 0,
    'ALTER TABLE `product_onhands` ADD COLUMN `approved_return_quantity` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `quantity_dikembalikan`;',
    'SELECT ''Column approved_return_quantity already exists'';'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =========================================================
-- 2. MARKETING NOTIFICATIONS
-- Untuk notifikasi manual dan terjadwal dari backend superadmin.
-- =========================================================

CREATE TABLE IF NOT EXISTS `marketing_notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `created_by` BIGINT UNSIGNED NULL,
    `title` VARCHAR(255) NOT NULL,
    `body` TEXT NOT NULL,
    `target_role` VARCHAR(255) NOT NULL DEFAULT 'marketing',
    `status` VARCHAR(255) NOT NULL DEFAULT 'draft',
    `scheduled_at` TIMESTAMP NULL DEFAULT NULL,
    `published_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `marketing_notifications_created_by_index` (`created_by`),
    CONSTRAINT `marketing_notifications_created_by_foreign`
        FOREIGN KEY (`created_by`) REFERENCES `users` (`id_user`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 3. MOBILE ACCESS TOKENS
-- Tambahan kolom push token. Walau sekarang Anda memilih notifikasi manual,
-- kolom ini sudah sempat ditambahkan di codebase.
-- =========================================================

SET @mobile_push_token_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'mobile_access_tokens'
      AND COLUMN_NAME = 'push_token'
);

SET @sql := IF(
    @mobile_push_token_exists = 0,
    'ALTER TABLE `mobile_access_tokens`
        ADD COLUMN `push_token` TEXT NULL AFTER `token`,
        ADD COLUMN `push_platform` VARCHAR(20) NULL AFTER `push_token`,
        ADD COLUMN `push_token_updated_at` TIMESTAMP NULL DEFAULT NULL AFTER `push_platform`;',
    'SELECT ''Push token columns already exist'';'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =========================================================
-- 4. MARKETING BONUS ADJUSTMENTS
-- Untuk bonus manual marketing dari superadmin.
-- =========================================================

CREATE TABLE IF NOT EXISTS `marketing_bonus_adjustments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `created_by` BIGINT UNSIGNED NULL,
    `bonus_month` DATE NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `note` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `marketing_bonus_adjustments_user_id_index` (`user_id`),
    KEY `marketing_bonus_adjustments_created_by_index` (`created_by`),
    CONSTRAINT `marketing_bonus_adjustments_user_id_foreign`
        FOREIGN KEY (`user_id`) REFERENCES `users` (`id_user`)
        ON DELETE CASCADE,
    CONSTRAINT `marketing_bonus_adjustments_created_by_foreign`
        FOREIGN KEY (`created_by`) REFERENCES `users` (`id_user`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- =========================================================
-- CATATAN
-- 1. Fitur QR sales tidak butuh kolom baru karena disimpan di JSON
--    tabel global_settings dengan key `master_social_hub`.
-- 2. Jika tabel `global_settings` belum ada, jalankan migration/table
--    bawaan project lebih dulu.
-- 3. File ini hanya merangkum tambahan schema yang dibuat pada perubahan
--    terbaru, supaya bisa di-import langsung di MariaDB.
-- =========================================================
