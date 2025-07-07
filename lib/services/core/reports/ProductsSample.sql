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
-- Table structure for table `ProductsSample`
--

CREATE TABLE `ProductsSample` (
  `id` int(11) NOT NULL,
  `reportId` int(11) NOT NULL,
  `productName` varchar(191) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `reason` varchar(191) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ProductsSample`
--

INSERT INTO `ProductsSample` (`id`, `reportId`, `productName`, `quantity`, `reason`, `status`, `clientId`, `userId`) VALUES
(7, 712, NULL, NULL, NULL, 0, 1861, 91),
(8, 714, NULL, NULL, NULL, 0, 1861, 91),
(9, 717, NULL, NULL, NULL, 0, 1861, 91),
(12, 1186, NULL, NULL, NULL, 0, 638, 52),
(15, 2375, NULL, NULL, NULL, 0, 526, 52),
(16, 2424, NULL, NULL, NULL, 0, 638, 52),
(17, 2512, NULL, NULL, NULL, 0, 1904, 62),
(19, 5513, NULL, NULL, NULL, 0, 2086, 94),
(20, 7105, NULL, NULL, NULL, 0, 2431, 94);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ProductsSample`
--
ALTER TABLE `ProductsSample`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ProductsSample_reportId_key` (`reportId`),
  ADD KEY `ProductsSample_userId_idx` (`userId`),
  ADD KEY `ProductsSample_clientId_idx` (`clientId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ProductsSample`
--
ALTER TABLE `ProductsSample`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `ProductsSample`
--
ALTER TABLE `ProductsSample`
  ADD CONSTRAINT `ProductsSample_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductsSample_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `Report` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductsSample_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
