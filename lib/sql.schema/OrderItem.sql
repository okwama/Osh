-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 07, 2025 at 02:07 AM
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
-- Table structure for table `OrderItem`
--

CREATE TABLE `OrderItem` (
  `id` int(11) NOT NULL,
  `orderId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `priceOptionId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `OrderItem`
--

INSERT INTO `OrderItem` (`id`, `orderId`, `productId`, `quantity`, `priceOptionId`) VALUES
(122, 83, 18, 1, 8),
(124, 84, 19, 10, 12),
(125, 84, 28, 10, 12),
(126, 85, 28, 10, 12),
(173, 97, 12, 2, 5),
(174, 97, 13, 2, 5),
(175, 97, 17, 2, 5),
(176, 97, 8, 2, 5),
(177, 98, 8, 5, 6),
(178, 99, 15, 4, 5),
(179, 99, 16, 1, 6),
(180, 100, 2, 1, 1),
(181, 101, 10, 1, 5),
(182, 102, 2, 2, 1),
(183, 103, 2, 1, 1),
(184, 104, 25, 1, 8),
(185, 105, 16, 1, 5),
(186, 106, 15, 5, 5),
(187, 106, 1, 1, 1),
(188, 107, 19, 4, 10),
(189, 108, 10, 1, 5),
(195, 110, 8, 2, 5),
(196, 111, 15, 22, 7),
(197, 112, 8, 12, 6),
(198, 113, 7, 2, 1),
(199, 114, 10, 1, 5),
(200, 115, 29, 2, 12),
(201, 115, 30, 2, 12),
(202, 115, 27, 2, 12),
(203, 115, 28, 2, 12),
(204, 115, 19, 2, 12),
(205, 116, 10, 3, 6),
(206, 116, 16, 2, 6),
(207, 116, 9, 2, 6),
(208, 116, 12, 3, 6),
(209, 117, 1, 2, 1),
(210, 118, 1, 3, 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `OrderItem`
--
ALTER TABLE `OrderItem`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `OrderItem_orderId_productId_priceOptionId_key` (`orderId`,`productId`,`priceOptionId`),
  ADD KEY `OrderItem_orderId_idx` (`orderId`),
  ADD KEY `OrderItem_priceOptionId_idx` (`priceOptionId`),
  ADD KEY `OrderItem_productId_fkey` (`productId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `OrderItem`
--
ALTER TABLE `OrderItem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=211;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `OrderItem`
--
ALTER TABLE `OrderItem`
  ADD CONSTRAINT `OrderItem_orderId_fkey` FOREIGN KEY (`orderId`) REFERENCES `MyOrder` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `OrderItem_priceOptionId_fkey` FOREIGN KEY (`priceOptionId`) REFERENCES `PriceOption` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `OrderItem_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
