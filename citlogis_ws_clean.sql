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
    

-- =========================
-- Table: leave_types
-- =========================
CREATE TABLE IF NOT EXISTS `leave_types` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL UNIQUE,
  `max_days_per_year` DECIMAL(5,2) DEFAULT NULL,
  `accrues` TINYINT(1) DEFAULT 0,
  `monthly_accrual` DECIMAL(5,2) DEFAULT 0.00,
  `requires_attachment` TINYINT(1) DEFAULT 0,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- Table: employee_types
-- =========================
CREATE TABLE IF NOT EXISTS `employee_types` (
  `id` TINYINT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(20) NOT NULL UNIQUE,
  `description` VARCHAR(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Initial employee types
INSERT INTO `employee_types` (`name`, `description`) VALUES 
('staff', 'Internal office staff'),
('sales_rep', 'Sales representatives');

-- =========================
-- Table: leave_requests
-- =========================
CREATE TABLE IF NOT EXISTS `leave_requests` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `employee_type_id` TINYINT NOT NULL,
  `employee_id` INT NOT NULL,
  `leave_type_id` INT NOT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `is_half_day` TINYINT(1) DEFAULT 0,
  `reason` TEXT,
  `status` ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  `approved_by` INT DEFAULT NULL,
  `attachment_url` TEXT,
  `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_leave_employee` (`employee_type_id`, `employee_id`),
  INDEX `idx_leave_status` (`status`),
  INDEX `idx_leave_date_range` (`start_date`, `end_date`),
  CONSTRAINT `fk_leave_request_type` FOREIGN KEY (`leave_type_id`) REFERENCES `leave_types` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_leave_request_approver` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_leave_employee_type` FOREIGN KEY (`employee_type_id`) REFERENCES `employee_types` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================
-- Table: leave_balances
-- =========================
CREATE TABLE IF NOT EXISTS `leave_balances` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `employee_type_id` TINYINT NOT NULL,
  `employee_id` INT NOT NULL,
  `leave_type_id` INT NOT NULL,
  `year` INT NOT NULL,
  `accrued` DECIMAL(5,2) DEFAULT 0.00,
  `used` DECIMAL(5,2) DEFAULT 0.00,
  `carried_forward` DECIMAL(5,2) DEFAULT 0.00,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3),
  UNIQUE KEY `uk_leave_balance` (`employee_type_id`, `employee_id`, `leave_type_id`, `year`),
  INDEX `idx_leave_balance_year` (`employee_type_id`, `employee_id`, `year`),
  CONSTRAINT `fk_leave_balance_type` FOREIGN KEY (`leave_type_id`) REFERENCES `leave_types` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_balance_employee_type` FOREIGN KEY (`employee_type_id`) REFERENCES `employee_types` (`id`) ON DELETE CASCADE
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
-- Table structure for table `_MyOrderToReport`
--

CREATE TABLE `_MyOrderToReport` (
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
-- Indexes for table `JourneyPlan`
--
ALTER TABLE `JourneyPlan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `JourneyPlan_clientId_idx` (`clientId`),
  ADD KEY `JourneyPlan_userId_idx` (`userId`),
  ADD KEY `JourneyPlan_routeId_fkey` (`routeId`);

--
-- Indexes for table `leaves`
--
ALTER TABLE `leaves`
  ADD PRIMARY KEY (`id`),
  ADD KEY `leaves_userId_fkey` (`userId`);

--
-- Indexes for table `LoginHistory`
--
ALTER TABLE `LoginHistory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `LoginHistory_userId_idx` (`userId`),
  ADD KEY `LoginHistory_loginAt_idx` (`loginAt`),
  ADD KEY `LoginHistory_logoutAt_idx` (`logoutAt`);

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
-- Indexes for table `NoticeBoard`
--
ALTER TABLE `NoticeBoard`
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
-- Indexes for table `purchase_items`
--
ALTER TABLE `purchase_items`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Regions`
--
ALTER TABLE `Regions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `Regions_name_countryId_key` (`name`,`countryId`),
  ADD KEY `Regions_countryId_fkey` (`countryId`);

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
-- Indexes for table `routes`
--
ALTER TABLE `routes`
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
-- Indexes for table `stock_take`
--
ALTER TABLE `stock_take`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `stock_transfer`
--
ALTER TABLE `stock_transfer`
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
-- Indexes for table `Target`
--
ALTER TABLE `Target`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Target_salesRepId_fkey` (`salesRepId