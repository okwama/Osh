-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 05, 2025 at 12:23 AM
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
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(100) NOT NULL,
  `balance` decimal(11,2) NOT NULL,
  `status` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `accounts_g`
--

CREATE TABLE `accounts_g` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(100) NOT NULL,
  `balance` decimal(11,2) NOT NULL,
  `status` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `AccountTypes`
--

CREATE TABLE `AccountTypes` (
  `id` int(11) NOT NULL,
  `account_type` varchar(100) NOT NULL,
  `account_category` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `account_category`
--

CREATE TABLE `account_category` (
  `id` int(3) NOT NULL,
  `name` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `account_update`
--

CREATE TABLE `account_update` (
  `id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `account_type` int(11) NOT NULL,
  `account_category` int(11) NOT NULL,
  `reference` varchar(250) NOT NULL,
  `amount` decimal(11,2) NOT NULL,
  `amount_in` decimal(11,2) NOT NULL,
  `amount_out` decimal(11,2) NOT NULL,
  `balance` decimal(11,2) NOT NULL,
  `transaction_date` varchar(100) NOT NULL,
  `update_date` varchar(100) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL,
  `notes` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `account_update_g`
--

CREATE TABLE `account_update_g` (
  `id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `reference` varchar(250) NOT NULL,
  `amount` decimal(11,2) NOT NULL,
  `amount_in` decimal(11,2) NOT NULL,
  `amount_out` decimal(11,2) NOT NULL,
  `balance` decimal(11,2) NOT NULL,
  `transaction_date` varchar(100) NOT NULL,
  `update_date` varchar(100) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Category`
--

CREATE TABLE `Category` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `clientHistory`
--

CREATE TABLE `clientHistory` (
  `id` int(11) NOT NULL,
  `client_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `reference` varchar(200) NOT NULL,
  `amount_in` decimal(10,2) NOT NULL,
  `amount_out` decimal(10,2) NOT NULL,
  `balance` decimal(10,2) NOT NULL,
  `my_date` varchar(50) NOT NULL,
  `createdAt` varchar(50) NOT NULL,
  `staff` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ClientPayment`
--

CREATE TABLE `ClientPayment` (
  `id` int(11) NOT NULL,
  `clientId` int(11) NOT NULL,
  `amount` double NOT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `date` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `status` varchar(191) DEFAULT NULL,
  `method` varchar(191) DEFAULT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Clients`
--

CREATE TABLE `Clients` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `address` varchar(191) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `balance` decimal(11,2) DEFAULT NULL,
  `email` varchar(191) DEFAULT NULL,
  `region_id` int(11) NOT NULL,
  `region` varchar(191) NOT NULL,
  `route_id` int(11) DEFAULT NULL,
  `route_name` varchar(191) DEFAULT NULL,
  `route_id_update` int(11) DEFAULT NULL,
  `route_name_update` varchar(100) DEFAULT NULL,
  `contact` varchar(191) NOT NULL,
  `tax_pin` varchar(191) DEFAULT NULL,
  `location` varchar(191) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `client_type` int(11) DEFAULT NULL,
  `outlet_account` int(11) DEFAULT NULL,
  `countryId` int(11) NOT NULL,
  `added_by` int(11) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `clients_g`
--

CREATE TABLE `clients_g` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `address` varchar(191) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `balance` decimal(11,2) DEFAULT NULL,
  `email` varchar(191) DEFAULT NULL,
  `region_id` int(11) NOT NULL,
  `region` varchar(191) NOT NULL,
  `route_id` int(11) DEFAULT NULL,
  `route_name` varchar(191) DEFAULT NULL,
  `route_id_update` int(11) DEFAULT NULL,
  `route_name_update` varchar(100) DEFAULT NULL,
  `contact` varchar(191) NOT NULL,
  `tax_pin` varchar(191) DEFAULT NULL,
  `location` varchar(191) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `client_type` int(11) DEFAULT NULL,
  `countryId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `client_history_g`
--

CREATE TABLE `client_history_g` (
  `id` int(11) NOT NULL,
  `client_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `reference` varchar(200) NOT NULL,
  `amount_in` decimal(10,2) NOT NULL,
  `amount_out` decimal(10,2) NOT NULL,
  `balance` decimal(10,2) NOT NULL,
  `my_date` varchar(50) NOT NULL,
  `createdAt` varchar(50) NOT NULL,
  `staff` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `client_payments_g`
--

CREATE TABLE `client_payments_g` (
  `id` int(11) NOT NULL,
  `clientId` int(11) NOT NULL,
  `amount` double NOT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `date` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `status` varchar(191) DEFAULT NULL,
  `method` varchar(191) DEFAULT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `company_assets`
--

CREATE TABLE `company_assets` (
  `id` int(11) NOT NULL,
  `asset_name` varchar(100) NOT NULL,
  `category` varchar(50) NOT NULL,
  `purchase_date` date NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `description` text DEFAULT NULL,
  `useful_life` int(11) NOT NULL,
  `residual_value` decimal(11,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` int(11) NOT NULL,
  `status` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contracts`
--

CREATE TABLE `contracts` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `comment` text NOT NULL,
  `date` varchar(100) NOT NULL,
  `doc` varchar(200) NOT NULL,
  `createdAt` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contracts_g`
--

CREATE TABLE `contracts_g` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `comment` text NOT NULL,
  `date` varchar(100) NOT NULL,
  `doc` varchar(200) NOT NULL,
  `createdAt` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `countries_g`
--

CREATE TABLE `countries_g` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `status` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Country`
--

CREATE TABLE `Country` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `status` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `departments_g`
--

CREATE TABLE `departments_g` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `depreciation_entries`
--

CREATE TABLE `depreciation_entries` (
  `id` int(11) NOT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `date_posted` date DEFAULT NULL,
  `notes` text NOT NULL,
  `posted_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `documents`
--

CREATE TABLE `documents` (
  `id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` text NOT NULL,
  `category_id` int(11) NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `uploaded_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `doc_categories`
--

CREATE TABLE `doc_categories` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Expenses`
--

CREATE TABLE `Expenses` (
  `id` int(11) NOT NULL,
  `expense_type_id` int(11) NOT NULL,
  `reference` varchar(50) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `paid` decimal(11,2) NOT NULL,
  `balance` decimal(11,2) NOT NULL,
  `expense_date` date NOT NULL,
  `posted_by` int(11) NOT NULL,
  `notes` text DEFAULT NULL,
  `posted_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `FeedbackReport`
--

CREATE TABLE `FeedbackReport` (
  `reportId` int(11) NOT NULL,
  `comment` varchar(191) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `clientId` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `feedback_reports_g`
--

CREATE TABLE `feedback_reports_g` (
  `reportId` int(11) NOT NULL,
  `comment` varchar(191) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `clientId` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `JourneyPlan`
--

CREATE TABLE `JourneyPlan` (
  `id` int(11) NOT NULL,
  `date` datetime(3) NOT NULL,
  `time` varchar(191) NOT NULL,
  `userId` int(11) DEFAULT NULL,
  `clientId` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `checkInTime` datetime(3) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `notes` varchar(191) DEFAULT NULL,
  `checkoutLatitude` double DEFAULT NULL,
  `checkoutLongitude` double DEFAULT NULL,
  `checkoutTime` datetime(3) DEFAULT NULL,
  `showUpdateLocation` tinyint(1) NOT NULL DEFAULT 1,
  `routeId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `journey_plans_g`
--

CREATE TABLE `journey_plans_g` (
  `id` int(11) NOT NULL,
  `date` datetime(3) NOT NULL,
  `time` varchar(191) NOT NULL,
  `userId` int(11) DEFAULT NULL,
  `clientId` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `checkInTime` datetime(3) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `notes` varchar(191) DEFAULT NULL,
  `checkoutLatitude` double DEFAULT NULL,
  `checkoutLongitude` double DEFAULT NULL,
  `checkoutTime` datetime(3) DEFAULT NULL,
  `showUpdateLocation` tinyint(1) NOT NULL DEFAULT 1,
  `routeId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `leaves`
--

CREATE TABLE `leaves` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `leaveType` varchar(191) NOT NULL,
  `startDate` datetime(3) NOT NULL,
  `endDate` datetime(3) NOT NULL,
  `reason` varchar(191) NOT NULL,
  `attachment` varchar(191) DEFAULT NULL,
  `status` varchar(191) NOT NULL DEFAULT 'PENDING',
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `leaves_g`
--

CREATE TABLE `leaves_g` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `leaveType` varchar(191) NOT NULL,
  `startDate` datetime(3) NOT NULL,
  `endDate` datetime(3) NOT NULL,
  `reason` varchar(191) NOT NULL,
  `attachment` varchar(191) DEFAULT NULL,
  `status` varchar(191) NOT NULL DEFAULT 'PENDING',
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `LoginHistory`
--

CREATE TABLE `LoginHistory` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `loginAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `logoutAt` datetime(3) DEFAULT NULL,
  `isLate` tinyint(1) DEFAULT 0,
  `isEarly` tinyint(1) DEFAULT 0,
  `timezone` varchar(191) DEFAULT 'UTC',
  `shiftStart` datetime(3) DEFAULT NULL,
  `shiftEnd` datetime(3) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `status` varchar(191) DEFAULT 'ACTIVE',
  `sessionEnd` varchar(191) DEFAULT NULL,
  `sessionStart` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `login_history_g`
--

CREATE TABLE `login_history_g` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `loginAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `logoutAt` datetime(3) DEFAULT NULL,
  `isLate` tinyint(1) DEFAULT 0,
  `isEarly` tinyint(1) DEFAULT 0,
  `timezone` varchar(191) DEFAULT 'UTC',
  `shiftStart` datetime(3) DEFAULT NULL,
  `shiftEnd` datetime(3) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `status` varchar(191) DEFAULT 'ACTIVE',
  `sessionEnd` varchar(191) DEFAULT NULL,
  `sessionStart` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `manager`
--

CREATE TABLE `manager` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `phone_number` varchar(20) NOT NULL,
  `department` int(11) NOT NULL,
  `region` int(11) NOT NULL,
  `country` int(11) NOT NULL,
  `status` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ManagerCheckin`
--

CREATE TABLE `ManagerCheckin` (
  `id` int(11) NOT NULL,
  `managerId` int(11) NOT NULL,
  `clientId` int(11) NOT NULL,
  `date` datetime(3) NOT NULL,
  `checkInAt` datetime(3) DEFAULT NULL,
  `checkOutAt` datetime(3) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `notes` varchar(191) DEFAULT NULL,
  `checkoutLatitude` double DEFAULT NULL,
  `checkoutLongitude` double DEFAULT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `status` varchar(191) DEFAULT NULL,
  `timezone` varchar(191) DEFAULT NULL,
  `visitDuration` int(11) DEFAULT NULL,
  `visitNumber` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `managers`
--

CREATE TABLE `managers` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `department` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `managers_g`
--

CREATE TABLE `managers_g` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `department` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `manager_checkins_g`
--

CREATE TABLE `manager_checkins_g` (
  `id` int(11) NOT NULL,
  `managerId` int(11) NOT NULL,
  `clientId` int(11) NOT NULL,
  `date` datetime(3) NOT NULL,
  `checkInAt` datetime(3) DEFAULT NULL,
  `checkOutAt` datetime(3) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `notes` varchar(191) DEFAULT NULL,
  `checkoutLatitude` double DEFAULT NULL,
  `checkoutLongitude` double DEFAULT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `status` varchar(191) DEFAULT NULL,
  `timezone` varchar(191) DEFAULT NULL,
  `visitDuration` int(11) DEFAULT NULL,
  `visitNumber` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `manager_outlet_accounts`
--

CREATE TABLE `manager_outlet_accounts` (
  `id` int(11) NOT NULL,
  `outlet_account_id` int(11) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `image` varchar(255) NOT NULL,
  `status` int(11) NOT NULL,
  `client_id` int(11) NOT NULL,
  `phone` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `address` varchar(100) NOT NULL,
  `type` int(11) NOT NULL,
  `country` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `MyAccounts`
--

CREATE TABLE `MyAccounts` (
  `id` int(11) NOT NULL,
  `account_name` varchar(100) NOT NULL,
  `account_number` varchar(20) NOT NULL,
  `account_type` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

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

-- --------------------------------------------------------

--
-- Table structure for table `my_orders_g`
--

CREATE TABLE `my_orders_g` (
  `id` int(11) NOT NULL,
  `totalAmount` double NOT NULL,
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
  `updatedAt` datetime(3) NOT NULL,
  `approved_by` varchar(200) NOT NULL,
  `approved_by_name` varchar(200) NOT NULL,
  `storeId` int(11) DEFAULT NULL,
  `retail_manager` int(11) NOT NULL,
  `key_channel_manager` int(11) NOT NULL,
  `distribution_manager` int(11) NOT NULL,
  `imageUrl` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Table structure for table `notice_boards_g`
--

CREATE TABLE `notice_boards_g` (
  `id` int(11) NOT NULL,
  `title` varchar(191) NOT NULL,
  `content` varchar(191) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Table structure for table `order_items_g`
--

CREATE TABLE `order_items_g` (
  `id` int(11) NOT NULL,
  `orderId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `priceOptionId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `outlet_accounts`
--

CREATE TABLE `outlet_accounts` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `status` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `outlet_categories`
--

CREATE TABLE `outlet_categories` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Pay`
--

CREATE TABLE `Pay` (
  `id` int(11) NOT NULL,
  `expense_id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `amount` decimal(11,2) NOT NULL,
  `reference` text NOT NULL,
  `payment_date` varchar(100) NOT NULL,
  `posted_by` int(11) NOT NULL,
  `notes` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `po_id` int(11) NOT NULL,
  `vendor_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) NOT NULL,
  `reference` varchar(100) DEFAULT NULL,
  `payment_date` date NOT NULL,
  `notes` text DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Payments`
--

CREATE TABLE `Payments` (
  `id` int(11) NOT NULL,
  `amount` decimal(11,2) NOT NULL,
  `payment_date` varchar(100) NOT NULL,
  `method` varchar(100) NOT NULL,
  `notes` text NOT NULL,
  `admin_id` int(11) NOT NULL,
  `status` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `PriceOption`
--

CREATE TABLE `PriceOption` (
  `id` int(11) NOT NULL,
  `option` varchar(191) NOT NULL,
  `value` int(11) NOT NULL,
  `categoryId` int(11) NOT NULL,
  `value_ngn` decimal(11,2) DEFAULT NULL,
  `value_tzs` decimal(11,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `price_options_g`
--

CREATE TABLE `price_options_g` (
  `id` int(11) NOT NULL,
  `option` varchar(191) NOT NULL,
  `value` int(11) NOT NULL,
  `categoryId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Table structure for table `ProductDetails`
--

CREATE TABLE `ProductDetails` (
  `id` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `date` varchar(100) NOT NULL DEFAULT 'current_timestamp(3)',
  `reference` varchar(191) NOT NULL,
  `quantityIn` int(11) NOT NULL,
  `quantityOut` int(11) NOT NULL,
  `newBalance` int(11) NOT NULL,
  `storeId` int(11) NOT NULL,
  `staff` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL,
  `update_date` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ProductReport`
--

CREATE TABLE `ProductReport` (
  `reportId` int(11) NOT NULL,
  `productName` varchar(191) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `comment` varchar(191) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `clientId` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `productId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ProductReturn`
--

CREATE TABLE `ProductReturn` (
  `id` int(11) NOT NULL,
  `reportId` int(11) NOT NULL,
  `productName` varchar(191) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `reason` varchar(191) DEFAULT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ProductReturnItem`
--

CREATE TABLE `ProductReturnItem` (
  `id` int(11) NOT NULL,
  `productReturnId` int(11) NOT NULL,
  `productName` varchar(191) NOT NULL,
  `quantity` int(11) NOT NULL,
  `reason` varchar(191) NOT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Table structure for table `products_g`
--

CREATE TABLE `products_g` (
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
  `image` varchar(191) DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products_samples_g`
--

CREATE TABLE `products_samples_g` (
  `id` int(11) NOT NULL,
  `reportId` int(11) NOT NULL,
  `productName` varchar(191) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `reason` varchar(191) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products_sample_items_g`
--

CREATE TABLE `products_sample_items_g` (
  `id` int(11) NOT NULL,
  `productsSampleId` int(11) NOT NULL,
  `productName` varchar(191) NOT NULL,
  `quantity` int(11) NOT NULL,
  `reason` varchar(191) NOT NULL,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_details_g`
--

CREATE TABLE `product_details_g` (
  `id` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `date` varchar(100) NOT NULL DEFAULT 'current_timestamp(3)',
  `reference` varchar(191) NOT NULL,
  `quantityIn` int(11) NOT NULL,
  `quantityOut` int(11) NOT NULL,
  `newBalance` int(11) NOT NULL,
  `storeId` int(11) NOT NULL,
  `staff` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL,
  `update_date` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_reports_g`
--

CREATE TABLE `product_reports_g` (
  `reportId` int(11) NOT NULL,
  `productName` varchar(191) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `comment` varchar(191) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `clientId` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `productId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_returns_g`
--

CREATE TABLE `product_returns_g` (
  `id` int(11) NOT NULL,
  `reportId` int(11) NOT NULL,
  `productName` varchar(191) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `reason` varchar(191) DEFAULT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_return_items_g`
--

CREATE TABLE `product_return_items_g` (
  `id` int(11) NOT NULL,
  `productReturnId` int(11) NOT NULL,
  `productName` varchar(191) NOT NULL,
  `quantity` int(11) NOT NULL,
  `reason` varchar(191) NOT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_transactions`
--

CREATE TABLE `product_transactions` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `transaction_date` datetime NOT NULL,
  `quantity_in` int(11) NOT NULL,
  `quantity_out` int(11) DEFAULT 0,
  `reference` varchar(50) NOT NULL,
  `reference_id` int(11) NOT NULL,
  `balance` int(11) NOT NULL,
  `notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Purchase`
--

CREATE TABLE `Purchase` (
  `id` int(11) NOT NULL,
  `storeId` int(11) NOT NULL,
  `date` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `supplierId` int(11) NOT NULL,
  `totalAmount` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `PurchaseHistory`
--

CREATE TABLE `PurchaseHistory` (
  `id` int(11) NOT NULL,
  `storeId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `previousQuantity` int(11) NOT NULL,
  `purchaseQuantity` int(11) NOT NULL,
  `newBalance` int(11) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `PurchaseItem`
--

CREATE TABLE `PurchaseItem` (
  `id` int(11) NOT NULL,
  `purchaseId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `PurchaseOrder`
--

CREATE TABLE `PurchaseOrder` (
  `id` int(11) NOT NULL,
  `payment_id` int(11) NOT NULL,
  `vendor_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `order_date` datetime NOT NULL,
  `admin_id` int(11) NOT NULL,
  `notes` text NOT NULL,
  `total` decimal(11,2) NOT NULL,
  `paid` decimal(11,2) NOT NULL,
  `status` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `PurchaseOrderItems`
--

CREATE TABLE `PurchaseOrderItems` (
  `id` int(11) NOT NULL,
  `po_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_cost` decimal(11,2) NOT NULL,
  `received_quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchases`
--

CREATE TABLE `purchases` (
  `id` int(11) NOT NULL,
  `supplier` int(11) NOT NULL,
  `comment` varchar(250) NOT NULL,
  `store` varchar(11) NOT NULL,
  `amount` decimal(11,2) NOT NULL,
  `paid` decimal(11,2) NOT NULL,
  `remain` decimal(11,2) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `month` varchar(200) NOT NULL,
  `year` varchar(200) NOT NULL,
  `purchase_date` varchar(100) NOT NULL,
  `my_date` varchar(20) NOT NULL,
  `staff` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchases_g`
--

CREATE TABLE `purchases_g` (
  `id` int(11) NOT NULL,
  `supplier` int(11) NOT NULL,
  `comment` varchar(250) NOT NULL,
  `store` varchar(11) NOT NULL,
  `amount` decimal(11,2) NOT NULL,
  `paid` decimal(11,2) NOT NULL,
  `remain` decimal(11,2) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `month` varchar(200) NOT NULL,
  `year` varchar(200) NOT NULL,
  `purchase_date` varchar(100) NOT NULL,
  `my_date` varchar(20) NOT NULL,
  `staff` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchases_g_alt`
--

CREATE TABLE `purchases_g_alt` (
  `id` int(11) NOT NULL,
  `storeId` int(11) NOT NULL,
  `date` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `supplierId` int(11) NOT NULL,
  `totalAmount` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_history_g`
--

CREATE TABLE `purchase_history_g` (
  `id` int(11) NOT NULL,
  `storeId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `previousQuantity` int(11) NOT NULL,
  `purchaseQuantity` int(11) NOT NULL,
  `newBalance` int(11) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_items`
--

CREATE TABLE `purchase_items` (
  `id` int(11) NOT NULL,
  `tb1_id` int(11) NOT NULL,
  `piece_id` varchar(200) NOT NULL,
  `product_name` varchar(200) NOT NULL,
  `quantity` varchar(200) NOT NULL,
  `rate` decimal(11,2) NOT NULL,
  `total` decimal(11,2) NOT NULL,
  `month` varchar(100) NOT NULL,
  `year` varchar(100) NOT NULL,
  `created_date` varchar(100) NOT NULL,
  `my_date` varchar(100) NOT NULL,
  `status` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `staff` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_items_g`
--

CREATE TABLE `purchase_items_g` (
  `id` int(11) NOT NULL,
  `purchaseId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_items_g_alt`
--

CREATE TABLE `purchase_items_g_alt` (
  `id` int(11) NOT NULL,
  `tb1_id` int(11) NOT NULL,
  `piece_id` varchar(200) NOT NULL,
  `product_name` varchar(200) NOT NULL,
  `quantity` varchar(200) NOT NULL,
  `rate` decimal(11,2) NOT NULL,
  `total` decimal(11,2) NOT NULL,
  `month` varchar(100) NOT NULL,
  `year` varchar(100) NOT NULL,
  `created_date` varchar(100) NOT NULL,
  `my_date` varchar(100) NOT NULL,
  `status` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `staff` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_orders_g`
--

CREATE TABLE `purchase_orders_g` (
  `id` int(11) NOT NULL,
  `vendor_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `order_date` datetime NOT NULL,
  `admin_id` int(11) NOT NULL,
  `notes` text NOT NULL,
  `status` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_order_items_g`
--

CREATE TABLE `purchase_order_items_g` (
  `id` int(11) NOT NULL,
  `po_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_cost` decimal(11,2) NOT NULL,
  `received_quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Regions`
--

CREATE TABLE `Regions` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `countryId` int(11) NOT NULL,
  `status` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `regions_g`
--

CREATE TABLE `regions_g` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `countryId` int(11) NOT NULL,
  `status` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Report`
--

CREATE TABLE `Report` (
  `id` int(11) NOT NULL,
  `orderId` int(11) DEFAULT NULL,
  `clientId` int(11) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `userId` int(11) NOT NULL,
  `journeyPlanId` int(11) DEFAULT NULL,
  `type` enum('PRODUCT_AVAILABILITY','VISIBILITY_ACTIVITY','PRODUCT_SAMPLE','PRODUCT_RETURN','FEEDBACK') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reports_g`
--

CREATE TABLE `reports_g` (
  `id` int(11) NOT NULL,
  `orderId` int(11) DEFAULT NULL,
  `clientId` int(11) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `userId` int(11) NOT NULL,
  `journeyPlanId` int(11) DEFAULT NULL,
  `type` enum('PRODUCT_AVAILABILITY','VISIBILITY_ACTIVITY','PRODUCT_SAMPLE','PRODUCT_RETURN','FEEDBACK') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Riders`
--

CREATE TABLE `Riders` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `contact` varchar(191) NOT NULL,
  `id_number` varchar(191) NOT NULL,
  `company_id` int(11) NOT NULL,
  `company` varchar(191) NOT NULL,
  `status` int(11) DEFAULT NULL,
  `password` varchar(191) DEFAULT NULL,
  `device_id` varchar(191) DEFAULT NULL,
  `device_name` varchar(191) DEFAULT NULL,
  `device_status` varchar(191) DEFAULT NULL,
  `token` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `RidersCompany`
--

CREATE TABLE `RidersCompany` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `status` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `riders_companies_g`
--

CREATE TABLE `riders_companies_g` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `status` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `riders_g`
--

CREATE TABLE `riders_g` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `contact` varchar(191) NOT NULL,
  `id_number` varchar(191) NOT NULL,
  `company_id` int(11) NOT NULL,
  `company` varchar(191) NOT NULL,
  `status` int(11) DEFAULT NULL,
  `password` varchar(191) DEFAULT NULL,
  `device_id` varchar(191) DEFAULT NULL,
  `device_name` varchar(191) DEFAULT NULL,
  `device_status` varchar(191) DEFAULT NULL,
  `token` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Table structure for table `routes_g`
--

CREATE TABLE `routes_g` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `region` int(11) NOT NULL,
  `region_name` varchar(100) NOT NULL,
  `country_id` int(11) NOT NULL,
  `country_name` varchar(100) NOT NULL,
  `leader_id` int(11) NOT NULL,
  `leader_name` varchar(100) NOT NULL,
  `status` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `SalesRep`
--

CREATE TABLE `SalesRep` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `email` varchar(191) NOT NULL,
  `phoneNumber` varchar(191) NOT NULL,
  `password` varchar(191) NOT NULL,
  `countryId` int(11) NOT NULL,
  `country` varchar(191) NOT NULL,
  `region_id` int(11) NOT NULL,
  `region` varchar(191) NOT NULL,
  `route_id` int(11) NOT NULL,
  `route` varchar(100) NOT NULL,
  `route_id_update` int(11) NOT NULL,
  `route_name_update` varchar(100) NOT NULL,
  `visits_targets` int(3) NOT NULL,
  `new_clients` int(3) NOT NULL,
  `vapes_targets` int(11) NOT NULL,
  `pouches_targets` int(11) NOT NULL,
  `role` varchar(191) DEFAULT 'USER',
  `manager_type` int(11) NOT NULL,
  `status` int(11) DEFAULT 0,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL,
  `retail_manager` int(11) NOT NULL,
  `key_channel_manager` int(11) NOT NULL,
  `distribution_manager` int(11) NOT NULL,
  `photoUrl` varchar(191) DEFAULT '',
  `managerId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `SalesTargets`
--

CREATE TABLE `SalesTargets` (
  `id` int(11) NOT NULL,
  `sales_rep_id` int(11) NOT NULL,
  `month` int(11) NOT NULL,
  `new_retail` int(11) DEFAULT 0,
  `vapes_retail` int(11) DEFAULT 0,
  `pouches_retail` int(11) DEFAULT 0,
  `new_ka` int(11) DEFAULT 0,
  `vapes_ka` int(11) DEFAULT 0,
  `pouches_ka` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_reps_g`
--

CREATE TABLE `sales_reps_g` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `email` varchar(191) NOT NULL,
  `phoneNumber` varchar(191) NOT NULL,
  `password` varchar(191) NOT NULL,
  `countryId` int(11) NOT NULL,
  `country` varchar(191) NOT NULL,
  `region_id` int(11) NOT NULL,
  `region` varchar(191) NOT NULL,
  `route_id` int(11) NOT NULL,
  `route` varchar(100) NOT NULL,
  `route_id_update` int(11) NOT NULL,
  `route_name_update` varchar(100) NOT NULL,
  `visits_targets` int(11) NOT NULL,
  `new_clients` int(11) NOT NULL,
  `role` varchar(191) DEFAULT 'USER',
  `manager_type` int(11) NOT NULL,
  `status` int(11) DEFAULT 0,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL,
  `retail_manager` int(11) NOT NULL,
  `key_channel_manager` int(11) NOT NULL,
  `distribution_manager` int(11) NOT NULL,
  `photoUrl` varchar(191) DEFAULT '',
  `pouches_targets` int(11) NOT NULL,
  `vapes_targets` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_take`
--

CREATE TABLE `stock_take` (
  `id` int(11) NOT NULL,
  `store_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `expected_quantity` int(11) NOT NULL,
  `counted_quantity` int(11) NOT NULL,
  `difference` int(11) NOT NULL,
  `stock_take_date` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_take_g`
--

CREATE TABLE `stock_take_g` (
  `id` int(11) NOT NULL,
  `store_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `expected_quantity` int(11) NOT NULL,
  `counted_quantity` int(11) NOT NULL,
  `difference` int(11) NOT NULL,
  `stock_take_date` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_transfer`
--

CREATE TABLE `stock_transfer` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `from_store` int(11) NOT NULL,
  `to_store` int(11) NOT NULL,
  `staff` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL,
  `transfer_date` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_transfer_g`
--

CREATE TABLE `stock_transfer_g` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `from_store` int(11) NOT NULL,
  `to_store` int(11) NOT NULL,
  `staff` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL,
  `transfer_date` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `StoreQuantity`
--

CREATE TABLE `StoreQuantity` (
  `id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `storeId` int(11) NOT NULL,
  `productId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Stores`
--

CREATE TABLE `Stores` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `regionId` int(11) DEFAULT NULL,
  `client_type` int(11) DEFAULT NULL,
  `countryId` int(11) NOT NULL,
  `region_id` int(11) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stores_g`
--

CREATE TABLE `stores_g` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `regionId` int(11) DEFAULT NULL,
  `client_type` int(11) DEFAULT NULL,
  `countryId` int(11) NOT NULL,
  `region_id` int(11) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `store_quantities_g`
--

CREATE TABLE `store_quantities_g` (
  `id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `storeId` int(11) NOT NULL,
  `productId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `SupplierHistory`
--

CREATE TABLE `SupplierHistory` (
  `id` int(11) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `ref_id` int(11) NOT NULL,
  `reference` varchar(100) NOT NULL,
  `date` varchar(50) NOT NULL,
  `amount_in` decimal(11,2) NOT NULL,
  `amount_out` decimal(11,2) NOT NULL,
  `balance` decimal(11,2) NOT NULL,
  `staff` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL,
  `updated_date` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Suppliers`
--

CREATE TABLE `Suppliers` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `accountBalance` decimal(11,2) NOT NULL DEFAULT 0.00,
  `contact` varchar(191) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `suppliers_g`
--

CREATE TABLE `suppliers_g` (
  `id` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `accountBalance` double NOT NULL DEFAULT 0,
  `contact` varchar(191) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `supplier_history_g`
--

CREATE TABLE `supplier_history_g` (
  `id` int(11) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `ref_id` int(11) NOT NULL,
  `reference` varchar(100) NOT NULL,
  `date` varchar(50) NOT NULL,
  `amount_in` decimal(11,2) NOT NULL,
  `amount_out` decimal(11,2) NOT NULL,
  `balance` decimal(11,2) NOT NULL,
  `staff` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL,
  `updated_date` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Target`
--

CREATE TABLE `Target` (
  `id` int(11) NOT NULL,
  `salesRepId` int(11) NOT NULL,
  `isCurrent` tinyint(1) NOT NULL DEFAULT 0,
  `targetValue` int(11) NOT NULL,
  `achievedValue` int(11) NOT NULL DEFAULT 0,
  `achieved` tinyint(1) NOT NULL DEFAULT 0,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `targets_g`
--

CREATE TABLE `targets_g` (
  `id` int(11) NOT NULL,
  `sales_rep` int(11) NOT NULL,
  `new_retail` tinyint(3) NOT NULL DEFAULT 0,
  `vapes_retail` int(4) NOT NULL,
  `pouches_retail` int(4) NOT NULL DEFAULT 0,
  `new_ka` tinyint(4) NOT NULL DEFAULT 0,
  `vapes_ka` int(3) DEFAULT NULL,
  `pouches_ka` int(3) NOT NULL,
  `date` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tasks`
--

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `completedAt` datetime(3) DEFAULT NULL,
  `isCompleted` tinyint(1) NOT NULL DEFAULT 0,
  `priority` varchar(191) NOT NULL DEFAULT 'medium',
  `status` varchar(191) NOT NULL DEFAULT 'pending',
  `salesRepId` int(11) NOT NULL,
  `assignedById` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tasks_g`
--

CREATE TABLE `tasks_g` (
  `id` int(11) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `completedAt` datetime(3) DEFAULT NULL,
  `isCompleted` tinyint(1) NOT NULL DEFAULT 0,
  `priority` varchar(191) NOT NULL DEFAULT 'medium',
  `status` varchar(191) NOT NULL DEFAULT 'pending',
  `salesRepId` int(11) NOT NULL,
  `assignedById` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Token`
--

CREATE TABLE `Token` (
  `id` int(11) NOT NULL,
  `token` varchar(255) NOT NULL,
  `salesRepId` int(11) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `expiresAt` datetime(3) NOT NULL,
  `blacklisted` tinyint(1) NOT NULL DEFAULT 0,
  `lastUsedAt` datetime(3) DEFAULT NULL,
  `tokenType` varchar(10) NOT NULL DEFAULT 'access'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tokens_g`
--

CREATE TABLE `tokens_g` (
  `id` int(11) NOT NULL,
  `token` varchar(191) NOT NULL,
  `salesRepId` int(11) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `expiresAt` datetime(3) NOT NULL,
  `blacklisted` tinyint(1) NOT NULL DEFAULT 0,
  `lastUsedAt` datetime(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TransferHistory`
--

CREATE TABLE `TransferHistory` (
  `id` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `fromStoreId` int(11) NOT NULL,
  `toStoreId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `transferredAt` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transfer_history_g`
--

CREATE TABLE `transfer_history_g` (
  `id` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `fromStoreId` int(11) NOT NULL,
  `toStoreId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `transferredAt` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Table structure for table `uplift_sales_g`
--

CREATE TABLE `uplift_sales_g` (
  `id` int(11) NOT NULL,
  `clientId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `status` varchar(191) NOT NULL DEFAULT 'pending',
  `totalAmount` double NOT NULL DEFAULT 0,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `uplift_sale_items_g`
--

CREATE TABLE `uplift_sale_items_g` (
  `id` int(11) NOT NULL,
  `upliftSaleId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unitPrice` double NOT NULL,
  `total` double NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `User`
--

CREATE TABLE `User` (
  `id` int(11) NOT NULL,
  `username` varchar(191) NOT NULL,
  `password` varchar(191) NOT NULL,
  `role` varchar(191) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `department` int(4) NOT NULL,
  `password` varchar(100) NOT NULL,
  `account_code` varchar(32) NOT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `facebook_id` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(32) NOT NULL,
  `gender` varchar(32) NOT NULL,
  `country` varchar(99) NOT NULL,
  `image` varchar(999) NOT NULL,
  `created` datetime DEFAULT NULL,
  `modified` datetime DEFAULT NULL,
  `status` tinyint(1) DEFAULT 1,
  `profile_photo` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users_g`
--

CREATE TABLE `users_g` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `department` int(11) NOT NULL,
  `password` varchar(100) NOT NULL,
  `account_code` varchar(32) NOT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `facebook_id` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(32) NOT NULL,
  `gender` varchar(32) NOT NULL,
  `country` varchar(99) NOT NULL,
  `image` varchar(999) NOT NULL,
  `created` datetime DEFAULT NULL,
  `modified` datetime DEFAULT NULL,
  `status` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `VisibilityReport`
--

CREATE TABLE `VisibilityReport` (
  `reportId` int(11) NOT NULL,
  `comment` varchar(191) DEFAULT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `clientId` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `visibility_reports_g`
--

CREATE TABLE `visibility_reports_g` (
  `reportId` int(11) NOT NULL,
  `comment` varchar(191) DEFAULT NULL,
  `imageUrl` varchar(191) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `clientId` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `_MyOrderToReport`
--

CREATE TABLE `_MyOrderToReport` (
  `A` int(11) NOT NULL,
  `B` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `_MyOrderToReport_g`
--

CREATE TABLE `_MyOrderToReport_g` (
  `A` int(11) NOT NULL,
  `B` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `_prisma_migrations`
--

CREATE TABLE `_prisma_migrations` (
  `id` varchar(36) NOT NULL,
  `checksum` varchar(64) NOT NULL,
  `finished_at` datetime(3) DEFAULT NULL,
  `migration_name` varchar(255) NOT NULL,
  `logs` text DEFAULT NULL,
  `rolled_back_at` datetime(3) DEFAULT NULL,
  `started_at` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `applied_steps_count` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `accounts_g`
--
ALTER TABLE `accounts_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `AccountTypes`
--
ALTER TABLE `AccountTypes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `account_category`
--
ALTER TABLE `account_category`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `account_update`
--
ALTER TABLE `account_update`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `account_update_g`
--
ALTER TABLE `account_update_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Category`
--
ALTER TABLE `Category`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `clientHistory`
--
ALTER TABLE `clientHistory`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ClientPayment`
--
ALTER TABLE `ClientPayment`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ClientPayment_clientId_fkey` (`clientId`),
  ADD KEY `ClientPayment_userId_fkey` (`userId`);

--
-- Indexes for table `Clients`
--
ALTER TABLE `Clients`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Clients_countryId_fkey` (`countryId`),
  ADD KEY `Clients_countryId_status_route_id_idx` (`countryId`,`status`,`route_id`);

--
-- Indexes for table `clients_g`
--
ALTER TABLE `clients_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Clients_g_countryId_fkey` (`countryId`),
  ADD KEY `clients_g_countryId_status_route_id_idx` (`countryId`,`status`,`route_id`);

--
-- Indexes for table `client_history_g`
--
ALTER TABLE `client_history_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `client_payments_g`
--
ALTER TABLE `client_payments_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ClientPayment_g_clientId_fkey` (`clientId`),
  ADD KEY `ClientPayment_g_userId_fkey` (`userId`);

--
-- Indexes for table `company_assets`
--
ALTER TABLE `company_assets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `contracts`
--
ALTER TABLE `contracts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contracts_g`
--
ALTER TABLE `contracts_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `countries_g`
--
ALTER TABLE `countries_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Country`
--
ALTER TABLE `Country`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `departments_g`
--
ALTER TABLE `departments_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `depreciation_entries`
--
ALTER TABLE `depreciation_entries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `asset_id` (`asset_id`);

--
-- Indexes for table `documents`
--
ALTER TABLE `documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `uploaded_by` (`uploaded_by`);

--
-- Indexes for table `doc_categories`
--
ALTER TABLE `doc_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Expenses`
--
ALTER TABLE `Expenses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `expense_type_id` (`expense_type_id`),
  ADD KEY `posted_by` (`posted_by`);

--
-- Indexes for table `FeedbackReport`
--
ALTER TABLE `FeedbackReport`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `FeedbackReport_reportId_key` (`reportId`),
  ADD KEY `FeedbackReport_userId_idx` (`userId`),
  ADD KEY `FeedbackReport_clientId_idx` (`clientId`),
  ADD KEY `FeedbackReport_reportId_idx` (`reportId`);

--
-- Indexes for table `feedback_reports_g`
--
ALTER TABLE `feedback_reports_g`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `feedback_reports_g_reportId_key` (`reportId`),
  ADD KEY `feedback_reports_g_userId_idx` (`userId`),
  ADD KEY `feedback_reports_g_clientId_idx` (`clientId`),
  ADD KEY `feedback_reports_g_reportId_idx` (`reportId`);

--
-- Indexes for table `JourneyPlan`
--
ALTER TABLE `JourneyPlan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `JourneyPlan_clientId_idx` (`clientId`),
  ADD KEY `JourneyPlan_userId_idx` (`userId`),
  ADD KEY `JourneyPlan_routeId_fkey` (`routeId`);

--
-- Indexes for table `journey_plans_g`
--
ALTER TABLE `journey_plans_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `journey_plans_g_clientId_idx` (`clientId`),
  ADD KEY `journey_plans_g_userId_idx` (`userId`),
  ADD KEY `JourneyPlan_g_routeId_fkey` (`routeId`);

--
-- Indexes for table `leaves`
--
ALTER TABLE `leaves`
  ADD PRIMARY KEY (`id`),
  ADD KEY `leaves_userId_fkey` (`userId`);

--
-- Indexes for table `leaves_g`
--
ALTER TABLE `leaves_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `leaves_g_userId_fkey` (`userId`);

--
-- Indexes for table `LoginHistory`
--
ALTER TABLE `LoginHistory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `LoginHistory_userId_idx` (`userId`),
  ADD KEY `LoginHistory_loginAt_idx` (`loginAt`),
  ADD KEY `LoginHistory_logoutAt_idx` (`logoutAt`);

--
-- Indexes for table `login_history_g`
--
ALTER TABLE `login_history_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `login_history_g_userId_idx` (`userId`),
  ADD KEY `login_history_g_loginAt_idx` (`loginAt`),
  ADD KEY `login_history_g_logoutAt_idx` (`logoutAt`);

--
-- Indexes for table `manager`
--
ALTER TABLE `manager`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ManagerCheckin`
--
ALTER TABLE `ManagerCheckin`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ManagerCheckin_managerId_idx` (`managerId`),
  ADD KEY `ManagerCheckin_clientId_idx` (`clientId`);

--
-- Indexes for table `managers`
--
ALTER TABLE `managers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `managers_g`
--
ALTER TABLE `managers_g`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `managers_g_userId_key` (`userId`);

--
-- Indexes for table `manager_checkins_g`
--
ALTER TABLE `manager_checkins_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `manager_checkins_g_managerId_idx` (`managerId`),
  ADD KEY `manager_checkins_g_clientId_idx` (`clientId`);

--
-- Indexes for table `manager_outlet_accounts`
--
ALTER TABLE `manager_outlet_accounts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `manager_outlet_accounts_client_id_fkey` (`client_id`),
  ADD KEY `manager_outlet_accounts_outlet_account_id_fkey` (`outlet_account_id`);

--
-- Indexes for table `MyAccounts`
--
ALTER TABLE `MyAccounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `MyOrder`
--
ALTER TABLE `MyOrder`
  ADD PRIMARY KEY (`id`),
  ADD KEY `MyOrder_userId_idx` (`userId`),
  ADD KEY `MyOrder_clientId_idx` (`clientId`);

--
-- Indexes for table `my_orders_g`
--
ALTER TABLE `my_orders_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `my_orders_g_userId_idx` (`userId`),
  ADD KEY `my_orders_g_clientId_idx` (`clientId`);

--
-- Indexes for table `NoticeBoard`
--
ALTER TABLE `NoticeBoard`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notice_boards_g`
--
ALTER TABLE `notice_boards_g`
  ADD PRIMARY KEY (`id`);

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
-- Indexes for table `order_items_g`
--
ALTER TABLE `order_items_g`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `order_items_g_orderId_productId_priceOptionId_key` (`orderId`,`productId`,`priceOptionId`),
  ADD KEY `order_items_g_orderId_idx` (`orderId`),
  ADD KEY `order_items_g_priceOptionId_idx` (`priceOptionId`),
  ADD KEY `OrderItem_g_productId_fkey` (`productId`);

--
-- Indexes for table `outlet_accounts`
--
ALTER TABLE `outlet_accounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `outlet_categories`
--
ALTER TABLE `outlet_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Pay`
--
ALTER TABLE `Pay`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `po_id` (`po_id`);

--
-- Indexes for table `Payments`
--
ALTER TABLE `Payments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `PriceOption`
--
ALTER TABLE `PriceOption`
  ADD PRIMARY KEY (`id`),
  ADD KEY `PriceOption_categoryId_fkey` (`categoryId`);

--
-- Indexes for table `price_options_g`
--
ALTER TABLE `price_options_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `PriceOption_g_categoryId_fkey` (`categoryId`);

--
-- Indexes for table `Product`
--
ALTER TABLE `Product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Product_clientId_fkey` (`clientId`);

--
-- Indexes for table `ProductDetails`
--
ALTER TABLE `ProductDetails`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ProductDetails_productId_fkey` (`productId`),
  ADD KEY `ProductDetails_storeId_fkey` (`storeId`);

--
-- Indexes for table `ProductReport`
--
ALTER TABLE `ProductReport`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ProductReport_userId_idx` (`userId`),
  ADD KEY `ProductReport_clientId_idx` (`clientId`),
  ADD KEY `ProductReport_reportId_idx` (`reportId`);

--
-- Indexes for table `ProductReturn`
--
ALTER TABLE `ProductReturn`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ProductReturn_reportId_key` (`reportId`),
  ADD KEY `ProductReturn_userId_idx` (`userId`),
  ADD KEY `ProductReturn_clientId_idx` (`clientId`);

--
-- Indexes for table `ProductReturnItem`
--
ALTER TABLE `ProductReturnItem`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ProductReturnItem_userId_idx` (`userId`),
  ADD KEY `ProductReturnItem_clientId_idx` (`clientId`),
  ADD KEY `ProductReturnItem_productReturnId_idx` (`productReturnId`);

--
-- Indexes for table `ProductsSample`
--
ALTER TABLE `ProductsSample`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ProductsSample_reportId_key` (`reportId`),
  ADD KEY `ProductsSample_userId_idx` (`userId`),
  ADD KEY `ProductsSample_clientId_idx` (`clientId`);

--
-- Indexes for table `ProductsSampleItem`
--
ALTER TABLE `ProductsSampleItem`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ProductsSampleItem_userId_idx` (`userId`),
  ADD KEY `ProductsSampleItem_clientId_idx` (`clientId`),
  ADD KEY `ProductsSampleItem_productsSampleId_idx` (`productsSampleId`);

--
-- Indexes for table `products_g`
--
ALTER TABLE `products_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Product_g_clientId_fkey` (`clientId`);

--
-- Indexes for table `products_samples_g`
--
ALTER TABLE `products_samples_g`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `products_samples_g_reportId_key` (`reportId`),
  ADD KEY `products_samples_g_userId_idx` (`userId`),
  ADD KEY `products_samples_g_clientId_idx` (`clientId`);

--
-- Indexes for table `products_sample_items_g`
--
ALTER TABLE `products_sample_items_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `products_sample_items_g_productsSampleId_idx` (`productsSampleId`),
  ADD KEY `products_sample_items_g_userId_idx` (`userId`),
  ADD KEY `products_sample_items_g_clientId_idx` (`clientId`);

--
-- Indexes for table `product_details_g`
--
ALTER TABLE `product_details_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ProductDetails_g_productId_fkey` (`productId`),
  ADD KEY `ProductDetails_g_storeId_fkey` (`storeId`);

--
-- Indexes for table `product_reports_g`
--
ALTER TABLE `product_reports_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_reports_g_userId_idx` (`userId`),
  ADD KEY `product_reports_g_clientId_idx` (`clientId`),
  ADD KEY `product_reports_g_reportId_idx` (`reportId`);

--
-- Indexes for table `product_returns_g`
--
ALTER TABLE `product_returns_g`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `product_returns_g_reportId_key` (`reportId`),
  ADD KEY `product_returns_g_userId_idx` (`userId`),
  ADD KEY `product_returns_g_clientId_idx` (`clientId`);

--
-- Indexes for table `product_return_items_g`
--
ALTER TABLE `product_return_items_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_return_items_g_productReturnId_idx` (`productReturnId`),
  ADD KEY `product_return_items_g_userId_idx` (`userId`),
  ADD KEY `product_return_items_g_clientId_idx` (`clientId`);

--
-- Indexes for table `product_transactions`
--
ALTER TABLE `product_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `Purchase`
--
ALTER TABLE `Purchase`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Purchase_storeId_fkey` (`storeId`),
  ADD KEY `Purchase_supplierId_fkey` (`supplierId`);

--
-- Indexes for table `PurchaseHistory`
--
ALTER TABLE `PurchaseHistory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `PurchaseHistory_productId_fkey` (`productId`),
  ADD KEY `PurchaseHistory_storeId_fkey` (`storeId`);

--
-- Indexes for table `PurchaseItem`
--
ALTER TABLE `PurchaseItem`
  ADD PRIMARY KEY (`id`),
  ADD KEY `PurchaseItem_productId_fkey` (`productId`),
  ADD KEY `PurchaseItem_purchaseId_fkey` (`purchaseId`);

--
-- Indexes for table `PurchaseOrder`
--
ALTER TABLE `PurchaseOrder`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `PurchaseOrderItems`
--
ALTER TABLE `PurchaseOrderItems`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `purchases`
--
ALTER TABLE `purchases`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `purchases_g`
--
ALTER TABLE `purchases_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `purchases_g_alt`
--
ALTER TABLE `purchases_g_alt`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Purchase_g_storeId_fkey` (`storeId`),
  ADD KEY `Purchase_g_supplierId_fkey` (`supplierId`);

--
-- Indexes for table `purchase_history_g`
--
ALTER TABLE `purchase_history_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `PurchaseHistory_g_productId_fkey` (`productId`),
  ADD KEY `PurchaseHistory_g_storeId_fkey` (`storeId`);

--
-- Indexes for table `purchase_items`
--
ALTER TABLE `purchase_items`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `purchase_items_g`
--
ALTER TABLE `purchase_items_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `PurchaseItem_g_productId_fkey` (`productId`),
  ADD KEY `PurchaseItem_g_purchaseId_fkey` (`purchaseId`);

--
-- Indexes for table `purchase_items_g_alt`
--
ALTER TABLE `purchase_items_g_alt`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `purchase_orders_g`
--
ALTER TABLE `purchase_orders_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `purchase_order_items_g`
--
ALTER TABLE `purchase_order_items_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Regions`
--
ALTER TABLE `Regions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `Regions_name_countryId_key` (`name`,`countryId`),
  ADD KEY `Regions_countryId_fkey` (`countryId`);

--
-- Indexes for table `regions_g`
--
ALTER TABLE `regions_g`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `regions_g_name_countryId_key` (`name`,`countryId`),
  ADD KEY `Regions_g_countryId_fkey` (`countryId`);

--
-- Indexes for table `Report`
--
ALTER TABLE `Report`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Report_userId_idx` (`userId`),
  ADD KEY `Report_orderId_idx` (`orderId`),
  ADD KEY `Report_clientId_idx` (`clientId`),
  ADD KEY `Report_journeyPlanId_idx` (`journeyPlanId`);

--
-- Indexes for table `reports_g`
--
ALTER TABLE `reports_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reports_g_userId_idx` (`userId`),
  ADD KEY `reports_g_orderId_idx` (`orderId`),
  ADD KEY `reports_g_clientId_idx` (`clientId`),
  ADD KEY `reports_g_journeyPlanId_idx` (`journeyPlanId`);

--
-- Indexes for table `Riders`
--
ALTER TABLE `Riders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `RidersCompany`
--
ALTER TABLE `RidersCompany`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `riders_companies_g`
--
ALTER TABLE `riders_companies_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `riders_g`
--
ALTER TABLE `riders_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `routes`
--
ALTER TABLE `routes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `routes_g`
--
ALTER TABLE `routes_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `SalesRep`
--
ALTER TABLE `SalesRep`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `SalesRep_email_key` (`email`),
  ADD UNIQUE KEY `SalesRep_phoneNumber_key` (`phoneNumber`),
  ADD KEY `SalesRep_countryId_fkey` (`countryId`),
  ADD KEY `idx_status_role` (`status`,`role`),
  ADD KEY `idx_location` (`countryId`,`region_id`,`route_id`),
  ADD KEY `idx_manager` (`managerId`);

--
-- Indexes for table `SalesTargets`
--
ALTER TABLE `SalesTargets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sales_rep_id` (`sales_rep_id`,`month`);

--
-- Indexes for table `sales_reps_g`
--
ALTER TABLE `sales_reps_g`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sales_reps_g_email_key` (`email`),
  ADD UNIQUE KEY `sales_reps_g_phoneNumber_key` (`phoneNumber`),
  ADD KEY `SalesRep_g_countryId_fkey` (`countryId`);

--
-- Indexes for table `stock_take`
--
ALTER TABLE `stock_take`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `stock_take_g`
--
ALTER TABLE `stock_take_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `stock_transfer`
--
ALTER TABLE `stock_transfer`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `stock_transfer_g`
--
ALTER TABLE `stock_transfer_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `StoreQuantity`
--
ALTER TABLE `StoreQuantity`
  ADD PRIMARY KEY (`id`),
  ADD KEY `StoreQuantity_productId_fkey` (`productId`),
  ADD KEY `StoreQuantity_storeId_fkey` (`storeId`);

--
-- Indexes for table `Stores`
--
ALTER TABLE `Stores`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Stores_regionId_fkey` (`regionId`);

--
-- Indexes for table `stores_g`
--
ALTER TABLE `stores_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Stores_g_regionId_fkey` (`regionId`);

--
-- Indexes for table `store_quantities_g`
--
ALTER TABLE `store_quantities_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `StoreQuantity_g_productId_fkey` (`productId`),
  ADD KEY `StoreQuantity_g_storeId_fkey` (`storeId`);

--
-- Indexes for table `SupplierHistory`
--
ALTER TABLE `SupplierHistory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `SupplierHistory_supplierId_fkey` (`supplier_id`);

--
-- Indexes for table `Suppliers`
--
ALTER TABLE `Suppliers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `suppliers_g`
--
ALTER TABLE `suppliers_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `supplier_history_g`
--
ALTER TABLE `supplier_history_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `SupplierHistory_g_supplierId_fkey` (`supplier_id`);

--
-- Indexes for table `Target`
--
ALTER TABLE `Target`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Target_salesRepId_fkey` (`salesRepId`);

--
-- Indexes for table `targets_g`
--
ALTER TABLE `targets_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Target_g_salesRepId_fkey` (`sales_rep`);

--
-- Indexes for table `tasks`
--
ALTER TABLE `tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tasks_assignedById_idx` (`assignedById`),
  ADD KEY `tasks_salesRepId_fkey` (`salesRepId`);

--
-- Indexes for table `tasks_g`
--
ALTER TABLE `tasks_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tasks_g_assignedById_idx` (`assignedById`),
  ADD KEY `tasks_g_salesRepId_fkey` (`salesRepId`);

--
-- Indexes for table `Token`
--
ALTER TABLE `Token`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Token_userId_fkey` (`salesRepId`),
  ADD KEY `idx_token_value` (`token`(64)),
  ADD KEY `idx_token_cleanup` (`expiresAt`,`blacklisted`),
  ADD KEY `idx_token_lookup` (`salesRepId`,`tokenType`,`blacklisted`,`expiresAt`);

--
-- Indexes for table `tokens_g`
--
ALTER TABLE `tokens_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Token_g_userId_fkey` (`salesRepId`),
  ADD KEY `tokens_g_blacklisted_idx` (`blacklisted`),
  ADD KEY `tokens_g_lastUsedAt_idx` (`lastUsedAt`);

--
-- Indexes for table `TransferHistory`
--
ALTER TABLE `TransferHistory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `TransferHistory_fromStoreId_fkey` (`fromStoreId`),
  ADD KEY `TransferHistory_productId_fkey` (`productId`),
  ADD KEY `TransferHistory_toStoreId_fkey` (`toStoreId`);

--
-- Indexes for table `transfer_history_g`
--
ALTER TABLE `transfer_history_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `TransferHistory_g_fromStoreId_fkey` (`fromStoreId`),
  ADD KEY `TransferHistory_g_productId_fkey` (`productId`),
  ADD KEY `TransferHistory_g_toStoreId_fkey` (`toStoreId`);

--
-- Indexes for table `UpliftSale`
--
ALTER TABLE `UpliftSale`
  ADD PRIMARY KEY (`id`),
  ADD KEY `UpliftSale_clientId_fkey` (`clientId`),
  ADD KEY `UpliftSale_userId_fkey` (`userId`);

--
-- Indexes for table `UpliftSaleItem`
--
ALTER TABLE `UpliftSaleItem`
  ADD PRIMARY KEY (`id`),
  ADD KEY `UpliftSaleItem_upliftSaleId_fkey` (`upliftSaleId`),
  ADD KEY `UpliftSaleItem_productId_fkey` (`productId`);

--
-- Indexes for table `uplift_sales_g`
--
ALTER TABLE `uplift_sales_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `UpliftSale_g_clientId_fkey` (`clientId`),
  ADD KEY `UpliftSale_g_userId_fkey` (`userId`);

--
-- Indexes for table `uplift_sale_items_g`
--
ALTER TABLE `uplift_sale_items_g`
  ADD PRIMARY KEY (`id`),
  ADD KEY `UpliftSaleItem_g_productId_fkey` (`productId`),
  ADD KEY `UpliftSaleItem_g_upliftSaleId_fkey` (`upliftSaleId`);

--
-- Indexes for table `User`
--
ALTER TABLE `User`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `User_username_key` (`username`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users_g`
--
ALTER TABLE `users_g`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `VisibilityReport`
--
ALTER TABLE `VisibilityReport`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `VisibilityReport_reportId_key` (`reportId`),
  ADD KEY `VisibilityReport_userId_idx` (`userId`),
  ADD KEY `VisibilityReport_clientId_idx` (`clientId`),
  ADD KEY `VisibilityReport_reportId_idx` (`reportId`);

--
-- Indexes for table `visibility_reports_g`
--
ALTER TABLE `visibility_reports_g`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `visibility_reports_g_reportId_key` (`reportId`),
  ADD KEY `visibility_reports_g_userId_idx` (`userId`),
  ADD KEY `visibility_reports_g_clientId_idx` (`clientId`),
  ADD KEY `visibility_reports_g_reportId_idx` (`reportId`);

--
-- Indexes for table `_MyOrderToReport`
--
ALTER TABLE `_MyOrderToReport`
  ADD UNIQUE KEY `_MyOrderToReport_AB_unique` (`A`,`B`),
  ADD KEY `_MyOrderToReport_B_index` (`B`);

--
-- Indexes for table `_MyOrderToReport_g`
--
ALTER TABLE `_MyOrderToReport_g`
  ADD UNIQUE KEY `_MyOrderToReport_g_AB_unique` (`A`,`B`),
  ADD KEY `_MyOrderToReport_g_B_index` (`B`);

--
-- Indexes for table `_prisma_migrations`
--
ALTER TABLE `_prisma_migrations`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `accounts_g`
--
ALTER TABLE `accounts_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `AccountTypes`
--
ALTER TABLE `AccountTypes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `account_category`
--
ALTER TABLE `account_category`
  MODIFY `id` int(3) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `account_update`
--
ALTER TABLE `account_update`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `account_update_g`
--
ALTER TABLE `account_update_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Category`
--
ALTER TABLE `Category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `clientHistory`
--
ALTER TABLE `clientHistory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ClientPayment`
--
ALTER TABLE `ClientPayment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Clients`
--
ALTER TABLE `Clients`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `clients_g`
--
ALTER TABLE `clients_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `client_history_g`
--
ALTER TABLE `client_history_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `client_payments_g`
--
ALTER TABLE `client_payments_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `company_assets`
--
ALTER TABLE `company_assets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `contracts`
--
ALTER TABLE `contracts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `contracts_g`
--
ALTER TABLE `contracts_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `countries_g`
--
ALTER TABLE `countries_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Country`
--
ALTER TABLE `Country`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `departments_g`
--
ALTER TABLE `departments_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `depreciation_entries`
--
ALTER TABLE `depreciation_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `documents`
--
ALTER TABLE `documents`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `doc_categories`
--
ALTER TABLE `doc_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Expenses`
--
ALTER TABLE `Expenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `FeedbackReport`
--
ALTER TABLE `FeedbackReport`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `feedback_reports_g`
--
ALTER TABLE `feedback_reports_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `JourneyPlan`
--
ALTER TABLE `JourneyPlan`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `journey_plans_g`
--
ALTER TABLE `journey_plans_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `leaves`
--
ALTER TABLE `leaves`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `leaves_g`
--
ALTER TABLE `leaves_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `LoginHistory`
--
ALTER TABLE `LoginHistory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `login_history_g`
--
ALTER TABLE `login_history_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `manager`
--
ALTER TABLE `manager`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ManagerCheckin`
--
ALTER TABLE `ManagerCheckin`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `managers`
--
ALTER TABLE `managers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `managers_g`
--
ALTER TABLE `managers_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `manager_checkins_g`
--
ALTER TABLE `manager_checkins_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `manager_outlet_accounts`
--
ALTER TABLE `manager_outlet_accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `MyAccounts`
--
ALTER TABLE `MyAccounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `MyOrder`
--
ALTER TABLE `MyOrder`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `my_orders_g`
--
ALTER TABLE `my_orders_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `NoticeBoard`
--
ALTER TABLE `NoticeBoard`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notice_boards_g`
--
ALTER TABLE `notice_boards_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `OrderItem`
--
ALTER TABLE `OrderItem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `order_items_g`
--
ALTER TABLE `order_items_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `outlet_accounts`
--
ALTER TABLE `outlet_accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `outlet_categories`
--
ALTER TABLE `outlet_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Pay`
--
ALTER TABLE `Pay`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Payments`
--
ALTER TABLE `Payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `PriceOption`
--
ALTER TABLE `PriceOption`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `price_options_g`
--
ALTER TABLE `price_options_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Product`
--
ALTER TABLE `Product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ProductDetails`
--
ALTER TABLE `ProductDetails`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ProductReport`
--
ALTER TABLE `ProductReport`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ProductReturn`
--
ALTER TABLE `ProductReturn`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ProductReturnItem`
--
ALTER TABLE `ProductReturnItem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ProductsSample`
--
ALTER TABLE `ProductsSample`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ProductsSampleItem`
--
ALTER TABLE `ProductsSampleItem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products_g`
--
ALTER TABLE `products_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products_samples_g`
--
ALTER TABLE `products_samples_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products_sample_items_g`
--
ALTER TABLE `products_sample_items_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_details_g`
--
ALTER TABLE `product_details_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_reports_g`
--
ALTER TABLE `product_reports_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_returns_g`
--
ALTER TABLE `product_returns_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_return_items_g`
--
ALTER TABLE `product_return_items_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_transactions`
--
ALTER TABLE `product_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Purchase`
--
ALTER TABLE `Purchase`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `PurchaseHistory`
--
ALTER TABLE `PurchaseHistory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `PurchaseItem`
--
ALTER TABLE `PurchaseItem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `PurchaseOrder`
--
ALTER TABLE `PurchaseOrder`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `PurchaseOrderItems`
--
ALTER TABLE `PurchaseOrderItems`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchases`
--
ALTER TABLE `purchases`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchases_g`
--
ALTER TABLE `purchases_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchases_g_alt`
--
ALTER TABLE `purchases_g_alt`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_history_g`
--
ALTER TABLE `purchase_history_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_items`
--
ALTER TABLE `purchase_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_items_g`
--
ALTER TABLE `purchase_items_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_items_g_alt`
--
ALTER TABLE `purchase_items_g_alt`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_orders_g`
--
ALTER TABLE `purchase_orders_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_order_items_g`
--
ALTER TABLE `purchase_order_items_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Regions`
--
ALTER TABLE `Regions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `regions_g`
--
ALTER TABLE `regions_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Report`
--
ALTER TABLE `Report`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reports_g`
--
ALTER TABLE `reports_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Riders`
--
ALTER TABLE `Riders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `RidersCompany`
--
ALTER TABLE `RidersCompany`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `riders_companies_g`
--
ALTER TABLE `riders_companies_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `riders_g`
--
ALTER TABLE `riders_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `routes`
--
ALTER TABLE `routes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `routes_g`
--
ALTER TABLE `routes_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `SalesRep`
--
ALTER TABLE `SalesRep`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `SalesTargets`
--
ALTER TABLE `SalesTargets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sales_reps_g`
--
ALTER TABLE `sales_reps_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_take`
--
ALTER TABLE `stock_take`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_take_g`
--
ALTER TABLE `stock_take_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_transfer`
--
ALTER TABLE `stock_transfer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_transfer_g`
--
ALTER TABLE `stock_transfer_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `StoreQuantity`
--
ALTER TABLE `StoreQuantity`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Stores`
--
ALTER TABLE `Stores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stores_g`
--
ALTER TABLE `stores_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `store_quantities_g`
--
ALTER TABLE `store_quantities_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `SupplierHistory`
--
ALTER TABLE `SupplierHistory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Suppliers`
--
ALTER TABLE `Suppliers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `suppliers_g`
--
ALTER TABLE `suppliers_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `supplier_history_g`
--
ALTER TABLE `supplier_history_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Target`
--
ALTER TABLE `Target`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `targets_g`
--
ALTER TABLE `targets_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tasks_g`
--
ALTER TABLE `tasks_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Token`
--
ALTER TABLE `Token`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tokens_g`
--
ALTER TABLE `tokens_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TransferHistory`
--
ALTER TABLE `TransferHistory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transfer_history_g`
--
ALTER TABLE `transfer_history_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `UpliftSale`
--
ALTER TABLE `UpliftSale`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `UpliftSaleItem`
--
ALTER TABLE `UpliftSaleItem`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `uplift_sales_g`
--
ALTER TABLE `uplift_sales_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `uplift_sale_items_g`
--
ALTER TABLE `uplift_sale_items_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `User`
--
ALTER TABLE `User`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users_g`
--
ALTER TABLE `users_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `VisibilityReport`
--
ALTER TABLE `VisibilityReport`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `visibility_reports_g`
--
ALTER TABLE `visibility_reports_g`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `ClientPayment`
--
ALTER TABLE `ClientPayment`
  ADD CONSTRAINT `ClientPayment_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ClientPayment_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Clients`
--
ALTER TABLE `Clients`
  ADD CONSTRAINT `Clients_countryId_fkey` FOREIGN KEY (`countryId`) REFERENCES `Country` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `clients_g`
--
ALTER TABLE `clients_g`
  ADD CONSTRAINT `clients_g_countryId_fkey` FOREIGN KEY (`countryId`) REFERENCES `countries_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `client_payments_g`
--
ALTER TABLE `client_payments_g`
  ADD CONSTRAINT `client_payments_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `client_payments_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `company_assets`
--
ALTER TABLE `company_assets`
  ADD CONSTRAINT `company_assets_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `depreciation_entries`
--
ALTER TABLE `depreciation_entries`
  ADD CONSTRAINT `depreciation_entries_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `company_assets` (`id`);

--
-- Constraints for table `documents`
--
ALTER TABLE `documents`
  ADD CONSTRAINT `documents_ibfk_1` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `Expenses`
--
ALTER TABLE `Expenses`
  ADD CONSTRAINT `Expenses_ibfk_1` FOREIGN KEY (`expense_type_id`) REFERENCES `MyAccounts` (`id`),
  ADD CONSTRAINT `Expenses_ibfk_2` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `FeedbackReport`
--
ALTER TABLE `FeedbackReport`
  ADD CONSTRAINT `FeedbackReport_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `FeedbackReport_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `Report` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `FeedbackReport_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `feedback_reports_g`
--
ALTER TABLE `feedback_reports_g`
  ADD CONSTRAINT `feedback_reports_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `feedback_reports_g_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `reports_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `feedback_reports_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `JourneyPlan`
--
ALTER TABLE `JourneyPlan`
  ADD CONSTRAINT `JourneyPlan_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `JourneyPlan_routeId_fkey` FOREIGN KEY (`routeId`) REFERENCES `routes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `JourneyPlan_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `journey_plans_g`
--
ALTER TABLE `journey_plans_g`
  ADD CONSTRAINT `journey_plans_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `journey_plans_g_routeId_fkey` FOREIGN KEY (`routeId`) REFERENCES `routes_g` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `journey_plans_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `leaves`
--
ALTER TABLE `leaves`
  ADD CONSTRAINT `leaves_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `leaves_g`
--
ALTER TABLE `leaves_g`
  ADD CONSTRAINT `leaves_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `LoginHistory`
--
ALTER TABLE `LoginHistory`
  ADD CONSTRAINT `LoginHistory_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `login_history_g`
--
ALTER TABLE `login_history_g`
  ADD CONSTRAINT `login_history_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ManagerCheckin`
--
ALTER TABLE `ManagerCheckin`
  ADD CONSTRAINT `ManagerCheckin_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ManagerCheckin_managerId_fkey` FOREIGN KEY (`managerId`) REFERENCES `managers` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `managers`
--
ALTER TABLE `managers`
  ADD CONSTRAINT `managers_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `managers_g`
--
ALTER TABLE `managers_g`
  ADD CONSTRAINT `managers_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `manager_checkins_g`
--
ALTER TABLE `manager_checkins_g`
  ADD CONSTRAINT `manager_checkins_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `manager_checkins_g_managerId_fkey` FOREIGN KEY (`managerId`) REFERENCES `managers_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `manager_outlet_accounts`
--
ALTER TABLE `manager_outlet_accounts`
  ADD CONSTRAINT `manager_outlet_accounts_client_id_fkey` FOREIGN KEY (`client_id`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `manager_outlet_accounts_outlet_account_id_fkey` FOREIGN KEY (`outlet_account_id`) REFERENCES `outlet_accounts` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `MyOrder`
--
ALTER TABLE `MyOrder`
  ADD CONSTRAINT `MyOrder_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `MyOrder_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `my_orders_g`
--
ALTER TABLE `my_orders_g`
  ADD CONSTRAINT `my_orders_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `my_orders_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `OrderItem`
--
ALTER TABLE `OrderItem`
  ADD CONSTRAINT `OrderItem_orderId_fkey` FOREIGN KEY (`orderId`) REFERENCES `MyOrder` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `OrderItem_priceOptionId_fkey` FOREIGN KEY (`priceOptionId`) REFERENCES `PriceOption` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `OrderItem_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `order_items_g`
--
ALTER TABLE `order_items_g`
  ADD CONSTRAINT `order_items_g_orderId_fkey` FOREIGN KEY (`orderId`) REFERENCES `my_orders_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `order_items_g_priceOptionId_fkey` FOREIGN KEY (`priceOptionId`) REFERENCES `price_options_g` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `order_items_g_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `products_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `PriceOption`
--
ALTER TABLE `PriceOption`
  ADD CONSTRAINT `PriceOption_categoryId_fkey` FOREIGN KEY (`categoryId`) REFERENCES `Category` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `price_options_g`
--
ALTER TABLE `price_options_g`
  ADD CONSTRAINT `price_options_g_categoryId_fkey` FOREIGN KEY (`categoryId`) REFERENCES `doc_categories` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `Product`
--
ALTER TABLE `Product`
  ADD CONSTRAINT `Product_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `ProductDetails`
--
ALTER TABLE `ProductDetails`
  ADD CONSTRAINT `ProductDetails_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductDetails_storeId_fkey` FOREIGN KEY (`storeId`) REFERENCES `Stores` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `ProductReport`
--
ALTER TABLE `ProductReport`
  ADD CONSTRAINT `ProductReport_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductReport_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `Report` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductReport_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ProductReturn`
--
ALTER TABLE `ProductReturn`
  ADD CONSTRAINT `ProductReturn_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductReturn_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `Report` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductReturn_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ProductReturnItem`
--
ALTER TABLE `ProductReturnItem`
  ADD CONSTRAINT `ProductReturnItem_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductReturnItem_productReturnId_fkey` FOREIGN KEY (`productReturnId`) REFERENCES `ProductReturn` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductReturnItem_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ProductsSample`
--
ALTER TABLE `ProductsSample`
  ADD CONSTRAINT `ProductsSample_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductsSample_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `Report` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductsSample_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ProductsSampleItem`
--
ALTER TABLE `ProductsSampleItem`
  ADD CONSTRAINT `ProductsSampleItem_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductsSampleItem_productsSampleId_fkey` FOREIGN KEY (`productsSampleId`) REFERENCES `ProductsSample` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `ProductsSampleItem_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `products_g`
--
ALTER TABLE `products_g`
  ADD CONSTRAINT `products_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `products_samples_g`
--
ALTER TABLE `products_samples_g`
  ADD CONSTRAINT `products_samples_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `products_samples_g_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `reports_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `products_samples_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `products_sample_items_g`
--
ALTER TABLE `products_sample_items_g`
  ADD CONSTRAINT `products_sample_items_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `products_sample_items_g_productsSampleId_fkey` FOREIGN KEY (`productsSampleId`) REFERENCES `products_samples_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `products_sample_items_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `product_details_g`
--
ALTER TABLE `product_details_g`
  ADD CONSTRAINT `product_details_g_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `products_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_details_g_storeId_fkey` FOREIGN KEY (`storeId`) REFERENCES `stores_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `product_reports_g`
--
ALTER TABLE `product_reports_g`
  ADD CONSTRAINT `product_reports_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_reports_g_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `reports_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `product_reports_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `product_returns_g`
--
ALTER TABLE `product_returns_g`
  ADD CONSTRAINT `product_returns_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_returns_g_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `reports_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_returns_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `product_return_items_g`
--
ALTER TABLE `product_return_items_g`
  ADD CONSTRAINT `product_return_items_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_return_items_g_productReturnId_fkey` FOREIGN KEY (`productReturnId`) REFERENCES `product_returns_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_return_items_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `product_transactions`
--
ALTER TABLE `product_transactions`
  ADD CONSTRAINT `product_transactions_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `Product` (`id`);

--
-- Constraints for table `Purchase`
--
ALTER TABLE `Purchase`
  ADD CONSTRAINT `Purchase_storeId_fkey` FOREIGN KEY (`storeId`) REFERENCES `Stores` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `Purchase_supplierId_fkey` FOREIGN KEY (`supplierId`) REFERENCES `Suppliers` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `PurchaseHistory`
--
ALTER TABLE `PurchaseHistory`
  ADD CONSTRAINT `PurchaseHistory_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `PurchaseHistory_storeId_fkey` FOREIGN KEY (`storeId`) REFERENCES `Stores` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `PurchaseItem`
--
ALTER TABLE `PurchaseItem`
  ADD CONSTRAINT `PurchaseItem_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `PurchaseItem_purchaseId_fkey` FOREIGN KEY (`purchaseId`) REFERENCES `Purchase` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `purchases_g_alt`
--
ALTER TABLE `purchases_g_alt`
  ADD CONSTRAINT `purchases_g_alt_storeId_fkey` FOREIGN KEY (`storeId`) REFERENCES `stores_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `purchases_g_alt_supplierId_fkey` FOREIGN KEY (`supplierId`) REFERENCES `suppliers_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `purchase_history_g`
--
ALTER TABLE `purchase_history_g`
  ADD CONSTRAINT `purchase_history_g_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `products_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `purchase_history_g_storeId_fkey` FOREIGN KEY (`storeId`) REFERENCES `stores_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `purchase_items_g`
--
ALTER TABLE `purchase_items_g`
  ADD CONSTRAINT `purchase_items_g_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `products_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `purchase_items_g_purchaseId_fkey` FOREIGN KEY (`purchaseId`) REFERENCES `purchases_g_alt` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `Regions`
--
ALTER TABLE `Regions`
  ADD CONSTRAINT `Regions_countryId_fkey` FOREIGN KEY (`countryId`) REFERENCES `Country` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `regions_g`
--
ALTER TABLE `regions_g`
  ADD CONSTRAINT `regions_g_countryId_fkey` FOREIGN KEY (`countryId`) REFERENCES `countries_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `Report`
--
ALTER TABLE `Report`
  ADD CONSTRAINT `Report_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `Report_journeyPlanId_fkey` FOREIGN KEY (`journeyPlanId`) REFERENCES `JourneyPlan` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `Report_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `reports_g`
--
ALTER TABLE `reports_g`
  ADD CONSTRAINT `reports_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `reports_g_journeyPlanId_fkey` FOREIGN KEY (`journeyPlanId`) REFERENCES `journey_plans_g` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `reports_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `SalesRep`
--
ALTER TABLE `SalesRep`
  ADD CONSTRAINT `SalesRep_countryId_fkey` FOREIGN KEY (`countryId`) REFERENCES `Country` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `SalesTargets`
--
ALTER TABLE `SalesTargets`
  ADD CONSTRAINT `SalesTargets_ibfk_1` FOREIGN KEY (`sales_rep_id`) REFERENCES `SalesRep` (`id`);

--
-- Constraints for table `sales_reps_g`
--
ALTER TABLE `sales_reps_g`
  ADD CONSTRAINT `sales_reps_g_countryId_fkey` FOREIGN KEY (`countryId`) REFERENCES `countries_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `StoreQuantity`
--
ALTER TABLE `StoreQuantity`
  ADD CONSTRAINT `StoreQuantity_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `StoreQuantity_storeId_fkey` FOREIGN KEY (`storeId`) REFERENCES `Stores` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `Stores`
--
ALTER TABLE `Stores`
  ADD CONSTRAINT `Stores_regionId_fkey` FOREIGN KEY (`regionId`) REFERENCES `Regions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `stores_g`
--
ALTER TABLE `stores_g`
  ADD CONSTRAINT `stores_g_regionId_fkey` FOREIGN KEY (`regionId`) REFERENCES `regions_g` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `store_quantities_g`
--
ALTER TABLE `store_quantities_g`
  ADD CONSTRAINT `store_quantities_g_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `products_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `store_quantities_g_storeId_fkey` FOREIGN KEY (`storeId`) REFERENCES `stores_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `SupplierHistory`
--
ALTER TABLE `SupplierHistory`
  ADD CONSTRAINT `SupplierHistory_supplierId_fkey` FOREIGN KEY (`supplier_id`) REFERENCES `Suppliers` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `supplier_history_g`
--
ALTER TABLE `supplier_history_g`
  ADD CONSTRAINT `SupplierHistory_g_supplierId_fkey` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `Target`
--
ALTER TABLE `Target`
  ADD CONSTRAINT `Target_salesRepId_fkey` FOREIGN KEY (`salesRepId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `targets_g`
--
ALTER TABLE `targets_g`
  ADD CONSTRAINT `targets_g_salesRepId_fkey` FOREIGN KEY (`sales_rep`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `tasks`
--
ALTER TABLE `tasks`
  ADD CONSTRAINT `tasks_assignedById_fkey` FOREIGN KEY (`assignedById`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `tasks_salesRepId_fkey` FOREIGN KEY (`salesRepId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `tasks_g`
--
ALTER TABLE `tasks_g`
  ADD CONSTRAINT `tasks_g_assignedById_fkey` FOREIGN KEY (`assignedById`) REFERENCES `users_g` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `tasks_g_salesRepId_fkey` FOREIGN KEY (`salesRepId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Token`
--
ALTER TABLE `Token`
  ADD CONSTRAINT `Token_salesRepId_fkey` FOREIGN KEY (`salesRepId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `tokens_g`
--
ALTER TABLE `tokens_g`
  ADD CONSTRAINT `tokens_g_salesRepId_fkey` FOREIGN KEY (`salesRepId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `TransferHistory`
--
ALTER TABLE `TransferHistory`
  ADD CONSTRAINT `TransferHistory_fromStoreId_fkey` FOREIGN KEY (`fromStoreId`) REFERENCES `Stores` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `TransferHistory_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `TransferHistory_toStoreId_fkey` FOREIGN KEY (`toStoreId`) REFERENCES `Stores` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `transfer_history_g`
--
ALTER TABLE `transfer_history_g`
  ADD CONSTRAINT `transfer_history_g_fromStoreId_fkey` FOREIGN KEY (`fromStoreId`) REFERENCES `stores_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `transfer_history_g_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `products_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `transfer_history_g_toStoreId_fkey` FOREIGN KEY (`toStoreId`) REFERENCES `stores_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `UpliftSale`
--
ALTER TABLE `UpliftSale`
  ADD CONSTRAINT `UpliftSale_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `UpliftSale_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `UpliftSaleItem`
--
ALTER TABLE `UpliftSaleItem`
  ADD CONSTRAINT `UpliftSaleItem_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `Product` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `UpliftSaleItem_upliftSaleId_fkey` FOREIGN KEY (`upliftSaleId`) REFERENCES `UpliftSale` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `uplift_sales_g`
--
ALTER TABLE `uplift_sales_g`
  ADD CONSTRAINT `uplift_sales_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `uplift_sales_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `uplift_sale_items_g`
--
ALTER TABLE `uplift_sale_items_g`
  ADD CONSTRAINT `uplift_sale_items_g_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `products_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `uplift_sale_items_g_upliftSaleId_fkey` FOREIGN KEY (`upliftSaleId`) REFERENCES `uplift_sales_g` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `VisibilityReport`
--
ALTER TABLE `VisibilityReport`
  ADD CONSTRAINT `VisibilityReport_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `Clients` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `VisibilityReport_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `Report` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `VisibilityReport_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `SalesRep` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `visibility_reports_g`
--
ALTER TABLE `visibility_reports_g`
  ADD CONSTRAINT `visibility_reports_g_clientId_fkey` FOREIGN KEY (`clientId`) REFERENCES `clients_g` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `visibility_reports_g_reportId_fkey` FOREIGN KEY (`reportId`) REFERENCES `reports_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `visibility_reports_g_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `sales_reps_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `_MyOrderToReport`
--
ALTER TABLE `_MyOrderToReport`
  ADD CONSTRAINT `_MyOrderToReport_A_fkey` FOREIGN KEY (`A`) REFERENCES `MyOrder` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `_MyOrderToReport_B_fkey` FOREIGN KEY (`B`) REFERENCES `Report` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `_MyOrderToReport_g`
--
ALTER TABLE `_MyOrderToReport_g`
  ADD CONSTRAINT `_MyOrderToReport_g_A_fkey` FOREIGN KEY (`A`) REFERENCES `my_orders_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `_MyOrderToReport_g_B_fkey` FOREIGN KEY (`B`) REFERENCES `reports_g` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
