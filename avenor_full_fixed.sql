# Converted with pg2mysql-1.9
# Converted on Tue, 24 Mar 2026 15:11:09 +0000
# Lightbox Technologies Inc. http://www.lightbox.ca

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone="+00:00";

CREATE TABLE areas (
    id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name varchar(255) NOT NULL,
    region varchar(255) NOT NULL,
    target_visits int(11) DEFAULT 20 NOT NULL,
    active TINYINT(1) DEFAULT 1 NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB;

CREATE TABLE attendances (
    id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id bigint NOT NULL,
    attendance_date date NOT NULL,
    check_in TIME NOT NULL,
    check_out TIME,
    `status` varchar(20) NOT NULL,
    notes text,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    check_in_latitude DECIMAL(10,7),
    check_in_longitude DECIMAL(10,7),
    check_out_latitude DECIMAL(10,7),
    check_out_longitude DECIMAL(10,7)
) ENGINE=InnoDB;

-- CREATE TABLE cache (
--     `key` varchar(255) NOT NULL,
--     value text NOT NULL,
--     expiration int(11) NOT NULL,
--     PRIMARY KEY (`key`),
    
-- ) ENGINE=InnoDB;
CREATE TABLE cache (
    cache_key VARCHAR(255) NOT NULL,
    value TEXT NOT NULL,
    expiration INT NOT NULL,
    PRIMARY KEY (cache_key)
)ENGINE=InnoDB;

-- CREATE TABLE cache_locks (
--     `key` varchar(255) NOT NULL,
--     owner varchar(255) NOT NULL,
--     expiration int(11) NOT NULL,
--     PRIMARY KEY (`key`)
-- ) ENGINE=InnoDB;

CREATE TABLE cache_locks (
    cache_key VARCHAR(255) NOT NULL,
    owner VARCHAR(255) NOT NULL,
    expiration INT NOT NULL,
    
    PRIMARY KEY (cache_key),
    INDEX idx_expiration (expiration)
) ENGINE=InnoDB;

CREATE TABLE failed_jobs (
    id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uuid varchar(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB;

CREATE TABLE hpp_calculation_items (
    id_hpp_item bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_hpp bigint NOT NULL,
    id_rm bigint NOT NULL,
    nama_rm varchar(255) NOT NULL,
    satuan varchar(255) NOT NULL,
    presentase DECIMAL(8,2) NOT NULL,
    harga_satuan DECIMAL(15,2) NOT NULL,
    harga_final DECIMAL(15,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB;

CREATE TABLE hpp_calculations (
    id_hpp bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_product bigint NOT NULL,
    total_hpp DECIMAL(15,2) DEFAULT '0',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB;

CREATE TABLE job_batches (
    id varchar(255) NOT NULL,
    name varchar(255) NOT NULL,
    total_jobs int(11) NOT NULL,
    pending_jobs int(11) NOT NULL,
    failed_jobs int(11) NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at int(11),
    created_at int(11) NOT NULL,
    finished_at int(11)
) ENGINE=InnoDB;

CREATE TABLE jobs (
    id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    queue varchar(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at int(11),
    available_at int(11) NOT NULL,
    created_at int(11) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE marketing_locations (
    id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id bigint NOT NULL,
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    source varchar(20) DEFAULT 'heartbeat',
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB;

CREATE TABLE migrations (
    id int(11) NOT NULL,
    migration varchar(255) NOT NULL,
    batch int(11) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE offline_sales (
    id_penjualan_offline bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_user bigint NOT NULL,
    id_product bigint,
    promo_id bigint,
    nama varchar(255) NOT NULL,
    nama_product varchar(255) NOT NULL,
    quantity int(11) NOT NULL,
    harga DECIMAL(14,2) NOT NULL,
    kode_promo varchar(255),
    promo varchar(255),
    bukti_pembelian varchar(255),
    approval_status varchar(255) DEFAULT 'pending',
    approved_by bigint,
    approved_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_product_onhand bigint
) ENGINE=InnoDB;

CREATE TABLE password_reset_tokens (
    email varchar(255) NOT NULL,
    token varchar(255) NOT NULL,
    created_at DATETIME
) ENGINE=InnoDB;

CREATE TABLE product_onhands (
    id_product_onhand bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id bigint NOT NULL,
    id_product bigint NOT NULL,
    nama_product varchar(255) NOT NULL,
    quantity int(11) NOT NULL,
    quantity_dikembalikan int(11) DEFAULT 0 NOT NULL,
    return_status varchar(255) DEFAULT 'belum',
    approved_by bigint,
    assignment_date date NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    take_status varchar(255) DEFAULT 'disetujui',
    take_approved_by bigint,
    take_requested_at DATETIME,
    take_reviewed_at DATETIME
) ENGINE=InnoDB;

CREATE TABLE products (
    id_product bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nama_product varchar(255) NOT NULL,
    harga DECIMAL(14,2) NOT NULL,
    harga_modal DECIMAL(14,2) NOT NULL,
    stock int(11) DEFAULT 0 NOT NULL,
    gambar varchar(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB;

CREATE TABLE promos (
    id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    kode_promo varchar(255) NOT NULL,
    nama_promo varchar(255) NOT NULL,
    potongan DECIMAL(14,2) NOT NULL,
    masa_aktif date NOT NULL,
    minimal_quantity int(11) DEFAULT 1 NOT NULL,
    minimal_belanja DECIMAL(14,2) DEFAULT '0',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB;

CREATE TABLE raw_materials (
    id_rm bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nama_rm varchar(255) NOT NULL,
    harga DECIMAL(15,2) NOT NULL,
    quantity int(11) NOT NULL,
    harga_satuan DECIMAL(15,2) NOT NULL,
    stock int(11) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    satuan varchar(255) NOT NULL,
    total_quantity int(11) DEFAULT 0 NOT NULL,
    harga_total DECIMAL(15,2) DEFAULT '0'

) ENGINE=InnoDB;

CREATE TABLE sessions (
    id varchar(255) NOT NULL,
    user_id bigint,
    ip_address varchar(45),
    user_agent text,
    payload text NOT NULL,
    last_activity int(11) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE users (
    id_user bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nama varchar(255) NOT NULL,
    `status` varchar(255) DEFAULT 'aktif',
    role varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    remember_token varchar(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB;

INSERT INTO `attendances` (`id`, `user_id`, `attendance_date`, `check_in`, `check_out`, `status`, `notes`, `created_at`, `check_in_latitude`, `check_in_longitude`, `check_out_latitude`, `check_out_longitude`) VALUES
('1','3','2026-03-24','11:50:45','11:52:48','hadir',NULL,'2026-03-24 11:50:45','-6.3226545','106.9610676','-6.3226468','106.9610867');

INSERT INTO `hpp_calculation_items` (`id_hpp_item`, `id_hpp`, `id_rm`, `nama_rm`, `satuan`, `presentase`, `harga_satuan`, `harga_final`, `created_at`) VALUES
('1','1','3','Caventus','ML','19.00','560.00','5320.00','2026-03-24 12:38:01'),
('2','1','8','akher mawed','ML','8.00','1080.00','4320.00','2026-03-24 12:38:01'),
('3','1','13','TEC','ML','5.00','203.00','507.50','2026-03-24 12:38:01'),
('4','1','14','DPG','ML','5.00','60.50','151.25','2026-03-24 12:38:01'),
('5','1','21','Box Hitam','pcs','2.00','1900.00','1900.00','2026-03-24 12:38:01'),
('6','1','17','Botol Hitam','pcs','2.00','5666.67','5666.67','2026-03-24 12:38:01'),
('7','1','18','packing','pcs','2.00','2000.00','2000.00','2026-03-24 12:38:01');

INSERT INTO `hpp_calculations` (`id_hpp`, `id_product`, `total_hpp`, `created_at`, `updated_at`) VALUES
('1','2','19865.42','2026-03-24 12:38:01','2026-03-24 12:38:01');

INSERT INTO `marketing_locations` (`id`, `user_id`, `latitude`, `longitude`, `source`, `recorded_at`) VALUES
('1','3','-6.3226545','106.9610676','heartbeat','2026-03-24 11:50:26'),
('2','3','-6.3226545','106.9610676','check_in','2026-03-24 11:50:45'),
('3','3','-6.3226456','106.9610746','heartbeat','2026-03-24 11:51:45'),
('4','3','-6.3226468','106.9610867','check_out','2026-03-24 11:52:48');

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
('1','0001_01_01_000000_create_users_table','1'),
('2','0001_01_01_000001_create_cache_table','1'),
('3','0001_01_01_000002_create_jobs_table','1'),
('4','2026_03_24_000003_create_areas_table','1'),
('5','2026_03_24_000004_create_attendances_table','1'),
('6','2026_03_24_000005_update_attendances_for_location_tracking','1'),
('7','2026_03_24_000006_create_marketing_locations_table','1'),
('8','2026_03_24_000007_create_products_table','1'),
('9','2026_03_24_000008_create_promos_table','1'),
('10','2026_03_24_000009_create_product_onhands_table','1'),
('11','2026_03_24_000010_create_offline_sales_table','1'),
('12','2026_03_24_000011_add_id_product_onhand_to_offline_sales_table','1'),
('13','2026_03_24_000012_add_take_approval_to_product_onhands_table','1'),
('14','2026_03_24_000013_create_raw_materials_table','2'),
('15','2026_03_24_000014_add_satuan_to_raw_materials_table','3'),
('16','2026_03_24_000015_update_raw_material_totals','4'),
('17','2026_03_24_000016_create_hpp_calculations_table','5'),
('18','2026_03_24_000017_create_hpp_calculation_items_table','5');

INSERT INTO `offline_sales` (`id_penjualan_offline`, `id_user`, `id_product`, `promo_id`, `nama`, `nama_product`, `quantity`, `harga`, `kode_promo`, `promo`, `bukti_pembelian`, `approval_status`, `approved_by`, `approved_at`, `created_at`, `id_product_onhand`) VALUES
('1','3','1','1','marketing','Azalea','2','100000.00','B2LM20260324','Beli 2 Lebih Murah','offline-sales/Rl5cjbsLsCaMPA0IKmXOlOf4gTY8iC9QsMq8G8Ky.png','disetujui','1','2026-03-24 12:51:10','2026-03-24 11:52:24','1');

INSERT INTO `product_onhands` (`id_product_onhand`, `user_id`, `id_product`, `nama_product`, `quantity`, `quantity_dikembalikan`, `return_status`, `approved_by`, `assignment_date`, `created_at`, `take_status`, `take_approved_by`, `take_requested_at`, `take_reviewed_at`) VALUES
('1','3','1','Azalea','2','0','belum',NULL,'2026-03-24','2026-03-24 11:50:56','disetujui','1','2026-03-24 11:50:56','2026-03-24 11:51:28');

INSERT INTO `products` (`id_product`, `nama_product`, `harga`, `harga_modal`, `stock`, `gambar`, `created_at`) VALUES
('1','Azalea','75000.00','0.00','18',NULL,'2026-03-24 10:56:15'),
('3','Solair','75000.00','0.00','20',NULL,'2026-03-24 19:07:04'),
('4','Zest','75000.00','0.00','20',NULL,'2026-03-24 19:07:40'),
('5','Honeydew','75000.00','0.00','20',NULL,'2026-03-24 19:08:09'),
('6','Athena','75000.00','0.00','20',NULL,'2026-03-24 19:08:15'),
('7','Pink Aura','75000.00','0.00','20',NULL,'2026-03-24 19:08:25'),
('8','Blossom Creme','75000.00','0.00','20',NULL,'2026-03-24 19:08:41'),
('9','Vanore','75000.00','0.00','20',NULL,'2026-03-24 19:08:52'),
('10','Marin','75000.00','0.00','20',NULL,'2026-03-24 19:08:59'),
('11','Limen','75000.00','0.00','20',NULL,'2026-03-24 19:09:18'),
('2','Sevon','75000.00','19865.42','20',NULL,'2026-03-24 19:06:54');

INSERT INTO `promos` (`id`, `kode_promo`, `nama_promo`, `potongan`, `masa_aktif`, `minimal_quantity`, `minimal_belanja`, `created_at`) VALUES
('1','B2LM20260324','Beli 2 Lebih Murah','50000.00','2026-03-30','2','0.00','2026-03-24 03:56:57');

INSERT INTO `raw_materials` (`id_rm`, `nama_rm`, `harga`, `quantity`, `harga_satuan`, `stock`, `created_at`, `satuan`, `total_quantity`, `harga_total`) VALUES
('2','Scandalous','715000.00','1000','715.00','0','2026-03-24 11:58:44','ML','0','0.00'),
('3','Caventus','560000.00','1000','560.00','0','2026-03-24 11:59:28','ML','0','0.00'),
('4','Vanilla Body','630000.00','1000','630.00','0','2026-03-24 11:59:52','ML','0','0.00'),
('5','JOP','690000.00','1000','690.00','0','2026-03-24 12:00:07','ML','0','0.00'),
('6','Sosxy','755000.00','1000','755.00','0','2026-03-24 12:00:23','ML','0','0.00'),
('7','rmw','560000.00','1000','560.00','0','2026-03-24 12:00:49','ML','0','0.00'),
('8','akher mawed','540000.00','500','1080.00','0','2026-03-24 12:01:18','ML','0','0.00'),
('9','amber romance','380000.00','500','760.00','0','2026-03-24 12:01:38','ML','0','0.00'),
('10','Nebula','575000.00','1000','575.00','0','2026-03-24 12:01:54','ML','0','0.00'),
('11','whitemusk','288000.00','500','576.00','0','2026-03-24 12:02:27','ML','0','0.00'),
('12','myway','550000.00','1000','550.00','0','2026-03-24 12:02:56','ML','0','0.00'),
('13','TEC','203000.00','1000','203.00','0','2026-03-24 12:03:18','ML','0','0.00'),
('14','DPG','60500.00','1000','60.50','0','2026-03-24 12:03:37','ML','0','0.00'),
('15','Alcohol Purity','257000.00','5000','51.40','0','2026-03-24 12:03:57','ML','0','0.00'),
('16','Botol Putih','558000.00','120','4650.00','0','2026-03-24 12:04:47','ML','0','0.00'),
('17','Botol Hitam','68000.00','12','5666.67','0','2026-03-24 12:05:14','pcs','0','0.00'),
('18','packing','2000.00','1','2000.00','0','2026-03-24 12:05:31','pcs','0','0.00'),
('19','Vial','1050.00','1','1050.00','0','2026-03-24 12:05:45','pcs','0','0.00'),
('20','Box Putih','31000.00','20','1550.00','0','2026-03-24 12:06:01','pcs','0','0.00'),
('21','Box Hitam','38000.00','20','1900.00','0','2026-03-24 12:06:16','pcs','0','0.00');

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('Rz8G2yKlCl6Kjulk7D902AwssHOlaB9y0V4mX8Ug','1','127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','YTo0OntzOjY6Il90b2tlbiI7czo0MDoia0NmNmZHZmF5VXBJMm1FR09ubjhUWTE1c3VmZGZvUUQ5UW1FNVliTiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MTtzOjk6Il9wcmV2aW91cyI7YToyOntzOjM6InVybCI7czoyNToiaHR0cDovLzEyNy4wLjAuMTo4MDAwL2hwcCI7czo1OiJyb3V0ZSI7czo5OiJocHAuaW5kZXgiO319','1774357218');

INSERT INTO `users` (`id_user`, `nama`, `status`, `role`, `password`, `remember_token`, `created_at`) VALUES
('2','admin','aktif','admin','$2y$12$MN20tW11D5N.iOh.oWFAfuUv2VPph/75GHnwx/.QmTWtpkMViIsiy',NULL,'2026-03-24 03:55:38'),
('4','reseller','aktif','reseller','$2y$12$mCLdq70RWvtrKzlCufPOseNH6yuh.achzpcnKqsi.zaphHwq8tieq',NULL,'2026-03-24 03:55:39'),
('5','test1','aktif','marketing','$2y$12$RMYfjaxnWQYKV0l9iQmDJeJS3Yz0TsydOXmIKknQ77Ntkw3PrwDum',NULL,'2026-03-24 11:42:10'),
('3','marketing','aktif','marketing','$2y$12$8.JarWMdIWG/nxodfixKGOsjbhOv3sBAD.R9CSukhwZv9lltalvdK','ponuMNKdpTSscQ7gQIksHgQLYIQu9TN4cH05IgbUbsOOayEXUeUC7YQ133bP','2026-03-24 03:55:39'),
('1','superadmin','aktif','superadmin','$2y$12$8Cx2sjMVEHnWv76rhDNFuOzYfwFRhxava5uxv6uovEHHQ./OKX.N6','X5rb3eNR3trVKBgDfSdV7WPHlYrWpJUenGYR8LNDQXKP3VBHXGW43QnK7TUD','2026-03-24 03:55:37');



ALTER TABLE cache_locks ADD PRIMARY KEY (key);
ALTER TABLE cache ADD PRIMARY KEY (key);

ALTER TABLE hpp_calculation_items ADD PRIMARY KEY (id_hpp_item);
ALTER TABLE hpp_calculations ADD PRIMARY KEY (id_hpp);




ALTER TABLE offline_sales ADD PRIMARY KEY (id_penjualan_offline);
ALTER TABLE password_reset_tokens ADD PRIMARY KEY (email);
ALTER TABLE product_onhands ADD PRIMARY KEY (id_product_onhand);
ALTER TABLE products ADD PRIMARY KEY (id_product);

ALTER TABLE raw_materials ADD PRIMARY KEY (id_rm);

ALTER TABLE users ADD PRIMARY KEY (id_user);
