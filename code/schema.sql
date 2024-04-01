BEGIN;

DROP DATABASE IF EXISTS filmsphere;
CREATE DATABASE filmsphere;
COMMIT;

USE filmsphere;
SET GLOBAL EVENT_SCHEDULER = ON;

/* -----------------------------------------------------
    Table `Stato`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Stato`;

CREATE TABLE `Stato`
(
    `codice`     VARCHAR(2) PRIMARY KEY,
    `nome`       VARCHAR(255) NOT NULL,
    `continente` VARCHAR(255) NOT NULL
);

/* -----------------------------------------------------
    Table `Artista`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Artista`;

CREATE TABLE `Artista`
(
    `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `nome`          VARCHAR(255)                    NOT NULL,
    `cognome`       VARCHAR(255)                    NOT NULL,
    `genere`        ENUM ('uomo', 'donna', 'altro') NOT NULL,
    `dataDiNascita` DATE                            NOT NULL,
    `dataDiMorte`   DATE DEFAULT NULL
);


/* -----------------------------------------------------
    Table `Film`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Film`;

CREATE TABLE `Film`
(
    `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `titolo`          VARCHAR(255)      NOT NULL,
    `descrizione`     VARCHAR(1024)     NOT NULL,
    `durata`          SMALLINT UNSIGNED NOT NULL,
    `annoProduzione`  SMALLINT UNSIGNED NOT NULL,
    `rating`          TINYINT UNSIGNED  NOT NULL DEFAULT 0,
    `numeroLike`      INT UNSIGNED      NOT NULL DEFAULT 0,
    `statoProduzione` VARCHAR(2)        NOT NULL,

    FOREIGN KEY (`statoProduzione`) REFERENCES Stato (`codice`)
);

/* -----------------------------------------------------
    Table `Interpretazione`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Interpretazione`;

CREATE TABLE `Interpretazione`
(
    `idArtista`   INT UNSIGNED,
    `idFilm`      INT UNSIGNED,
    `personaggio` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`idArtista`, `idFilm`),
    FOREIGN KEY (`idArtista`) REFERENCES Artista (`id`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`)
);


/* -----------------------------------------------------
    Table `Direzione`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Direzione`;

CREATE TABLE `Direzione`
(
    `idArtista` INT UNSIGNED,
    `idFilm`    INT UNSIGNED,
    PRIMARY KEY (`idArtista`, `idFilm`),
    FOREIGN KEY (`idArtista`) REFERENCES Artista (`id`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`)
);


/* -----------------------------------------------------
    Table `Premio`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Premio`;

CREATE TABLE `Premio`
(
    `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `nome`        VARCHAR(255)                       NOT NULL,
    `istituzione` VARCHAR(255)                       NOT NULL,
    `prestigio`   TINYINT UNSIGNED                   NOT NULL,
    `categoria`   ENUM ('film', 'attore', 'regista') NOT NULL,

    CHECK ( `prestigio` BETWEEN 1 AND 5)

);


/* -----------------------------------------------------
    Table `PremiazioneRegista`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `PremiazioneRegista`;

CREATE TABLE `PremiazioneRegista`
(
    `idArtista` INT UNSIGNED,
    `idFilm`    INT UNSIGNED,
    `idPremio`  INT UNSIGNED,
    `data`      DATE,
    PRIMARY KEY (`idArtista`, `idFilm`, `idPremio`, `data`),
    FOREIGN KEY (`idArtista`) REFERENCES Artista (`id`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`),
    FOREIGN KEY (`idPremio`) REFERENCES Premio (`id`)
);

/* -----------------------------------------------------
    Table `PremiazioneFilm`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `PremiazioneFilm`;

CREATE TABLE `PremiazioneFilm`
(
    `idFilm`   INT UNSIGNED,
    `idPremio` INT UNSIGNED,
    `data`     DATE,
    PRIMARY KEY (`idFilm`, `idPremio`, `data`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`),
    FOREIGN KEY (`idPremio`) REFERENCES Premio (`id`)
);


/* -----------------------------------------------------
    Table `PremiazioneAttore`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `PremiazioneAttore`;

CREATE TABLE `PremiazioneAttore`
(
    `idArtista` INT UNSIGNED,
    `idFilm`    INT UNSIGNED,
    `idPremio`  INT UNSIGNED,
    `data`      DATE,
    PRIMARY KEY (`idArtista`, `idFilm`, `idPremio`, `data`),
    FOREIGN KEY (`idArtista`) REFERENCES Artista (`id`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`),
    FOREIGN KEY (`idPremio`) REFERENCES Premio (`id`)
);


/* -----------------------------------------------------
    Table `Lingua`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Lingua`;

CREATE TABLE `Lingua`
(
    `codice` VARCHAR(2) PRIMARY KEY,
    `nome`   VARCHAR(255) NOT NULL
);

/* -----------------------------------------------------
    Table `Sottotitoli`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Sottotitoli`;

CREATE TABLE `Sottotitoli`
(
    `codiceLingua` VARCHAR(2),
    `idFilm`       INT UNSIGNED,
    PRIMARY KEY (`codiceLingua`, `idFilm`),
    FOREIGN KEY (`codiceLingua`) REFERENCES Lingua (`codice`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`)
);

/* -----------------------------------------------------
    Table `Audio`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Audio`;

CREATE TABLE `Audio`
(
    `codiceLingua` VARCHAR(2),
    `idFilm`       INT UNSIGNED,
    PRIMARY KEY (`codiceLingua`, `idFilm`),
    FOREIGN KEY (`codiceLingua`) REFERENCES Lingua (`codice`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`)
);


/* -----------------------------------------------------
    Table `Critico`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Critico`;

CREATE TABLE `Critico`
(
    `id`      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `nome`    VARCHAR(255) NOT NULL,
    `cognome` VARCHAR(255) NOT NULL
);

/* -----------------------------------------------------
    Table `RecensioneCritico`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `RecensioneCritico`;

CREATE TABLE `RecensioneCritico`
(
    `idCritico`   INT UNSIGNED,
    `idFilm`      INT UNSIGNED,
    `data`        DATE DEFAULT (CURRENT_DATE) NOT NULL,
    `votazione`   TINYINT UNSIGNED            NOT NULL,
    `descrizione` VARCHAR(1024)               NOT NULL,
    PRIMARY KEY (`idCritico`, `idFilm`),
    FOREIGN KEY (`idCritico`) REFERENCES Critico (`id`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`)
);

/* -----------------------------------------------------
    Table `Genere`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Genere`;

CREATE TABLE `Genere`
(
    `id`   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `nome` VARCHAR(255)
);

/* -----------------------------------------------------
    Table `Classificazione`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Classificazione`;

CREATE TABLE `Classificazione`
(
    `idGenere` INT UNSIGNED,
    `idFilm`   INT UNSIGNED,
    PRIMARY KEY (`idGenere`, `idFilm`),
    FOREIGN KEY (`idGenere`) REFERENCES Genere (`id`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`)
);


/* -----------------------------------------------------
    Table `Utente`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Utente`;

CREATE TABLE `Utente`
(
    `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `nome`          VARCHAR(255) NOT NULL,
    `cognome`       VARCHAR(255) NOT NULL,
    `mail`          VARCHAR(255) NOT NULL UNIQUE,
    `password`      VARCHAR(255) NOT NULL,
    `nazionalita`   VARCHAR(2)   NOT NULL,
    `dataDiNascita` DATE         NOT NULL,
    FOREIGN KEY (`nazionalita`) REFERENCES Stato (`codice`)

);

/* -----------------------------------------------------
    Table `RecensioneUtente`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `RecensioneUtente`;

CREATE TABLE `RecensioneUtente`
(
    `idUtente`  INT UNSIGNED,
    `idFilm`    INT UNSIGNED,
    `data`      DATE DEFAULT (CURRENT_DATE) NOT NULL,
    `votazione` BOOL                        NOT NULL,
    PRIMARY KEY (`idUtente`, `idFilm`),
    FOREIGN KEY (`idUtente`) REFERENCES Utente (`id`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`)
);


/* -----------------------------------------------------
    Table `Pacchetto`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Pacchetto`;

CREATE TABLE `Pacchetto`
(
    `nome`      VARCHAR(255) PRIMARY KEY,
    `durata`    SMALLINT UNSIGNED NOT NULL,
    `etaMinima` TINYINT UNSIGNED,
    `tariffa`   FLOAT             NOT NULL,
    CHECK (`etaMinima` BETWEEN 14 AND 18)
);


/* -----------------------------------------------------
    Table `Abbonamento`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Abbonamento`;

CREATE TABLE `Abbonamento`
(
    `idUtente`           INT UNSIGNED PRIMARY KEY,
    `stato`              ENUM ('attivo','interrotto') NOT NULL DEFAULT 'attivo',
    `giornoFatturazione` TINYINT UNSIGNED             NOT NULL,
    `costoMensile`       FLOAT                        NOT NULL DEFAULT 0,
    `nomePacchetto`      VARCHAR(255)                 NOT NULL,

    FOREIGN KEY (`nomePacchetto`) REFERENCES Pacchetto (`nome`)

);


/* -----------------------------------------------------
    Table `FunzionalitaExtra`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `FunzionalitaExtra`;

CREATE TABLE `FunzionalitaExtra`
(
    `nome`    VARCHAR(255) PRIMARY KEY,
    `tariffa` FLOAT NOT NULL
);


/* -----------------------------------------------------
    Table `OffertaFunzionalita`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `OffertaFunzionalita`;

CREATE TABLE `OffertaFunzionalita`
(
    `idUtente`         INT UNSIGNED,
    `nomeFunzionalita` VARCHAR(255),
    PRIMARY KEY (`idUtente`, `nomeFunzionalita`),
    FOREIGN KEY (`idUtente`) REFERENCES Abbonamento (`idUtente`),
    FOREIGN KEY (`nomeFunzionalita`) REFERENCES FunzionalitaExtra (`nome`)

);


/* -----------------------------------------------------
    Table `Compatibilita`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Compatibilita`;

CREATE TABLE `Compatibilita`
(
    `idFilm`                   INT UNSIGNED,
    `idUtente`                 INT UNSIGNED,
    `percentualeCompatibilita` DECIMAL(4, 1) NOT NULL DEFAULT 50,
    PRIMARY KEY (`idFilm`, `idUtente`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`),
    FOREIGN KEY (`idUtente`) REFERENCES Utente (`id`),
    CHECK (`percentualeCompatibilita` BETWEEN 0 AND 100)

);

/* -----------------------------------------------------
    Table `CartaDiPagamento`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `CartaDiPagamento`;

CREATE TABLE `CartaDiPagamento`
(
    `numero`       VARCHAR(19) PRIMARY KEY,
    `scadenza`     DATE                                                                                   NOT NULL,
    `circuito`     ENUM ('visa','mastercard', 'maestro', 'american express','discovery','jcb','unionpay') NOT NULL,
    `intestatario` VARCHAR(255)                                                                           NOT NULL
);


/* -----------------------------------------------------
    Table `Fattura`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Fattura`;

CREATE TABLE `Fattura`
(
    `codice`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `dataEmissione`    DATE         NOT NULL DEFAULT (CURRENT_DATE),
    `dataScadenza`     DATE         NOT NULL DEFAULT (CURRENT_DATE + INTERVAL 1 MONTH),
    `importo`          FLOAT        NOT NULL,
    `idUtente`         INT UNSIGNED NOT NULL,
    `dataSaldo`        DATE                  DEFAULT NULL,
    `numeroCartaSaldo` VARCHAR(19)           DEFAULT NULL,

    FOREIGN KEY (`idUtente`) REFERENCES Utente (`id`),
    FOREIGN KEY (`numeroCartaSaldo`) REFERENCES CartaDiPagamento (`numero`),
    CHECK ( `dataScadenza` > `dataEmissione`),
    CHECK ( `dataSaldo` >= `dataEmissione`),
    CHECK ((`dataSaldo` IS NULL AND `numeroCartaSaldo` IS NULL) OR
           (`dataSaldo` IS NOT NULL AND `numeroCartaSaldo` IS NOT NULL))
);


/* -----------------------------------------------------
    Table `MetodoDiPagamento`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `MetodoDiPagamento`;

CREATE TABLE `MetodoDiPagamento`
(
    `idUtente`    INT UNSIGNED,
    `numeroCarta` VARCHAR(19),
    PRIMARY KEY (`idUtente`, `numeroCarta`),
    FOREIGN KEY (`idUtente`) REFERENCES Utente (`id`),
    FOREIGN KEY (`numeroCarta`) REFERENCES CartaDiPagamento (`numero`)
);


/* -----------------------------------------------------
    Table `RestrizionePacchetto`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `RestrizionePacchetto`;

CREATE TABLE `RestrizionePacchetto`
(
    `codiceStato`   VARCHAR(2),
    `nomePacchetto` VARCHAR(255),
    PRIMARY KEY (`codiceStato`, `nomePacchetto`),
    FOREIGN KEY (`codiceStato`) REFERENCES Stato (`codice`),
    FOREIGN KEY (`nomePacchetto`) REFERENCES Pacchetto (`nome`)
);


/* -----------------------------------------------------
    Table `Dispositivo`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Dispositivo`;

CREATE TABLE `Dispositivo`
(
    `ipAddress`        VARCHAR(15) PRIMARY KEY,
    `versione`         VARCHAR(10)                              NOT NULL,
    `sistemaOperativo` VARCHAR(255)                             NOT NULL,
    `nome`             VARCHAR(255)                             NOT NULL,
    `macAddress`       VARCHAR(17)                              NOT NULL,
    `tipo`             ENUM ('tablet', 'smartphone', 'desktop') NOT NULL,

    CHECK (IS_IPV4(`ipAddress`)),
    CHECK (`macAddress` REGEXP '^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$')
);


/* -----------------------------------------------------
    Table `Connessione`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Connessione`;

CREATE TABLE `Connessione`
(
    `ipDispositivo` VARCHAR(15),
    `inizio`        TIMESTAMP,
    `idUtente`      INT UNSIGNED,
    `fine`          TIMESTAMP DEFAULT NULL,
    `longitudine`   FLOAT NOT NULL,
    `latitudine`    FLOAT NOT NULL,

    PRIMARY KEY (`ipDispositivo`, `inizio`, `idUtente`),
    FOREIGN KEY (`idUtente`) REFERENCES Utente (`id`),
    FOREIGN KEY (`ipDispositivo`) REFERENCES Dispositivo (`ipAddress`),
    CHECK ((`longitudine` BETWEEN -180 AND 180) AND (`latitudine` BETWEEN -90 AND 90)),
    CHECK ( `fine` >= `inizio` )

);


/* -----------------------------------------------------
    Table `Formato`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Formato`;

CREATE TABLE `Formato`
(
    `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `nome`       VARCHAR(255) NOT NULL,
    `versione`   VARCHAR(255) NOT NULL,
    `estensione` VARCHAR(255) NOT NULL
);

/* -----------------------------------------------------
    Table `Codec`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Codec`;

CREATE TABLE `Codec`
(
    `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `nome`         VARCHAR(255)            NOT NULL,
    `compressione` VARCHAR(255)            NOT NULL,
    `versione`     VARCHAR(255)            NOT NULL,
    `tipologia`    ENUM ('audio', 'video') NOT NULL
);


/* -----------------------------------------------------
    Table `Contenuto`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Contenuto`;

CREATE TABLE `Contenuto`
(
    `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `dimensione`      FLOAT                             NOT NULL,
    `aspectRateo`     VARCHAR(255)                      NOT NULL,
    `risoluzione`     ENUM ('HD', 'FHD', 'UHD', 'FUHD') NOT NULL,
    `bitrate`         FLOAT                             NOT NULL,
    `watchtime`       INT UNSIGNED                      NOT NULL DEFAULT 0,
    `visualizzazioni` INT UNSIGNED                      NOT NULL DEFAULT 0,
    `idFilm`          INT UNSIGNED                      NOT NULL,
    `idFormato`       INT UNSIGNED                      NOT NULL,
    `idCodecAudio`    INT UNSIGNED                      NOT NULL,
    `idCodecVideo`    INT UNSIGNED                      NOT NULL,
    `dataRilascio`    DATE                              NOT NULL,

    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`),
    FOREIGN KEY (`idFormato`) REFERENCES Formato (`id`),
    FOREIGN KEY (`idCodecAudio`) REFERENCES Codec (`id`),
    FOREIGN KEY (`idCodecVideo`) REFERENCES Codec (`id`)
);

/* -----------------------------------------------------
    Table `RestrizioneContenuto`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `RestrizioneContenuto`;

CREATE TABLE `RestrizioneContenuto`
(
    `idContenuto` INT UNSIGNED,
    `codiceStato` VARCHAR(2),
    PRIMARY KEY (`idContenuto`, `codiceStato`),
    FOREIGN KEY (`idContenuto`) REFERENCES Contenuto (`id`),
    FOREIGN KEY (`codiceStato`) REFERENCES Stato (`codice`)
);


/* -----------------------------------------------------
    Table `Server`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Server`;

CREATE TABLE `Server`
(
    `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `memoriaUsata` FLOAT                   NOT NULL DEFAULT 0,
    `bandaUsata`   FLOAT                   NOT NULL DEFAULT 0,
    `memoriaMax`   FLOAT                   NOT NULL,
    `bandaMax`     FLOAT                   NOT NULL,
    `tipo`         ENUM ('edge', 'origin') NOT NULL,
    `ipAddress`    VARCHAR(15)             NOT NULL,
    `latitudine`   FLOAT                   NOT NULL,
    `longitudine`  FLOAT                   NOT NULL,
    `localita`     VARCHAR(2)              NOT NULL,
    FOREIGN KEY (`localita`) REFERENCES Stato (`codice`),

    CHECK ((`longitudine` BETWEEN -180 AND 180) AND (`latitudine` BETWEEN -90 AND 90)),
    CHECK (IS_IPV4(`ipAddress`)),
    CHECK (`bandaUsata` <= `bandaMax`),
    CHECK (`memoriaUsata` <= `memoriaMax`)

);


/* -----------------------------------------------------
    Table `Archiviazione`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Archiviazione`;

CREATE TABLE `Archiviazione`
(
    `idContenuto` INT UNSIGNED,
    `idServer`    INT UNSIGNED,
    PRIMARY KEY (`idContenuto`, `idServer`),
    FOREIGN KEY (`idContenuto`) REFERENCES Contenuto (`id`),
    FOREIGN KEY (`idServer`) REFERENCES Server (`id`)
);


/* -----------------------------------------------------
    Table `Erogazione`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Erogazione`;

CREATE TABLE `Erogazione`
(
    `id`                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `inizio`            TIMESTAMP         DEFAULT NOW() NOT NULL,
    `fine`              TIMESTAMP         DEFAULT NULL,
    `minutiVisti`       SMALLINT UNSIGNED DEFAULT NULL,
    `idContenuto`       INT UNSIGNED                    NOT NULL,
    `ipDispositivo`     VARCHAR(15)                     NOT NULL,
    `inizioConnessione` TIMESTAMP                       NOT NULL,
    `idUtente`          INT UNSIGNED                    NOT NULL,
    FOREIGN KEY (`idContenuto`) REFERENCES Contenuto (`id`),
    FOREIGN KEY (ipDispositivo, inizioConnessione, idUtente) REFERENCES Connessione (`ipDispositivo`, `inizio`, `idUtente`),
    CHECK ( `fine` >= `inizio` AND `inizio` >= `inizioConnessione`),
    CHECK ((`fine` IS NULL AND `minutiVisti` IS NULL) OR
           (`fine` IS NOT NULL AND `minutiVisti` IS NOT NULL))
#     CHECK (`minutiVisti` <= TIMESTAMPDIFF(MINUTE, inizio, fine)) DISABILITATO AI FINI DEL TESTING


);


/* -----------------------------------------------------
    Table `Collegamento`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `Collegamento`;

CREATE TABLE `Collegamento`
(
    `idErogazione` INT UNSIGNED,
    `idServer`     INT UNSIGNED,
    `stato`        ENUM ('attivo', 'interrotto', 'terminato') NOT NULL DEFAULT 'attivo',
    PRIMARY KEY (`idErogazione`, `idServer`),
    FOREIGN KEY (`idErogazione`) REFERENCES Erogazione (`id`),
    FOREIGN KEY (`idServer`) REFERENCES Server (`id`)
);


/* -----------------------------------------------------
    Table `ServerLog`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `ServerLog`;

CREATE TABLE `ServerLog`
(
    `id`        INT UNSIGNED AUTO_INCREMENT                                                                                            NOT NULL PRIMARY KEY,
    `timestamp` TIMESTAMP                                                                                                              NOT NULL DEFAULT NOW(),
    `idServer`  INT UNSIGNED,
    `criticita` ENUM ('info', 'warning', 'error')                                                                                      NOT NULL,
    `codice`    ENUM ('excessive load','excessive memory usage','server startup','server shutdown','server status', 'streaming error') NOT NULL,
    `messaggio` VARCHAR(1024)                                                                                                          NOT NULL,
    FOREIGN KEY (`idServer`) REFERENCES Server (`id`)
);

/* -----------------------------------------------------
    Table `ClassificaGenere`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `ClassificaGenere`;

CREATE TABLE `ClassificaGenere`
(
    `idFilm`    INT UNSIGNED,
    `idGenere`  INT UNSIGNED,
    `settimana` SMALLINT UNSIGNED,
    `anno`      SMALLINT UNSIGNED,
    `posizione` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`idFilm`, `idGenere`, `settimana`, `anno`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`),
    FOREIGN KEY (`idGenere`) REFERENCES Genere (`id`),
    CHECK ( `settimana` BETWEEN 1 AND 53)
);

/* -----------------------------------------------------
    Table `ClassificaStato`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `ClassificaStato`;

CREATE TABLE `ClassificaStato`
(
    `idFilm`      INT UNSIGNED,
    `codiceStato` VARCHAR(2),
    `settimana`   SMALLINT UNSIGNED,
    `anno`        SMALLINT UNSIGNED,
    `posizione`   SMALLINT UNSIGNED NOT NULL,
    `risoluzione` VARCHAR(255)      NOT NULL,
    PRIMARY KEY (`idFilm`, `codiceStato`, `settimana`, `anno`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`),
    FOREIGN KEY (`codiceStato`) REFERENCES Stato (`codice`),
    CHECK ( `settimana` BETWEEN 1 AND 53)
);

/* -----------------------------------------------------
    Table `ClassificaPacchetto`
   ----------------------------------------------------- */
DROP TABLE IF EXISTS `ClassificaPacchetto`;

CREATE TABLE `ClassificaPacchetto`
(
    `idFilm`        INT UNSIGNED,
    `nomePacchetto` VARCHAR(255),
    `settimana`     SMALLINT UNSIGNED,
    `anno`          SMALLINT UNSIGNED,
    `posizione`     SMALLINT UNSIGNED NOT NULL,
    `risoluzione`   VARCHAR(255)      NOT NULL,
    PRIMARY KEY (`idFilm`, `nomePacchetto`, `settimana`, `anno`),
    FOREIGN KEY (`idFilm`) REFERENCES Film (`id`),
    FOREIGN KEY (`nomePacchetto`) REFERENCES Pacchetto (`nome`),
    CHECK ( `settimana` BETWEEN 1 AND 53)
);






















