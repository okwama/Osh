-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 06, 2025 at 03:00 AM
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
-- Table structure for table `routes`
--

CREATE TABLE `routes` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `region` int(11) NOT NULL,
  `region_name` varchar(100) NOT NULL,
  `country_id` int(11) NOT NULL,
  `country_name` varchar(100) NOT NULL,
  `leader_id` int(11) NOT NULL,
  `leader_name` varchar(100) NOT NULL,
  `status` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `routes`
--

INSERT INTO `routes` (`id`, `name`, `region`, `region_name`, `country_id`, `country_name`, `leader_id`, `leader_name`, `status`) VALUES
(1, 'CBD/HURLINGHAM/KILIMANI', 1, 'Nairobi', 1, 'Kenya', 1, 'Benjamin', 0),
(2, 'THIKA RD/KASARANI/TRM/RUIRU/KIMBO/JUJA', 1, 'Nairobi', 1, 'Kenya', 1, 'Benjamin', 0),
(3, 'Narok /Maasai Mara', 1, 'Nairobi', 0, '', 0, '', 0),
(4, 'NAIVASHA/NYANDARUA/GILGIL/NYAHURURU', 0, '', 0, '', 0, '', 0),
(5, 'COAST', 0, '', 0, '', 0, '', 0),
(6, 'MACHAKOS', 0, '', 0, '', 0, '', 0),
(7, 'NAKURU EAST/NAKURU WEST', 0, '', 0, '', 0, '', 0),
(8, 'ELDORET/KITALE/BUNGOMA', 0, '', 0, '', 0, '', 0),
(9, 'ARUSHA/DODOMA/DAR ES SALAAM', 0, '', 0, '', 0, '', 0),
(10, 'DIANI/UKUNDA', 0, '', 0, '', 0, '', 0),
(11, 'MOMBASA RD/OUTERING/SOUTH B/UTAWALA/BURUBURU', 0, '', 0, '', 0, '', 0),
(12, 'BAMBURI/MTAWAPA/NYALI', 0, '', 0, '', 0, '', 0),
(13, 'SOUTH B/LANGATA/RONGAI/MADARAKA', 0, '', 0, '', 0, '', 0),
(14, 'MSA RD/KITENGELA/ATHI RIVER/BELLEVUE/MACHAKOS TOWN', 0, '', 0, '', 0, '', 0),
(15, 'KAHAWA WEST/JUJA/THIKA/KENOL', 0, '', 0, '', 0, '', 0),
(16, 'PARKLANDS/RUAKA/LIMURU RD/BANANA/EASTLEIGH/PANGANI', 0, '', 0, '', 0, '', 0),
(17, 'JOGOO RD/KAYOLE/KANGUNDO RD/ OUTERING RD', 0, '', 0, '', 0, '', 0),
(18, 'MOMBASA ', 0, '', 0, '', 0, '', 0),
(19, 'NGONG RD/LENANA RD/KILIMANI/CBD/KAREN', 0, '', 0, '', 0, '', 0),
(20, 'KISII/OYUGIS/HOMABAY', 0, '', 0, '', 0, '', 0),
(21, 'KAYOLE/DONHOLM/EMBAKASI/UTAWALA', 0, '', 0, '', 0, '', 0),
(22, 'DONHOL/FEDHA/UTAWALA/MLOLONGO/ATHI RIVER/KITENGELA', 0, '', 0, '', 0, '', 0),
(23, 'NORTHERN BYPASS/RUAKA/MIREMA/CBD', 0, '', 0, '', 0, '', 0),
(24, 'BULBUL/VET/NGONG TOWN/KISERIAN/MATASIA/RONGAI', 0, '', 0, '', 0, '', 0),
(25, 'KIAMBU RD/KIAMBU TOWN/LIMURU ', 0, '', 0, '', 0, '', 0),
(26, 'EMBU TOWN/CHUKA/KERUGOYA/MWEA/KUTUS', 0, '', 0, '', 0, '', 0),
(27, 'MERU/ISIOLO/MAKUTANO', 0, '', 0, '', 0, '', 0),
(28, 'KISUMU TOWN/AHERO-KISUMU/KISUMU-MASENO', 0, '', 0, '', 0, '', 0),
(29, 'NYERI TOWN/KARATINA/OTHAYA', 0, '', 0, '', 0, '', 0),
(30, 'WAIYAKI WAY/WESTLANDS/KIKUYU/KITUSURU', 0, '', 0, '', 0, '', 0),
(31, 'KITUI', 0, '', 0, '', 0, '', 0),
(32, 'WESTLANDS/KITUSURU/KILELESHWA/LAVINGTON', 0, '', 0, '', 0, '', 0),
(33, 'KAKAMEGA/MUMIAS', 0, '', 0, '', 0, '', 0),
(34, 'WAIYAKI WAY/KIKUYU RD/NAIROBI-NAKURU HIGHWAY/REDHILL', 0, '', 0, '', 0, '', 0),
(35, 'KILIFI/MALINDI/WATAMU', 0, '', 0, '', 0, '', 0),
(36, 'NANYUKI', 0, '', 0, '', 0, '', 0),
(37, 'BOMAS/LANGATA RD/NAIROBI WEST/SOUTH C', 0, '', 0, '', 0, '', 0),
(38, 'KAREN/KERARAPON/BULBUL/ZAMBIA', 0, '', 0, '', 0, '', 0),
(39, 'NAIROBI/MURANGA/KIRINYAGA', 0, '', 0, '', 0, '', 0),
(40, 'RUIRU/MARURUI/KIAMBU RD/RIDGEWAYS', 0, '', 0, '', 0, '', 0),
(41, 'KAMAKIS/KAHAWA SUKARI/MOUNTAIN MALL/SURVEY', 0, '', 0, '', 0, '', 0),
(42, 'NAKURU EAST/NAKURU WEST', 0, '', 0, '', 0, '', 0),
(43, 'DAR ES SALAAM', 0, '', 0, '', 0, '', 0),
(44, 'DODOMA', 0, '', 0, '', 0, '', 0),
(45, 'ARUSHA', 0, '', 0, '', 0, '', 0),
(46, 'MURANGA/SAGANA/KENOL', 0, '', 0, '', 0, '', 0),
(47, 'MOSHI', 0, '', 0, '', 0, '', 0),
(49, 'VOI/MTITO/EMALI/SULTAN MAHMUD', 0, '', 0, '', 0, '', 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `routes`
--
ALTER TABLE `routes`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `routes`
--
ALTER TABLE `routes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
