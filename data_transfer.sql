Terminal close -- exit!
trib 5.7.24, for Linux (x86_64)
--
-- Host: 192.168.157.152    Database: data_transfer
-- ------------------------------------------------------
-- Server version	5.7.23-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED='37213942-ad43-11e8-8ddc-0050561e0286:1-1939669:2786876-2791575,
7f190aab-83f0-11e8-87f1-0050561e0286:1-8503';

--
-- Table structure for table `schema_sync`
--

DROP TABLE IF EXISTS `schema_sync`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_sync` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source_host` varchar(45) DEFAULT NULL,
  `source_shema` varchar(45) DEFAULT NULL,
  `destination_host` varchar(45) DEFAULT NULL,
  `destination_schema` varchar(45) DEFAULT NULL,
  `sync_structure` tinyint(1) DEFAULT '0',
  `hidden` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=212 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schema_sync`
--

LOCK TABLES `schema_sync` WRITE;
/*!40000 ALTER TABLE `schema_sync` DISABLE KEYS */;
INSERT INTO `schema_sync` VALUES (184,'192.168.157.104','freeosk','192.168.157.152','freeoskqa',1,1),(191,'192.168.157.106','analytics','192.168.157.152','analytics',1,1),(198,'192.168.157.104','transfer_test','192.168.157.152','transfer_test',1,0);
/*!40000 ALTER TABLE `schema_sync` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schema_sync_filter`
--

DROP TABLE IF EXISTS `schema_sync_filter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_sync_filter` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `schema_sync_id` int(11) DEFAULT NULL,
  `db_object` varchar(45) DEFAULT NULL,
  `db_object_name` varchar(45) DEFAULT NULL,
  `filter_field_name` varchar(45) NOT NULL DEFAULT 'NULL',
  `filter_field_range_start` varchar(45) NOT NULL DEFAULT 'NULL',
  `filter_field_range_end` varchar(45) NOT NULL DEFAULT 'NULL',
  `is_excluded` tinyint(1) DEFAULT '0',
  `hidden` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=128 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schema_sync_filter`
--

LOCK TABLES `schema_sync_filter` WRITE;
/*!40000 ALTER TABLE `schema_sync_filter` DISABLE KEYS */;
INSERT INTO `schema_sync_filter` VALUES (2,1,'BASE TABLE','campaign_email_trackings','NULL','NULL','NULL',1,0),(9,1,'BASE TABLE','email_optins','NULL','NULL','NULL',1,0),(16,1,'BASE TABLE','mobile_offer_audience_users','NULL','NULL','NULL',1,0),(23,1,'BASE TABLE','mobile_session_events','NULL','NULL','NULL',1,0),(30,1,'BASE TABLE','ods_alert_log','NULL','NULL','NULL',1,0),(37,1,'BASE TABLE','ods_dispense_events','NULL','NULL','NULL',1,0),(44,1,'BASE TABLE','ods_etl_log','NULL','NULL','NULL',1,0),(51,1,'BASE TABLE','ods_events','NULL','NULL','NULL',1,0),(58,1,'BASE TABLE','ods_kiosk_connections','NULL','NULL','NULL',1,0),(65,1,'BASE TABLE','ods_opt_in_data','NULL','NULL','NULL',1,0),(72,1,'BASE TABLE','ods_timefix_log','NULL','NULL','NULL',1,0),(79,1,'BASE TABLE','ods_users','NULL','NULL','NULL',1,0),(86,1,'VIEW','v_merchandising_data','NULL','NULL','NULL',1,0),(93,1,'VIEW','v_ods_opt_in_data','NULL','NULL','NULL',1,0),(100,1,'VIEW','v_optins','NULL','NULL','NULL',1,0),(107,1,'VIEW','v_running_execute_placement_program','NULL','NULL','NULL',1,0),(114,1,'BASE TABLE','walmart_instant_savings_trackings','NULL','NULL','NULL',1,0),(121,198,'BASE TABLE','placements','start_date','2019-04-09','NULL',0,0);
/*!40000 ALTER TABLE `schema_sync_filter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `table_config`
--

DROP TABLE IF EXISTS `table_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `table_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `table_name` varchar(45) DEFAULT NULL,
  `filter_field_name` varchar(45) NOT NULL DEFAULT 'NULL',
  `filter_field_range_start` varchar(45) NOT NULL DEFAULT 'NULL',
  `filter_field_range_end` varchar(45) NOT NULL DEFAULT 'NULL',
  `source_host` varchar(45) DEFAULT NULL,
  `source_shema` varchar(45) DEFAULT NULL,
  `destination_host` varchar(45) DEFAULT NULL,
  `destination_schema` varchar(45) DEFAULT NULL,
  `sync_structure` tinyint(1) DEFAULT '0',
  `hidden` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=182 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `table_config`
--

LOCK TABLES `table_config` WRITE;
/*!40000 ALTER TABLE `table_config` DISABLE KEYS */;
INSERT INTO `table_config` VALUES (0,'program_exceptions','id','886','2742','192.168.157.106','ods','192.168.157.103','ods',0,1),(93,'programs','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(167,'kiosk_models','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(168,'delivery_modules','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(169,'locations','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(170,'timezones','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(171,'ods_name_value','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(172,'engineering_recommendations','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(173,'sample_engineering_recommendations','id','473345','524590','192.168.157.106','ods','192.168.157.103','ods',0,1),(175,'service_exceptions','id','43464 ','60465','192.168.157.106','ods','192.168.157.103','ods',0,1),(176,'exception_types','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(177,'scheduled_services','id','2868639','2934260','192.168.157.106','ods','192.168.157.103','ods',0,1),(178,'placements','NULL','NULL','NULL','192.168.157.106','ods','192.168.157.103','ods',0,1),(179,'ods_scan_events ','date_submitted','2018-12-01','2018-12-11','192.168.157.106','ods','192.168.157.103','ods',0,1),(180,'locations','NULL','NULL','NULL','192.168.157.104','freeosk','192.168.157.103','freeoskqa',0,0),(181,'kiosks','NULL','NULL','NULL','192.168.157.104','freeosk','192.168.157.103','freeoskqa',0,0);
/*!40000 ALTER TABLE `table_config` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-05-03 12:48:40
