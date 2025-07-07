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
-- Table structure for table `UpliftSale`
--

CREATE TABLE `UpliftSale` (
  `id` int(11) NOT NULL,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `status` varchar(191) NOT NULL DEFAULT 'pending',
  `totalAmount` double NOT NULL DEFAULT 0,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `UpliftSale`
--

INSERT INTO `UpliftSale` (`id`, `clientId`, `userId`, `status`, `totalAmount`, `createdAt`, `updatedAt`) VALUES
(3, 689, 52, 'pending', 2380, '2025-05-08 12:52:18.455', '2025-05-08 12:52:20.288'),
(13, 246, 46, 'pending', 18750, '2025-05-27 09:41:02.778', '2025-05-27 09:41:06.085'),
(15, 2325, 94, 'pending', 300, '2025-06-17 07:59:18.359', '2025-06-17 07:59:20.963'),
(16, 2159, 94, 'pending', 5000, '2025-06-19 17:43:53.341', '2025-06-19 17:43:55.525'),
(17, 2204, 94, 'pending', 23, '2025-07-04 06:07:16.204', '2025-07-04 06:07:18.535');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `UpliftSale`
--
ALTER TABLE `UpliftSale`
  ADD PRIMARY KEY (`id`),
  ADD KEY `UpliftSale_clientId_fkey` (`clientId`),
  ADD KEY `UpliftSale_userId_fkey` (`userId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `UpliftSale`
--
ALTER TABLE `UpliftSale`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `UpliftSale`
--
ALTER TABLE `UpliftSale`
  ADD CONSTRAINT `UpliftSale_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `UpliftSale_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
