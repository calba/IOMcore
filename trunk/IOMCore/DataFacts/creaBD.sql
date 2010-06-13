#IOMCore::DataFacts necesita esta tabla creada en la base de datos para
#funcionar

DROP TABLE IF EXISTS DATAFACTS;

CREATE TABLE DATAFACTS (
  ID BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
  TIPOOBJ VARCHAR(32) NOT NULL ,
  OBJ_id BIGINT NOT NULL ,
  CLAVE VARCHAR(64) NOT NULL ,
  VALOR BLOB NOT NULL ,
  TINI DATETIME NOT NULL ,
  TFIN DATETIME ,
  IDUSR VARCHAR(45) NOT NULL ,
  TIMESET TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (id) ,
  INDEX OBJID (TIPOOBJ ASC, OBJ_id ASC) )
ENGINE = InnoDB;

