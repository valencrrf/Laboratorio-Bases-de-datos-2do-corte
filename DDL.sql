-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema online_game
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema online_game
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `online_game` DEFAULT CHARACTER SET utf8 ;
USE `online_game` ;

-- -----------------------------------------------------
-- Table `online_game`.`platform`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `online_game`.`platform` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `online_game`.`genre`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `online_game`.`genre` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `online_game`.`publisher`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `online_game`.`publisher` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `online_game`.`videogame`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `online_game`.`videogame` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(250) NOT NULL,
  `release_year` INT NULL,
  `platform_id` INT NOT NULL,
  `genre_id` INT NOT NULL,
  `publisher_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_videogame_platform_idx` (`platform_id` ASC) VISIBLE,
  INDEX `fk_videogame_genre1_idx` (`genre_id` ASC) VISIBLE,
  INDEX `fk_videogame_publisher1_idx` (`publisher_id` ASC) VISIBLE,
  CONSTRAINT `fk_videogame_platform`
    FOREIGN KEY (`platform_id`)
    REFERENCES `online_game`.`platform` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_videogame_genre1`
    FOREIGN KEY (`genre_id`)
    REFERENCES `online_game`.`genre` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_videogame_publisher1`
    FOREIGN KEY (`publisher_id`)
    REFERENCES `online_game`.`publisher` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `online_game`.`sale`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `online_game`.`sale` (
  `region` VARCHAR(45) NOT NULL,
  `sales` DECIMAL(10,2) NOT NULL,
  `videogame_id` INT NOT NULL,
  PRIMARY KEY (`region`, `videogame_id`),
  INDEX `fk_sale_videogame1_idx` (`videogame_id` ASC) VISIBLE,
  CONSTRAINT `fk_sale_videogame1`
    FOREIGN KEY (`videogame_id`)
    REFERENCES `online_game`.`videogame` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
