SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

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

SET FOREIGN_KEY_CHECKS = 1;
