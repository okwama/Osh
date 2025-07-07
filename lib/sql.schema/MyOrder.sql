-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 07, 2025 at 02:06 AM
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
-- Table structure for table `MyOrder`
--

CREATE TABLE `MyOrder` (
  `id` int(11) NOT NULL,
  `totalAmount` double NOT NULL,
  `totalCost` decimal(11,2) NOT NULL,
  `amountPaid` decimal(11,2) NOT NULL,
  `balance` decimal(11,2) NOT NULL,
  `comment` varchar(191) NOT NULL,
  `customerType` varchar(191) NOT NULL,
  `customerId` varchar(191) NOT NULL,
  `customerName` varchar(191) NOT NULL,
  `orderDate` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `riderId` int(11) DEFAULT NULL,
  `riderName` varchar(191) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `approvedTime` varchar(191) DEFAULT NULL,
  `dispatchTime` varchar(191) DEFAULT NULL,
  `deliveryLocation` varchar(191) DEFAULT NULL,
  `complete_latitude` varchar(191) DEFAULT NULL,
  `complete_longitude` varchar(191) DEFAULT NULL,
  `complete_address` varchar(191) DEFAULT NULL,
  `pickupTime` varchar(191) DEFAULT NULL,
  `deliveryTime` varchar(191) DEFAULT NULL,
  `cancel_reason` varchar(191) DEFAULT NULL,
  `recepient` varchar(191) DEFAULT NULL,
  `userId` int(11) NOT NULL,
  `clientId` int(11) NOT NULL,
  `countryId` int(11) NOT NULL,
  `regionId` int(11) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `approved_by` varchar(200) NOT NULL,
  `approved_by_name` varchar(200) NOT NULL,
  `storeId` int(11) DEFAULT NULL,
  `retail_manager` int(11) NOT NULL,
  `key_channel_manager` int(11) NOT NULL,
  `distribution_manager` int(11) NOT NULL,
  `imageUrl` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `MyOrder`
--

INSERT INTO `MyOrder` (`id`, `totalAmount`, `totalCost`, `amountPaid`, `balance`, `comment`, `customerType`, `customerId`, `customerName`, `orderDate`, `riderId`, `riderName`, `status`, `approvedTime`, `dispatchTime`, `deliveryLocation`, `complete_latitude`, `complete_longitude`, `complete_address`, `pickupTime`, `deliveryTime`, `cancel_reason`, `recepient`, `userId`, `clientId`, `countryId`, `regionId`, `createdAt`, `updatedAt`, `approved_by`, `approved_by_name`, `storeId`, `retail_manager`, `key_channel_manager`, `distribution_manager`, `imageUrl`) VALUES
(84, 9000, 0.00, 0.00, 9000.00, '', 'RETAIL', '', 'Customer', '2025-05-27 12:02:23.371', 0, NULL, 1, '2025-06-04 12:56:03 pm', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 63, 214, 1, 1, '2025-05-27 12:02:23.371', '2025-05-27 12:06:59.489', '12', 'Woosh', 1, 0, 0, 0, NULL),
(85, 4500, 0.00, 0.00, 4500.00, '', 'RETAIL', '', 'Customer', '2025-05-27 14:21:52.967', NULL, NULL, 1, '2025-06-04 01:31:35 pm', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 63, 979, 1, 1, '2025-05-27 14:21:52.967', '2025-05-27 14:21:52.967', '12', 'Woosh', 1, 0, 0, 0, NULL),
(97, 11200, 1600.00, 0.00, 11200.00, 'Order for total gachie 8pcs', 'RETAIL', '', 'Customer', '2025-06-10 09:07:34.233', NULL, NULL, 1, '2025-06-22 07:11:26 pm', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 30, 272, 1, 1, '2025-06-10 09:07:34.233', '2025-06-10 09:07:34.233', '12', 'Woosh', 1, 0, 0, 0, NULL),
(98, 7700, 1000.00, 0.00, 7700.00, '', 'RETAIL', '', 'Customer', '2025-06-13 15:27:21.619', NULL, NULL, 1, '2025-06-23 06:46:21 pm', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 26, 1990, 1, 1, '2025-06-13 15:27:21.619', '2025-06-13 15:27:21.619', '12', 'Woosh', 1, 0, 0, 0, NULL),
(99, 7140, 0.00, 0.00, 7140.00, 'test', 'RETAIL', '', 'Customer', '2025-06-21 07:52:26.498', NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 2325, 1, 1, '2025-06-17 07:52:26.498', '2025-06-17 07:52:26.498', 'Unapproved', 'Pending', 1, 0, 0, 0, 'https://ik.imagekit.io/bja2qwwdjjy/whoosh/1750146738458-923799733_Q2VBEEcQx.png'),
(100, 1100, 0.00, 0.00, 1100.00, 'test', 'RETAIL', '', 'Customer', '2025-06-18 13:11:08.167', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 1796, 1, 1, '2025-06-18 13:11:08.167', '2025-06-18 13:11:08.167', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(101, 1400, 0.00, 0.00, 1400.00, '', 'RETAIL', '', 'Customer', '2025-06-18 13:16:23.318', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 1796, 1, 1, '2025-06-18 13:16:23.318', '2025-06-18 13:16:23.318', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(102, 2200, 0.00, 0.00, 2200.00, 'h', 'RETAIL', '', 'Customer', '2025-06-19 17:42:42.461', NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 2317, 1, 1, '2025-06-19 17:42:42.461', '2025-06-19 17:42:42.461', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(103, 1100, 0.00, 0.00, 1100.00, '', 'RETAIL', '', 'Customer', '2025-06-20 14:21:55.593', NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 1796, 1, 1, '2025-06-20 14:21:55.593', '2025-06-20 14:21:55.593', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(104, 380, 0.00, 0.00, 380.00, '', 'RETAIL', '', 'Customer', '2025-06-20 14:23:59.258', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 1796, 1, 1, '2025-06-20 14:23:59.258', '2025-06-20 14:23:59.258', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(105, 1400, 200.00, 0.00, 1400.00, '', 'RETAIL', '', 'Customer', '2025-06-20 14:26:11.010', NULL, NULL, 1, '2025-06-22 07:09:13 pm', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 2171, 1, 1, '2025-06-20 14:26:11.010', '2025-06-20 14:26:11.010', '12', 'Woosh', 1, 2, 0, 2, NULL),
(106, 8100, 1200.00, 0.00, 8100.00, '', 'RETAIL', '', 'Customer', '2025-06-22 16:33:11.305', NULL, NULL, 1, '2025-06-22 07:33:36 pm', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 1780, 1, 1, '2025-06-22 16:33:11.305', '2025-06-22 16:33:11.305', '12', 'Woosh', 1, 2, 0, 9, NULL),
(107, 1600, 800.00, 0.00, 1600.00, '', 'RETAIL', '', 'Customer', '2025-06-22 16:34:29.508', NULL, NULL, 4, '2025-06-22 07:34:36 pm', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 1780, 1, 1, '2025-06-22 16:34:29.508', '2025-06-22 16:34:29.508', '12', 'Woosh', 1, 2, 0, 9, NULL),
(108, 1400, 0.00, 0.00, 1400.00, '', 'RETAIL', '', 'Customer', '2025-06-24 19:47:33.242', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 2413, 2, 1, '2025-06-24 19:47:33.242', '2025-06-24 19:47:33.242', 'Unapproved', 'Pending', 4, 0, 0, 0, NULL),
(110, 2800, 0.00, 0.00, 2800.00, '', '', '', '', '2025-06-25 15:31:04.902', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 103, 899, 1, 0, '2025-06-25 15:31:04.902', '2025-06-25 15:31:04.902', 'Unapproved', '', NULL, 0, 0, 0, NULL),
(111, 700, 0.00, 0.00, 0.00, '', '', '', '', '2025-06-25 15:32:33.725', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 103, 2430, 1, 0, '2025-06-25 15:32:33.725', '2025-06-25 15:31:04.902', 'Unapproved', '', NULL, 0, 0, 0, NULL),
(112, 0, 0.00, 0.00, 0.00, '', '', '', '', '2025-06-25 16:45:11.294', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 103, 2008, 0, 0, '2025-06-25 16:45:11.294', '2025-06-25 16:45:11.294', '', '', NULL, 0, 0, 0, NULL),
(113, 2200, 0.00, 0.00, 2200.00, '', '', '', '', '2025-06-25 16:48:09.581', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 103, 2221, 1, 0, '2025-06-25 16:48:09.581', '2025-06-25 16:48:09.581', '', '', NULL, 0, 0, 0, NULL),
(114, 1400, 0.00, 0.00, 1400.00, '', 'RETAIL', '', 'Customer', '2025-06-28 12:23:30.357', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 140, 1, 1, '2025-06-28 12:23:30.357', '2025-06-28 12:23:30.357', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(115, 4500, 0.00, 0.00, 4500.00, 'location:Fedha \npayment on delivery \n', 'RETAIL', '', 'Customer', '2025-07-01 14:26:58.078', NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 114, 473, 1, 1, '2025-07-01 14:26:58.078', '2025-07-01 14:26:58.078', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(116, 15400, 0.00, 0.00, 15400.00, 'payment on delivery \nlocation:fedha', 'RETAIL', '', 'Customer', '2025-07-01 14:34:07.537', NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 114, 404, 1, 1, '2025-07-01 14:34:07.537', '2025-07-01 14:34:07.537', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(117, 2200, 0.00, 0.00, 2200.00, '', 'RETAIL', '', 'Customer', '2025-07-02 18:00:24.920', NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 146, 1, 1, '2025-07-02 18:00:24.920', '2025-07-02 18:00:24.920', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL),
(118, 3300, 0.00, 0.00, 3300.00, '', 'RETAIL', '', 'Customer', '2025-07-02 18:02:05.500', NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 94, 2430, 1, 1, '2025-07-02 18:02:05.500', '2025-07-02 18:02:05.500', 'Unapproved', 'Pending', 1, 0, 0, 0, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `MyOrder`
--
ALTER TABLE `MyOrder`
  ADD PRIMARY KEY (`id`),
  ADD KEY `MyOrder_userId_idx` (`userId`),
  ADD KEY `MyOrder_clientId_idx` (`clientId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `MyOrder`
--
ALTER TABLE `MyOrder`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=119;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `MyOrder`
--
ALTER TABLE `MyOrder`
  ADD CONSTRAINT `MyOrder_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `MyOrder_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
