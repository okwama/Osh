-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 06, 2025 at 02:46 AM
-- Server version: 10.6.22-MariaDB-cll-lve
-- PHP Version: 8.3.22

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `citlogis_ws`
--

-- --------------------------------------------------------

--
-- Table structure for table `Product`
--

CREATE TABLE `Product` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `category_id` int(11) NOT NULL,
  `category` varchar(191) NOT NULL,
  `unit_cost` decimal(11,2) NOT NULL,
  `description` varchar(191) DEFAULT NULL,
  `currentStock` int(11) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL,
  `clientId` int(11) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `unit_cost_ngn` decimal(11,2) DEFAULT NULL,
  `unit_cost_tzs` decimal(11,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `Product`
--

INSERT INTO `Product` (`id`, `name`, `category_id`, `category`, `unit_cost`, `description`, `currentStock`, `createdAt`, `updatedAt`, `clientId`, `image`, `unit_cost_ngn`, `unit_cost_tzs`) VALUES
(1, 'Carlifonia Strawberry 3000puffs', 1, '3000 puffs', 200.00, '', NULL, '2025-05-06 09:09:37.260', '2025-06-25 17:05:21.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_1_1750863921.jpg', 90.00, 4130.00),
(2, 'Australian Ice Mango 3000puffs', 1, '3000 puffs', 200.00, '', NULL, '2025-05-06 09:10:00.366', '2025-06-25 16:59:30.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_2_1750863570.jpg', 90.00, 4130.00),
(3, 'Ice Passion Fruit 3000puffs', 1, '3000 puffs', 200.00, '', NULL, '2025-05-07 05:59:00.405', '2025-06-25 17:04:30.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_3_1750863870.jpg', 90.00, 4130.00),
(4, 'Pineapple Mint 3000puffs', 1, '3000 puffs', 200.00, '', NULL, '2025-05-07 05:59:55.441', '2025-06-25 17:04:50.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_4_1750863890.jpg', 90.00, 4130.00),
(5, 'Pina colada 3000puffs', 1, '3000 puffs', 200.00, '', NULL, '2025-05-07 06:00:13.389', '2025-06-25 17:05:34.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_5_1750863934.jpg', 90.00, 4130.00),
(6, 'Ice Watermelon Bliss 3000puffs', 1, '3000 puffs', 200.00, '', NULL, '2025-05-07 06:00:45.242', '2025-06-25 17:05:06.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_6_1750863906.jpg', 90.00, 4130.00),
(7, 'Minty Snow 3000puffs', 1, '3000 puffs', 200.00, '', NULL, '2025-05-07 06:01:02.942', '2025-06-25 17:04:06.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_7_1750863846.jpg', 90.00, 4130.00),
(8, 'Chizi Mint 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:01:41.401', '2025-06-25 17:03:44.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_8_1750863824.jpg', 90.00, 4130.00),
(9, 'Dawa Cocktail 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:01:54.911', '2025-06-25 17:03:29.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_9_1750863809.jpg', 90.00, 4130.00),
(10, 'Caramel Hazelnut 9000 puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:02:09.187', '2025-06-25 16:59:52.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_10_1750863592.jpg', 90.00, 4130.00),
(11, 'Kiwi Dragon Strawberry 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:02:54.414', '2025-06-25 17:00:07.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_11_1750863607.jpg', 90.00, 4130.00),
(12, 'Fresh Lychee 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:03:06.141', '2025-06-25 17:00:21.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_12_1750863621.jpg', 90.00, 4130.00),
(13, 'Ice Sparkling Orange 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:03:34.833', '2025-06-25 17:00:44.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_13_1750863644.jpg', 90.00, 4130.00),
(14, 'Pineapple Mango Mint 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:03:48.958', '2025-06-25 17:01:03.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_14_1750863663.jpg', 90.00, 4130.00),
(15, 'Blue Razz 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:04:00.932', '2025-06-25 17:01:15.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_15_1750863675.jpg', 90.00, 4130.00),
(16, 'Chilly Lemon Soda 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:04:16.580', '2025-06-25 17:01:30.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_16_1750863690.jpg', 90.00, 4130.00),
(17, 'Strawberry ice cream 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-07 06:04:29.395', '2025-06-25 17:01:54.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_17_1750863714.jpg', 90.00, 4130.00),
(18, 'Cool Mint 3dot', 4, 'Gold pouch 3dot ', 200.00, '', NULL, '2025-05-07 06:04:40.846', '2025-06-25 17:06:51.000', NULL, 'https://citlogisticssystems.com/woosh/admin//upload/products/product_18_1750864011.jpg', 90.00, 4130.00),
(19, 'Cool Mint 5dot', 5, 'Gold pouch 5dot', 200.00, NULL, NULL, '2025-05-07 06:04:54.227', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00),
(20, 'Frost Apple 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-20 05:21:40.620', '2025-06-25 17:24:15.000', NULL, '', 90.00, 4130.00),
(21, 'Mango Peach 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-20 05:25:34.421', '2025-06-25 17:23:53.000', NULL, '', 90.00, 4130.00),
(22, 'Sun Kissed 9000puffs', 3, '9000 puffs', 200.00, '', NULL, '2025-05-20 05:26:43.146', '2025-06-25 17:24:38.000', NULL, '', 90.00, 4130.00),
(23, 'Strawberry Mint 3 dot', 4, 'Gold pouch 3dot ', 200.00, NULL, NULL, '2025-05-20 05:32:01.035', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00),
(24, 'Sweet Mint 3dot', 4, 'Gold pouch 3dot ', 200.00, NULL, NULL, '2025-05-20 05:32:34.605', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00),
(25, 'Citrus Mint 3dot', 4, 'Gold pouch 3dot ', 200.00, NULL, NULL, '2025-05-20 05:33:06.714', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00),
(26, 'Mix Berry mint 3dot', 4, 'Gold pouch 3dot ', 200.00, NULL, NULL, '2025-05-20 05:33:39.064', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00),
(27, 'Strawberry Mint 5 dot', 5, 'Gold pouch 5dot', 200.00, NULL, NULL, '2025-05-20 05:35:23.670', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00),
(28, 'Sweet Mint 5dot', 5, 'Gold pouch 5dot', 200.00, NULL, NULL, '2025-05-20 05:35:55.672', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00),
(29, 'Citrus Mint 5dot', 5, 'Gold pouch 5dot', 200.00, NULL, NULL, '2025-05-20 05:36:52.357', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00),
(30, 'Mix Berry Mint 5dot', 5, 'Gold pouch 5dot', 200.00, NULL, NULL, '2025-05-20 05:37:22.148', '2025-05-07 06:04:54.227', NULL, '', 90.00, 4130.00);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `Product`
--
ALTER TABLE `Product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Product_clientId_fkey` (`clientId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `Product`
--
ALTER TABLE `Product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `Product`
--
ALTER TABLE `Product`
  ADD CONSTRAINT `Product_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
