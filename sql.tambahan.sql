-- SQL tambahan untuk import MariaDB
-- Tanpa menyebut nama database secara eksplisit.
-- Tanggal: 2026-04-06
-- Jalankan setelah memilih database target di client MariaDB Anda.

START TRANSACTION;

-- =========================================================
-- 1. PRODUCT ONHANDS
-- Tambahan kolom retur approve dan koreksi manual barang terjual.
-- =========================================================

SET @product_onhands_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'product_onhands'
);

SET @product_onhands_quantity_dikembalikan_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'product_onhands'
      AND COLUMN_NAME = 'quantity_dikembalikan'
);

SET @approved_return_quantity_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'product_onhands'
      AND COLUMN_NAME = 'approved_return_quantity'
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
        @approved_return_quantity_exists > 0,
        'SELECT ''Column approved_return_quantity already exists'';',
        IF(
            @product_onhands_quantity_dikembalikan_exists > 0,
            'ALTER TABLE `product_onhands` ADD COLUMN `approved_return_quantity` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `quantity_dikembalikan`;',
            'ALTER TABLE `product_onhands` ADD COLUMN `approved_return_quantity` INT UNSIGNED NOT NULL DEFAULT 0;'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
    @product_onhands_table_exists = 0,
    'SELECT ''Table product_onhands does not exist'';',
    IF(
        @manual_sold_quantity_exists > 0,
        'SELECT ''Column manual_sold_quantity already exists'';',
        IF(
            @approved_return_quantity_exists > 0,
            'ALTER TABLE `product_onhands` ADD COLUMN `manual_sold_quantity` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `approved_return_quantity`;',
            IF(
                @product_onhands_quantity_dikembalikan_exists > 0,
                'ALTER TABLE `product_onhands` ADD COLUMN `manual_sold_quantity` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `quantity_dikembalikan`;',
                'ALTER TABLE `product_onhands` ADD COLUMN `manual_sold_quantity` INT UNSIGNED NOT NULL DEFAULT 0;'
            )
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =========================================================
-- 2. MARKETING NOTIFICATIONS
-- =========================================================

CREATE TABLE IF NOT EXISTS `marketing_notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `created_by` BIGINT NULL,
    `title` VARCHAR(255) NOT NULL,
    `body` TEXT NOT NULL,
    `target_role` VARCHAR(255) NOT NULL DEFAULT 'marketing',
    `status` VARCHAR(255) NOT NULL DEFAULT 'draft',
    `scheduled_at` TIMESTAMP NULL DEFAULT NULL,
    `published_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `marketing_notifications_created_by_index` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 3. MOBILE ACCESS TOKENS
-- Tambahan kolom push token.
-- =========================================================

SET @mobile_access_tokens_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'mobile_access_tokens'
);

SET @mobile_token_column_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'mobile_access_tokens'
      AND COLUMN_NAME = 'token'
);

SET @mobile_push_token_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'mobile_access_tokens'
      AND COLUMN_NAME = 'push_token'
);

SET @sql := IF(
    @mobile_access_tokens_table_exists = 0,
    'SELECT ''Table mobile_access_tokens does not exist'';',
    IF(
        @mobile_push_token_exists > 0,
        'SELECT ''Push token columns already exist'';',
        IF(
            @mobile_token_column_exists > 0,
            'ALTER TABLE `mobile_access_tokens`
                ADD COLUMN `push_token` TEXT NULL AFTER `token`,
                ADD COLUMN `push_platform` VARCHAR(20) NULL AFTER `push_token`,
                ADD COLUMN `push_token_updated_at` TIMESTAMP NULL DEFAULT NULL AFTER `push_platform`;',
            'ALTER TABLE `mobile_access_tokens`
                ADD COLUMN `push_token` TEXT NULL,
                ADD COLUMN `push_platform` VARCHAR(20) NULL,
                ADD COLUMN `push_token_updated_at` TIMESTAMP NULL DEFAULT NULL;'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =========================================================
-- 4. MARKETING BONUS ADJUSTMENTS
-- =========================================================

CREATE TABLE IF NOT EXISTS `marketing_bonus_adjustments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `created_by` BIGINT NULL,
    `bonus_month` DATE NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `note` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `marketing_bonus_adjustments_user_id_index` (`user_id`),
    KEY `marketing_bonus_adjustments_created_by_index` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 5. ARTICLES
-- Tambahan kategori dan SEO article.
-- =========================================================

SET @articles_table_exists := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'articles'
);

SET @articles_author_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'articles'
      AND COLUMN_NAME = 'author'
);

SET @articles_image_path_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'articles'
      AND COLUMN_NAME = 'image_path'
);

SET @article_category_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'articles'
      AND COLUMN_NAME = 'category'
);

SET @article_seo_title_exists := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'articles'
      AND COLUMN_NAME = 'seo_title'
);

SET @sql := IF(
    @articles_table_exists = 0,
    'SELECT ''Table articles does not exist'';',
    IF(
        @article_category_exists > 0,
        'SELECT ''Column category already exists'';',
        IF(
            @articles_author_exists > 0,
            'ALTER TABLE `articles` ADD COLUMN `category` VARCHAR(100) NULL AFTER `author`;',
            'ALTER TABLE `articles` ADD COLUMN `category` VARCHAR(100) NULL;'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
    @articles_table_exists = 0,
    'SELECT ''Table articles does not exist'';',
    IF(
        @article_seo_title_exists > 0,
        'SELECT ''Article SEO columns already exist'';',
        IF(
            @articles_image_path_exists > 0,
            'ALTER TABLE `articles`
                ADD COLUMN `seo_title` VARCHAR(255) NULL AFTER `image_path`,
                ADD COLUMN `seo_description` VARCHAR(500) NULL AFTER `seo_title`,
                ADD COLUMN `seo_keywords` VARCHAR(1000) NULL AFTER `seo_description`,
                ADD COLUMN `seo_canonical_url` VARCHAR(2048) NULL AFTER `seo_keywords`,
                ADD COLUMN `seo_robots` VARCHAR(255) NULL AFTER `seo_canonical_url`,
                ADD COLUMN `og_title` VARCHAR(255) NULL AFTER `seo_robots`,
                ADD COLUMN `og_description` VARCHAR(500) NULL AFTER `og_title`,
                ADD COLUMN `og_image_url` VARCHAR(2048) NULL AFTER `og_description`,
                ADD COLUMN `og_image_alt` VARCHAR(255) NULL AFTER `og_image_url`;',
            'ALTER TABLE `articles`
                ADD COLUMN `seo_title` VARCHAR(255) NULL,
                ADD COLUMN `seo_description` VARCHAR(500) NULL,
                ADD COLUMN `seo_keywords` VARCHAR(1000) NULL,
                ADD COLUMN `seo_canonical_url` VARCHAR(2048) NULL,
                ADD COLUMN `seo_robots` VARCHAR(255) NULL,
                ADD COLUMN `og_title` VARCHAR(255) NULL,
                ADD COLUMN `og_description` VARCHAR(500) NULL,
                ADD COLUMN `og_image_url` VARCHAR(2048) NULL,
                ADD COLUMN `og_image_alt` VARCHAR(255) NULL;'
        )
    )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

COMMIT;

-- Catatan:
-- 1. File ini tidak memakai USE database_tertentu.
-- 2. Jalankan setelah database target dipilih di client MariaDB.
-- 3. Foreign key sengaja tidak dipaksa di file ini agar import lebih aman
--    untuk dump lama yang struktur existing-nya belum sepenuhnya identik.
