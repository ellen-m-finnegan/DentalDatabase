-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 25, 2022 at 11:54 PM
-- Server version: 10.4.22-MariaDB
-- PHP Version: 8.1.2

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `mulcahydentalpractice`
--

-- --------------------------------------------------------

--
-- Table structure for table `appointments`
--

CREATE TABLE `appointments` (
  `appointmentNumber` int(11) NOT NULL,
  `appointmentDate` date NOT NULL DEFAULT current_timestamp() COMMENT 'appointment date',
  `appointmentTime` time DEFAULT NULL COMMENT 'appointment time',
  `patientNumber` int(11) NOT NULL COMMENT 'Patient identifier',
  `appointmentCancelDate` date DEFAULT NULL COMMENT 'enter cancellation date if cancelled, otherwise NULL',
  `reminded` tinyint(1) NOT NULL DEFAULT 0,
  `lateCancelation` varchar(3) DEFAULT NULL COMMENT 'If late cancellation enter YES, if not type NO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `appointments`
--

INSERT INTO `appointments` (`appointmentNumber`, `appointmentDate`, `appointmentTime`, `patientNumber`, `appointmentCancelDate`, `reminded`, `lateCancelation`) VALUES
(1, '2021-11-05', '10:00:00', 2004, NULL, 0, NULL),
(2, '2021-11-05', '12:30:00', 2006, NULL, 0, NULL),
(3, '2021-11-07', '11:00:00', 2001, '2021-11-06', 0, 'YES'),
(4, '2021-11-07', '14:00:00', 2010, NULL, 0, NULL),
(5, '2021-11-16', '15:45:00', 2001, '2021-11-16', 0, 'YES'),
(6, '2021-11-21', '09:30:00', 2001, '2021-11-20', 0, 'YES'),
(7, '2021-11-21', '12:45:00', 2002, NULL, 0, NULL),
(8, '2021-12-03', '11:00:00', 2017, NULL, 0, NULL),
(9, '2021-12-03', '16:00:00', 2012, NULL, 0, NULL),
(10, '2021-12-08', '10:30:00', 2015, NULL, 0, NULL),
(11, '2021-12-08', '15:00:00', 2013, NULL, 0, NULL),
(12, '2022-01-26', '14:00:00', 2014, NULL, 0, NULL),
(13, '2022-02-02', '11:00:00', 2015, '2022-02-01', 0, 'YES'),
(14, '2022-03-07', '09:00:00', 2016, NULL, 0, NULL),
(15, '2022-03-16', '11:45:00', 2020, NULL, 0, NULL),
(16, '2022-03-26', '11:00:00', 2020, NULL, 0, NULL),
(17, '2022-04-23', '09:30:00', 2007, NULL, 0, NULL),
(18, '2022-04-23', '11:00:00', 2010, NULL, 0, NULL),
(19, '2022-04-23', '15:00:00', 2001, '2022-04-23', 0, 'YES'),
(20, '2022-04-24', '09:30:00', 2009, NULL, 0, NULL),
(21, '2022-04-24', '11:00:00', 2005, NULL, 0, NULL),
(22, '2022-04-24', '14:00:00', 2002, NULL, 0, NULL),
(23, '2022-04-24', '15:00:00', 2006, '2022-04-11', 0, 'NO'),
(24, '2022-04-24', '16:30:00', 2003, NULL, 0, NULL),
(25, '2022-04-27', '09:30:00', 2004, NULL, 0, NULL),
(26, '2022-05-02', '11:00:00', 2001, NULL, 0, NULL),
(27, '2022-05-04', '09:30:00', 2006, NULL, 0, NULL),
(28, '2022-05-04', '11:30:00', 2017, NULL, 0, NULL),
(29, '2022-05-04', '13:30:00', 2011, NULL, 0, NULL),
(30, '2022-05-04', '15:00:00', 2004, NULL, 0, NULL),
(31, '2022-05-05', '09:30:00', 2009, NULL, 0, NULL),
(32, '2022-05-05', '10:30:00', 2014, '2022-04-26', 0, 'NO'),
(33, '2022-05-05', '10:30:00', 2003, NULL, 0, NULL),
(34, '2022-05-05', '12:30:00', 2013, NULL, 0, NULL);

--
-- Triggers `appointments`
--
DELIMITER $$
CREATE TRIGGER `Bill_Late_Cancelation` AFTER UPDATE ON `appointments` FOR EACH ROW BEGIN
	IF NEW.lateCancelation = TRUE THEN
		INSERT INTO bill VALUES (NULL, OLD.appointmentDate, 20, 1, OLD.appointmentNumber);
		DELETE FROM appointments WHERE appointmentNumber=OLD.appointmentNumber;
	END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Catch_Defaulters` BEFORE INSERT ON `appointments` FOR EACH ROW BEGIN
-- Defaulters can be for 2 reasons: patient owes too much OR has a long outstanding bill
	DECLARE checkDefaulter boolean;
	DECLARE limitDateToPay date;
	DECLARE tooMuchDate date;

-- Check too old statements
	SET limitDateToPay = (SELECT ADDDATE((SELECT MIN(paymentDate)
		-- Select correct patient
		FROM payment, bill, appointments
		WHERE bill.billNumber=bill.billNumber
		AND bill.appointmentNumber=appointments.appointmentNumber
		AND appointments.patientNumber=NEW.patientNumber
		-- Select payments unpaid
		AND paymnetNumber NOT IN (
				SELECT paymentNumber FROM payment WHERE patientNumber = new.patientNumber)) 
	,INTERVAL 1 MONTH));
	-- Check if date limit for unpaid payments is before curent date
	IF CURDATE() > limitDateToPay THEN
		-- Updates table temporarily
		UPDATE patient SET defaulter = true WHERE patientNumber = NEW.patientNumber;
	END IF;

	CREATE TEMPORARY TABLE IF NOT EXISTS possible_Dates AS (SELECT MIN(paymentDate)
		-- Look for patient
		FROM payment, bill, appointments
		WHERE payment.billNumber=bill.billNumber
		AND bill.appointmentNumber=appointments.appointmentNumber
		AND appointments.patientNumber=NEW.patientNumber
		AND payment.total > 99.99
		-- Bill unpaid
		AND paymentNumber NOT IN (
				SELECT paymentNumber FROM Payment WHERE patientNumber = new.patientNumber));
	-- Set the date adding 10 days to the oldest unpaid payment larger than the limit
	SET tooMuchDate = (SELECT ADDDATE((SELECT DISTINCT * FROM possible_Dates), INTERVAL 10 DAY));
	-- Check if the date of the not too old but large unpaid payment is older than 10 days
	IF (CURDATE() > tooMuchDate) THEN
		UPDATE patient SET defaulter = true WHERE patientNumber = NEW.patientNumber;
	END IF;
	-- Set if any of above has happened
	SET checkDefaulter = (SELECT defaulter FROM patient WHERE patientNumber = NEW.patientNumber);
	-- Check if any of the above has happened
	IF checkDefaulter = TRUE THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'No new appointments until the debt has been cleared';
	END IF;
	-- Drop temporary table
	DROP TEMPORARY TABLE IF EXISTS possible_Dates;
-- If nothing happens, INSERT without problems
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bill`
--

CREATE TABLE `bill` (
  `billNumber` int(11) NOT NULL,
  `billDate` date DEFAULT current_timestamp() COMMENT 'Date bill was issued',
  `patientNumber` int(11) NOT NULL COMMENT 'Patient identifier',
  `appointmentNumber` int(11) DEFAULT NULL COMMENT 'Appointment identifier',
  `treatmentName` varchar(255) DEFAULT NULL COMMENT 'Name of treatment received.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `bill`
--

INSERT INTO `bill` (`billNumber`, `billDate`, `patientNumber`, `appointmentNumber`, `treatmentName`) VALUES
(1301, '2021-11-04', 2004, 1, 'Crown'),
(1302, '2021-11-04', 2006, 2, 'Fillings'),
(1303, '2021-11-06', 2001, 3, 'Cancellation'),
(1304, '2021-11-06', 2003, 4, 'Examination'),
(1305, '2021-11-15', 2001, 5, 'Cancellation'),
(1306, '2021-11-20', 2001, 6, 'Cancellation'),
(1307, '2021-11-20', 2002, 7, 'Examination'),
(1308, '2021-12-02', 2002, 8, 'Examination'),
(1309, '2021-12-02', 2012, 9, 'Cleaning'),
(1310, '2021-12-07', 2015, 10, 'X-ray'),
(1311, '2021-12-07', 2013, 11, 'Examination'),
(1312, '2022-01-25', 2014, 12, 'X-ray'),
(1313, '2022-02-01', 2015, 13, 'Cancellation'),
(1314, '2022-03-06', 2016, 14, 'Extraction'),
(1315, '2022-03-15', 2020, 15, 'Extraction'),
(1316, '2022-03-25', 2020, 16, 'X-ray'),
(1317, '2022-04-22', 2007, 17, 'Dentures'),
(1318, '2022-04-22', 2010, 18, 'Examination'),
(1319, '2022-04-22', 2001, 19, 'Cancellation'),
(1320, '2022-04-23', 2009, 20, 'Examination'),
(1321, '2022-04-23', 2005, 21, 'Crown'),
(1322, '2022-04-23', 2002, 22, 'Cleaning'),
(1323, '2022-04-23', 2003, 24, 'Examination');

-- --------------------------------------------------------

--
-- Stand-in structure for view `highrepayment`
-- (See below for the actual view)
--
CREATE TABLE `highrepayment` (
`patientNumber` int(11)
,`patientFirstName` varchar(255)
,`patientLastName` varchar(255)
,`patientBalance` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `latecancel`
-- (See below for the actual view)
--
CREATE TABLE `latecancel` (
`patientFirstName` varchar(255)
,`patientLastName` varchar(255)
,`appointmentDate` date
,`appointmentTime` time
,`appointmentCancelDate` date
,`lateCancelation` varchar(3)
);

-- --------------------------------------------------------

--
-- Table structure for table `latecancelations`
--

CREATE TABLE `latecancelations` (
  `patientNumber` int(11) DEFAULT NULL,
  `appointmentDate` date DEFAULT NULL,
  `lateCancelation` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Stand-in structure for view `laterepayment`
-- (See below for the actual view)
--
CREATE TABLE `laterepayment` (
`patientNumber` int(11)
,`patientFirstName` varchar(255)
,`patientLastName` varchar(255)
,`billDate` date
,`patientBalance` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `nextweek_appointments`
-- (See below for the actual view)
--
CREATE TABLE `nextweek_appointments` (
`patientNumber` int(11)
,`appointmentDate` date
,`appointmentTime` time
,`reminded` tinyint(1)
);

-- --------------------------------------------------------

--
-- Table structure for table `patient`
--

CREATE TABLE `patient` (
  `patientNumber` int(11) NOT NULL,
  `patientFirstName` varchar(255) DEFAULT NULL COMMENT 'Forename',
  `patientLastName` varchar(255) DEFAULT NULL COMMENT 'Surname',
  `patientDOB` date DEFAULT NULL COMMENT 'DOB',
  `patientPhone` int(10) DEFAULT NULL COMMENT 'phone number',
  `patientEircode` varchar(7) DEFAULT NULL COMMENT 'eircode',
  `patientEmail` varchar(255) DEFAULT NULL COMMENT 'email address',
  `patientBalance` decimal(10,2) DEFAULT NULL COMMENT 'Amount patient owes',
  `defaulter` tinyint(1) DEFAULT 0 COMMENT 'if 1 - patient owes too much or for too long'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `patient`
--

INSERT INTO `patient` (`patientNumber`, `patientFirstName`, `patientLastName`, `patientDOB`, `patientPhone`, `patientEircode`, `patientEmail`, `patientBalance`, `defaulter`) VALUES
(2001, 'Gary', 'Keaveney', '1943-07-12', 857496234, 'H23DY90', 'gkeave43@gmail.com', '30.00', 0),
(2002, 'Betty', 'Cummins', '2002-09-05', 838656517, 'H13DL91', 'bettyxcumminsx12x@gmail.com', '0.00', 0),
(2003, 'Darragh', 'Leonard', '2005-05-12', 874228692, 'H34ED95', 'lendarragh@gmail.com', '50.00', 0),
(2004, 'George', 'Leonard', '1977-10-14', 874228692, 'H34ED95', 'gleonard77@gmail.com', '100.00', 0),
(2005, 'Meadhbh', 'Leonard', '1980-05-15', 874228692, 'H34ED95', 'moconnell22@gmail.com', '0.00', 0),
(2006, 'Ciara', 'Leonard', '2011-02-19', 874228692, 'H34ED95', 'moconnell22@gmail.com', '0.00', 0),
(2007, 'Karen', 'Carroll', '1951-11-30', 868932058, 'H12FX01', 'karcar@yahoo.com', '0.00', 0),
(2008, 'Becky', 'McLoughlin', '1996-03-06', 858937878, 'H18YLW5', 'bmcloughin@gmail.com', '0.00', 0),
(2009, 'Milo', 'Costelloe', '1994-04-28', 873357130, 'H13DD00', 'm.costelloe7@ucc.ie', '0.00', 0),
(2010, 'Niamh', 'Nelson', '1997-07-10', 899907358, 'H10L5Q7', 'niamhynelsonx@live.com', '0.00', 0),
(2011, 'Amy', 'Sheriden', '1997-12-03', 856677432, 'H15MX70', 'a.sheriden8@nuig.ie', '0.00', 0),
(2012, 'Darragh', 'Sheriden', '1999-05-22', 890077023, 'H15MX70', 'd.sheriden4@nuig.com', '0.00', 0),
(2013, 'Ruairí', 'Sheriden', '1995-03-15', 878763570, 'H15MX70', 'r.sheriden12@ucc.com', '0.00', 0),
(2014, 'Darragh', 'Walsh', '1989-12-15', 850073469, 'H10YY25', 'dazwalshy@live.com', '30.00', 0),
(2015, 'Meghan', 'Hynes', '1987-01-30', 834447523, 'HU3BC45', 'megzhynes34@gmail.com', '10.00', 0),
(2016, 'Jane', 'Monaghan', '2001-07-04', 873571222, 'H79DZ74', 'monaghanjanexx1@gmail.com', '15.00', 0),
(2017, 'Helen', 'McGann', '1947-01-22', 866903258, 'H12QR58', NULL, '0.00', 0),
(2018, 'Ellen', 'Finnegan', '1996-10-21', 876462081, 'H08CH33', 'efinnegan12@gmail.com', '0.00', 0),
(2019, 'Andy', 'Muldoon', '1988-08-12', 856532588, 'H15MQ34', 'andrewmuldooooon@live.com', '0.00', 0),
(2020, 'Joe', 'Burke', '1949-01-01', 862340983, 'H15UQ14', NULL, '75.00', 0);

-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

CREATE TABLE `payment` (
  `paymentDate` date DEFAULT NULL COMMENT 'Date payment received ',
  `paymentNumber` int(11) NOT NULL,
  `patientNumber` int(11) NOT NULL COMMENT 'Patient identifier',
  `paymentMethod` varchar(255) DEFAULT NULL COMMENT 'Method of payment',
  `paymentAmount` decimal(10,2) DEFAULT NULL COMMENT 'transaction amount',
  `billNumber` int(11) DEFAULT NULL COMMENT 'Bill identifier',
  `billBalance` decimal(10,2) DEFAULT NULL COMMENT 'amount still owed on this bill'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `payment`
--

INSERT INTO `payment` (`paymentDate`, `paymentNumber`, `patientNumber`, `paymentMethod`, `paymentAmount`, `billNumber`, `billBalance`) VALUES
('2021-11-04', 2400, 2006, 'Cash', '20.00', 1302, '40.00'),
('2021-11-05', 2401, 2006, 'Credit card', '40.00', 1301, '0.00'),
('2021-11-06', 2402, 2003, 'Cash', '50.00', 1304, '0.00'),
('2021-11-20', 2403, 2002, 'Cash', '30.00', 1307, '30.00'),
('2021-12-02', 2404, 2012, 'Cheque', '50.00', 1309, '0.00'),
('2021-12-02', 2405, 2002, 'Cash', '20.00', 1365, '0.00'),
('2021-12-02', 2406, 2002, 'Cash', '50.00', 1308, '0.00'),
('2021-12-07', 2407, 2015, 'Cash', '20.00', 1310, '10.00'),
('2021-12-07', 2408, 2013, 'Cash', '10.00', 1311, '40.00'),
('2021-12-07', 2409, 2015, 'Cash', '10.00', 1310, '0.00'),
('2021-12-15', 2410, 2013, 'Cheque', '40.00', 1311, '0.00'),
('2022-03-06', 2411, 2016, 'Cash', '65.00', 1314, '15.00'),
('2022-03-15', 2412, 2020, 'Credit card', NULL, 1315, '45.00'),
('2022-04-22', 2413, 2007, 'Cash', '10.00', 1317, '30.00'),
('2022-04-22', 2414, 2010, 'Cheque', '50.00', 1318, '0.00'),
('2022-04-22', 2415, 2009, 'Cash', '5.00', 1320, '45.00'),
('2022-04-23', 2416, 2007, 'Cash', '10.00', 1317, '20.00'),
('2022-04-24', 2417, 2007, 'Cash', '10.00', 1317, '10.00'),
('2022-04-24', 2418, 2007, 'Cash', '10.00', 1317, '0.00'),
('2022-04-24', 2419, 2009, 'Credit card', '45.00', 1320, '0.00'),
('2022-04-24', 2420, 2005, 'Credit card', '100.00', 1321, '0.00'),
('2022-04-24', 2421, 2002, 'Credit card', '50.00', 1322, '0.00');

-- --------------------------------------------------------

--
-- Table structure for table `referrals`
--

CREATE TABLE `referrals` (
  `referralNumber` int(11) NOT NULL COMMENT 'Referral row identifier',
  `patientNumber` int(11) DEFAULT NULL COMMENT 'Patient identifier',
  `specialistNumber` int(11) DEFAULT NULL COMMENT 'Specialist identifier',
  `appointmentNumber` int(11) DEFAULT NULL COMMENT 'Appointment identifier'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `referrals`
--

INSERT INTO `referrals` (`referralNumber`, `patientNumber`, `specialistNumber`, `appointmentNumber`) VALUES
(4001, 2003, 1003, 2),
(4002, 2002, 1007, 8),
(4003, 2015, 1002, 10),
(4004, 2014, 1002, 12),
(4005, 2010, 1005, 18),
(4006, 2009, 1001, 20),
(4007, 2003, 1004, 24);

-- --------------------------------------------------------

--
-- Table structure for table `specialist`
--

CREATE TABLE `specialist` (
  `specialistNumber` int(11) NOT NULL COMMENT 'Specialist row identifier ',
  `specialistFirstName` varchar(255) DEFAULT NULL COMMENT 'Specialist forename ',
  `specialistLastName` varchar(255) DEFAULT NULL COMMENT 'Specialist surname',
  `specialistRole` varchar(255) DEFAULT NULL COMMENT 'Speciality ',
  `specialistPhone` int(10) DEFAULT NULL COMMENT 'phone number',
  `specialistAddress` varchar(255) DEFAULT NULL COMMENT 'clinic address',
  `specialistEmail` varchar(255) DEFAULT NULL COMMENT 'referal email address'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `specialist`
--

INSERT INTO `specialist` (`specialistNumber`, `specialistFirstName`, `specialistLastName`, `specialistRole`, `specialistPhone`, `specialistAddress`, `specialistEmail`) VALUES
(1001, 'Michelle', 'McNamara', 'Endonontist', 21196781, 'Dr. McNamara Dental Cork', 'referals@mcnamaradental.ie'),
(1002, 'Catherine', 'Connell', 'Dental and Oral Surgeon', 21876321, 'Ms. Connell Dental Surgery Bons Secours Cork', 'referals@connellsurgery.ie'),
(1003, 'Ivan', 'Ivanovski', 'Orthodontist', 21876543, 'Smile Bright Cork City', 'referals@smilebright.ie'),
(1004, 'Louise', 'Rabbitte', 'Maxillofacial Surgeon', 21985464, 'Ms. Rabbitte Maxilfacial and Plastic Surgery Bons Secours Cork', 'referals@rabbittemaxillofacial.ie'),
(1005, 'John', 'Shaughnessy', 'Prosthodontist', 21224987, 'Pearly Whites Prosthodontist Cork', 'referals@pearlywhites.ie'),
(1006, 'Sarah', 'McDermott', 'Periodontist', 21233529, 'Periodontist Consultancy Cork', 'referals@mcdermottperiodontist.ie'),
(1007, 'Sean', 'Collins', 'Orthodontist', 21698246, 'Rebels Orthodontistry Cork City', 'referals@rebelsorthodontist.ie');

-- --------------------------------------------------------

--
-- Table structure for table `treatment`
--

CREATE TABLE `treatment` (
  `treatmentName` varchar(255) NOT NULL COMMENT 'treatment name',
  `treatmentCost` decimal(10,2) NOT NULL COMMENT 'treatment cost'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `treatment`
--

INSERT INTO `treatment` (`treatmentName`, `treatmentCost`) VALUES
('Cancellation', '10.00'),
('Cleaning', '50.00'),
('Crown', '1000.00'),
('Dentures', '1200.00'),
('Examination', '50.00'),
('Extraction', '120.00'),
('Fillings', '85.00'),
('X-ray', '35.00');

-- --------------------------------------------------------

--
-- Structure for view `highrepayment`
--
DROP TABLE IF EXISTS `highrepayment`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `highrepayment`  AS SELECT `patient`.`patientNumber` AS `patientNumber`, `patient`.`patientFirstName` AS `patientFirstName`, `patient`.`patientLastName` AS `patientLastName`, `patient`.`patientBalance` AS `patientBalance` FROM `patient` WHERE `patient`.`patientBalance` > 50 ;

-- --------------------------------------------------------

--
-- Structure for view `latecancel`
--
DROP TABLE IF EXISTS `latecancel`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `latecancel`  AS SELECT `patient`.`patientFirstName` AS `patientFirstName`, `patient`.`patientLastName` AS `patientLastName`, `appointments`.`appointmentDate` AS `appointmentDate`, `appointments`.`appointmentTime` AS `appointmentTime`, `appointments`.`appointmentCancelDate` AS `appointmentCancelDate`, `appointments`.`lateCancelation` AS `lateCancelation` FROM (`patient` join `appointments`) WHERE `patient`.`patientNumber` = `appointments`.`patientNumber` AND `appointments`.`lateCancelation` = 'YES' ;

-- --------------------------------------------------------

--
-- Structure for view `laterepayment`
--
DROP TABLE IF EXISTS `laterepayment`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `laterepayment`  AS SELECT `patient`.`patientNumber` AS `patientNumber`, `patient`.`patientFirstName` AS `patientFirstName`, `patient`.`patientLastName` AS `patientLastName`, `bill`.`billDate` AS `billDate`, `patient`.`patientBalance` AS `patientBalance` FROM (`patient` join `bill`) WHERE `patient`.`patientNumber` = `bill`.`patientNumber` AND `patient`.`patientBalance` > 0 AND curdate() - `bill`.`billDate` > 10 ;

-- --------------------------------------------------------

--
-- Structure for view `nextweek_appointments`
--
DROP TABLE IF EXISTS `nextweek_appointments`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `nextweek_appointments`  AS SELECT `appointments`.`patientNumber` AS `patientNumber`, `appointments`.`appointmentDate` AS `appointmentDate`, `appointments`.`appointmentTime` AS `appointmentTime`, `appointments`.`reminded` AS `reminded` FROM `appointments` WHERE `appointments`.`appointmentTime` is not null AND `appointments`.`appointmentDate` between curdate() and curdate() + interval 10 day ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`appointmentNumber`),
  ADD KEY `patientNumber` (`patientNumber`);

--
-- Indexes for table `bill`
--
ALTER TABLE `bill`
  ADD PRIMARY KEY (`billNumber`),
  ADD KEY `patientNumber` (`patientNumber`),
  ADD KEY `apptNumber` (`appointmentNumber`),
  ADD KEY `treatmentName` (`treatmentName`);

--
-- Indexes for table `patient`
--
ALTER TABLE `patient`
  ADD PRIMARY KEY (`patientNumber`);

--
-- Indexes for table `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`paymentNumber`),
  ADD KEY `patientNumber` (`patientNumber`),
  ADD KEY `billNumber` (`billNumber`);

--
-- Indexes for table `referrals`
--
ALTER TABLE `referrals`
  ADD PRIMARY KEY (`referralNumber`),
  ADD KEY `patientNumber` (`patientNumber`),
  ADD KEY `specialistNumber` (`specialistNumber`),
  ADD KEY `apptNumber` (`appointmentNumber`);

--
-- Indexes for table `specialist`
--
ALTER TABLE `specialist`
  ADD PRIMARY KEY (`specialistNumber`);

--
-- Indexes for table `treatment`
--
ALTER TABLE `treatment`
  ADD PRIMARY KEY (`treatmentName`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointments`
--
ALTER TABLE `appointments`
  MODIFY `appointmentNumber` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `bill`
--
ALTER TABLE `bill`
  MODIFY `billNumber` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1324;

--
-- AUTO_INCREMENT for table `patient`
--
ALTER TABLE `patient`
  MODIFY `patientNumber` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2021;

--
-- AUTO_INCREMENT for table `payment`
--
ALTER TABLE `payment`
  MODIFY `paymentNumber` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2422;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointments`
--
ALTER TABLE `appointments`
  ADD CONSTRAINT `appointments_ibfk_1` FOREIGN KEY (`patientNumber`) REFERENCES `patient` (`patientNumber`);

--
-- Constraints for table `bill`
--
ALTER TABLE `bill`
  ADD CONSTRAINT `bill_ibfk_1` FOREIGN KEY (`patientNumber`) REFERENCES `patient` (`patientNumber`),
  ADD CONSTRAINT `bill_ibfk_2` FOREIGN KEY (`appointmentNumber`) REFERENCES `appointments` (`appointmentNumber`),
  ADD CONSTRAINT `bill_ibfk_3` FOREIGN KEY (`treatmentName`) REFERENCES `treatment` (`treatmentName`);

--
-- Constraints for table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`patientNumber`) REFERENCES `patient` (`patientNumber`);

--
-- Constraints for table `referrals`
--
ALTER TABLE `referrals`
  ADD CONSTRAINT `referrals_ibfk_1` FOREIGN KEY (`patientNumber`) REFERENCES `patient` (`patientNumber`),
  ADD CONSTRAINT `referrals_ibfk_2` FOREIGN KEY (`specialistNumber`) REFERENCES `specialist` (`specialistNumber`),
  ADD CONSTRAINT `referrals_ibfk_3` FOREIGN KEY (`appointmentNumber`) REFERENCES `appointments` (`appointmentNumber`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
