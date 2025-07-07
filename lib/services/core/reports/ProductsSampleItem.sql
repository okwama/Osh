-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 07, 2025 at 01:02 AM
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
-- Table structure for table `ProductsSampleItem`
--

CREATE TABLE `ProductsSampleItem` (
  `id` int(11) NOT NULL,
  `productsSampleId` int(11) NOT NULL,
  `productName` varchar(191) NOT NULL,
  `quantity` int(11) NOT NULL,
  `reason` varchar(191) NOT NULL,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ProductsSampleItem`
--

INSERT INTO `ProductsSampleItem` (`id`, `productsSampleId`, `productName`, `quantity`, `reason`, `clientId`, `userId`) VALUES
(6, 7, 'Chilly Lemon Soda 9000puffs', 1, 'No sample available', 1861, 91),
(7, 7, 'Carlifonia Strawberry 3000puffs', 1, 'no sample available', 1861, 91),
(8, 8, 'Carlifonia Strawberry 3000puffs', 1, 'no sample available', 1861, 91),
(9, 8, 'Chilly Lemon Soda 9000puffs', 1, 'No sample available', 1861, 91),
(10, 9, 'Chilly Lemon Soda 9000puffs', 1, 'No sample available', 1861, 91),
(11, 9, 'Carlifonia Strawberry 3000puffs', 1, 'no sample available', 1861, 91),
(14, 12, 'Citrus Mint 5dot', 0, 'needing o 3', 638, 52),
(19, 15, 'Blue Razz 9000puffs', 1, 'for testing', 526, 52),
(20, 16, 'Pineapple Mint 3000puffs', 1, 'for sampling', 638, 52),
(21, 17, 'Blue Razz 9000puffs', 1, 'to create awareness in this outlet where vapes are not known', 1904, 62),
(23, 19, 'Blue Razz 9000puffs', 1, 'test', 2086, 94),
(24, 19, 'Mango Peach', 1, 'display', 2086, 94),
(25, 20, 'Blue Razz 9000puffs', 2, 'test', 2431, 94);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ProductsSampleItem`
--
ALTER TABLE `ProductsSampleItem`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ProductsSampleItem_userId_idx` (`userId`),
  ADD KEY `ProductsSampleItem_clientId_idx` (`clientId`),
  ADD KEY `ProductsSampleItem_productsSampleId_idx` (`productsSampleId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ProductsSampleItem`
--
ALTER TABLE `ProductsSampleItem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `ProductsSampleItem`
--
ALTER TABLE `ProductsSampleItem`
  ADD CONSTRAINT `ProductsSampleItem_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductsSampleItem_productsSampleId_fkey` FOREIGN KEY (`productsSampleId`) REFERENCES `ProductsSample` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductsSampleItem_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
