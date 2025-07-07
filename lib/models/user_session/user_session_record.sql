
CREATE TABLE `LoginHistory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
  `sessionEnd` datetime(3) DEFAULT NULL,
  `sessionStart` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_userId` (`userId`),
  KEY `idx_loginAt` (`loginAt`),
  KEY `idx_logoutAt` (`logoutAt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `LoginHistory`
--

INSERT INTO `LoginHistory` (`id`, `userId`, `loginAt`, `logoutAt`, `isLate`, `isEarly`, `timezone`, `shiftStart`, `shiftEnd`, `duration`, `status`, `sessionEnd`, `sessionStart`) VALUES
(152, 32, '2025-05-21 06:00:16.498', '2025-05-21 09:41:00.989', 0, 1, 'Africa/Nairobi', '2025-05-21 09:00:00.000', '2025-05-21 18:00:00.000', 220, '2', NULL, NULL),
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

