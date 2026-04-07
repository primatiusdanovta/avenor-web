-- SQL tambahan untuk import MariaDB
-- Fokus: Sales Field Executive, consign, pickup batch, bukti foto consign,
-- dan account receivables dinamis.
-- Tanggal: 2026-04-08
-- Jalankan setelah memilih database target di client MariaDB Anda.

START TRANSACTION;

-- =========================================================
-- 1. USERS
-- Tambahkan role sales_field_executive dan migrasikan reseller lama.
-- =========================================================

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

UPDATE `users`
SET `role` = 'sales_field_executive'
WHERE `role` = 'reseller';

-- =========================================================
-- 2. PRODUCT ONHANDS
-- Tambahkan batch pickup untuk tracking barang yang diambil pagi hari.
-- =========================================================

SET @product_onhands_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'product_onhands'
);

SET @pickup_batch_code_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'product_onhands'
      AND COLUMN_NAME = 'pickup_batch_code'
);

SET @manual_sold_quantity_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'product_onhands'
      AND COLUMN_NAME = 'manual_sold_quantity'
);

SET @sql := IF(
    @product_onhands_table_exists = 0,
    'SELECT ''Table product_onhands does not exist'';',
    IF(
        @pickup_batch_code_exists > 0,
        'SELECT ''Column pickup_batch_code already exists'';',
        IF(
            @manual_sold_quantity_exists > 0,
            'ALTER TABLE `product_onhands` ADD COLUMN `pickup_batch_code` VARCHAR(255) NULL AFTER `manual_sold_quantity`;',
            'ALTER TABLE `product_onhands` ADD COLUMN `pickup_batch_code` VARCHAR(255) NULL;'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =========================================================
-- 3. CONSIGNMENTS
-- Header consign per tempat titip.
-- =========================================================

CREATE TABLE IF NOT EXISTS `consignments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `place_name` VARCHAR(255) NOT NULL,
    `address` TEXT NOT NULL,
    `consignment_date` DATE NOT NULL,
    `submitted_at` TIMESTAMP NULL DEFAULT NULL,
    `latitude` DECIMAL(10,7) NOT NULL,
    `longitude` DECIMAL(10,7) NOT NULL,
    `notes` TEXT NULL,
    `handover_proof_photo` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `consignments_user_id_index` (`user_id`),
    KEY `consignments_place_name_index` (`place_name`),
    KEY `consignments_consignment_date_index` (`consignment_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @consignments_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'consignments'
);

SET @consignments_proof_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'consignments'
      AND COLUMN_NAME = 'handover_proof_photo'
);

SET @consignments_notes_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'consignments'
      AND COLUMN_NAME = 'notes'
);

SET @sql := IF(
    @consignments_table_exists = 0,
    'SELECT ''Table consignments does not exist'';',
    IF(
        @consignments_proof_exists > 0,
        'SELECT ''Column handover_proof_photo already exists'';',
        IF(
            @consignments_notes_exists > 0,
            'ALTER TABLE `consignments` ADD COLUMN `handover_proof_photo` VARCHAR(255) NULL AFTER `notes`;',
            'ALTER TABLE `consignments` ADD COLUMN `handover_proof_photo` VARCHAR(255) NULL;'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =========================================================
-- 4. CONSIGNMENT ITEMS
-- Detail product yang dititip, terjual, dan dikembalikan.
-- =========================================================

CREATE TABLE IF NOT EXISTS `consignment_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `consignment_id` BIGINT UNSIGNED NOT NULL,
    `product_onhand_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NULL,
    `product_name` VARCHAR(255) NOT NULL,
    `pickup_batch_code` VARCHAR(255) NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    `sold_quantity` INT NOT NULL DEFAULT 0,
    `returned_quantity` INT NOT NULL DEFAULT 0,
    `status` VARCHAR(100) NOT NULL DEFAULT 'dititipkan',
    `status_notes` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `consignment_items_consignment_id_index` (`consignment_id`),
    KEY `consignment_items_product_onhand_id_index` (`product_onhand_id`),
    KEY `consignment_items_product_id_index` (`product_id`),
    KEY `consignment_items_status_index` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 5. ACCOUNT RECEIVABLES
-- Nilai titip penuh dan piutang berjalan berdasarkan barang terjual.
-- =========================================================

CREATE TABLE IF NOT EXISTS `account_receivables` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `consignment_id` BIGINT UNSIGNED NULL,
    `receivable_name` VARCHAR(255) NOT NULL,
    `place_name` VARCHAR(255) NOT NULL,
    `consignment_date` DATE NOT NULL,
    `due_date` DATE NOT NULL,
    `consigned_value` DECIMAL(14,2) NOT NULL DEFAULT 0,
    `total_value` DECIMAL(14,2) NOT NULL DEFAULT 0,
    `status` VARCHAR(100) NOT NULL DEFAULT 'dititipkan',
    `items_summary` TEXT NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `account_receivables_consignment_id_index` (`consignment_id`),
    KEY `account_receivables_due_date_place_name_index` (`due_date`, `place_name`),
    KEY `account_receivables_status_index` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @account_receivables_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'account_receivables'
);

SET @ar_total_value_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'account_receivables'
      AND COLUMN_NAME = 'total_value'
);

SET @ar_consigned_value_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'account_receivables'
      AND COLUMN_NAME = 'consigned_value'
);

SET @ar_status_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'account_receivables'
      AND COLUMN_NAME = 'status'
);

SET @sql := IF(
    @account_receivables_table_exists = 0,
    'SELECT ''Table account_receivables does not exist'';',
    IF(
        @ar_consigned_value_exists > 0,
        'SELECT ''Column consigned_value already exists'';',
        IF(
            @ar_total_value_exists > 0,
            'ALTER TABLE `account_receivables` ADD COLUMN `consigned_value` DECIMAL(14,2) NOT NULL DEFAULT 0 AFTER `due_date`;',
            'ALTER TABLE `account_receivables` ADD COLUMN `consigned_value` DECIMAL(14,2) NOT NULL DEFAULT 0;'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
    @account_receivables_table_exists = 0,
    'SELECT ''Table account_receivables does not exist'';',
    IF(
        @ar_status_exists > 0,
        'SELECT ''Column status already exists'';',
        IF(
            @ar_total_value_exists > 0,
            'ALTER TABLE `account_receivables` ADD COLUMN `status` VARCHAR(100) NOT NULL DEFAULT ''dititipkan'' AFTER `total_value`;',
            'ALTER TABLE `account_receivables` ADD COLUMN `status` VARCHAR(100) NOT NULL DEFAULT ''dititipkan'';'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `account_receivables`
SET `consigned_value` = `total_value`
WHERE `consigned_value` = 0
  AND `total_value` > 0;

UPDATE `account_receivables`
SET `status` = 'dititipkan'
WHERE `status` IS NULL OR `status` = '';

-- =========================================================
-- 6. BACKFILL ACCOUNT RECEIVABLES DARI DATA CONSIGN LAMA
-- Membuat record baru jika belum ada, lalu menghitung ulang nilainya.
-- =========================================================

SET @consignment_items_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'consignment_items'
);

SET @products_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'products'
);

INSERT INTO `account_receivables` (
    `consignment_id`,
    `receivable_name`,
    `place_name`,
    `consignment_date`,
    `due_date`,
    `consigned_value`,
    `total_value`,
    `status`,
    `items_summary`,
    `notes`,
    `created_at`,
    `updated_at`
)
SELECT
    c.`id` AS `consignment_id`,
    CONCAT('Titipan ', c.`place_name`) AS `receivable_name`,
    c.`place_name`,
    c.`consignment_date`,
    c.`consignment_date` AS `due_date`,
    ROUND(SUM(COALESCE(p.`harga`, 0) * COALESCE(ci.`quantity`, 0)), 2) AS `consigned_value`,
    ROUND(SUM(COALESCE(p.`harga`, 0) * COALESCE(ci.`sold_quantity`, 0)), 2) AS `total_value`,
    CASE
        WHEN SUM(COALESCE(ci.`sold_quantity`, 0)) = 0
             AND SUM(COALESCE(ci.`returned_quantity`, 0)) >= SUM(COALESCE(ci.`quantity`, 0)) THEN 'dikembalikan'
        WHEN SUM(COALESCE(ci.`sold_quantity`, 0)) >= SUM(COALESCE(ci.`quantity`, 0))
             AND SUM(COALESCE(ci.`quantity`, 0)) > 0 THEN 'terjual'
        WHEN SUM(COALESCE(ci.`sold_quantity`, 0)) > 0
             AND (SUM(COALESCE(ci.`quantity`, 0)) - SUM(COALESCE(ci.`sold_quantity`, 0)) - SUM(COALESCE(ci.`returned_quantity`, 0))) > 0 THEN 'sebagian_terjual'
        WHEN SUM(COALESCE(ci.`sold_quantity`, 0)) > 0
             AND SUM(COALESCE(ci.`returned_quantity`, 0)) > 0
             AND (SUM(COALESCE(ci.`quantity`, 0)) - SUM(COALESCE(ci.`sold_quantity`, 0)) - SUM(COALESCE(ci.`returned_quantity`, 0))) = 0 THEN 'selesai'
        WHEN SUM(COALESCE(ci.`returned_quantity`, 0)) > 0
             AND (SUM(COALESCE(ci.`quantity`, 0)) - SUM(COALESCE(ci.`sold_quantity`, 0)) - SUM(COALESCE(ci.`returned_quantity`, 0))) > 0 THEN 'sebagian_dikembalikan'
        ELSE 'dititipkan'
    END AS `status`,
    GROUP_CONCAT(
        CONCAT(
            COALESCE(ci.`product_name`, '-'),
            ' titip ', COALESCE(ci.`quantity`, 0),
            ' | terjual ', COALESCE(ci.`sold_quantity`, 0),
            ' | kembali ', COALESCE(ci.`returned_quantity`, 0)
        )
        ORDER BY ci.`id` SEPARATOR ', '
    ) AS `items_summary`,
    'Backfill otomatis dari data consign' AS `notes`,
    NOW() AS `created_at`,
    NOW() AS `updated_at`
FROM `consignments` c
INNER JOIN `consignment_items` ci ON ci.`consignment_id` = c.`id`
LEFT JOIN `products` p ON p.`id_product` = ci.`product_id`
LEFT JOIN `account_receivables` ar ON ar.`consignment_id` = c.`id`
WHERE @consignments_table_exists > 0
  AND @consignment_items_table_exists > 0
  AND @products_table_exists > 0
  AND ar.`id` IS NULL
GROUP BY c.`id`, c.`place_name`, c.`consignment_date`;

UPDATE `account_receivables` ar
INNER JOIN (
    SELECT
        c.`id` AS `consignment_id`,
        CONCAT('Titipan ', c.`place_name`) AS `receivable_name`,
        c.`place_name`,
        c.`consignment_date`,
        ROUND(SUM(COALESCE(p.`harga`, 0) * COALESCE(ci.`quantity`, 0)), 2) AS `consigned_value`,
        ROUND(SUM(COALESCE(p.`harga`, 0) * COALESCE(ci.`sold_quantity`, 0)), 2) AS `total_value`,
        CASE
            WHEN SUM(COALESCE(ci.`sold_quantity`, 0)) = 0
                 AND SUM(COALESCE(ci.`returned_quantity`, 0)) >= SUM(COALESCE(ci.`quantity`, 0)) THEN 'dikembalikan'
            WHEN SUM(COALESCE(ci.`sold_quantity`, 0)) >= SUM(COALESCE(ci.`quantity`, 0))
                 AND SUM(COALESCE(ci.`quantity`, 0)) > 0 THEN 'terjual'
            WHEN SUM(COALESCE(ci.`sold_quantity`, 0)) > 0
                 AND (SUM(COALESCE(ci.`quantity`, 0)) - SUM(COALESCE(ci.`sold_quantity`, 0)) - SUM(COALESCE(ci.`returned_quantity`, 0))) > 0 THEN 'sebagian_terjual'
            WHEN SUM(COALESCE(ci.`sold_quantity`, 0)) > 0
                 AND SUM(COALESCE(ci.`returned_quantity`, 0)) > 0
                 AND (SUM(COALESCE(ci.`quantity`, 0)) - SUM(COALESCE(ci.`sold_quantity`, 0)) - SUM(COALESCE(ci.`returned_quantity`, 0))) = 0 THEN 'selesai'
            WHEN SUM(COALESCE(ci.`returned_quantity`, 0)) > 0
                 AND (SUM(COALESCE(ci.`quantity`, 0)) - SUM(COALESCE(ci.`sold_quantity`, 0)) - SUM(COALESCE(ci.`returned_quantity`, 0))) > 0 THEN 'sebagian_dikembalikan'
            ELSE 'dititipkan'
        END AS `status`,
        GROUP_CONCAT(
            CONCAT(
                COALESCE(ci.`product_name`, '-'),
                ' titip ', COALESCE(ci.`quantity`, 0),
                ' | terjual ', COALESCE(ci.`sold_quantity`, 0),
                ' | kembali ', COALESCE(ci.`returned_quantity`, 0)
            )
            ORDER BY ci.`id` SEPARATOR ', '
        ) AS `items_summary`
    FROM `consignments` c
    INNER JOIN `consignment_items` ci ON ci.`consignment_id` = c.`id`
    LEFT JOIN `products` p ON p.`id_product` = ci.`product_id`
    WHERE @consignments_table_exists > 0
      AND @consignment_items_table_exists > 0
      AND @products_table_exists > 0
    GROUP BY c.`id`, c.`place_name`, c.`consignment_date`
) src ON src.`consignment_id` = ar.`consignment_id`
SET ar.`receivable_name` = src.`receivable_name`,
    ar.`place_name` = src.`place_name`,
    ar.`consignment_date` = src.`consignment_date`,
    ar.`due_date` = src.`consignment_date`,
    ar.`consigned_value` = src.`consigned_value`,
    ar.`total_value` = src.`total_value`,
    ar.`status` = src.`status`,
    ar.`items_summary` = src.`items_summary`,
    ar.`notes` = COALESCE(ar.`notes`, 'Backfill otomatis dari data consign'),
    ar.`updated_at` = NOW()
WHERE @account_receivables_table_exists > 0
  AND @consignments_table_exists > 0
  AND @consignment_items_table_exists > 0
  AND @products_table_exists > 0;

-- =========================================================
-- 7. FOREIGN KEY TAMBAHAN
-- Dibuat opsional dan aman untuk import ulang.
-- =========================================================

SET @fk_consignments_user_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'consignments'
      AND CONSTRAINT_NAME = 'consignments_user_id_foreign'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @sql := IF(
    @consignments_table_exists = 0 OR @users_table_exists = 0,
    'SELECT ''Skip consignments.user_id foreign key'';',
    IF(
        @fk_consignments_user_exists > 0,
        'SELECT ''Foreign key consignments_user_id_foreign already exists'';',
        'ALTER TABLE `consignments` ADD CONSTRAINT `consignments_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_consignment_items_consignment_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'consignment_items'
      AND CONSTRAINT_NAME = 'consignment_items_consignment_id_foreign'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @sql := IF(
    (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'consignment_items') = 0 OR @consignments_table_exists = 0,
    'SELECT ''Skip consignment_items.consignment_id foreign key'';',
    IF(
        @fk_consignment_items_consignment_exists > 0,
        'SELECT ''Foreign key consignment_items_consignment_id_foreign already exists'';',
        'ALTER TABLE `consignment_items` ADD CONSTRAINT `consignment_items_consignment_id_foreign` FOREIGN KEY (`consignment_id`) REFERENCES `consignments` (`id`) ON DELETE CASCADE;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_account_receivables_consignment_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'account_receivables'
      AND CONSTRAINT_NAME = 'account_receivables_consignment_id_foreign'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @sql := IF(
    @account_receivables_table_exists = 0 OR @consignments_table_exists = 0,
    'SELECT ''Skip account_receivables.consignment_id foreign key'';',
    IF(
        @fk_account_receivables_consignment_exists > 0,
        'SELECT ''Foreign key account_receivables_consignment_id_foreign already exists'';',
        'ALTER TABLE `account_receivables` ADD CONSTRAINT `account_receivables_consignment_id_foreign` FOREIGN KEY (`consignment_id`) REFERENCES `consignments` (`id`) ON DELETE SET NULL;'
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

COMMIT;

-- Catatan:
-- 1. File ini tidak memakai USE database tertentu.
-- 2. Aman untuk import ulang karena memakai IF NOT EXISTS / cek kolom / cek FK.
-- 3. Blok backfill akan membuat atau menghitung ulang AR dari data consign yang sudah ada.
-- 4. Setelah import SQL ini, logika sinkronisasi AR tetap dijalankan oleh aplikasi
--    saat consign dibuat atau status item consign diupdate.
