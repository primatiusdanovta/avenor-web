-- Patch import MariaDB untuk menyelaraskan schema terbaru mobile owner modules.
-- Fokus patch ini:
-- 1. menambahkan kolom `amount` pada tabel `account_payables`
-- 2. menambahkan field revenue target pada tabel `sales_targets`

SET @now := NOW();

ALTER TABLE `account_payables`
  ADD COLUMN IF NOT EXISTS `amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00
  AFTER `account_payable`;

UPDATE `account_payables`
SET `amount` = 0.00
WHERE `amount` IS NULL;

INSERT INTO `migrations` (`migration`, `batch`)
SELECT '2026_04_14_000056_add_amount_to_account_payables_table',
       COALESCE((SELECT MAX(`batch`) FROM `migrations`), 0) + 1
WHERE NOT EXISTS (
  SELECT 1
  FROM `migrations`
  WHERE `migration` = '2026_04_14_000056_add_amount_to_account_payables_table'
);

ALTER TABLE `sales_targets`
  ADD COLUMN IF NOT EXISTS `monthly_target_revenue` DECIMAL(15,2) NOT NULL DEFAULT 0.00
  AFTER `role`;

ALTER TABLE `sales_targets`
  ADD COLUMN IF NOT EXISTS `minimum_kpi_value` DECIMAL(8,2) NOT NULL DEFAULT 0.00
  AFTER `monthly_target_revenue`;

ALTER TABLE `sales_targets`
  ADD COLUMN IF NOT EXISTS `maximum_late_days` INT UNSIGNED NOT NULL DEFAULT 0
  AFTER `minimum_kpi_value`;

ALTER TABLE `sales_targets`
  ADD COLUMN IF NOT EXISTS `minimum_attendance_percentage` DECIMAL(8,2) NOT NULL DEFAULT 0.00
  AFTER `maximum_late_days`;

ALTER TABLE `sales_targets`
  ADD COLUMN IF NOT EXISTS `revenue_bonus` DECIMAL(15,2) NOT NULL DEFAULT 0.00
  AFTER `minimum_attendance_percentage`;

UPDATE `sales_targets`
SET `monthly_target_revenue` = 0.00
WHERE `monthly_target_revenue` IS NULL;

UPDATE `sales_targets`
SET `minimum_kpi_value` = 0.00
WHERE `minimum_kpi_value` IS NULL;

UPDATE `sales_targets`
SET `maximum_late_days` = 0
WHERE `maximum_late_days` IS NULL;

UPDATE `sales_targets`
SET `minimum_attendance_percentage` = 0.00
WHERE `minimum_attendance_percentage` IS NULL;

UPDATE `sales_targets`
SET `revenue_bonus` = 0.00
WHERE `revenue_bonus` IS NULL;

INSERT INTO `migrations` (`migration`, `batch`)
SELECT '2026_04_14_000057_add_revenue_target_fields_to_sales_targets_table',
       COALESCE((SELECT MAX(`batch`) FROM `migrations`), 0) + 1
WHERE NOT EXISTS (
  SELECT 1
  FROM `migrations`
  WHERE `migration` = '2026_04_14_000057_add_revenue_target_fields_to_sales_targets_table'
);
