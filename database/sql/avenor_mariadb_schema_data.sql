SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `mobile_access_tokens`;
DROP TABLE IF EXISTS `product_fragrance_details`;
DROP TABLE IF EXISTS `online_sale_items`;
DROP TABLE IF EXISTS `online_sales`;
DROP TABLE IF EXISTS `sales_targets`;
DROP TABLE IF EXISTS `seo_settings`;
DROP TABLE IF EXISTS `landing_page_contents`;
DROP TABLE IF EXISTS `global_settings`;
DROP TABLE IF EXISTS `fragrance_details`;
DROP TABLE IF EXISTS `account_payables`;
DROP TABLE IF EXISTS `expenses`;
DROP TABLE IF EXISTS `offline_sales`;
DROP TABLE IF EXISTS `product_onhands`;
DROP TABLE IF EXISTS `content_creators`;
DROP TABLE IF EXISTS `hpp_calculation_items`;
DROP TABLE IF EXISTS `hpp_calculations`;
DROP TABLE IF EXISTS `raw_materials`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `promos`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `marketing_locations`;
DROP TABLE IF EXISTS `attendances`;
DROP TABLE IF EXISTS `areas`;
DROP TABLE IF EXISTS `failed_jobs`;
DROP TABLE IF EXISTS `job_batches`;
DROP TABLE IF EXISTS `jobs`;
DROP TABLE IF EXISTS `cache_locks`;
DROP TABLE IF EXISTS `cache`;
DROP TABLE IF EXISTS `sessions`;
DROP TABLE IF EXISTS `password_reset_tokens`;
DROP TABLE IF EXISTS `migrations`;
DROP TABLE IF EXISTS `users`;

CREATE TABLE IF NOT EXISTS `users` (
  `id_user` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama` VARCHAR(255) NOT NULL,
  `status` VARCHAR(255) NOT NULL DEFAULT 'aktif',
  `role` ENUM('superadmin','admin','marketing','reseller') NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  `remember_token` VARCHAR(100) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_user`),
  UNIQUE KEY `users_nama_unique` (`nama`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
  `email` VARCHAR(255) NOT NULL,
  `token` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sessions` (
  `id` VARCHAR(255) NOT NULL,
  `user_id` BIGINT UNSIGNED NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `payload` LONGTEXT NOT NULL,
  `last_activity` INT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cache` (
  `key` VARCHAR(255) NOT NULL,
  `value` MEDIUMTEXT NOT NULL,
  `expiration` INT NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cache_locks` (
  `key` VARCHAR(255) NOT NULL,
  `owner` VARCHAR(255) NOT NULL,
  `expiration` INT NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `jobs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `queue` VARCHAR(255) NOT NULL,
  `payload` LONGTEXT NOT NULL,
  `attempts` TINYINT UNSIGNED NOT NULL,
  `reserved_at` INT UNSIGNED NULL,
  `available_at` INT UNSIGNED NOT NULL,
  `created_at` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_batches` (
  `id` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `total_jobs` INT NOT NULL,
  `pending_jobs` INT NOT NULL,
  `failed_jobs` INT NOT NULL,
  `failed_job_ids` LONGTEXT NOT NULL,
  `options` MEDIUMTEXT NULL,
  `cancelled_at` INT NULL,
  `created_at` INT NOT NULL,
  `finished_at` INT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `migrations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `migration` VARCHAR(255) NOT NULL,
  `batch` INT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `failed_jobs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` VARCHAR(255) NOT NULL,
  `connection` TEXT NOT NULL,
  `queue` TEXT NOT NULL,
  `payload` LONGTEXT NOT NULL,
  `exception` LONGTEXT NOT NULL,
  `failed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `areas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `region` VARCHAR(255) NOT NULL,
  `target_visits` INT UNSIGNED NOT NULL DEFAULT 20,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `areas_name_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attendances` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `attendance_date` DATE NOT NULL,
  `check_in` TIME NULL,
  `check_in_latitude` DECIMAL(10,7) NULL,
  `check_in_longitude` DECIMAL(10,7) NULL,
  `check_out` TIME NULL,
  `check_out_latitude` DECIMAL(10,7) NULL,
  `check_out_longitude` DECIMAL(10,7) NULL,
  `status` VARCHAR(20) NOT NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `attendances_user_id_attendance_date_unique` (`user_id`,`attendance_date`),
  CONSTRAINT `attendances_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_user`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `marketing_locations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `latitude` DECIMAL(10,7) NOT NULL,
  `longitude` DECIMAL(10,7) NOT NULL,
  `source` VARCHAR(20) NOT NULL DEFAULT 'heartbeat',
  `recorded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `marketing_locations_user_id_recorded_at_index` (`user_id`,`recorded_at`),
  CONSTRAINT `marketing_locations_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_user`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `products` (
  `id_product` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama_product` VARCHAR(255) NOT NULL,
  `harga` DECIMAL(14,2) NOT NULL,
  `harga_modal` DECIMAL(14,2) NOT NULL,
  `stock` INT UNSIGNED NOT NULL DEFAULT 0,
  `gambar` VARCHAR(255) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_product`),
  UNIQUE KEY `products_nama_product_unique` (`nama_product`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `promos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kode_promo` VARCHAR(255) NOT NULL,
  `nama_promo` VARCHAR(255) NOT NULL,
  `potongan` DECIMAL(14,2) NOT NULL,
  `masa_aktif` DATE NOT NULL,
  `minimal_quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `minimal_belanja` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `promos_kode_promo_unique` (`kode_promo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `customers` (
  `id_pelanggan` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama` VARCHAR(255) NULL,
  `no_telp` VARCHAR(255) NULL,
  `tiktok_instagram` VARCHAR(255) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `pembelian_terakhir` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id_pelanggan`),
  UNIQUE KEY `customers_no_telp_unique` (`no_telp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `raw_materials` (
  `id_rm` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama_rm` VARCHAR(255) NOT NULL,
  `satuan` VARCHAR(255) NOT NULL,
  `harga` DECIMAL(15,2) NOT NULL,
  `quantity` DECIMAL(15,2) NOT NULL,
  `harga_satuan` DECIMAL(15,2) NOT NULL,
  `stock` DECIMAL(15,2) NOT NULL,
  `total_quantity` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `harga_total` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_rm`),
  UNIQUE KEY `raw_materials_nama_rm_unique` (`nama_rm`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpp_calculations` (
  `id_hpp` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_product` BIGINT UNSIGNED NOT NULL,
  `total_hpp` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_hpp`),
  UNIQUE KEY `hpp_calculations_id_product_unique` (`id_product`),
  CONSTRAINT `hpp_calculations_id_product_foreign` FOREIGN KEY (`id_product`) REFERENCES `products` (`id_product`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hpp_calculation_items` (
  `id_hpp_item` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_hpp` BIGINT UNSIGNED NOT NULL,
  `id_rm` BIGINT UNSIGNED NOT NULL,
  `nama_rm` VARCHAR(255) NOT NULL,
  `satuan` VARCHAR(255) NOT NULL,
  `presentase` DECIMAL(8,2) NOT NULL,
  `harga_satuan` DECIMAL(15,2) NOT NULL,
  `harga_final` DECIMAL(15,2) NOT NULL,
  `total_stock` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_hpp_item`),
  KEY `hpp_calculation_items_id_hpp_foreign` (`id_hpp`),
  KEY `hpp_calculation_items_id_rm_foreign` (`id_rm`),
  CONSTRAINT `hpp_calculation_items_id_hpp_foreign` FOREIGN KEY (`id_hpp`) REFERENCES `hpp_calculations` (`id_hpp`) ON DELETE CASCADE,
  CONSTRAINT `hpp_calculation_items_id_rm_foreign` FOREIGN KEY (`id_rm`) REFERENCES `raw_materials` (`id_rm`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `content_creators` (
  `id_contentcreator` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama` VARCHAR(255) NOT NULL,
  `bidang` JSON NOT NULL,
  `username_instagram` VARCHAR(255) NULL,
  `username_tiktok` VARCHAR(255) NULL,
  `followers_instagram` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `followers_tiktok` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `range_fee_percontent` VARCHAR(255) NULL,
  `jenis_konten` VARCHAR(255) NULL,
  `no_telp` VARCHAR(30) NULL,
  `wilayah` VARCHAR(255) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_contentcreator`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_onhands` (
  `id_product_onhand` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `id_product` BIGINT UNSIGNED NOT NULL,
  `nama_product` VARCHAR(255) NOT NULL,
  `quantity` INT UNSIGNED NOT NULL,
  `quantity_dikembalikan` INT UNSIGNED NOT NULL DEFAULT 0,
  `take_status` VARCHAR(255) NOT NULL DEFAULT 'disetujui',
  `return_status` VARCHAR(255) NOT NULL DEFAULT 'belum',
  `approved_by` BIGINT UNSIGNED NULL,
  `take_approved_by` BIGINT UNSIGNED NULL,
  `take_requested_at` TIMESTAMP NULL DEFAULT NULL,
  `take_reviewed_at` TIMESTAMP NULL DEFAULT NULL,
  `assignment_date` DATE NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_product_onhand`),
  KEY `product_onhands_user_id_foreign` (`user_id`),
  KEY `product_onhands_id_product_foreign` (`id_product`),
  KEY `product_onhands_approved_by_foreign` (`approved_by`),
  KEY `product_onhands_take_approved_by_foreign` (`take_approved_by`),
  CONSTRAINT `product_onhands_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_user`) ON DELETE CASCADE,
  CONSTRAINT `product_onhands_id_product_foreign` FOREIGN KEY (`id_product`) REFERENCES `products` (`id_product`) ON DELETE CASCADE,
  CONSTRAINT `product_onhands_approved_by_foreign` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id_user`) ON DELETE SET NULL,
  CONSTRAINT `product_onhands_take_approved_by_foreign` FOREIGN KEY (`take_approved_by`) REFERENCES `users` (`id_user`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `offline_sales` (
  `id_penjualan_offline` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `transaction_code` VARCHAR(255) NULL,
  `id_user` BIGINT UNSIGNED NOT NULL,
  `id_pelanggan` BIGINT UNSIGNED NULL,
  `id_product` BIGINT UNSIGNED NULL,
  `id_product_onhand` BIGINT UNSIGNED NULL,
  `promo_id` BIGINT UNSIGNED NULL,
  `nama` VARCHAR(255) NOT NULL,
  `nama_product` VARCHAR(255) NOT NULL,
  `quantity` INT UNSIGNED NOT NULL,
  `harga` DECIMAL(14,2) NOT NULL,
  `total_hpp` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `kode_promo` VARCHAR(255) NULL,
  `promo` VARCHAR(255) NULL,
  `bukti_pembelian` VARCHAR(255) NULL,
  `approval_status` VARCHAR(255) NOT NULL DEFAULT 'pending',
  `approved_by` BIGINT UNSIGNED NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_penjualan_offline`),
  KEY `offline_sales_transaction_code_index` (`transaction_code`),
  KEY `offline_sales_id_user_foreign` (`id_user`),
  KEY `offline_sales_id_pelanggan_foreign` (`id_pelanggan`),
  KEY `offline_sales_id_product_foreign` (`id_product`),
  KEY `offline_sales_id_product_onhand_foreign` (`id_product_onhand`),
  KEY `offline_sales_promo_id_foreign` (`promo_id`),
  KEY `offline_sales_approved_by_foreign` (`approved_by`),
  CONSTRAINT `offline_sales_id_user_foreign` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE,
  CONSTRAINT `offline_sales_id_pelanggan_foreign` FOREIGN KEY (`id_pelanggan`) REFERENCES `customers` (`id_pelanggan`) ON DELETE SET NULL,
  CONSTRAINT `offline_sales_id_product_foreign` FOREIGN KEY (`id_product`) REFERENCES `products` (`id_product`) ON DELETE SET NULL,
  CONSTRAINT `offline_sales_id_product_onhand_foreign` FOREIGN KEY (`id_product_onhand`) REFERENCES `product_onhands` (`id_product_onhand`) ON DELETE SET NULL,
  CONSTRAINT `offline_sales_promo_id_foreign` FOREIGN KEY (`promo_id`) REFERENCES `promos` (`id`) ON DELETE SET NULL,
  CONSTRAINT `offline_sales_approved_by_foreign` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id_user`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `users`
  ADD COLUMN IF NOT EXISTS `require_return_before_checkout` TINYINT(1) NOT NULL DEFAULT 1 AFTER `password`;

ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `deskripsi` TEXT NULL AFTER `gambar`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `landing_page_active` TINYINT(1) NOT NULL DEFAULT 0 AFTER `deskripsi`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `seo_title` VARCHAR(255) NULL AFTER `landing_page_active`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `seo_description` TEXT NULL AFTER `seo_title`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `canonical_url` VARCHAR(255) NULL AFTER `seo_description`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `landing_theme_key` VARCHAR(100) NULL AFTER `canonical_url`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `landing_seo_fallback_key` VARCHAR(100) NULL AFTER `landing_theme_key`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `top_notes_text` TEXT NULL AFTER `landing_seo_fallback_key`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `heart_notes_text` TEXT NULL AFTER `top_notes_text`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `base_notes_text` TEXT NULL AFTER `heart_notes_text`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `education_content` JSON NULL AFTER `base_notes_text`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `faq_data` JSON NULL AFTER `education_content`;
ALTER TABLE `products`
  ADD COLUMN IF NOT EXISTS `educational_blocks` JSON NULL AFTER `faq_data`;

CREATE TABLE IF NOT EXISTS `sales_targets` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role` VARCHAR(255) NOT NULL,
  `daily_target_qty` INT UNSIGNED NOT NULL DEFAULT 0,
  `daily_bonus` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `weekly_target_qty` INT UNSIGNED NOT NULL DEFAULT 0,
  `weekly_bonus` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `monthly_target_qty` INT UNSIGNED NOT NULL DEFAULT 0,
  `monthly_bonus` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sales_targets_role_unique` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `online_sales` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` VARCHAR(255) NOT NULL,
  `order_status` VARCHAR(255) NULL,
  `order_substatus` VARCHAR(255) NULL,
  `cancelation` VARCHAR(255) NULL,
  `province` VARCHAR(255) NULL,
  `regency_city` VARCHAR(255) NULL,
  `paid_time` DATETIME NULL,
  `total_amount` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `online_sales_order_id_unique` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `online_sale_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `online_sale_id` BIGINT UNSIGNED NOT NULL,
  `id_product` BIGINT UNSIGNED NULL,
  `raw_product_name` VARCHAR(255) NOT NULL,
  `nama_product` VARCHAR(255) NOT NULL,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 0,
  `harga` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `created_at` DATETIME NULL,
  `updated_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  KEY `online_sale_items_online_sale_id_foreign` (`online_sale_id`),
  KEY `online_sale_items_id_product_foreign` (`id_product`),
  CONSTRAINT `online_sale_items_online_sale_id_foreign` FOREIGN KEY (`online_sale_id`) REFERENCES `online_sales` (`id`) ON DELETE CASCADE,
  CONSTRAINT `online_sale_items_id_product_foreign` FOREIGN KEY (`id_product`) REFERENCES `products` (`id_product`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fragrance_details` (
  `id_fd` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `jenis` VARCHAR(255) NOT NULL,
  `detail` VARCHAR(255) NOT NULL,
  `deskripsi` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_fd`),
  UNIQUE KEY `fragrance_details_detail_unique` (`detail`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_fragrance_details` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_product` BIGINT UNSIGNED NOT NULL,
  `id_fd` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_fragrance_details_product_fd_unique` (`id_product`, `id_fd`),
  KEY `product_fragrance_details_id_fd_foreign` (`id_fd`),
  CONSTRAINT `product_fragrance_details_id_product_foreign` FOREIGN KEY (`id_product`) REFERENCES `products` (`id_product`) ON DELETE CASCADE,
  CONSTRAINT `product_fragrance_details_id_fd_foreign` FOREIGN KEY (`id_fd`) REFERENCES `fragrance_details` (`id_fd`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `expenses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(255) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `amount` DECIMAL(15,2) NOT NULL,
  `expense_date` DATE NOT NULL,
  `notes` TEXT NULL,
  `created_by` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `expenses_created_by_foreign` (`created_by`),
  KEY `expenses_category_expense_date_index` (`category`, `expense_date`),
  CONSTRAINT `expenses_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id_user`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `account_payables` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_payable` VARCHAR(255) NOT NULL,
  `due_date` DATE NOT NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `landing_page_contents` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `section_name` VARCHAR(100) NOT NULL,
  `title` VARCHAR(255) NULL,
  `description` TEXT NULL,
  `image_path` VARCHAR(255) NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `meta_data` JSON NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `landing_page_contents_section_name_index` (`section_name`),
  KEY `landing_page_contents_section_name_is_active_index` (`section_name`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `seo_settings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `page_key` VARCHAR(255) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `meta_description` TEXT NULL,
  `meta_keywords` TEXT NULL,
  `canonical_url` VARCHAR(255) NULL,
  `og_title` VARCHAR(255) NULL,
  `og_description` TEXT NULL,
  `og_image` VARCHAR(255) NULL,
  `robots` VARCHAR(255) NOT NULL DEFAULT 'index,follow',
  `schema_json` LONGTEXT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `seo_settings_page_key_unique` (`page_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `global_settings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `key` VARCHAR(255) NOT NULL,
  `value` JSON NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `global_settings_key_unique` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mobile_access_tokens` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `token` VARCHAR(64) NOT NULL,
  `last_used_at` TIMESTAMP NULL DEFAULT NULL,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mobile_access_tokens_token_unique` (`token`),
  KEY `mobile_access_tokens_user_id_expires_at_index` (`user_id`, `expires_at`),
  CONSTRAINT `mobile_access_tokens_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_user`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO customers (id_pelanggan, nama, no_telp, tiktok_instagram, created_at, pembelian_terakhir) VALUES (1, 'test', '012345', 'testt', '2026-03-30 05:04:00', '2026-03-30 05:04:00');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (1, 'universal', 'Wanita', 'Aroma yang umum disukai untuk karakter feminin.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (2, 'universal', 'Pria', 'Aroma yang umum disukai untuk karakter maskulin.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (3, 'universal', 'Unisex', 'Aroma yang cocok digunakan pria maupun wanita.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (4, 'fragrance family', 'Citrus', 'Nuansa segar dari buah-buahan sitrus.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (5, 'fragrance family', 'Woody', 'Nuansa kayu yang hangat dan elegan.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (6, 'fragrance family', 'Fresh', 'Nuansa ringan, bersih, dan menyegarkan.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (7, 'fragrance family', 'Aquatic', 'Nuansa airy dan watery yang segar.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (8, 'fragrance family', 'Gourmand', 'Nuansa manis seperti dessert dan edible notes.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (9, 'fragrance family', 'Sweet', 'Nuansa manis yang dominan dan playful.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (10, 'fragrance family', 'Floral', 'Nuansa bunga yang lembut hingga mewah.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (11, 'fragrance family', 'Green/Herbal', 'Nuansa dedaunan, herbal, dan natural.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (12, 'fragrance family', 'Spicy/Aromatic', 'Nuansa rempah dan aromatic yang tegas.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (13, 'fragrance family', 'Fougere', 'Nuansa klasik aromatic dengan herbal dan woody.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (14, 'fragrance family', 'Chypre', 'Nuansa elegan dengan balance citrus, moss, dan woody.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (15, 'activities', 'Versatile', 'Cocok dipakai di banyak suasana dan waktu.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (16, 'activities', 'Formal & Elegan', 'Cocok untuk acara resmi dan kesan sophisticated.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (17, 'activities', 'Hangout/Daily', 'Nyaman untuk aktivitas santai dan harian.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (18, 'activities', 'Sensual/Intens', 'Karakter aroma yang lebih bold dan memikat.', '2026-03-30 03:48:01');
INSERT INTO fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (19, 'activities', 'Sports', 'Cocok untuk aktivitas aktif dan suasana energik.', '2026-03-30 03:48:01');
INSERT INTO `global_settings` (`id`, `key`, `value`, `created_at`, `updated_at`) VALUES (1, 'master_social_hub', '{"tiktok_url":"https:\/\/www.tiktok.com\/@avenorperfume","instagram_url":"https:\/\/www.instagram.com\/avenorperfume_\/","facebook_url":"https:\/\/www.facebook.com\/AvenorPerfume","whatsapp_url":null,"tokopedia_url":"https:\/\/tk.tokopedia.com\/ZSHYbroDF\/","tiktok_shop_url":null,"hero_video_path":"landing\/hero-videos\/b1bb281c-4c19-4a0b-86ab-3804c0a550fe.mp4","hero_video_mime":"video\/mp4","cards":{"tiktok":{"eyebrow":"TikTok","title":"Review Highlights","description":"Short-form fragrance impressions, reactions, and launch moments."},"instagram":{"eyebrow":"Instagram","title":"Aesthetic Grid","description":"Editorial visuals, rituals, and product stories in a curated gallery."},"whatsapp":{"eyebrow":"WhatsApp","title":"Consult with Our Scent Expert","description":"Start a direct conversation and get guided toward the right scent."}}}', '2026-03-31 22:50:50', '2026-04-01 00:26:46');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (1, 'hero', 'Avenor Nocturne', 'A fragrance study in gold, smoke, and midnight florals. Crafted as a modern luxury ritual for the senses.', NULL, true, '{"badge":"Maison Avenor","eyebrow":"Modern Dark Luxury","cta_label":"Discover The Notes","cta_href":"#notes-journey","secondary_label":"View Ingredients","secondary_href":"#ingredients-bento"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (2, 'story', 'A fragrance revealed in three luminous movements.', 'From the first sparkling release to the warm resinous trail, each accord is designed to unfold like a private gallery experience.', NULL, true, '{"kicker":"Narrative Scroll"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (3, 'top_notes', 'Top Notes', 'Bergamot zest, pink pepper, and saffron shimmer with a cold metallic glow before melting into skin.', NULL, true, '{"order":1,"short_label":"Top","accent":"#d4af37"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (4, 'heart_notes', 'Heart Notes', 'Dark rose and jasmine sambac bloom at the center, softened by incense smoke and velvet woods.', NULL, true, '{"order":2,"short_label":"Heart","accent":"#b7922f"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (5, 'base_notes', 'Base Notes', 'Amber, sandalwood, and patchouli settle into a long, tactile finish with warm leather depth.', NULL, true, '{"order":3,"short_label":"Base","accent":"#8d6a1f"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (6, 'ingredients_intro', 'Ingredient Bento', 'A precise composition of rare textures, sparkling spices, and lingering woods.', NULL, true, '{"kicker":"Tap to Reveal"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (7, 'ingredient', 'Saffron Thread', 'Adds a radiant, suede-like heat and metallic glow in the opening accord.', NULL, true, '{"key":"ingredient-saffron-thread","icon":"spark","order":1}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (8, 'ingredient', 'Rose Absolute', 'A deep floral heart that feels lush, nocturnal, and quietly dramatic.', NULL, true, '{"key":"ingredient-rose-absolute","icon":"bloom","order":2}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (9, 'ingredient', 'Sandalwood', 'Brings creamy depth and a polished, skin-close finish to the dry down.', NULL, true, '{"key":"ingredient-sandalwood","icon":"wood","order":3}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (10, 'ingredient', 'Pink Pepper', 'Lifts the composition with crisp sparkle and subtle contemporary spice.', NULL, true, '{"key":"ingredient-pink-pepper","icon":"pepper","order":4}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (11, 'ingredient', 'Amber Resin', 'Creates an enveloping glow that lingers with warmth and golden density.', NULL, true, '{"key":"ingredient-amber-resin","icon":"amber","order":5}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (12, 'ingredient', 'Incense Smoke', 'Adds a dark ceremonial trail that turns the scent into an atmosphere.', NULL, true, '{"key":"ingredient-incense-smoke","icon":"smoke","order":6}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (1, 3, -6.3226313, 106.9609515, 'heartbeat', '2026-03-30 03:52:57');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (2, 3, -6.3226805, 106.9609328, 'heartbeat', '2026-03-30 08:02:48');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (3, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 09:43:20');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (4, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 09:48:22');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (5, 3, -6.3226347, 106.9610332, 'heartbeat', '2026-03-30 09:51:59');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (6, 3, -6.3226617, 106.9610690, 'heartbeat', '2026-03-30 09:57:13');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (7, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:02:41');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (8, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:02:47');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (9, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:07:36');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (10, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:08:02');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (11, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:11:32');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (12, 3, -6.3226317, 106.9609576, 'heartbeat', '2026-03-30 10:30:25');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (13, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:43:58');
INSERT INTO marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (14, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-31 18:05:07');
INSERT INTO migrations (id, migration, batch) VALUES (1, '0001_01_01_000000_create_users_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (2, '0001_01_01_000001_create_cache_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (3, '0001_01_01_000002_create_jobs_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (4, '2026_03_24_000003_create_areas_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (5, '2026_03_24_000004_create_attendances_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (6, '2026_03_24_000005_update_attendances_for_location_tracking', 1);
INSERT INTO migrations (id, migration, batch) VALUES (7, '2026_03_24_000006_create_marketing_locations_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (8, '2026_03_24_000007_create_products_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (9, '2026_03_24_000008_create_promos_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (10, '2026_03_24_000009_create_product_onhands_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (11, '2026_03_24_000010_create_offline_sales_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (12, '2026_03_24_000011_add_id_product_onhand_to_offline_sales_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (13, '2026_03_24_000012_add_take_approval_to_product_onhands_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (14, '2026_03_24_000013_create_raw_materials_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (15, '2026_03_24_000014_add_satuan_to_raw_materials_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (16, '2026_03_24_000015_update_raw_material_totals', 1);
INSERT INTO migrations (id, migration, batch) VALUES (17, '2026_03_24_000016_create_hpp_calculations_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (18, '2026_03_24_000017_create_hpp_calculation_items_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (19, '2026_03_28_000018_create_customers_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (20, '2026_03_28_000019_add_id_pelanggan_to_offline_sales_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (21, '2026_03_28_000020_add_transaction_code_to_offline_sales_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (22, '2026_03_28_000021_update_raw_material_precision_and_add_hpp_item_stock', 1);
INSERT INTO migrations (id, migration, batch) VALUES (23, '2026_03_28_000022_create_content_creators_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (24, '2026_03_30_000023_create_sales_targets_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (25, '2026_03_30_000024_create_online_sales_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (26, '2026_03_30_000025_create_online_sale_items_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (27, '2026_03_30_000026_create_fragrance_details_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (28, '2026_03_30_000027_add_description_to_products_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (29, '2026_03_30_000028_create_product_fragrance_details_table', 1);
INSERT INTO migrations (id, migration, batch) VALUES (30, '2026_03_31_000021_add_total_hpp_to_offline_sales_table', 2);
INSERT INTO migrations (id, migration, batch) VALUES (31, '2026_03_31_000022_fix_sales_targets_id_auto_increment', 2);
INSERT INTO migrations (id, migration, batch) VALUES (32, '2026_03_31_000023_create_expenses_table', 2);
INSERT INTO migrations (id, migration, batch) VALUES (33, '2026_04_01_000024_add_require_return_before_checkout_to_users_table', 2);
INSERT INTO migrations (id, migration, batch) VALUES (34, '2026_04_01_000025_create_account_payables_table', 2);
INSERT INTO migrations (id, migration, batch) VALUES (35, '2026_04_01_000026_create_landing_page_contents_table', 3);
INSERT INTO migrations (id, migration, batch) VALUES (36, '2026_04_01_000027_create_seo_settings_table', 3);
INSERT INTO migrations (id, migration, batch) VALUES (37, '2026_04_01_000028_add_landing_fields_to_products_table', 4);
INSERT INTO migrations (id, migration, batch) VALUES (38, '2026_04_01_000029_add_faq_and_educational_blocks_to_products_table', 4);
INSERT INTO migrations (id, migration, batch) VALUES (39, '2026_04_01_000030_create_global_settings_table', 4);
INSERT INTO offline_sales (id_penjualan_offline, id_user, id_product, promo_id, nama, nama_product, quantity, harga, kode_promo, promo, bukti_pembelian, approval_status, approved_by, approved_at, created_at, id_product_onhand, id_pelanggan, transaction_code, total_hpp) VALUES (1043, 1, 3, NULL, 'superadmin', 'Azalea', 2, 150000.00, NULL, NULL, 'offline-sales/5b0bJhNcj1oxQYK5slolp6hkRMLedFtj6On5fwVY.png', 'disetujui', 1, '2026-03-30 05:04:00', '2026-03-30 05:04:00', NULL, 1, 'TRX-20260330050450-MNF2P68U', 0.00);
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (1, 1, NULL, 'Zest by Avenor Perfume - Extrait de perfume - 50ml', 'Zest by Avenor Perfume - Extrait de perfume - 50ml', 1, 68663.00, '2026-03-17 10:58:19', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (2, 2, 3, 'Azalea by Avenor Perfume - Extrait de parfum - 50ml', 'Azalea', 1, 40423.00, '2026-03-14 12:19:59', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (3, 3, 2, 'Sevon by Avenor Perfume  - Extrait de parfum - Parfum tahan lama untuk Laki-Laki Pria - Wanginya Maskulin - 50ml', 'Sevon', 1, 44256.00, '2026-03-16 08:31:34', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (4, 4, 1, 'Solair by Avenor Perfume  - Extrait de parfum - 50ml', 'Solair', 1, 45032.00, '2026-03-11 10:53:07', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (5, 4, 3, 'Azalea by Avenor Perfume - Extrait de parfum - 50ml', 'Azalea', 1, 45032.00, '2026-03-11 10:53:07', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (6, 5, NULL, 'Honeydew by Avenor Perfume - Extrait de perfume - 50ml', 'Honeydew by Avenor Perfume - Extrait de perfume - 50ml', 1, 46537.00, '2026-03-14 18:35:35', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (7, 5, 1, 'Solair by Avenor Perfume  - Extrait de parfum - 50ml', 'Solair', 1, 46537.00, '2026-03-14 18:35:35', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (8, 6, 1, 'Solair by Avenor Perfume  - Extrait de parfum - 50ml', 'Solair', 1, 43738.00, '2026-03-12 08:57:40', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (9, 7, NULL, 'Honeydew by Avenor Perfume - Extrait de perfume - 50ml', 'Honeydew by Avenor Perfume - Extrait de perfume - 50ml', 1, 46745.33, '2026-03-13 10:16:48', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (10, 7, NULL, 'Blossom Creme by Avenor Perfume - Extrait de perfume - 50ml - Wangi Creamy', 'Blossom Creme by Avenor Perfume - Extrait de perfume - 50ml - Wangi Creamy', 1, 46745.33, '2026-03-13 10:16:48', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (11, 7, 4, 'Athena by Avenor Perfume - Parfum untuk Wanita - Extrait de parfum - 50ml', 'Athena', 1, 46745.34, '2026-03-13 10:16:48', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (12, 8, 4, 'Athena by Avenor Perfume - Parfum untuk Wanita - Extrait de parfum - 50ml', 'Athena', 2, 69881.00, '2026-03-09 10:26:55', '2026-03-30 05:51:46');
INSERT INTO online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (13, 9, 1, 'Solair by Avenor Perfume  - Extrait de parfum - 50ml', 'Solair', 1, 46538.00, '2026-03-09 06:30:35', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (1, '583083275656070698', 'Selesai', 'Selesai', '', 'Banten', 'Kota Tangerang', '2026-03-17 10:58:19', 68663.00, '2026-03-17 10:58:19', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (2, '583043939786327209', 'Selesai', 'Selesai', '', 'Jawa Barat', 'Kota Bekasi', '2026-03-14 12:19:59', 40423.00, '2026-03-14 12:19:59', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (3, '583042456174626087', 'Selesai', 'Selesai', '', 'Jawa Timur', 'Kabupaten Bangkalan', '2026-03-16 08:31:34', 44256.00, '2026-03-16 08:31:34', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (4, '583023183878391116', 'Selesai', 'Selesai', '', 'D.I. Yogyakarta', 'Kab. Kulon Progo', '2026-03-11 10:53:07', 90064.00, '2026-03-11 10:53:07', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (5, '582994516850804222', 'Selesai', 'Selesai', '', 'Sulawesi Tenggara', 'Kota Kendari', '2026-03-14 18:35:35', 93074.00, '2026-03-14 18:35:35', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (6, '582990768866886951', 'Selesai', 'Selesai', '', 'Jawa Timur', 'Kabupaten Bangkalan', '2026-03-12 08:57:40', 43738.00, '2026-03-12 08:57:40', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (7, '582988929179551513', 'Selesai', 'Selesai', '', 'North Sumatra', 'Medan City', '2026-03-13 10:16:48', 140236.00, '2026-03-13 10:16:48', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (8, '582988803961160993', 'Selesai', 'Selesai', '', 'Jawa Barat', 'Kota Bekasi', '2026-03-09 10:26:55', 69881.00, '2026-03-09 10:26:55', '2026-03-30 05:51:46');
INSERT INTO online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (9, '582986027112105413', 'Selesai', 'Selesai', '', 'Banten', 'Kota Tangerang', '2026-03-09 06:30:35', 46538.00, '2026-03-09 06:30:35', '2026-03-30 05:51:46');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (1, 1, 2, '2026-03-30 12:17:06');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (2, 1, 3, '2026-03-30 12:17:06');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (3, 1, 14, '2026-03-30 12:17:06');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (4, 1, 4, '2026-03-30 12:17:06');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (5, 1, 6, '2026-03-30 12:17:06');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (6, 4, 17, '2026-03-31 23:14:27');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (7, 4, 6, '2026-03-31 23:14:27');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (8, 4, 11, '2026-03-31 23:14:27');
INSERT INTO product_fragrance_details (id, id_product, id_fd, created_at) VALUES (9, 4, 12, '2026-03-31 23:14:27');
INSERT INTO products (id_product, nama_product, harga, harga_modal, stock, gambar, created_at, deskripsi, landing_page_active, seo_title, seo_description, canonical_url, top_notes_text, heart_notes_text, base_notes_text, education_content, faq_data, educational_blocks) VALUES (2, 'Sevon', 75000.00, 0.00, 0, NULL, '2026-03-30 03:48:01', 'Woody aromatic perfume dengan karakter elegan.', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO products (id_product, nama_product, harga, harga_modal, stock, gambar, created_at, deskripsi, landing_page_active, seo_title, seo_description, canonical_url, top_notes_text, heart_notes_text, base_notes_text, education_content, faq_data, educational_blocks) VALUES (3, 'Azalea', 75000.00, 0.00, 0, NULL, '2026-03-30 03:48:01', 'Floral sweet perfume dengan kesan lembut.', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO products (id_product, nama_product, harga, harga_modal, stock, gambar, created_at, deskripsi, landing_page_active, seo_title, seo_description, canonical_url, top_notes_text, heart_notes_text, base_notes_text, education_content, faq_data, educational_blocks) VALUES (4, 'Athena', 75000.00, 0.00, 0, 'products/nSn3G2y0AhMVMtzAqDh4ARneCtvb6cxDjCEwGnZ1.png', '2026-03-30 03:48:01', 'Fresh floral perfume untuk kesan modern. Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO products (id_product, nama_product, harga, harga_modal, stock, gambar, created_at, deskripsi, landing_page_active, seo_title, seo_description, canonical_url, top_notes_text, heart_notes_text, base_notes_text, education_content, faq_data, educational_blocks) VALUES (1, 'Solair', 75000.00, 0.00, 0, NULL, '2026-03-30 03:48:01', 'Fresh citrus perfume untuk pemakaian harian.', true, NULL, NULL, NULL, NULL, NULL, NULL, '{"title":"Customer Education","body":null,"tips":[]}', '[]', '{"title":"Customer Education","body":null,"tips":[]}');
INSERT INTO sales_targets (id, role, daily_target_qty, daily_bonus, weekly_target_qty, weekly_bonus, monthly_target_qty, monthly_bonus, created_at, updated_at) VALUES (2, 'reseller', 0, 0.00, 0, 0.00, 0, 0.00, '2026-03-30 03:48:01', '2026-03-30 03:48:01');
INSERT INTO sales_targets (id, role, daily_target_qty, daily_bonus, weekly_target_qty, weekly_bonus, monthly_target_qty, monthly_bonus, created_at, updated_at) VALUES (1, 'marketing', 4, 0.00, 24, 350000.00, 100, 1500000.00, '2026-03-30 03:48:01', '2026-03-30 03:51:17');
INSERT INTO seo_settings (id, page_key, title, meta_description, meta_keywords, canonical_url, og_title, og_description, og_image, robots, schema_json, is_active, created_at, updated_at) VALUES (1, 'landing', 'Avenor Perfume | Luxury Fragrance Experience', 'Discover Avenor Perfume through a modern dark luxury landing page featuring scent stages, ingredients, and a refined fragrance narrative.', 'avenor perfume, parfum mewah, luxury perfume, fragrance notes, parfum premium', NULL, 'Avenor Perfume | Luxury Fragrance Experience', 'A modern dark luxury fragrance discovery experience with immersive notes and ingredient storytelling.', NULL, 'index,follow', '{
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "Avenor Perfume",
    "description": "Luxury fragrance experience by Avenor Perfume."
}', true, '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('Qjec2JZpCnKAIbROXRLIfHrFRoTstSmvNywdBpvm', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoibExLcm9iNXd1MmFVcXlPMFNQQTdSYW9Da2UxdXFrU3dDNGJqQXpFbCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042016);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('UlHS4wUgmb7Puo8pHJc2tEhMrRhlfGTtoTLK6YbK', NULL, '127.0.0.1', 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Mobile Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoibzBqc2VzRGQxM3N3bm40YnAxZnJKWGlSQVp4MkNONFdodnZmVVdDNyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042034);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('ovpqqtun4UhI77GLUiiOmBQfj4cwoOjaKLfJDqWA', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiVDl2aXlWRVpnR1pPdmMwT2wwNDNrRmNWdVZhRTB4V1d0TFJJY1ExTyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042098);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('FnZsrOqtn9txzeGgKJtNuBBqKStR5rumrmvKZ0su', NULL, '127.0.0.1', 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Mobile Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiUTFHTVA4VFZWc2Z1T2N5NEhGY1ROY3dtMXhUT3MxZUpYSldHUHZUNiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042106);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('XjcxuySqguWrXlr7LI3eK9ktL92UTtrQ8Jd7mquq', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiRDJhSDc4Q3B1cjZ3d2RLS0dBSWJsRVN6UzFCUTRZUUU2QkljQ3BLeSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042168);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('WLGDnp4tvk6Rj82SqYDnaRcCUTGD1yZZDz2EeGrl', NULL, '127.0.0.1', 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Mobile Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiWDR3cU1aQlhSMnNWNXg4aFEwQ21RRjlweTZlZmJkeUtXdFdBZTEwOCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042176);
INSERT INTO sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('K2GqOL2n0eywJO8Qp7b8cdCfrsXeZLtY9HrAyBK1', 1, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiWndRcXZtSXJCdmJlSkE0NzNndlJ2ajJwU3NiREdZQ1h0cmx6NmhFTSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MTtzOjk6Il9wcmV2aW91cyI7YToyOntzOjM6InVybCI7czo3NDoiaHR0cDovLzEyNy4wLjAuMTo4MDAwL21hc3Rlci1oZXJvLXZpZGVvP3Y9MmRlZTJiODJmNmQ1YTBmOWNiNmE0NTAwNTViMWEzYzIiO3M6NToicm91dGUiO3M6MzM6Imdsb2JhbC1zZXR0aW5ncy5tYXN0ZXItaGVyby12aWRlbyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1775051410);
INSERT INTO users (id_user, nama, status, role, password, remember_token, created_at, require_return_before_checkout) VALUES (2, 'admin', 'aktif', 'admin', '$2y$12$btrQAWjikxBkLtFk0wmHd.tFbAzPa86jVP3mWR3L2IEOByBN1OU9S', NULL, '2026-03-30 03:47:59', true);
INSERT INTO users (id_user, nama, status, role, password, remember_token, created_at, require_return_before_checkout) VALUES (4, 'reseller', 'aktif', 'reseller', '$2y$12$0AuMbJL/hpAvlTdQi7qoTumAsFDDX4uH3L8HwSUN9Ibn3DEPrTcAe', NULL, '2026-03-30 03:48:00', true);
INSERT INTO users (id_user, nama, status, role, password, remember_token, created_at, require_return_before_checkout) VALUES (1, 'superadmin', 'aktif', 'superadmin', '$2y$12$qPgNe9Z4mNvXVst8jC1NC.eg0mCR04gdpKpiqix6qjgEaJuYiUzwi', '3Qwk4b56rETDWqKb5RSaswkfCDZ1XjK15y8FdCTTtlomnoNK9DnIGDvw7JRm', '2026-03-30 03:47:58', true);
INSERT INTO users (id_user, nama, status, role, password, remember_token, created_at, require_return_before_checkout) VALUES (3, 'marketing', 'aktif', 'marketing', '$2y$12$OrtqI5C0brMgFnALF.1Peuaib3DRQxBQjgBfW60AAFcztGA0WPS2K', 'eRrAqCM8qLxjjO02UArilhooKKpYv1DI7DKBZ2CBaseBl80w8WZuuwp9VFMo', '2026-03-30 03:48:00', false);

INSERT INTO `fragrance_details` (`id_fd`, `jenis`, `detail`, `deskripsi`, `created_at`) VALUES
(20, 'fragrance family', 'Fruity', 'Nuansa buah yang juicy, manis, dan cerah.', '2026-04-02 00:00:00'),
(21, 'fragrance family', 'Powdery', 'Nuansa lembut, halus, dan clean seperti bedak mewah.', '2026-04-02 00:00:00'),
(22, 'fragrance family', 'Musky', 'Nuansa musk yang hangat, bersih, dan sensual.', '2026-04-02 00:00:00'),
(23, 'fragrance family', 'Amber', 'Nuansa amber yang hangat, manis, dan rich.', '2026-04-02 00:00:00');

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(40, '2026_04_01_000031_add_landing_theme_and_seo_preset_fields_to_products_table', 4),
(41, '2026_04_02_000032_create_mobile_access_tokens_table', 5),
(42, '2026_04_02_000033_add_fruity_fragrance_detail', 5),
(43, '2026_04_02_000034_add_more_fragrance_details', 5);

SET FOREIGN_KEY_CHECKS = 1;
