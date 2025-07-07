-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 07, 2025 at 02:01 AM
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
-- Table structure for table `UpliftSaleItem`
--

CREATE TABLE `UpliftSaleItem` (
  `id` int(11) NOT NULL,
  `upliftSaleId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unitPrice` double NOT NULL,
  `total` double NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `UpliftSaleItem`
--

INSERT INTO `UpliftSaleItem` (`id`, `upliftSaleId`, `productId`, `quantity`, `unitPrice`, `total`, `createdAt`) VALUES
(3, 3, 19, 7, 340, 2380, '2025-05-08 12:52:19.555'),
(15, 13, 2, 3, 1250, 3750, '2025-05-27 09:41:03.885'),
(16, 13, 3, 3, 1250, 3750, '2025-05-27 09:41:03.885'),
(17, 13, 7, 3, 1250, 3750, '2025-05-27 09:41:03.885'),
(18, 13, 4, 3, 1250, 3750, '2025-05-27 09:41:03.885'),
(19, 13, 1, 3, 1250, 3750, '2025-05-27 09:41:03.885'),
(21, 15, 15, 2, 100, 200, '2025-06-17 07:59:19.543'),
(22, 15, 8, 1, 100, 100, '2025-06-17 07:59:19.543'),
(23, 16, 10, 1, 2000, 2000, '2025-06-19 17:43:54.435'),
(24, 16, 9, 1, 3000, 3000, '2025-06-19 17:43:54.435'),
(25, 17, 15, 1, 23, 23, '2025-07-04 06:07:17.602');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `UpliftSaleItem`
--
ALTER TABLE `UpliftSaleItem`
  ADD PRIMARY KEY (`id`),
  ADD KEY `UpliftSaleItem_upliftSaleId_fkey` (`upliftSaleId`),
  ADD KEY `UpliftSaleItem_productId_fkey` (`productId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `UpliftSaleItem`
--
ALTER TABLE `UpliftSaleItem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `UpliftSaleItem`
--
ALTER TABLE `UpliftSaleItem`
  ADD CONSTRAINT `UpliftSaleItem_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `UpliftSaleItem_upliftSaleId_fkey` FOREIGN KEY (`upliftSaleId`) REFERENCES `UpliftSale` (`id`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
