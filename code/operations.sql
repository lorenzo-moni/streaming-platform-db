USE filmsphere;

-- -------------OPERAZIONE 1----------------------
-- Registrazione Utente e Creazione Abbonamento
-- -----------------------------------------------

DROP PROCEDURE IF EXISTS registrazioneUtente;
DELIMITER $$

CREATE PROCEDURE registrazioneUtente(IN nome_ VARCHAR(255), IN cognome_ VARCHAR(255), IN mail_ VARCHAR(255),
                                     IN password_ VARCHAR(255),
                                     IN nazionalita_ VARCHAR(2), IN dataDiNascita_ DATE, IN nomePacchetto_ VARCHAR(255),
                                     IN numeroCarta_ VARCHAR(19),
                                     IN scadenzaCarta_ DATE, IN circuitoCarta_ VARCHAR(255),
                                     IN intestatario_ VARCHAR(255), OUT idUtente_ INT UNSIGNED)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK; -- Annulla tutte le operazioni in caso di errore
            RESIGNAL;
        END;
    START TRANSACTION;


    INSERT INTO Utente(nome, cognome, mail, password, nazionalita, dataDiNascita)
    VALUES (nome_, cognome_, mail_, password_, nazionalita_, dataDiNascita_);

    SELECT LAST_INSERT_ID() INTO idUtente_;

    IF NOT EXISTS(SELECT 1
                  FROM CartaDiPagamento CDP
                  WHERE CDP.numero = numeroCarta_
                    AND CDP.scadenza = scadenzaCarta_
                    AND CDP.circuito = circuitoCarta_
                    AND CDP.intestatario = intestatario_)
    THEN
        INSERT INTO CartaDiPagamento(numero, scadenza, circuito, intestatario)
        VALUES (numeroCarta_, scadenzaCarta_, circuitoCarta_, intestatario_);
    END IF;

    INSERT INTO MetodoDiPagamento(idUtente, numeroCarta) VALUES (idUtente_, numeroCarta_);

    INSERT INTO Abbonamento (nomePacchetto, idUtente, giornoFatturazione)
    VALUES (nomePacchetto_, idUtente_, DAY(CURRENT_DATE));
    COMMIT;


    -- Se si vuole aggiungere una funzionalità extra verrà chiamata
-- la funzione "AggiuntaFunzionalitaExtra" per ogni funzionalità extra da aggiungere

END $$
DELIMITER ;

-- -------------OPERAZIONE-----------------------
--           AggiuntaFunzionalitaExtra
-- -----------------------------------------------

DROP PROCEDURE IF EXISTS aggiuntaFunzionalitaExtra;
DELIMITER $$

CREATE PROCEDURE aggiuntaFunzionalitaExtra(IN idUtente_ INT UNSIGNED, IN nome_ VARCHAR(255))
BEGIN

    INSERT INTO OffertaFunzionalita
    VALUES (idUtente_, nome_);

END $$
DELIMITER ;


-- -------------OPERAZIONE 2----------------------
--               Login Utente
-- -----------------------------------------------

DROP PROCEDURE IF EXISTS loginUtente;
DELIMITER $$

CREATE PROCEDURE loginUtente(IN mail_ VARCHAR(255), IN password_ VARCHAR(255), IN ipAddress_ VARCHAR(15),
                             IN versione_ VARCHAR(10), IN sistemaOperativo_ VARCHAR(255),
                             IN nome_ VARCHAR(255), IN macAddress_ VARCHAR(17), IN tipo_ VARCHAR(255),
                             IN latitudine_ FLOAT, IN longitudine_ FLOAT, OUT idUtente_ INT UNSIGNED)
BEGIN


    DECLARE mailUtente_ VARCHAR(255);
    DECLARE passwordUtente_ VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK; -- Annulla tutte le operazioni in caso di errore
            RESIGNAL;
        END;
    START TRANSACTION;

    IF NOT EXISTS(SELECT 1
                  FROM Utente U
                  WHERE U.mail = mail_) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Mail inserita non esistente';
    END IF;

    SELECT U.id, U.mail, U.password
    INTO idUtente_,mailUtente_,passwordUtente_
    FROM Utente U
    WHERE U.mail = mail_;

    IF (passwordUtente_ <> password_) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Password Errata';
    END IF;

    IF EXISTS(SELECT 1
              FROM Connessione C
              WHERE C.idUtente = idUtente_
                AND C.fine IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Utente già loggato';
    END IF;

    INSERT INTO Dispositivo
    VALUES (ipAddress_, versione_, sistemaOperativo_, nome_, macAddress_, tipo_)
    ON DUPLICATE KEY UPDATE versione = versione_, sistemaOperativo = sistemaOperativo_, nome = nome_;

    INSERT INTO Connessione (ipDispositivo, inizio, idUtente, longitudine, latitudine)
    VALUES (ipAddress_, NOW(), idUtente_, longitudine_, latitudine_);
    COMMIT;


END $$
DELIMITER ;


-- -------------OPERAZIONE 3----------------------
--      Emissione Fatture con ridondanza
-- -----------------------------------------------


DROP PROCEDURE IF EXISTS emissioneFatture;
DELIMITER $$

CREATE PROCEDURE emissioneFatture(IN day_ INT)
BEGIN

    DECLARE finito INT DEFAULT 0;
    DECLARE idUtente_ INT UNSIGNED;
    DECLARE costoTotale_ FLOAT DEFAULT 0;


    DECLARE Fatture CURSOR FOR
        SELECT A.idUtente, A.costoMensile
        FROM Abbonamento A
        WHERE A.giornoFatturazione = day_;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finito = 1;

    OPEN Fatture;

    scan:
    LOOP

        FETCH Fatture INTO idUtente_,costoTotale_;

        IF finito = 1 THEN
            LEAVE scan;
        END IF;

        INSERT INTO Fattura(importo, idUtente) VALUES (costoTotale_, idUtente_);

    END LOOP scan;

    CLOSE Fatture;

END $$
DELIMITER ;


-- -------------OPERAZIONE 3----------------------
--      Aggiornamento ridondanza
-- -----------------------------------------------

-- TRIGGER PER LA REGISTRAZIONE DI UN NUOVO UTENTE

DELIMITER $$
DROP TRIGGER IF EXISTS aggiuntaCostoMensile $$

CREATE TRIGGER aggiuntaCostoMensile
    BEFORE INSERT
    ON Abbonamento
    FOR EACH ROW

BEGIN
    DECLARE costoPacchetto_ FLOAT;

    SELECT P.tariffa
    INTO costoPacchetto_
    FROM Pacchetto P
    WHERE P.nome = NEW.nomePacchetto;

    SET NEW.costoMensile = costoPacchetto_;

END $$
DELIMITER ;


-- TRIGGER PER L'AGGIUNTA DI UNA FUNZIONALITA EXTRA ALL'ABBONAMENTO

DELIMITER $$
DROP TRIGGER IF EXISTS aggiuntaCostoFunzionalita;

CREATE TRIGGER aggiuntaCostoFunzionalita
    AFTER INSERT
    ON OffertaFunzionalita
    FOR EACH ROW
BEGIN
    DECLARE costoPrecedente_ FLOAT;
    DECLARE costoNuovaFunzionalita_ FLOAT;

    SELECT F.tariffa
    INTO costoNuovaFunzionalita_
    FROM FunzionalitaExtra F
    WHERE F.nome = NEW.nomeFunzionalita;


    SELECT A.costoMensile
    INTO costoPrecedente_
    FROM Abbonamento A
    WHERE NEW.idUtente = A.idUtente;

    UPDATE Abbonamento
    SET costoMensile = (costoPrecedente_ + costoNuovaFunzionalita_)
    WHERE idUtente = NEW.idUtente;

END $$
DELIMITER ;

-- TRIGGER PER LA RIMOZIONE DI UNA FUNZIONALITA EXTRA ALL'ABBONAMENTO

DELIMITER $$
DROP TRIGGER IF EXISTS sottrazioneCostoFunzionalita;

CREATE TRIGGER sottrazioneCostoFunzionalita
    AFTER DELETE
    ON OffertaFunzionalita
    FOR EACH ROW
BEGIN
    DECLARE costoPrecedente_ FLOAT;
    DECLARE costoNuovaFunzionalita_ FLOAT;

    SELECT F.tariffa
    INTO costoNuovaFunzionalita_
    FROM FunzionalitaExtra F
    WHERE F.nome = OLD.nomeFunzionalita;


    SELECT A.costoMensile
    INTO costoPrecedente_
    FROM Abbonamento A
    WHERE OLD.idUtente = A.idUtente;

    UPDATE Abbonamento
    SET costoMensile = (costoPrecedente_ - costoNuovaFunzionalita_)
    WHERE idUtente = OLD.idUtente;

END $$
DELIMITER ;

-- PROCEDURA PER SALDARE UNA FATTURA

DROP PROCEDURE IF EXISTS SaldaFattura;
DELIMITER $$

CREATE PROCEDURE SaldaFattura(IN codiceFattura_ INT UNSIGNED, IN numeroCartaSaldo_ VARCHAR(19),
                              IN idUtente_ INT UNSIGNED)
BEGIN
    DECLARE costoAggiuntivo_ FLOAT DEFAULT 0;

    IF (SELECT idUtente FROM Fattura F WHERE F.codice = codiceFattura_) <> idUtente_ THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile saldare una fattura relativa ad un altro utente';
    END IF;

    -- se la fattura è scaduta c'è un sovrapprezzo di 20 euro sull'importo
    IF EXISTS (SELECT 1
               FROM Fattura F
               WHERE F.codice = codiceFattura_
                 AND F.dataScadenza < CURRENT_DATE) THEN
        SET costoAggiuntivo_ = 20;
    END IF;

    UPDATE Fattura
    SET numeroCartaSaldo=numeroCartaSaldo_,
        dataSaldo= CURRENT_DATE,
        importo=importo + costoAggiuntivo_
    WHERE idUtente = idUtente_
      AND codice = codiceFattura_;

END $$


/*------------------------------
  EVENT per EmissioneFatture
 ------------------------------*/

DROP EVENT IF EXISTS AggiornaEmissioneFatture;

CREATE EVENT AggiornaEmissioneFatture
    ON SCHEDULE EVERY 1 DAY STARTS '2023-09-08 00:00:00' ON COMPLETION PRESERVE DO
    CALL emissioneFatture(DAY(CURRENT_DATE));



-- -------------OPERAZIONE 4----------------------
--      Richiesta Visualizzazione Contenuto
-- -----------------------------------------------

DROP PROCEDURE IF EXISTS VisualizzazioneContenuto;
DELIMITER $$

CREATE PROCEDURE VisualizzazioneContenuto(IN idUtente_ INT UNSIGNED, IN idContenuto_ INT UNSIGNED)
BEGIN

    DECLARE ipAddress_ VARCHAR(15);
    DECLARE inizioConnessione_ TIMESTAMP;
    DECLARE latitudine_ FLOAT;
    DECLARE longitudine_ FLOAT;
    DECLARE idErogazione_ INT UNSIGNED;
    DECLARE bestServerId_ INT UNSIGNED;
    DECLARE erogazioniAttive_ INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK; -- Annulla tutte le operazioni in caso di errore
            RESIGNAL;
        END;
    START TRANSACTION;

    -- controllo sul contenuto
    IF NOT EXISTS(SELECT 1 FROM Contenuto C WHERE C.id = idContenuto_) OR idContenuto_ IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Contenuto non presente sulla piattaforma';
    END IF;

    -- controllo sull'abbonamento attivo
    IF NOT EXISTS(SELECT 1
                  FROM Abbonamento
                  WHERE idUtente = idUtente_
                    AND stato = 'attivo') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abbonamento non attivo';
    END IF;

    -- controllo sulla connessione dell'utente
    IF NOT EXISTS(SELECT 1
                  FROM Connessione C
                  WHERE C.idUtente = idUtente_
                    AND C.fine IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Utente non loggato sulla piattaforma';
    END IF;

    -- vari controlli sulla risoluzione del contenuto e sulle condizioni dell'abbonamento attivo

    IF EXISTS (SELECT 1
               FROM Contenuto C
               WHERE C.id = idContenuto_
                 AND C.risoluzione = 'FUHD')
    THEN
        IF NOT EXISTS (SELECT 1
                       FROM OffertaFunzionalita O
                       WHERE O.nomeFunzionalita = '8K'
                         AND O.idUtente = idUtente_) OR (SELECT 1
                                                         FROM Abbonamento A
                                                         WHERE A.idUtente = idUtente_
                                                           AND A.nomePacchetto = 'ultimate') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Contenuto non disponibile con l\'abbonamento attivo in questo momento';
        END IF;
    END IF;

    IF EXISTS (SELECT 1
               FROM Contenuto C
               WHERE C.id = idContenuto_
                 AND C.risoluzione = 'UHD')
    THEN
        IF NOT EXISTS (SELECT 1
                       FROM OffertaFunzionalita O
                       WHERE O.nomeFunzionalita IN ('8K', '4K')
                         AND O.idUtente = idUtente_) OR (SELECT 1
                                                         FROM Abbonamento A
                                                         WHERE A.idUtente = idUtente_
                                                           AND A.nomePacchetto IN ('ultimate', 'deluxe')) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Contenuto non disponibile con l\'abbonamento attivo in questo momento';
        END IF;
    END IF;

    SELECT COUNT(*)
    INTO erogazioniAttive_
    FROM Erogazione E
    WHERE E.idUtente = idUtente_
      AND E.fine IS NULL;

    IF erogazioniAttive_ <> 0 AND (SELECT A.nomePacchetto
                                   FROM Abbonamento A
                                   WHERE A.idUtente = idUtente_) = 'basic' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Contenuto non disponibile con l\'abbonamento attivo in questo momento (troppi collegamenti attivi in contemporanea)';
    END IF;

    IF erogazioniAttive_ > 1 AND (SELECT A.nomePacchetto
                                  FROM Abbonamento A
                                  WHERE A.idUtente = idUtente_) = 'premium' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Contenuto non disponibile con l\'abbonamento attivo in questo momento (troppi collegamenti attivi in contemporanea)';
    END IF;

    IF erogazioniAttive_ > 3 AND (SELECT A.nomePacchetto
                                  FROM Abbonamento A
                                  WHERE A.idUtente = idUtente_) = 'pro' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Contenuto non disponibile con l\'abbonamento attivo in questo momento (troppi collegamenti attivi in contemporanea)';
    END IF;

    IF erogazioniAttive_ > 7 AND (SELECT A.nomePacchetto
                                  FROM Abbonamento A
                                  WHERE A.idUtente = idUtente_) = 'deluxe' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Contenuto non disponibile con l\'abbonamento attivo in questo momento (troppi collegamenti attivi in contemporanea)';
    END IF;


    SELECT C.ipDispositivo, C.inizio, C.longitudine, C.latitudine
    INTO ipAddress_,inizioConnessione_,longitudine_,latitudine_
    FROM Connessione C
    WHERE C.idUtente = idUtente_
      AND C.fine IS NULL;

    INSERT INTO Erogazione(idContenuto, ipDispositivo, inizioConnessione, idUtente)
    VALUES (idContenuto_, ipAddress_, inizioConnessione_, idUtente_);

    SET idErogazione_ = LAST_INSERT_ID();

-- Adesso si richiama la funzionalità che trova il server più opportuno

    CALL BestServer(idContenuto_, latitudine_, longitudine_, NULL, bestServerId_);


    IF NOT EXISTS(SELECT 1 FROM Archiviazione A WHERE A.idServer = bestServerId_ AND A.idContenuto = idContenuto_) THEN
        CALL trasferisciContenuto(bestServerId_, idContenuto_);
    END IF;

    INSERT INTO Collegamento(idErogazione, idServer) VALUES (idErogazione_, bestServerId_);
    COMMIT;

END $$
DELIMITER ;


-- -------------OPERAZIONE 4----------------------
--      Aggiornamento ridondanze
-- -----------------------------------------------


-- TRIGGER CHE MANTIENE AGGIORNATA LA BANDA USATA PER L'AGGIUNTA DI UN EROGAZIONE

DELIMITER $$
DROP TRIGGER IF EXISTS aggiornamentoBanda;

CREATE TRIGGER aggiornamentoBanda
    AFTER INSERT
    ON Collegamento
    FOR EACH ROW
BEGIN
    DECLARE bandaErogazione_ FLOAT;

    SELECT C.bitrate
    INTO bandaErogazione_
    FROM Erogazione E
             INNER JOIN Contenuto C ON E.idContenuto = C.id
    WHERE new.idErogazione = E.id;

    UPDATE Server
    SET bandaUsata = bandaUsata + bandaErogazione_
    WHERE id = NEW.idServer;

END $$
DELIMITER ;


-- TRIGGER CHE MANTIENE AGGIORNATA LA BANDA USATA PER LA FINE DI UN EROGAZIONE

DELIMITER $$
DROP TRIGGER IF EXISTS aggiornamentoBandaFine;

CREATE TRIGGER aggiornamentoBandaFine
    AFTER UPDATE
    ON Erogazione
    FOR EACH ROW
BEGIN


    IF (NEW.fine IS NOT NULL AND OLD.fine IS NULL) THEN

        UPDATE Collegamento
        SET stato = 'terminato'
        WHERE idErogazione = NEW.id
          AND stato = 'attivo';

    END IF;

END $$
DELIMITER ;


-- TRIGGER CHE MANTIENE AGGIORNATA LA BANDA USATA PER IL CAMBIO DI UN COLLEGAMENTO

DELIMITER $$
DROP TRIGGER IF EXISTS aggiornamentoBandaCambioCollegamento;

CREATE TRIGGER aggiornamentoBandaCambioCollegamento
    AFTER UPDATE
    ON Collegamento
    FOR EACH ROW
BEGIN
    DECLARE bandaErogazione_ FLOAT;

    IF (NEW.stato <> 'attivo' AND OLD.stato = 'attivo') THEN

        SELECT C.bitrate
        INTO bandaErogazione_
        FROM Contenuto C
                 INNER JOIN Erogazione E ON C.id = E.idContenuto
        WHERE E.id = NEW.idErogazione;


        UPDATE Server
        SET bandaUsata = bandaUsata - bandaErogazione_
        WHERE id = NEW.idServer;


    END IF;

END $$
DELIMITER ;

-- TRIGGER CHE MANTIENE AGGIORNATA LA BANDA USATA PER L'eliminazione di un collegamento

DELIMITER $$
DROP TRIGGER IF EXISTS aggiornamentoBandaEliminazioneCollegamento;

CREATE TRIGGER aggiornamentoBandaEliminazioneCollegamento
    AFTER DELETE
    ON Collegamento
    FOR EACH ROW
BEGIN
    DECLARE bandaErogazione_ FLOAT;

    IF (OLD.stato = 'attivo') THEN
        SELECT C.bitrate
        INTO bandaErogazione_
        FROM Contenuto C
                 INNER JOIN Erogazione E ON C.id = E.idContenuto
        WHERE E.id = OLD.idErogazione;


        UPDATE Server
        SET bandaUsata = bandaUsata - bandaErogazione_
        WHERE id = OLD.idServer;


    END IF;

END $$
DELIMITER ;


-- TRIGGER CHE MANTIENE AGGIORNATA LA MEMORIA USATA IN CASO DI AGGIUNTA CONTENUTO

DELIMITER $$
DROP TRIGGER IF EXISTS aggiornamentoMemoriaAggiunta;

CREATE TRIGGER aggiornamentoMemoriaAggiunta
    AFTER INSERT
    ON Archiviazione
    FOR EACH ROW
BEGIN
    DECLARE dimensioniNuovoContenuto_ FLOAT;

    SELECT C.dimensione
    INTO dimensioniNuovoContenuto_
    FROM Contenuto C
    WHERE C.id = NEW.idContenuto;

    UPDATE Server
    SET memoriaUsata = memoriaUsata + dimensioniNuovoContenuto_
    WHERE id = NEW.idServer;


END $$
DELIMITER ;

-- TRIGGER CHE MANTIENE AGGIORNATA LA MEMORIA USATA IN CASO DI ELIMINAZIONE CONTENUTO

DELIMITER $$
DROP TRIGGER IF EXISTS aggiornamentoMemoriaEliminazione;

CREATE TRIGGER aggiornamentoMemoriaEliminazione
    AFTER DELETE
    ON Archiviazione
    FOR EACH ROW
BEGIN
    DECLARE dimensioniVecchioContenuto_ FLOAT;

    SELECT C.dimensione
    INTO dimensioniVecchioContenuto_
    FROM Contenuto C
    WHERE C.id = OLD.idContenuto;

    UPDATE Server
    SET memoriaUsata = memoriaUsata - dimensioniVecchioContenuto_
    WHERE id = OLD.idServer;


END $$
DELIMITER ;


-- -------------OPERAZIONE 5----------------------
--           Aggiornamento rating
-- -----------------------------------------------


DROP PROCEDURE IF EXISTS AggiornamentoRating;
DELIMITER $$

CREATE PROCEDURE AggiornamentoRating()
BEGIN
    DECLARE finito INT DEFAULT 0;
    DECLARE totaleVisualizzazioni_ INT DEFAULT 0;
    DECLARE totaleWatchTime_ INT DEFAULT 0;
    DECLARE PremiFilm_ FLOAT DEFAULT 0;
    DECLARE PremiAttori_ FLOAT DEFAULT 0;
    DECLARE PremiRegisti_ FLOAT DEFAULT 0;
    DECLARE PremiCast_ FLOAT DEFAULT 0;
    DECLARE idFilm_ INT UNSIGNED;
    DECLARE numeroLike_ INT UNSIGNED;
    DECLARE durata_ INT UNSIGNED;
    DECLARE RecensioniCritici_ FLOAT DEFAULT 0;


    DECLARE ratingCursor CURSOR FOR
        SELECT id
        FROM Film;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finito = 1;


    OPEN ratingCursor;

    scan:
    LOOP

        FETCH ratingCursor INTO IdFilm_;

        IF finito = 1 THEN
            LEAVE scan;
        END IF;

        SELECT F.numeroLike, SUM(C.visualizzazioni) AS views, SUM(C.watchtime) AS WatchTimeTotale, F.durata
        INTO numeroLike_,totaleVisualizzazioni_,totaleWatchTime_, durata_
        FROM Film F
                 INNER JOIN Contenuto C ON F.id = C.idFilm
        WHERE F.id = idFilm_
        GROUP BY F.id, F.numeroLike, F.durata;

        SELECT IF(COUNT(*) = 0, 0, SUM(P.prestigio) / (COUNT(*) * 5))
        INTO PremiAttori_
        FROM PremiazioneAttore PA
                 INNER JOIN Premio P ON PA.idPremio = P.id
        WHERE PA.idFilm = idFilm_;

        SELECT IF(COUNT(*) = 0, 0, SUM(P.prestigio) / (COUNT(*) * 5))
        INTO PremiRegisti_
        FROM PremiazioneRegista PR
                 INNER JOIN Premio P ON PR.idPremio = P.id
        WHERE PR.idFilm = idFilm_;

        SET PremiCast_ = PremiAttori_ + PremiRegisti_;

        SELECT IF(COUNT(*) = 0, 0, SUM(P.prestigio) / (COUNT(*) * 5))
        INTO PremiFilm_
        FROM PremiazioneFilm PA
                 INNER JOIN Premio P ON PA.idPremio = P.id
        WHERE PA.idFilm = idFilm_;

        SELECT IF(COUNT(*) = 0, 0, SUM(RC.votazione) / (COUNT(*) * 10))
        INTO RecensioniCritici_
        FROM RecensioneCritico RC
        WHERE RC.idFilm = idFilm_;

        UPDATE Film
        SET rating = IF(totaleVisualizzazioni_ = 0, 0, numeroLike_ / totaleVisualizzazioni_) * 20 +
                     RecensioniCritici_ * 25 +
                     premiFilm_ * 15 + PremiCast_ * 10 +
                     IF(totaleVisualizzazioni_ = 0, 0, totaleWatchTime_ / (totaleVisualizzazioni_ * durata_)) * 30
        WHERE id = idFilm_;


    END LOOP;

    CLOSE ratingCursor;

END $$
DELIMITER ;


-- -------------OPERAZIONE 5----------------------
--       Inserimento Classifiche Genere
-- -----------------------------------------------


DROP PROCEDURE IF EXISTS CreazioneClassificaGenere;
DELIMITER $$

CREATE PROCEDURE CreazioneClassificaGenere()
BEGIN

    IF EXISTS(SELECT 1
              FROM ClassificaGenere CG
              WHERE CG.settimana = WEEK(CURRENT_DATE)
                AND CG.anno = YEAR(CURRENT_DATE)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La classifica è già stata calcolata';
    END IF;

    INSERT INTO ClassificaGenere(idFilm, idGenere, settimana, anno, posizione)
    SELECT D.IdFilm, D.idGenere, WEEK(CURRENT_DATE), YEAR(CURRENT_DATE), D.posizione
    FROM (SELECT F.id                                                               AS IdFilm,
                 F.rating,
                 C.idGenere,
                 DENSE_RANK() OVER (PARTITION BY C.idGenere ORDER BY F.rating DESC) AS posizione
          FROM Film F
                   INNER JOIN Classificazione C ON F.id = C.idFilm) AS D
    WHERE D.posizione <= 5;

END $$
DELIMITER ;

-- CREAZIONE EVENT

/*------------------------------
  EVENT per ClassificaGenere
 ------------------------------*/

DROP EVENT IF EXISTS AggiornaClassificaGenereRating;

CREATE EVENT AggiornaClassificaGenereRating
    ON SCHEDULE EVERY 1 WEEK STARTS '2023-09-10 23:00:00' ON COMPLETION PRESERVE DO
    BEGIN
        CALL AggiornamentoRating();
        CALL CreazioneClassificaGenere();
    END;


DROP PROCEDURE IF EXISTS MostraClassificaGenere;

DELIMITER $$
CREATE PROCEDURE MostraClassificaGenere(IN settimana_ SMALLINT UNSIGNED, IN anno_ SMALLINT UNSIGNED)
BEGIN

    IF (settimana_ IS NOT NULL AND anno_ IS NOT NULL AND settimana_ BETWEEN 1 AND 53) THEN
        SELECT G.nome, CG.posizione, F.titolo, F.rating
        FROM ClassificaGenere CG
                 INNER JOIN Genere G ON G.id = CG.idGenere
                 INNER JOIN Film F ON F.id = CG.idFilm
        WHERE CG.anno = anno_
          AND CG.settimana = settimana_
        ORDER BY CG.idGenere, CG.posizione;

    ELSE
        SELECT CG.anno, CG.settimana, G.nome, CG.posizione, F.titolo, F.rating
        FROM ClassificaGenere CG
                 INNER JOIN Genere G ON G.id = CG.idGenere
                 INNER JOIN Film F ON F.id = CG.idFilm
        ORDER BY CG.anno, CG.settimana, CG.idGenere, CG.posizione;

    END IF;

END $$


-- -------------OPERAZIONE 5----------------------
--       Trigger per aggiornamento ridondanze
-- -----------------------------------------------

-- Trigger per Numero Like


DELIMITER $$
DROP TRIGGER IF EXISTS aggiornamentoLike;

CREATE TRIGGER aggiornamentoLike
    AFTER INSERT
    ON RecensioneUtente
    FOR EACH ROW

BEGIN

    IF (NEW.votazione = 1) THEN
        UPDATE Film
        SET numeroLike = numeroLike + 1
        WHERE id = NEW.idFilm;

    END IF;

END $$
DELIMITER ;


-- Trigger per Watchtime e Visualizzazioni Contenuto


DELIMITER $$
DROP TRIGGER IF EXISTS aggiornamentoWatchTime;

CREATE TRIGGER aggiornamentoWatchTime
    AFTER UPDATE
    ON Erogazione
    FOR EACH ROW

BEGIN

    IF (NEW.fine IS NOT NULL AND NEW.minutiVisti IS NOT NULL) THEN

        UPDATE Contenuto
        SET watchtime       = watchtime + NEW.minutiVisti,
            visualizzazioni = visualizzazioni + 1
        WHERE NEW.idContenuto = id;

    END IF;

END $$
DELIMITER ;


-- --------------OPERAZIONE 6----------------------
--     Trovare il server con più streaming di un
--    determinato film in un determinato periodo
-- ------------------------------------------------


DROP PROCEDURE IF EXISTS Operazione6;
DELIMITER $$

CREATE PROCEDURE Operazione6(IN idFilm_ INT UNSIGNED, IN dataInizio_ DATE, IN dataFine_ DATE,
                             OUT idServer_ INT UNSIGNED)
BEGIN


    WITH ServerErogazioni AS (SELECT CL.idServer, COUNT(CL.idErogazione) AS numeroErogazioni
                              FROM Collegamento CL
                                       INNER JOIN Erogazione E ON CL.idErogazione = E.id
                                       INNER JOIN Contenuto C ON C.id = E.idContenuto

                              WHERE C.idFilm = idFilm_
                                AND (DATE(E.inizio) BETWEEN dataInizio_ AND dataFine_)
                                AND (DATE(E.fine) BETWEEN dataInizio_ AND dataFine_)
                              GROUP BY CL.idServer)
    SELECT idServer
    INTO idServer_
    FROM ServerErogazioni SE
    WHERE SE.numeroErogazioni >= ALL (SELECT numeroErogazioni
                                      FROM ServerErogazioni)
    LIMIT 1;


END $$
DELIMITER ;


-- -------------OPERAZIONE 7----------------------
--  Trovare il numero di premi totali che sono stati
--       vinti dai film prodotti in ogni Stato
-- -----------------------------------------------


DROP PROCEDURE IF EXISTS Operazione7;
DELIMITER $$

CREATE PROCEDURE Operazione7()
BEGIN

    WITH Premi AS (SELECT F.id,
                          F.statoProduzione,
                          (SELECT COUNT(*) FROM PremiazioneRegista PR WHERE PR.idFilm = F.id) AS PremiRegisti,
                          (SELECT COUNT(*) FROM PremiazioneAttore PA WHERE PA.idFilm = F.id)  AS PremiAttori,
                          (SELECT COUNT(*) FROM PremiazioneFilm PF WHERE PF.idFilm = F.id)    AS PremiFilm
                   FROM Film F),
         PremiFilm AS (SELECT P.id, P.statoProduzione, P.PremiAttori + P.PremiFilm + P.PremiRegisti AS Totale
                       FROM Premi P),
         Migliore AS (SELECT PF.statoProduzione, SUM(PF.Totale) AS PremiTotali
                      FROM PremiFilm PF
                      GROUP BY PF.statoProduzione
                      ORDER BY PremiTotali DESC)
    SELECT S.nome, M.PremiTotali
    FROM Migliore M
             INNER JOIN Stato S ON M.statoProduzione = S.codice;

END $$
DELIMITER ;


-- -------------OPERAZIONE 8----------------------
--  Trovare la distribuzione di erogazioni di un film per
--     continente in un determinato lasso temporale
-- -----------------------------------------------

DROP PROCEDURE IF EXISTS Operazione8;
DELIMITER $$

CREATE PROCEDURE Operazione8(IN idFilm_ INT UNSIGNED, IN dataInizio_ DATE, IN dataFine_ DATE)
BEGIN

    WITH ErogazioniTarget AS (SELECT E.id AS idErogazione, ST.continente, S.id AS idServer
                              FROM Erogazione E
                                       INNER JOIN Collegamento CL ON CL.idErogazione = E.id
                                       INNER JOIN Server S ON S.id = CL.idServer
                                       INNER JOIN Stato ST ON ST.codice = S.localita
                              WHERE DATE(E.inizio) BETWEEN dataInizio_ AND dataFine_
                                AND DATE(E.fine) BETWEEN dataInizio_ AND dataFine_
                                AND E.idContenuto IN (SELECT C.id
                                                      FROM Contenuto C
                                                      WHERE C.idFilm = idFilm_))
    SELECT continente                                                         AS Continente,
           COUNT(*)                                                           AS Erogazioni,
           ROUND(COUNT(*) / (SELECT COUNT(*) FROM ErogazioniTarget) * 100, 2) AS Percentuale
    FROM ErogazioniTarget
    GROUP BY continente;

END $$
DELIMITER ;