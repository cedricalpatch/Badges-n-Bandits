-- MySQL dump 10.13  Distrib 8.0.16, for Win64 (x86_64)
--
-- ------------------------------------------------------
-- Server version	5.5.64-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
 SET NAMES utf8 ;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bans`
--

DROP TABLE IF EXISTS `bans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `bans` (
  `id` int(24) unsigned NOT NULL,
  `player_id` int(24) unsigned NOT NULL COMMENT 'the players table relationship',
  `banned` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `reason` varchar(99) DEFAULT 'Rule Violation' COMMENT 'The reason for the ban. If not given, will be set as generic',
  `active` tinyint(4) DEFAULT '1' COMMENT 'If 0, player is not banned, but was previously banned (record keeping)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ban_id_UNIQUE` (`id`),
  UNIQUE KEY `player_id_UNIQUE` (`player_id`),
  CONSTRAINT `bans_fk_player_id` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `camps`
--

DROP TABLE IF EXISTS `camps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `camps` (
  `id` int(24) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(99) DEFAULT 'Name of the campsite',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `characters`
--

DROP TABLE IF EXISTS `characters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `characters` (
  `id` int(24) unsigned NOT NULL,
  `player_id` int(24) unsigned NOT NULL,
  `model` varchar(48) NOT NULL DEFAULT 'mp_male',
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `gold` decimal(12,2) unsigned DEFAULT '0.00',
  `cash` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `playtime` int(24) unsigned NOT NULL DEFAULT '1' COMMENT 'time played in minutes',
  `cop_rank` int(16) unsigned NOT NULL DEFAULT '1',
  `civ_rank` int(16) unsigned NOT NULL DEFAULT '1',
  `miles` decimal(12,2) unsigned DEFAULT '0.00' COMMENT 'miles walked',
  `bounty` int(12) unsigned DEFAULT '0',
  `x` decimal(7,2) NOT NULL DEFAULT '0.05',
  `y` decimal(7,2) NOT NULL DEFAULT '0.05',
  `z` decimal(7,2) NOT NULL DEFAULT '0.05',
  `heading` decimal(7,2) NOT NULL DEFAULT '180.00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `player_id_UNIQUE` (`player_id`),
  CONSTRAINT `characters_fk_player_id` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clans`
--

DROP TABLE IF EXISTS `clans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `clans` (
  `id` int(16) unsigned NOT NULL AUTO_INCREMENT,
  `leader_id` int(24) unsigned DEFAULT NULL,
  `tag` varchar(5) NOT NULL DEFAULT 'NoTag',
  `title` varchar(48) NOT NULL DEFAULT 'No Clan Name',
  `cop_level` int(16) unsigned NOT NULL DEFAULT '1',
  `civ_level` int(16) unsigned NOT NULL DEFAULT '1',
  `ranks` text,
  `mod_rank` int(16) unsigned NOT NULL DEFAULT '3',
  `admin_rank` int(16) unsigned NOT NULL DEFAULT '4',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `tag_UNIQUE` (`tag`),
  UNIQUE KEY `leader_id_UNIQUE` (`leader_id`),
  CONSTRAINT `clans_fk_chars_id` FOREIGN KEY (`leader_id`) REFERENCES `characters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='clans are more permanent groups for current/later use';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `horses`
--

DROP TABLE IF EXISTS `horses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `horses` (
  `id` int(24) unsigned NOT NULL AUTO_INCREMENT,
  `character_id` int(24) unsigned NOT NULL COMMENT 'owner',
  `hitch_id` int(16) unsigned NOT NULL DEFAULT '0' COMMENT 'last known hitching post',
  `name` varchar(48) DEFAULT 'Horse',
  `hunger` decimal(5,2) unsigned NOT NULL DEFAULT '100.00' COMMENT 'last known hunger',
  `stamina` decimal(5,2) unsigned NOT NULL DEFAULT '100.00' COMMENT 'last known stamina',
  `level` int(8) unsigned NOT NULL DEFAULT '1',
  `gold` decimal(12,2) unsigned NOT NULL DEFAULT '0.00' COMMENT 'gold on the horse',
  `cash` decimal(12,2) unsigned NOT NULL DEFAULT '0.00' COMMENT 'cash on the horse',
  `impound` tinyint(4) NOT NULL DEFAULT '0' COMMENT 'held by the law',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `horses_fk_char_id_idx` (`character_id`),
  CONSTRAINT `horses_fk_char_id` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inmates`
--

DROP TABLE IF EXISTS `inmates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `inmates` (
  `id` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `character_id` int(24) unsigned NOT NULL,
  `seconds` int(24) unsigned NOT NULL DEFAULT '60',
  `convicted` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `felony` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'True if felony false if misdemeanor',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `character_id_UNIQUE` (`character_id`),
  CONSTRAINT `inmates_fk_char_id` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `players` (
  `id` int(24) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique ID',
  `steam_id` varchar(99) DEFAULT NULL,
  `club_id` varchar(99) DEFAULT NULL,
  `redm_id` varchar(99) DEFAULT NULL,
  `discord_id` varchar(99) DEFAULT NULL,
  `username` varchar(99) NOT NULL COMMENT 'last known username',
  `ip` varchar(15) DEFAULT NULL COMMENT 'last known ip address',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'first time played',
  `lastjoin` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rank` int(4) unsigned NOT NULL DEFAULT '0' COMMENT 'Player VIP TrialMod Mod JrAdmin Admin SrAdmin HeadAdmin Staff Owner',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `storage`
--

DROP TABLE IF EXISTS `storage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `storage` (
  `id` int(32) unsigned NOT NULL AUTO_INCREMENT,
  `character_id` int(24) unsigned NOT NULL DEFAULT '0',
  `horse_id` int(24) unsigned NOT NULL DEFAULT '0',
  `camp_id` int(16) unsigned NOT NULL DEFAULT '0',
  `item_name` varchar(48) NOT NULL DEFAULT 'item_generic' COMMENT 'code friendly name of the item',
  `title` varchar(48) NOT NULL DEFAULT 'Generic Item' COMMENT 'user friendly item name',
  `quantity` int(8) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `storage_fk_horse_id_idx` (`horse_id`),
  KEY `storage_fk_char_id_idx` (`character_id`),
  KEY `storage_fk_camp_id_idx` (`camp_id`),
  CONSTRAINT `storage_fk_char_id` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `storage_fk_camp_id` FOREIGN KEY (`camp_id`) REFERENCES `camps` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `storage_fk_horse_id` FOREIGN KEY (`horse_id`) REFERENCES `horses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `weapons`
--

DROP TABLE IF EXISTS `weapons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `weapons` (
  `id` int(12) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique database id',
  `character_id` int(24) unsigned NOT NULL COMMENT 'which character has this on their person',
  `horse_id` int(24) unsigned NOT NULL COMMENT 'which horse has this weapon',
  `camp_id` int(24) unsigned NOT NULL COMMENT 'which camp has this weapon stored',
  `identity` varchar(48) NOT NULL DEFAULT 'WEAPON_LASSO' COMMENT 'code friendly weapon name',
  `title` varchar(48) NOT NULL DEFAULT 'Lasso' COMMENT 'user friendly weapon name',
  `ammo` int(16) unsigned NOT NULL DEFAULT '1' COMMENT 'ammo remaining',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `weapons_fk_char_id_idx` (`character_id`),
  KEY `weapons_fk_horse_id_idx` (`horse_id`),
  CONSTRAINT `weapons_fk_char_id` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `weapons_fk_horse_id` FOREIGN KEY (`horse_id`) REFERENCES `horses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='weapons currently in someones or somethings possession';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping events for database 'bbgame'
--

--
-- Dumping routines for database 'bbgame'
--
/*!50003 DROP FUNCTION IF EXISTS `PlayerJoining` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `PlayerJoining`(
  `steam` VARCHAR(99),
  `sclub` VARCHAR(99),
  `redm` VARCHAR(99),
  `discd` VARCHAR(99),
  `ip` VARCHAR(15),
  `username` VARCHAR(56)
) RETURNS int(16) unsigned
BEGIN

	DECLARE uid INT(32) UNSIGNED DEFAULT 0;
    DECLARE tst TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    
    # Try to locate the account in prescedence of ID
    IF steam IS NOT NULL THEN
		SELECT id INTO uid FROM players WHERE steam_id = steam;
	ELSEIF sclub IS NOT NULL THEN
		SELECT id INTO uid FROM players WHERE club_id = sclub;
	ELSEIF redm IS NOT NULL THEN
		SELECT id INTO uid FROM players WHERE redm_id = fivem;
	ELSEIF discd IS NOT NULL THEN
		SELECT id INTO uid FROM players WHERE discord_id = discd;
    ELSE 
		SET uid = 0;
    END IF;
    
    # If UID is 0 they have no account or their account was not found
    IF uid = 0 OR uid IS NULL THEN 
    
      # Insert new Entry
      INSERT INTO players (steam_id, club_id, redm_id, discord_id, ip, username, created, lastjoin)
        VALUES            (steam,    sclub,   redm,    discd,      ip, username, tst,     tst);
      
      # Get the new Entry's UID
      SELECT id INTO uid FROM players WHERE created = tst LIMIT 1;
  
    END IF;
    
    RETURN uid;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-12-16 12:39:17
