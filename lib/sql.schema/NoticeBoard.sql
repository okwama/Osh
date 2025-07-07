-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 06, 2025 at 01:31 PM
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
-- Table structure for table `NoticeBoard`
--

CREATE TABLE `NoticeBoard` (
  `id` int(11) NOT NULL,
  `title` varchar(191) NOT NULL,
  `content` varchar(191) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `countryId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `NoticeBoard`
--

INSERT INTO `NoticeBoard` (`id`, `title`, `content`, `createdAt`, `updatedAt`, `countryId`) VALUES
(6, 'STOCK OUT', '9000 PUFFS OUT OF STOCK\r\n1. CHIZI MINT\r\n2. PINEAPPLE MANGO MINT\r\n3. STRAWBERRY ICE CREAM\r\n4. SUN KISSED GRAPE\r\n5. BLUE RAZZ\r\n6. FROST APPLE\r\n7. MANGO PEACH.', '2025-06-16 15:23:48.577', '2025-06-16 15:23:48.577', 1),
(7, 'STOCK AVAILABLE 9000 PUFFS', '1. KWI DRAGON STRAWBERRY \r\n2. CARAMEL HAZELNUT\r\n3. ICE SPARKLING ORANGE\r\n4. FRESH LYCHEE\r\n5. CHILLY LEMON\r\n6. DAWA COCKTAIL', '2025-06-16 15:27:23.693', '2025-06-16 15:27:23.693', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `NoticeBoard`
--
ALTER TABLE `NoticeBoard`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `NoticeBoard`
--
ALTER TABLE `NoticeBoard`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
