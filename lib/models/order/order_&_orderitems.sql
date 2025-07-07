-- this is the sql for the order tables

-- create the order table
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

CREATE TABLE `OrderItem` (
  `id` int(11) NOT NULL,
  `orderId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `priceOptionId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
