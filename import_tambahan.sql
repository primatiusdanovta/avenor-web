-- SQL tambahan MariaDB
-- Ringkasan migration:
-- 2026_04_10_000054 / 000055 / 000056 / 000057 / 2026_04_11_040000 / 2026_04_11_050000

START TRANSACTION;

SET @now := NOW();

CREATE TABLE IF NOT EXISTS `stores` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `display_name` VARCHAR(255) NOT NULL,
  `status` VARCHAR(255) NOT NULL DEFAULT 'active',
  `timezone` VARCHAR(255) NOT NULL DEFAULT 'Asia/Jakarta',
  `currency` VARCHAR(255) NOT NULL DEFAULT 'IDR',
  `address` TEXT NULL,
  `settings` JSON NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `stores_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `permission_roles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `key` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `legacy_role` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `permissions` JSON NOT NULL,
  `is_locked` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permission_roles_key_unique` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `store_user_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `store_user_assignments_user_store_unique` (`user_id`, `store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `stores` (`code`,`name`,`display_name`,`status`,`timezone`,`currency`,`settings`,`created_at`,`updated_at`) VALUES
('avenor_perfume','avenor_perfume','Avenor Perfume','active','Asia/Jakarta','IDR',JSON_OBJECT('brand_title','Avenor Perfume','brand_image','/img/avenor_hitam.png','favicon','/img/avenor_hitam.png','web_title','Avenor Perfume'),@now,@now),
('smoothies_sweetie','smoothies_sweetie','Smoothies Sweetie','active','Asia/Jakarta','IDR',JSON_OBJECT('brand_title','Smoothies Sweetie','brand_image','/img/sweetie.png','favicon','/img/sweetie.png','web_title','Smoothies Sweetie'),@now,@now)
ON DUPLICATE KEY UPDATE `display_name`=VALUES(`display_name`),`status`=VALUES(`status`),`timezone`=VALUES(`timezone`),`currency`=VALUES(`currency`),`settings`=VALUES(`settings`),`updated_at`=@now;

SET @avenor_store_id := (SELECT `id` FROM `stores` WHERE `code`='avenor_perfume' LIMIT 1);
SET @sweetie_store_id := (SELECT `id` FROM `stores` WHERE `code`='smoothies_sweetie' LIMIT 1);

ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `permission_role_id` BIGINT UNSIGNED NULL AFTER `role`;
SET @sql := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'role' AND COLUMN_TYPE LIKE 'enum(%') = 0,
  'SELECT ''Skip users.role enum sync'';',
  'ALTER TABLE `users` MODIFY `role` ENUM(''superadmin'',''admin'',''marketing'',''sales_field_executive'',''owner'',''karyawan'') NOT NULL;'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE `users` SET `role`='sales_field_executive' WHERE `role`='reseller';
UPDATE `users` SET `nama`='field executive' WHERE `nama`='reseller' AND `role`='sales_field_executive';

INSERT INTO `permission_roles` (`key`,`name`,`legacy_role`,`description`,`permissions`,`is_locked`,`created_at`,`updated_at`) VALUES
('superadmin','Superadmin','superadmin','Akses penuh seluruh store dan master store.',JSON_ARRAY('dashboard.view','stores.view','stores.manage','roles.view','roles.manage','users.view','users.manage','products.view','products.manage','products.take','products.approve','raw_materials.view','raw_materials.manage','hpp.view','hpp.manage','offline_sales.view','offline_sales.manage','offline_sales.approve','online_sales.view','online_sales.manage','expenses.view','expenses.manage','account_receivables.view','account_receivables.manage','account_payables.view','account_payables.manage','customers.view','customers.manage','notifications.view','notifications.manage','attendance.view','attendance.manage','attendance.checkin','attendance.checkout'),1,@now,@now),
('admin_full_access','Admin Full Access','admin','Akses penuh menu operasional store termasuk user dan role checklist.',JSON_ARRAY('dashboard.view','stores.view','roles.view','roles.manage','users.view','users.manage','products.view','products.manage','products.take','products.approve','raw_materials.view','raw_materials.manage','hpp.view','hpp.manage','offline_sales.view','offline_sales.manage','offline_sales.approve','online_sales.view','online_sales.manage','expenses.view','expenses.manage','account_receivables.view','account_receivables.manage','account_payables.view','account_payables.manage','customers.view','customers.manage','notifications.view','notifications.manage','attendance.view','attendance.manage','attendance.checkin','attendance.checkout'),1,@now,@now),
('marketing_default','Marketing Default','marketing','Akses marketing untuk absensi, barang, dan penjualan offline.',JSON_ARRAY('dashboard.view','products.view','products.take','offline_sales.view','offline_sales.manage','attendance.view','attendance.manage','attendance.checkin','attendance.checkout'),1,@now,@now),
('sales_field_default','Sales Field Executive Default','sales_field_executive','Akses sales field executive untuk absensi, barang, dan penjualan offline.',JSON_ARRAY('dashboard.view','products.view','products.take','offline_sales.view','offline_sales.manage','attendance.view','attendance.manage','attendance.checkin','attendance.checkout'),1,@now,@now),
('owner_default','Owner Default','owner','Akses owner Smoothies Sweetie untuk operasional dan SOP.',JSON_ARRAY('dashboard.view','products.view','products.manage','raw_materials.view','raw_materials.manage','hpp.view','hpp.manage','offline_sales.view','offline_sales.manage','customers.view','customers.manage','attendance.view','attendance.manage','attendance.checkin','attendance.checkout','extra_toppings.view','extra_toppings.manage','sops.view','sops.manage'),1,@now,@now),
('karyawan_default','Karyawan Default','karyawan','Akses karyawan Smoothies Sweetie untuk absensi, penjualan, dan SOP.',JSON_ARRAY('dashboard.view','products.view','offline_sales.view','offline_sales.manage','attendance.view','attendance.manage','attendance.checkin','attendance.checkout','sops.view'),1,@now,@now)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`legacy_role`=VALUES(`legacy_role`),`description`=VALUES(`description`),`permissions`=VALUES(`permissions`),`is_locked`=VALUES(`is_locked`),`updated_at`=@now;

UPDATE `users` SET `permission_role_id`=(SELECT `id` FROM `permission_roles` WHERE `key`='superadmin' LIMIT 1) WHERE `role`='superadmin' AND (`permission_role_id` IS NULL OR `permission_role_id`=0);
UPDATE `users` SET `permission_role_id`=(SELECT `id` FROM `permission_roles` WHERE `key`='admin_full_access' LIMIT 1) WHERE `role`='admin' AND (`permission_role_id` IS NULL OR `permission_role_id`=0);
UPDATE `users` SET `permission_role_id`=(SELECT `id` FROM `permission_roles` WHERE `key`='marketing_default' LIMIT 1) WHERE `role`='marketing' AND (`permission_role_id` IS NULL OR `permission_role_id`=0);
UPDATE `users` SET `permission_role_id`=(SELECT `id` FROM `permission_roles` WHERE `key`='sales_field_default' LIMIT 1) WHERE `role`='sales_field_executive' AND (`permission_role_id` IS NULL OR `permission_role_id`=0);
UPDATE `users` SET `permission_role_id`=(SELECT `id` FROM `permission_roles` WHERE `key`='owner_default' LIMIT 1) WHERE `role`='owner' AND (`permission_role_id` IS NULL OR `permission_role_id`=0);
UPDATE `users` SET `permission_role_id`=(SELECT `id` FROM `permission_roles` WHERE `key`='karyawan_default' LIMIT 1) WHERE `role`='karyawan' AND (`permission_role_id` IS NULL OR `permission_role_id`=0);

INSERT INTO `store_user_assignments` (`user_id`,`store_id`,`is_primary`,`created_at`,`updated_at`)
SELECT `id_user`, @avenor_store_id, 1, @now, @now FROM `users` WHERE @avenor_store_id IS NOT NULL
ON DUPLICATE KEY UPDATE `is_primary`=VALUES(`is_primary`),`updated_at`=@now;

INSERT INTO `users` (`nama`,`status`,`role`,`permission_role_id`,`password`,`remember_token`,`created_at`)
SELECT 'admin_swetiee','aktif','admin',(SELECT `id` FROM `permission_roles` WHERE `key`='admin_full_access' LIMIT 1),'$2y$10$TgtsftQp04tW5v3wQ4MVVOGQ/OpIsPr8233X3EB9wI9YlB.llO4ce',NULL,@now
WHERE NOT EXISTS (SELECT 1 FROM `users` WHERE `nama`='admin_swetiee');

INSERT INTO `store_user_assignments` (`user_id`,`store_id`,`is_primary`,`created_at`,`updated_at`)
SELECT `id_user`, @sweetie_store_id, 1, @now, @now FROM `users` WHERE `nama`='admin_swetiee' AND @sweetie_store_id IS NOT NULL
ON DUPLICATE KEY UPDATE `is_primary`=VALUES(`is_primary`),`updated_at`=@now;

INSERT INTO `store_user_assignments` (`user_id`,`store_id`,`is_primary`,`created_at`,`updated_at`)
SELECT `id_user`, @sweetie_store_id, 0, @now, @now FROM `users` WHERE `role`='superadmin' AND @sweetie_store_id IS NOT NULL
ON DUPLICATE KEY UPDATE `updated_at`=@now;

ALTER TABLE `products` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id_product`;
ALTER TABLE `raw_materials` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id_rm`;
ALTER TABLE `hpp_calculations` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id_hpp`;
ALTER TABLE `promos` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `product_onhands` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id_product_onhand`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id_penjualan_offline`;
ALTER TABLE `online_sales` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `online_sale_items` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `expenses` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `account_payables` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `account_receivables` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `customers` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id_pelanggan`;
ALTER TABLE `attendances` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `marketing_locations` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `marketing_notifications` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;
ALTER TABLE `consignments` ADD COLUMN IF NOT EXISTS `store_id` BIGINT UNSIGNED NULL AFTER `id`;

UPDATE `products` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `raw_materials` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `hpp_calculations` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `promos` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `product_onhands` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `offline_sales` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `online_sales` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `online_sale_items` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `expenses` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `account_payables` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `account_receivables` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `customers` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `attendances` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `marketing_locations` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `marketing_notifications` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;
UPDATE `consignments` SET `store_id`=@avenor_store_id WHERE `store_id` IS NULL;

ALTER TABLE `raw_materials` ADD COLUMN IF NOT EXISTS `waste_materials` DECIMAL(14,2) NOT NULL DEFAULT 0.00 AFTER `total_quantity`;
ALTER TABLE `raw_materials` ADD COLUMN IF NOT EXISTS `waste_percentage` DECIMAL(8,2) NOT NULL DEFAULT 0.00 AFTER `waste_materials`;
ALTER TABLE `raw_materials` ADD COLUMN IF NOT EXISTS `waste_loss_percentage` DECIMAL(8,2) NOT NULL DEFAULT 0.00 AFTER `waste_percentage`;
ALTER TABLE `raw_materials` ADD COLUMN IF NOT EXISTS `waste_loss_amount` DECIMAL(14,2) NOT NULL DEFAULT 0.00 AFTER `waste_loss_percentage`;

CREATE TABLE IF NOT EXISTS `product_variants` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `price` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `total_satuan_ml` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `is_default` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_variants_product_id_name_unique` (`product_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `extra_toppings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `price` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `extra_toppings_store_id_name_unique` (`store_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sops` (
  `id_sop` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `store_id` BIGINT UNSIGNED NULL,
  `title` VARCHAR(255) NOT NULL,
  `detail` TEXT NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id_sop`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `sale_number` VARCHAR(255) NULL AFTER `transaction_code`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `product_variant_id` BIGINT UNSIGNED NULL AFTER `id_product`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `product_variant_name` VARCHAR(255) NULL AFTER `product_variant_id`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `unit_price` DECIMAL(14,2) NOT NULL DEFAULT 0.00 AFTER `product_variant_name`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `extra_topping_total` DECIMAL(14,2) NOT NULL DEFAULT 0.00 AFTER `unit_price`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `extra_toppings` JSON NULL AFTER `extra_topping_total`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `payment_method` VARCHAR(255) NULL AFTER `extra_toppings`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `payment_status` VARCHAR(255) NOT NULL DEFAULT 'pending' AFTER `payment_method`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `paid_at` TIMESTAMP NULL DEFAULT NULL AFTER `payment_status`;
ALTER TABLE `offline_sales` ADD COLUMN IF NOT EXISTS `closed_at` TIMESTAMP NULL DEFAULT NULL AFTER `paid_at`;

UPDATE `sales_targets` SET `role`='sales_field_executive' WHERE `role`='reseller';
INSERT INTO `sales_targets` (`role`,`daily_target_qty`,`daily_bonus`,`weekly_target_qty`,`weekly_bonus`,`monthly_target_qty`,`monthly_bonus`,`created_at`,`updated_at`)
SELECT 'sales_field_executive',0,0.00,0,0.00,0,0.00,@now,@now
WHERE NOT EXISTS (SELECT 1 FROM `sales_targets` WHERE `role`='sales_field_executive');

COMMIT;
