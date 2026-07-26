-- Script Pembuatan Database dan Tabel MySQL untuk Toko Elektronik (Laragon)
-- Silakan impor file ini di phpMyAdmin atau HeidiSQL (port 3306)

CREATE DATABASE IF NOT EXISTS `toko_elektronik_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `toko_elektronik_db`;

-- Nonaktifkan sementara pengecekan foreign key agar drop & create tabel berjalan lancar tanpa bentrok
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `transaction_items`;
DROP TABLE IF EXISTS `transactions`;
DROP TABLE IF EXISTS `cart`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `users`;

-- Tabel users
CREATE TABLE `users` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `role` varchar(20) NOT NULL DEFAULT 'user',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Tabel products
CREATE TABLE `products` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text,
  `price` double NOT NULL,
  `stock` int NOT NULL,
  `image` text,
  `category` varchar(100),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Tabel cart
CREATE TABLE `cart` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `productId` int unsigned NOT NULL,
  `quantity` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cart_productId` (`productId`),
  CONSTRAINT `fk_cart_product` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Tabel transactions
CREATE TABLE `transactions` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `invoice` varchar(100) NOT NULL,
  `userId` int unsigned NOT NULL,
  `total` double NOT NULL,
  `shippingFee` double NOT NULL DEFAULT 0,
  `address` text,
  `status` varchar(50) NOT NULL DEFAULT 'Menunggu Konfirmasi',
  `date` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_transaction_userId` (`userId`),
  CONSTRAINT `fk_transaction_user` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Tabel transaction_items
CREATE TABLE `transaction_items` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `transactionId` int unsigned NOT NULL,
  `productId` int unsigned NOT NULL,
  `quantity` int NOT NULL,
  `price` double NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_item_transactionId` (`transactionId`),
  KEY `idx_item_productId` (`productId`),
  CONSTRAINT `fk_item_transaction` FOREIGN KEY (`transactionId`) REFERENCES `transactions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_item_product` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Aktifkan kembali pengecekan foreign key
SET FOREIGN_KEY_CHECKS = 1;

-- Seeding data Admin dan User
INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`) VALUES
(1, 'Administrator', 'admin@toko.com', 'admin123', 'admin'),
(2, 'User Demo', 'user@toko.com', 'user123', 'user')
ON DUPLICATE KEY UPDATE `name`=`name`;

-- Seeding data Produk Elektronik
INSERT INTO `products` (`id`, `name`, `description`, `price`, `stock`, `image`, `category`) VALUES
(1, 'MacBook Air M2 13-inch', 'Apple M2 chip dengan 8-core CPU dan 8-core GPU, 8GB RAM, 256GB SSD Storage. Layar Liquid Retina 13.6 inci yang memukau.', 18500000, 15, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&q=80&w=800', 'laptops'),
(2, 'iPhone 15 Pro Max 256GB', 'Desain titanium yang kokoh dan ringan dengan layar Super Retina XDR 6.7 inci. Chip A17 Pro yang revolusioner dengan GPU 6-core.', 24999000, 10, 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?auto=format&fit=crop&q=80&w=800', 'smartphones'),
(3, 'Sony WH-1000XM5 Wireless Headphones', 'Headphone dengan noise cancellation terdepan di industri. Suara berkualitas tinggi dengan driver 30mm yang dirancang khusus.', 5499000, 25, 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?auto=format&fit=crop&q=80&w=800', 'audio'),
(4, 'Samsung Galaxy S24 Ultra', 'Smartphone dengan Galaxy AI, kamera 200MP, S Pen terintegrasi, dan prosesor Snapdragon 8 Gen 3 for Galaxy.', 21999000, 12, 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?auto=format&fit=crop&q=80&w=800', 'smartphones'),
(5, 'iPad Air 5th Gen M1', 'Layar Liquid Retina 10.9 inci dengan True Tone. Chip Apple M1 dengan neural engine untuk performa luar biasa.', 9500000, 18, 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?auto=format&fit=crop&q=80&w=800', 'tablets'),
(6, 'LG OLED evo C3 55 Inch 4K Smart TV', 'TV OLED dengan prosesor AI $\\alpha$9 Gen6 4K. Kualitas gambar dengan warna sempurna dan hitam pekat.', 17999000, 8, 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?auto=format&fit=crop&q=80&w=800', 'tv'),
(7, 'ASUS ROG Zephyrus G14', 'Laptop gaming kompak dengan AMD Ryzen 9 dan NVIDIA GeForce RTX 4060. Layar ROG Nebula Display 165Hz.', 25999000, 7, 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?auto=format&fit=crop&q=80&w=800', 'laptops'),
(8, 'AirPods Pro (2nd Generation)', 'Active Noise Cancellation yang 2x lebih efektif. Audio Spasial yang dipersonalisaikan dengan pelacakan kepala dinamis.', 3999000, 30, 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?auto=format&fit=crop&q=80&w=800', 'audio')
ON DUPLICATE KEY UPDATE `name`=`name`;
