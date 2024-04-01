USE filmsphere;


DELIMITER $$

DROP PROCEDURE IF EXISTS `debug_msg`$$

CREATE PROCEDURE debug_msg(enabled INTEGER, msg VARCHAR(255))
BEGIN
    IF enabled THEN
        SELECT CONCAT('** ', msg) AS '** DEBUG:';
    END IF;
END $$


/*------------------------------
  Funzionalità 1
  Nome: BestServer
  Descrizione: la seguente funzionalità si occupa di identificare il server più oppurtuno per andare ad effettuare un'erogazione

 ------------------------------*/

DROP PROCEDURE IF EXISTS BestServer;
DELIMITER $$

CREATE PROCEDURE BestServer(IN idContenuto_ INT UNSIGNED, IN latitudineUtente_ FLOAT,
                            IN longitudineUtente_ FLOAT, IN idServerFull_ INT UNSIGNED,
                            OUT idBestServer_ INT UNSIGNED)

BEGIN
    DECLARE costoStreaming_ FLOAT DEFAULT 0;
    DECLARE distanzaUtenteServer_ FLOAT DEFAULT 0;
    DECLARE idServer_ INT UNSIGNED;
    DECLARE bandaUsata_ FLOAT;
    DECLARE memoriaUsata_ FLOAT;
    DECLARE bandaMax_ FLOAT;
    DECLARE memoriaMax_ FLOAT;
    DECLARE latitudineServer_ FLOAT;
    DECLARE longitudineServer_ FLOAT;
    DECLARE finito INT DEFAULT 0;
    DECLARE CostoMin_ FLOAT DEFAULT 0;
    DECLARE bitrateContenuto_ FLOAT;
    DECLARE durataContenuto_ SMALLINT UNSIGNED;
    DECLARE dimensioneContenuto_ FLOAT;
    DECLARE idServerTrasferimento_ INT UNSIGNED;
    DECLARE distanzaTrasferimento_ FLOAT;
    DECLARE costoTrasferimento_ FLOAT;
    DECLARE costoTotale_ FLOAT;

    -- cursore che scorre un resulset con tutti i server tranne eventualmente idServerFull_
-- se dato come input un valore diverso da null

    DECLARE costoCursore CURSOR FOR
        SELECT id, bandaUsata, memoriaUsata, latitudine, longitudine, bandaMax, memoriaMax
        FROM Server
        WHERE id <> IFNULL(idServerFull_, 0)
        ORDER BY id DESC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finito = 1;

    SET idBestServer_ = NULL;

    SELECT C.dimensione, F.durata
    INTO dimensioneContenuto_, durataContenuto_
    FROM Contenuto C
             INNER JOIN Film F ON F.id = C.idFilm
    WHERE C.id = idContenuto_;

    SELECT C.bitrate
    INTO bitrateContenuto_
    FROM Contenuto C
    WHERE C.id = idContenuto_;


    OPEN costoCursore;

    scan:
    LOOP

        FETCH costoCursore INTO idServer_,bandaUsata_,memoriaUsata_,latitudineServer_,longitudineServer_, bandaMax_, memoriaMax_;

        IF finito = 1 THEN
            LEAVE scan;
        END IF;
-- se il server non può streammare il contenuto, si passa direttamente al server successivo
        IF (bandaUsata_ + bitrateContenuto_ >= bandaMax_) THEN
            ITERATE scan;
        END IF;

        SET distanzaTrasferimento_ = 0;

        # 20000 km è la distanza massima tra due punti sulla Terra

        SET distanzaUtenteServer_ =
                    ST_DISTANCE_SPHERE(POINT(longitudineUtente_, latitudineUtente_),
                                       POINT(longitudineServer_, latitudineServer_)) / 1000;
        SET costoStreaming_ =
                        (distanzaUtenteServer_ / 20000) * 30 + (bitrateContenuto_ / (bandaMax_ - bandaUsata_)) * 20 +
                        (bandaUsata_ / bandaMax_) * 50;

-- calcolato il costo di streaming

        SET costoTrasferimento_ = 0;

-- Si controlla se il server ha il contenuto, se non lo ha si entra nel corpo dell'if
        IF NOT EXISTS(SELECT 1
                      FROM Archiviazione A
                      WHERE A.idContenuto = idContenuto_
                        AND A.idServer = idServer_)
        THEN
-- Controllo se il server ha abbastanza memoria disponibile per l'archiviazione del contenuto, altrimenti passo a quello dopo

            IF (memoriaUsata_ + dimensioneContenuto_ >= memoriaMax_) THEN
                ITERATE scan;
            END IF;

            WITH costiServer AS (SELECT S.id,
                                        ((ST_DISTANCE_SPHERE(POINT(S.longitudine, S.latitudine),
                                                             POINT(longitudineServer_, latitudineServer_)) /
                                          (20000 * 1000) * 50 +
                                          (bandaUsata_ / bandaMax_) * 40 +
                                          (S.bandaUsata / S.bandaMax) * 10) / 1.5) AS costoTrasferimento
                                 FROM Server S
                                          INNER JOIN Archiviazione A ON S.id = A.idServer
                                 WHERE A.idContenuto = idContenuto_
                                   AND A.idServer <> idServer_)
            SELECT CS.id, CS.costoTrasferimento
            INTO idServerTrasferimento_,costoTrasferimento_
            FROM costiServer CS
            ORDER BY CS.costoTrasferimento
            LIMIT 1;


        END IF;

        SET costoTotale_ = costoStreaming_ + costoTrasferimento_;


-- con questo if mi calcolo alla fine il costototale minore tra tutti i server e tiene conto del server a cui è associato quel costo
        IF (costototale_ < CostoMin_ OR idBestServer_ IS NULL) THEN
            SET CostoMin_ = costoTotale_;
            SET idBestServer_ = idServer_;
        END IF;


        CALL debug_msg(@debug,
                       CONCAT('idServer: ', idServer_, ' costoStreaming: ', costoStreaming_, ' costoTrasferimento: ',
                              costoTrasferimento_, ' costoTotale: ', costoTotale_, ' idServerTrasferimento: ',
                              idServerTrasferimento_));


    END LOOP scan;

    CLOSE costoCursore;

-- se nessun server è in grado di streammare il contenuto c'è un errore di streaming
    IF idBestServer_ IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non vi è un server in grado di streammare il contenuto, riprova più tardi';
    END IF;

END
$$

DELIMITER ;

DROP PROCEDURE IF EXISTS trasferisciContenuto;
DELIMITER $$

CREATE PROCEDURE trasferisciContenuto(IN serverDestinazione_ INT UNSIGNED, IN idContenuto_ INT UNSIGNED)
BEGIN

    INSERT INTO Archiviazione(idContenuto, idServer) VALUES (idContenuto_, serverDestinazione_);

END $$
DELIMITER ;


/*------------------------------
  Funzionalità 2
  Nome: GestioneRaccomandazioneContenuti
  Descrizione: La seguente funzionalità si occupa di gestire i vari casi per l'aggiornamento del sistema di raccomandazione dei contenuti
                in particolare si occupa di aggiornare la compatibilità dei film per un utente tramite dei trigger e
  di visualizzare i 10 contenuti consigliati su richiesta dell'utente

 ------------------------------*/

DROP FUNCTION IF EXISTS lambda;

DELIMITER $$
CREATE FUNCTION lambda(x FLOAT) RETURNS FLOAT
    DETERMINISTIC
BEGIN
    DECLARE result FLOAT;
    SET result = (3.8 * EXP(- (x / 55)) - 0.6168);
    RETURN result;
END $$

DELIMITER ;

DELIMITER  $$
DROP PROCEDURE IF EXISTS aggiornaCompatibilitaFilmStessoGenere $$

CREATE PROCEDURE aggiornaCompatibilitaFilmStessoGenere(IN idFilmVisualizzato INT UNSIGNED, IN idUtente INT UNSIGNED,
                                                       IN valore FLOAT,
                                                       IN modifica ENUM ('incremento', 'decremento'))
BEGIN

    DECLARE percentualeDefault FLOAT DEFAULT 50;

    -- inserisce in compatibilita o aggiorna se esiste gia il record, la percentuale di compatibilità dei film dello stesso genere,
-- utilizzando lambda per calcolare il moltiplicatore per il valore da incrementare o decrementare
    INSERT INTO Compatibilita(idFilm, idUtente, percentualeCompatibilita)
    WITH filmStessoGenere AS (SELECT *
                              FROM Film F
                              WHERE EXISTS(SELECT 1
                                           FROM Classificazione C1
                                           WHERE C1.idFilm = F.id
                                             AND C1.idGenere IN (SELECT idGenere
                                                                 FROM Classificazione C2
                                                                 WHERE C2.idFilm = idFilmVisualizzato)))
    SELECT D.id,
           idUtente,
           IF(modifica = 'decremento',
              percentualeDefault - (lambda(percentualeDefault) * (valore)),
              percentualeDefault + (lambda(percentualeDefault) * (valore))) AS NuovaPercentuale
    FROM filmStessoGenere AS D
    ON DUPLICATE KEY UPDATE percentualeCompatibilita = IF(modifica = 'decremento', percentualeCompatibilita -
                                                                                   (lambda(100 - percentualeCompatibilita) *
                                                                                    valore), percentualeCompatibilita +
                                                                                             (lambda(percentualeCompatibilita) *
                                                                                              valore));


END $$

DELIMITER ;


/*------------------------------
  Funzionalità 2.1
  Nome: AggiornamentoCompatibilitaErogazioneTerminata
  Descrizione: il seguente trigger si occupa di gestire l'aggiornamento delle compatibilità a seguito di una fine di un erogazione.

 ------------------------------*/

DELIMITER $$
DROP TRIGGER IF EXISTS AggiornamentoCompatibilitaErogazioneTerminata $$;

CREATE TRIGGER AggiornamentoCompatibilitaErogazioneTerminata
    AFTER UPDATE
    ON Erogazione
    FOR EACH ROW
BEGIN

    DECLARE durataContenuto SMALLINT UNSIGNED;
    DECLARE idFilmVisualizzato INT UNSIGNED;
    DECLARE percentuale FLOAT;
    -- quando termina un erogazione e quindi vengono modificati gli attributi fine e minutiVisti
    -- si va ad aggiornare la compatibilita
    IF (NEW.fine IS NOT NULL AND NEW.minutiVisti IS NOT NULL) THEN

        SELECT F.durata, F.id
        INTO durataContenuto, idFilmVisualizzato
        FROM Film F
                 INNER JOIN Contenuto C ON C.idFilm = F.id
        WHERE C.id = NEW.idContenuto;

        SET percentuale = (NEW.minutiVisti / durataContenuto) * 100;

        IF (percentuale BETWEEN 5 AND 60) THEN

            -- decremento film stesso genere
            CALL aggiornaCompatibilitaFilmStessoGenere
                (idFilmVisualizzato, NEW.idUtente, (100 - percentuale) / 10, 'decremento');

            -- decremento film stesso
            UPDATE Compatibilita C
            SET percentualeCompatibilita = percentualeCompatibilita - lambda(100 - percentualeCompatibilita) * 5
            WHERE C.idFilm = idFilmVisualizzato
              AND C.idUtente = new.idUtente;

        ELSEIF (percentuale BETWEEN 61 AND 100) THEN

            CALL aggiornaCompatibilitaFilmStessoGenere
                (idFilmVisualizzato, NEW.idUtente, percentuale / 10, 'incremento');

            -- incremento film stesso
            UPDATE Compatibilita C
            SET percentualeCompatibilita = percentualeCompatibilita + lambda(percentualeCompatibilita) * 5
            WHERE C.idFilm = idFilmVisualizzato
              AND C.idUtente = new.idUtente;

            -- incremento di 6% compatibilità per i film dello stesso genere presenti nella classifica genere dell'ultima settimana

            UPDATE
                Compatibilita C
            SET percentualeCompatibilita = percentualeCompatibilita + lambda(percentualeCompatibilita) * 6
            WHERE C.idFilm IN (SELECT idFilm
                               FROM ClassificaGenere
                               WHERE anno = (SELECT MAX(anno)
                                             FROM ClassificaGenere)
                                 AND settimana = (SELECT MAX(settimana)
                                                  FROM ClassificaGenere
                                                  WHERE anno = (SELECT MAX(anno)
                                                                FROM ClassificaGenere))
                                 AND idGenere IN
                                     (SELECT CLF.idGenere
                                      FROM Classificazione CLF
                                      WHERE CLF.idFilm = idFilmVisualizzato));

        END IF;

    END IF;

END $$


/*------------------------------
  Funzionalità 2.2
  Nome: AggiornamentoCompatibilitaRecensioneAggiunta
  Descrizione: il seguente trigger si occupa di gestire l'aggiornamento delle compatibilità a seguito di una nuova recensione.

 ------------------------------*/

DELIMITER
$$
DROP TRIGGER IF EXISTS AggiornamentoCompatibilitaRecensioneAggiunta $$;

CREATE TRIGGER AggiornamentoCompatibilitaRecensioneAggiunta
    AFTER INSERT
    ON RecensioneUtente
    FOR EACH ROW
BEGIN

    DECLARE percentualeDefault FLOAT DEFAULT 50;


    DECLARE modifica ENUM ('incremento','decremento');
    SET modifica = IF(NEW.votazione = 1, 'incremento', 'decremento');
    -- aggiornamento film stesso genere di 5% a seconda del voto positivo o negativo
    CALL aggiornaCompatibilitaFilmStessoGenere
        (new.idFilm, NEW.idUtente, 5, modifica);

    -- se la votazione è positiva
    IF (modifica = 'incremento') THEN

        -- incremento il film stesso
        UPDATE Compatibilita C
        SET percentualeCompatibilita = percentualeCompatibilita + lambda(percentualeCompatibilita) * 10
        WHERE C.idFilm = NEW.idFilm
          AND C.idUtente = new.idUtente;


    ELSE

        -- decremento il film stesso
        UPDATE Compatibilita C
        SET percentualeCompatibilita = percentualeCompatibilita - lambda(100 - percentualeCompatibilita) * 10
        WHERE C.idFilm = NEW.idFilm
          AND C.idUtente = new.idUtente;

    END IF;

    -- aggiornamento della compatibilità ( o inserimento se il film aveva ancora quella di default )
    -- per i film che sono stati diretti dallo stesso regista, aumento o decremento del 3%
    INSERT INTO Compatibilita(idFilm, idUtente, percentualeCompatibilita)
    WITH filmStessoRegista AS (SELECT *
                               FROM Film F
                               WHERE EXISTS(SELECT 1
                                            FROM Direzione D
                                            WHERE D.idFilm = F.id
                                              AND D.idArtista IN (SELECT D2.idArtista
                                                                  FROM Direzione D2
                                                                  WHERE D2.idFilm = NEW.idFilm)))
    SELECT D.id,
           NEW.idUtente,
           IF(modifica = 'decremento',
              percentualeDefault - (lambda(percentualeDefault) * (3)),
              percentualeDefault + (lambda(percentualeDefault) * (3))) AS NuovaPercentuale
    FROM filmStessoRegista AS D
    ON DUPLICATE KEY UPDATE percentualeCompatibilita = IF(modifica = 'decremento', percentualeCompatibilita -
                                                                                   (lambda(100 - percentualeCompatibilita) *
                                                                                    3), percentualeCompatibilita +
                                                                                        (lambda(percentualeCompatibilita) *
                                                                                         3));


END $$


DROP PROCEDURE IF EXISTS MostraCompatibilitaUtente;

DELIMITER $$
CREATE PROCEDURE MostraCompatibilitaUtente(IN idUtente_ INT UNSIGNED)
BEGIN

    SELECT C.idUtente,
           F.titolo,
           CONCAT(C.percentualeCompatibilita, '%')     AS compatibilita,
           GROUP_CONCAT(DISTINCT G.nome ORDER BY G.id) AS Generi
    FROM Compatibilita C
             INNER JOIN Film F ON F.id = C.idFilm
             INNER JOIN Classificazione CLF ON CLF.idFilm = F.id
             INNER JOIN Genere G ON G.id = CLF.idGenere
    WHERE idUtente = idUtente_
    GROUP BY C.idUtente, F.titolo, compatibilita
    ORDER BY compatibilita DESC;

END $$

/*------------------------------
  Funzionalità 3: Classifica Stato
  Nome: CreazioneClassificaStato
  Descrizione:la suguente funzionalità inserirà la classifica per Stato della settimana corrente

 ------------------------------*/
DELIMITER $$
DROP PROCEDURE IF EXISTS CreazioneClassificaStato;

CREATE PROCEDURE CreazioneClassificaStato()
BEGIN
    -- se esiste già non faccio niente
    IF EXISTS(SELECT 1
              FROM ClassificaStato CG
              WHERE CG.settimana = WEEK(CURRENT_DATE)
                AND CG.anno = YEAR(CURRENT_DATE)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'La classifica è già stata calcolata, effettua una query a ClassificaStato per ottenerla';
    END IF;

    INSERT INTO ClassificaStato(codiceStato, idFilm, posizione, risoluzione, settimana, anno)
    -- CTE Contiene tutte le informazioni per ciascun film, ripetute per quante volte questo è stato erogato
    WITH CTE AS (SELECT E.*, F.durata, C.risoluzione, C.idFilm, U.nazionalita, C.watchtime
                 FROM Erogazione E
                          INNER JOIN Utente U ON E.idUtente = U.id
                          INNER JOIN Contenuto C ON C.id = E.idContenuto
                          INNER JOIN Film F ON F.id = C.idFilm),
         -- WatchtimePerRisoluzione contiene per ciascun film, in ciascuna nazione,una riga per ogni risoluzione diversa
         -- in cui è presente e il totale dei minutiVisti dagli utenti di quella nazione per quella risoluzione
         WatchtimePerRisoluzione AS (SELECT CTE.idFilm,
                                            CTE.nazionalita,
                                            CTE.risoluzione,
                                            SUM(CTE.minutiVisti) AS WatchTime
                                     FROM CTE
                                     GROUP BY CTE.idFilm, CTE.nazionalita, CTE.risoluzione),
         -- WatchtimeMaxPerFilmENazione contiene per ogni film e ogni nazione il massimo di minutiVisti in una determinata risoluzione,
         -- di cui ci ricaveremo successivamente il nome
         WatchtimeMaxPerFilmENazione AS (SELECT W.idFilm, W.nazionalita, MAX(W.WatchTime) AS MaxWatchtime
                                         FROM WatchtimePerRisoluzione W
                                         GROUP BY W.idFilm, W.nazionalita),

         -- RisoluzioniPerFilmENazione associa a ciascun film per ogni stato la risoluzione in cui è stato visto più volte
         -- dagli utenti di quella nazionalita, e il numero della riga di ogni film e nazione, in modo da poter successivamente
         -- in casi di parimerito tenerci solo una riga con scelta casuale
         RisoluzioniPerFilmENazione AS (SELECT W.idFilm,
                                               W.nazionalita,
                                               WW.risoluzione,
                                               ROW_NUMBER() OVER (PARTITION BY W.idFilm,W.nazionalita) AS numero
                                        FROM WatchtimeMaxPerFilmENazione W
                                                 INNER JOIN WatchtimePerRisoluzione WW ON W.idFilm = WW.idFilm
                                        WHERE W.nazionalita = WW.nazionalita
                                          AND W.MaxWatchtime = WW.WatchTime),
         -- in casi di parimerito adesso selezioniamo dalla tabella precedente solo una risoluzione per film e nazione
         RisoluzioneUnicaPerFilmENazione AS (SELECT *
                                             FROM RisoluzioniPerFilmENazione
                                             WHERE numero = 1),
         -- FilmNazioneScore contiene per ogni film e stato lo score calcolato come
         -- somma dei minuti visti dagli utenti di quella nazionalita / durata del film
         FilmNazioneScore AS (SELECT C.idFilm, C.nazionalita, (SUM(C.watchtime) / C.durata) AS score
                              FROM CTE C
                              GROUP BY C.idFilm, C.nazionalita)

    -- si fa il dense_rank sullo score per ogni nazionalità e si inserisce in classificaStato
    SELECT F.nazionalita,
           F.idFilm,
           DENSE_RANK() OVER (PARTITION BY F.nazionalita ORDER BY F.score DESC) AS posizione,
           R.risoluzione,
           WEEK(CURRENT_DATE)                                                   AS settimana,
           YEAR(CURRENT_DATE)                                                   AS anno
    FROM FilmNazioneScore F
             INNER JOIN RisoluzioneUnicaPerFilmENazione R ON (F.idFilm = R.idFilm AND F.nazionalita = R.nazionalita);

END $$


/*------------------------------
  EVENT per ClassificaStato
 ------------------------------*/

DROP EVENT IF EXISTS AggiornaClassificaStato;

CREATE EVENT AggiornaClassificaStato
    ON SCHEDULE EVERY 1 WEEK STARTS '2023-09-10 23:00:00' ON COMPLETION PRESERVE DO
    CALL CreazioneClassificaStato();


DROP PROCEDURE IF EXISTS MostraClassificaStato;

DELIMITER $$
CREATE PROCEDURE MostraClassificaStato(IN settimana_ SMALLINT UNSIGNED, IN anno_ SMALLINT UNSIGNED)
BEGIN

    IF (settimana_ IS NOT NULL AND anno_ IS NOT NULL AND settimana_ BETWEEN 1 AND 53) THEN
        SELECT S.nome, CS.posizione, F.titolo, CS.risoluzione
        FROM ClassificaStato CS
                 INNER JOIN Stato S ON S.codice = CS.codiceStato
                 INNER JOIN Film F ON F.id = CS.idFilm
        WHERE CS.anno = anno_
          AND CS.settimana = settimana_
        ORDER BY CS.codiceStato, CS.posizione;

    ELSE
        SELECT CS.anno, CS.settimana, S.nome, CS.posizione, F.titolo, CS.risoluzione
        FROM ClassificaStato CS
                 INNER JOIN Stato S ON S.codice = CS.codiceStato
                 INNER JOIN Film F ON F.id = CS.idFilm
        ORDER BY CS.anno, CS.settimana, CS.codiceStato, CS.posizione;

    END IF;

END $$


/*------------------------------
  Funzionalità 4: Classifica Pacchetto
  Nome: CreazioneClassificaPacchetto
  Descrizione:la suguente funzionalità inserirà la classifica per Pacchetto della settimana corrente

 ------------------------------*/
DELIMITER $$
DROP PROCEDURE IF EXISTS CreazioneClassificaPacchetto;

CREATE PROCEDURE CreazioneClassificaPacchetto()
BEGIN

    -- se esiste già non faccio niente
    IF EXISTS(SELECT 1
              FROM ClassificaPacchetto CP
              WHERE CP.settimana = WEEK(CURRENT_DATE)
                AND CP.anno = YEAR(CURRENT_DATE)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'La classifica è già stata calcolata, effettua una query a ClassificaPacchetto per ottenerla';
    END IF;

    INSERT INTO ClassificaPacchetto(nomePacchetto, idFilm, posizione, risoluzione, settimana, anno)
    -- CTE Contiene tutte le informazioni per ciascun film, ripetute per quante volte questo è stato erogato
    WITH CTE AS (SELECT E.*, F.durata, C.risoluzione, C.idFilm, A.nomePacchetto, C.watchtime
                 FROM Erogazione E
                          INNER JOIN Utente U ON E.idUtente = U.id
                          INNER JOIN Contenuto C ON C.id = E.idContenuto
                          INNER JOIN Film F ON F.id = C.idFilm
                          INNER JOIN Abbonamento A ON A.idUtente = U.id),
         -- WatchtimePerRisoluzione contiene per ciascun film e ciascun pacchetto,una riga per ogni risoluzione diversa
         -- in cui è presente e il totale dei minutiVisti dagli utenti abbonati con quel pacchetto per quella risoluzione
         WatchtimePerRisoluzione AS (SELECT CTE.idFilm,
                                            CTE.nomePacchetto,
                                            CTE.risoluzione,
                                            SUM(CTE.minutiVisti) AS WatchTime
                                     FROM CTE
                                     GROUP BY CTE.idFilm, CTE.nomePacchetto, CTE.risoluzione),
         -- WatchtimeMaxPerFilmEPacchetto contiene per ogni film e ogni pacchetto il massimo di minutiVisti in una determinata risoluzione,
         -- di cui ci ricaveremo successivamente il nome
         WatchtimeMaxPerFilmEPacchetto AS (SELECT W.idFilm, W.nomePacchetto, MAX(W.WatchTime) AS MaxWatchtime
                                           FROM WatchtimePerRisoluzione W
                                           GROUP BY W.idFilm, W.nomePacchetto),
         -- RisoluzioniPerFilmEPacchetto associa a ciascun film per ogni pacchetto la risoluzione in cui è stato visto più volte
         -- dagli utenti abbonati a quel pachcetto, e il numero della riga di ogni film e pacchetto, in modo da poter successivamente
         -- in casi di parimerito tenerci solo una riga con scelta casuale
         RisoluzioniPerFilmEPacchetto AS (SELECT W.idFilm,
                                                 W.nomePacchetto,
                                                 WW.risoluzione,
                                                 ROW_NUMBER() OVER (PARTITION BY W.idFilm,W.nomePacchetto) AS numero
                                          FROM WatchtimeMaxPerFilmEPacchetto W
                                                   INNER JOIN WatchtimePerRisoluzione WW ON W.idFilm = WW.idFilm
                                          WHERE W.nomePacchetto = WW.nomePacchetto
                                            AND W.MaxWatchtime = WW.WatchTime),
         -- in casi di parimerito adesso selezioniamo dalla tabella precedente solo una risoluzione per film e pacchetto
         RisoluzioneUnicaPerFilmEPacchetto AS (SELECT *
                                               FROM RisoluzioniPerFilmEPacchetto
                                               WHERE numero = 1),
         -- FilmPacchettoScore contiene per ogni film e pacchetto lo score calcolato come
         -- somma dei minuti visti dagli utenti abbonati a quel pacchetto / durata del film
         FilmPacchettoScore AS (SELECT C.idFilm, C.nomePacchetto, (SUM(C.watchtime) / C.durata) AS score
                                FROM CTE C
                                GROUP BY C.idFilm, C.nomePacchetto)
    -- si fa il dense_rank sullo score per ogni pacchetto e si inserisce in classificaStato
    SELECT F.nomePacchetto,
           F.idFilm,
           DENSE_RANK() OVER (PARTITION BY F.nomePacchetto ORDER BY F.score DESC) AS posizione,
           R.risoluzione,
           WEEK(CURRENT_DATE)                                                     AS settimana,
           YEAR(CURRENT_DATE)                                                     AS anno
    FROM FilmPacchettoScore F
             INNER JOIN RisoluzioneUnicaPerFilmEPacchetto R
                        ON (F.idFilm = R.idFilm AND F.nomePacchetto = R.nomePacchetto);

END $$

/*------------------------------
  EVENT per ClassificaPacchetto
 ------------------------------*/

DROP EVENT IF EXISTS AggiornaClassificaPacchetto;

CREATE EVENT AggiornaClassificaPacchetto
    ON SCHEDULE EVERY 1 WEEK STARTS '2023-09-10 23:00:00' ON COMPLETION PRESERVE DO
    CALL CreazioneClassificaPacchetto();


DROP PROCEDURE IF EXISTS MostraClassificaPacchetto;

DELIMITER $$
CREATE PROCEDURE MostraClassificaPacchetto(IN settimana_ SMALLINT UNSIGNED, IN anno_ SMALLINT UNSIGNED)
BEGIN

    IF (settimana_ IS NOT NULL AND anno_ IS NOT NULL AND settimana_ BETWEEN 1 AND 53) THEN
        SELECT CP.nomePacchetto, CP.posizione, F.titolo, CP.risoluzione
        FROM ClassificaPacchetto CP
                 INNER JOIN Film F ON F.id = CP.idFilm
        WHERE CP.anno = anno_
          AND CP.settimana = settimana_
        ORDER BY CP.nomePacchetto, CP.posizione;

    ELSE
        SELECT CP.anno, CP.settimana, CP.nomePacchetto, CP.posizione, F.titolo, CP.risoluzione
        FROM ClassificaPacchetto CP
                 INNER JOIN Film F ON F.id = CP.idFilm
        ORDER BY CP.anno, CP.settimana, CP.nomePacchetto, CP.posizione;

    END IF;

END $$


/*------------------------------
  Funzionalità 5: Caching
  Nome: CachingContenutiRaccomandati
  Descrizione: la suguente funzionalità inserirà per ogni utente,
  i 3 film con la compatibilità maggiore non ancora visualizzati nel server più vicino
  alla posizione dell'ultima connessione

 ------------------------------*/


DROP PROCEDURE IF EXISTS CachingContenutiRaccomandati;
DELIMITER $$

CREATE PROCEDURE CachingContenutiRaccomandati()
BEGIN
    DECLARE longitudineUtente_ FLOAT;
    DECLARE latitudineUtente_ FLOAT;
    DECLARE finito INT DEFAULT 0;
    DECLARE idUtente_ INT UNSIGNED;
    DECLARE idServerVicino_ INT UNSIGNED;

    DECLARE utenteCursore CURSOR FOR
        WITH Connessioni AS (SELECT *
                             FROM Utente U
                                      INNER JOIN Connessione C ON C.idUtente = U.id)
        SELECT idUtente, latitudine, longitudine
        FROM Connessioni C
        WHERE C.inizio = (SELECT MAX(inizio)
                          FROM Connessioni C1
                          WHERE C1.idUtente = C.idUtente);

    -- il cursore scorre un result set formato da tutti gli utenti e le loro ultime posizioni ( latitudine e longitudine )

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finito = 1;


    OPEN utenteCursore;

    scan:
    LOOP

        FETCH utenteCursore INTO idUtente_,latitudineUtente_,longitudineUtente_;

        IF finito = 1 THEN
            LEAVE scan;
        END IF;

        -- per l utente che abbiamo adesso dentro idUtente_ si cerca il server più vicino alla posizione della sua ultima connessione
        WITH ServerDistanze AS (SELECT S.id,
                                       ST_DISTANCE_SPHERE(POINT(longitudineUtente_, latitudineUtente_),
                                                          POINT(S.longitudine, S.latitudine)) AS distanza
                                FROM Server S)
        SELECT S.id
        INTO idServerVicino_
        FROM ServerDistanze S
        WHERE S.distanza = (SELECT MIN(S2.distanza)
                            FROM ServerDistanze S2)
        LIMIT 1;

        -- inseriamo in archivio del server trovato prima ( solo se non presenti gia ) i contenuti associati ai 3 film
        -- con più compatibilità solo se questa è superiore al 70%
        INSERT IGNORE INTO Archiviazione(idContenuto, idServer)
        WITH FilmPiuCompatibili AS (SELECT *
                                    FROM Compatibilita C
                                    WHERE C.idUtente = idUtente_
                                      AND percentualeCompatibilita > 70
                                      AND NOT EXISTS(SELECT 1                                                  FROM Erogazione E
                                                     WHERE E.idUtente = C.idUtente
                                                       AND E.idContenuto IN (SELECT CO.id
                                                                             FROM Contenuto CO
                                                                             WHERE CO.idFilm = C.idFilm))
                                    ORDER BY C.percentualeCompatibilita DESC
                                    LIMIT 3)
        SELECT C.id, idServerVicino_
        FROM FilmPiuCompatibili FC
                 INNER JOIN Contenuto C ON FC.idFilm = C.idFilm;


    END LOOP scan;

    CLOSE utenteCursore;

END $$

DROP EVENT IF EXISTS GestisciCachingContenuti;
DELIMITER $$

CREATE EVENT GestisciCachingContenuti
    ON SCHEDULE EVERY 1 DAY STARTS '2023-09-03 00:00:00' ON COMPLETION PRESERVE DO
    CALL CachingContenutiRaccomandati();


/*------------------------------
  Funzionalità 6
  Nome: GestioneLog
  Descrizione:la suguente funzionalità si occupa di inserire i log dei server
  nella tabella ServerLog nei vari casi descritti nella documentazione

 ------------------------------*/

/*------------------------------
   EVENT PER SERVER STATUS
 Descrizione:il seguente trigger si occupa di inserire nel server log un record di tipo info ogni ora

------------------------------*/

DROP EVENT IF EXISTS EmissioneLogServerStatus;
DELIMITER $$

CREATE EVENT EmissioneLogServerStatus
    ON SCHEDULE EVERY 1 HOUR STARTS '2023-09-03 00:00:00' ON COMPLETION PRESERVE DO
    BEGIN

        INSERT INTO ServerLog(idServer, criticita, codice, messaggio)
        SELECT id,
               'info',
               'server status',
               CONCAT('Memoria Usata: ', ROUND(S.memoriaUsata / S.memoriaMax * 100, 2),
                      '%, Banda Usata: ', ROUND(S.bandaUsata / S.bandaMax * 100, 2), '%')
        FROM Server S;

    END $$

/*------------------------------
    TRIGGER PER EXCESSIVE LOAD E STREAMING ERROR
  Descrizione:il seguente trigger si occupa di inserire nel server log
  un record di tipo WARNING quando la banda usata di un server supera il 90%
  e di tipo un record di tipo ERROR quando raggiunge il 99%

 ------------------------------*/

DROP TRIGGER IF EXISTS EmissioneLogExcessiveLoad;
DELIMITER $$

CREATE TRIGGER EmissioneLogExcessiveLoad
    AFTER UPDATE
    ON Server
    FOR EACH ROW
BEGIN

    IF (NEW.bandaUsata / NEW.bandaMax BETWEEN 0.8 AND 0.94) AND (OLD.bandaUsata / OLD.bandaMax < 0.9)
    THEN
        INSERT INTO ServerLog(idServer, criticita, codice, messaggio)
        VALUES (NEW.id, 'warning', 'excessive load', CONCAT('Banda utilizzata dal server quasi al completo! (',
                                                            ROUND(NEW.bandaUsata / NEW.bandaMax * 100, 2), '%)'));

    END IF;

    IF (NEW.bandaUsata / NEW.bandaMax BETWEEN 0.95 AND 1) AND (OLD.bandaUsata / OLD.bandaMax < 0.95) THEN
        INSERT INTO ServerLog(idServer, criticita, codice, messaggio)
        VALUES (NEW.id, 'error', 'streaming error', 'Banda utilizzata dal server al completo!');

    END IF;

END $$


/*------------------------------
    TRIGGER PER EXCESSIVE MEMORY USAGE
  Descrizione:il seguente trigger si occupa di inserire nel server log
  un record di tipo WARNING quando la memoria utilizzata da un server supera l'90%

 ------------------------------*/

DROP TRIGGER IF EXISTS EmissioneLogExcessiveMemoryUsage;
DELIMITER $$

CREATE TRIGGER EmissioneLogExcessiveMemoryUsage
    AFTER UPDATE
    ON Server
    FOR EACH ROW
BEGIN

    IF ((NEW.memoriaUsata / NEW.memoriaMax >= 0.9) AND (OLD.memoriaUsata / OLD.memoriaMax < 0.9))
    THEN
        INSERT INTO ServerLog(idServer, criticita, codice, messaggio)
        VALUES (NEW.id, 'warning', 'excessive memory usage',
                CONCAT('Memoria utilizzata dal server quasi al completo! (',
                       ROUND(NEW.memoriaUsata / NEW.memoriaMax * 100, 2),
                       '%)'));

    END IF;


END $$

/*------------------------------
  Procedura per gestire Excessive Load
  Descrizione: la seguente procedura va a spostare dei collegamenti
  dal server sovraccarico ad altri server più opportuni
 ------------------------------*/


DROP PROCEDURE IF EXISTS GestioneExcessiveLoad;
DELIMITER $$


CREATE PROCEDURE GestioneExcessiveLoad(IN idServer_ INT UNSIGNED)
BEGIN
    DECLARE finito INT DEFAULT 0;
    DECLARE latitudineUtente_ FLOAT;
    DECLARE longitutineUtente_ FLOAT;
    DECLARE idErogazione_ INT UNSIGNED;
    DECLARE idContenuto_ INT UNSIGNED;
    DECLARE idNuovoBestServer_ INT UNSIGNED;
    DECLARE bandaPercentuale_ FLOAT;
    -- in caso di excessive load si efffettua dei cambi di server per le erogazioni più recenti fino a che
    -- il server non ritorna sotto il 60% di banda utilizzata
    DECLARE cambioServer CURSOR FOR
        SELECT E.id, E.idContenuto, CE.latitudine, CE.longitudine
        FROM Collegamento C
                 INNER JOIN Erogazione E ON C.idErogazione = E.id
                 INNER JOIN Connessione CE ON (E.idUtente = CE.idUtente AND E.ipDispositivo = CE.ipDispositivo AND
                                               E.inizioConnessione = CE.inizio)
        WHERE C.idServer = idServer_
          AND C.stato = 'attivo'
        ORDER BY E.inizio DESC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finito = 1;

    OPEN cambioServer;

    scan:
    LOOP
        FETCH cambioServer INTO idErogazione_, idContenuto_, latitudineUtente_, longitutineUtente_;

        SELECT S.bandaUsata / S.bandaMax INTO bandaPercentuale_ FROM Server S WHERE S.id = idServer_;
        -- si esce dal loop quando la banda torna sotto il 60% o quando finiscono i collegamenti di quel server
        IF (bandaPercentuale_ <= 0.6) OR (finito = 1) THEN
            LEAVE scan;
        END IF;
        -- si cerca il server più opportuno a cui si dovrebbe collegare l'utente escludendo il server stesso che è in sovraccarico
        CALL BestServer(idContenuto_, latitudineUtente_, longitutineUtente_, idServer_, idNuovoBestServer_);

        #         CALL debug_msg(TRUE, CONCAT('idOldServer: ', idServer_, ' idNewServer: ', idNuovoBestServer_));

        -- si controlla che non ci siano gia stati dei collegamenti tra il nuovoBestServer trovato e l'erogazione da cambiare,
        -- in modo da non far ritornare un erogazione interrotta in stato attivo, il tutto per evitare un deadlock in cui 2 server
        -- continuano a scambiarsi un erogazione all'infinito

        IF (idNuovoBestServer_ <> idServer_ AND NOT EXISTS (SELECT 1
                                                            FROM Collegamento C
                                                            WHERE C.idServer = idNuovoBestServer_
                                                              AND C.idErogazione = idErogazione_)) THEN
            -- se il nuovo server su cui effettuare il cambio del collegamento non ha il contenuto, si inserisce e
            -- la memoria disponibile di quel server è gia stata controllata nella procedura BestServer
            IF NOT EXISTS(SELECT 1
                          FROM Archiviazione A
                          WHERE A.idServer = idNuovoBestServer_
                            AND A.idContenuto = idContenuto_) THEN
                CALL trasferisciContenuto(idNuovoBestServer_, idContenuto_);
            END IF;

            -- si aggiorna da attivo ad interrotto lo stato del collegamento precedente e poi si inserisce il nuovo collegamento
            UPDATE
                Collegamento CL
            SET stato='interrotto'
            WHERE CL.idServer = idServer_
              AND CL.idErogazione = idErogazione_;

            INSERT INTO Collegamento(idErogazione, idServer) VALUES (idErogazione_, idNuovoBestServer_);

        END IF;

    END LOOP scan;

    CLOSE cambioServer;

END $$


/*------------------------------
  Procedura per gestire Excessive Memory
  Descrizione: la seguente procedura va ad eliminare i contenuti meno richiesti
  dal server con memoria quasi piena
 ------------------------------*/

DROP PROCEDURE IF EXISTS GestioneExcessiveMemory;
DELIMITER $$


CREATE PROCEDURE GestioneExcessiveMemory(IN idServer_ INT UNSIGNED)
BEGIN
    DECLARE finito INT DEFAULT 0;
    DECLARE idContenuto_ INT UNSIGNED;
    DECLARE memoriaPercentuale_ FLOAT;


    DECLARE updateMemory CURSOR FOR
        WITH ErogazioniContenuto AS (SELECT *
                                     FROM Erogazione E
                                              INNER JOIN Collegamento CL ON E.id = CL.idServer
                                     WHERE CL.idServer = idServer_),
             Result AS (SELECT A.idContenuto, SUM(IF(E1.idErogazione IS NULL, 0, 1)) AS Erogazioni
                        FROM Archiviazione A
                                 LEFT JOIN ErogazioniContenuto E1 ON E1.idContenuto = A.idContenuto
                        WHERE A.idServer = idServer_
                        GROUP BY A.idContenuto
                        ORDER BY Erogazioni)
        SELECT R.idContenuto
        FROM Result R;

    -- vengono selezionati dal cursore gli id dei contenuti archiviati da quello meno erogato a quello piu erogato

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finito = 1;

    OPEN updateMemory;

    scan:
    LOOP

        FETCH updateMemory INTO idContenuto_;

        SELECT S.memoriaUsata / S.memoriaMax
        INTO memoriaPercentuale_
        FROM Server S
        WHERE S.id = idServer_;


        -- se la memoria usata è minore del 60% o gli id archiviati sono finiti esce dal loop

        IF (memoriaPercentuale_ <= 0.6) OR (finito = 1) THEN
            LEAVE scan;
        END IF;

        -- se esistono dei collegamenti attivi che stanno streammando, oppure tale contenuto si trova solamente
        -- sul server in questione si passa al contenuto successivo.

        IF EXISTS (SELECT 1
                   FROM Collegamento CL
                            INNER JOIN Erogazione E ON CL.idErogazione = E.id
                   WHERE E.idContenuto = idContenuto_
                     AND CL.stato = 'attivo') OR NOT EXISTS (SELECT 1
                                                             FROM Archiviazione A
                                                             WHERE A.idContenuto = idContenuto_
                                                               AND A.idServer <> idServer_)
        THEN
            ITERATE scan;
        END IF;

        -- passati i controlli si elimina il contenuto da quel server
        DELETE
        FROM Archiviazione A
        WHERE (A.idContenuto = idContenuto_ AND A.idServer = idServer_);

    END LOOP scan;

    CLOSE updateMemory;

END $$


/*------------------------------
  Procedura per gestire gli Streaming Erorr
  Descrizione: la seguente procedura va ad eliminare tutti i collegamenti dal server
  che raggiunge un'errore di streaming causato dal saturamento delle connessioni in contemporanea
 ------------------------------*/

DROP PROCEDURE IF EXISTS GestioneStreamingError;
DELIMITER $$


CREATE PROCEDURE GestioneStreamingError(IN idServer_ INT UNSIGNED)
BEGIN
    DECLARE finito INT DEFAULT 0;
    DECLARE idErogazione_ INT UNSIGNED;


    DECLARE updateCollegamenti CURSOR FOR
        SELECT C.idErogazione
        FROM Collegamento C
        WHERE C.idServer = idServer_
          AND C.stato = 'attivo';

    -- vengono selezionati dal cursore gli id dei contenuti archiviati da quello meno erogato a quello piu erogato

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finito = 1;

    OPEN updateCollegamenti;

    scan:
    LOOP

        FETCH updateCollegamenti INTO idErogazione_;
        -- se le connessioni sono finite esco dal loop

        IF (finito = 1) THEN
            LEAVE scan;
        END IF;
        -- aggiorno erogazione ( che ha un trigger che aggiornerà collegamento da attivo a terminato )
        UPDATE Erogazione E
        SET E.fine=NOW(),
            E.minutiVisti=TIMESTAMPDIFF(MINUTE, E.inizio, E.fine)
        WHERE E.id = idErogazione_;

        INSERT INTO ServerLog(idServer, criticita, codice, messaggio)
        VALUES (idServer_, 'info', 'server shutdown', 'Spegnimento server a seguito di uno streaming error');
        INSERT INTO ServerLog(idServer, criticita, codice, messaggio)
        VALUES (idServer_, 'info', 'server startup', 'Riavvio server completato a seguito di uno streaming error');

    END LOOP scan;

    CLOSE updateCollegamenti;

END $$


/*------------------------------
  EVENT GESTIONE LOG
  Nome: ServerLogUpdate
  Descrizione: il seguente evento si occupa di controllare i nuovi serverLog e agire di conseguenza

 ------------------------------*/

DROP EVENT IF EXISTS ServerLogUpdate;
DELIMITER $$

CREATE EVENT ServerLogUpdate ON SCHEDULE EVERY 15 MINUTE STARTS '2023-09-08 00:00:00' DO
    BEGIN


        DECLARE finito INT DEFAULT 0;
        DECLARE idServer_ INT UNSIGNED;
        DECLARE codice_ VARCHAR(255);


        -- si seleziona l'id del server e il codice per ogni serverLog aggiunto nel quarto d'ora precedente
        DECLARE checkLog CURSOR FOR
            SELECT S.idServer, S.codice
            FROM ServerLog S
            WHERE TIMESTAMPDIFF(MINUTE, S.timestamp, NOW()) <= 15;


        OPEN checkLog;

        scan :
        LOOP
            FETCH checkLog INTO idServer_, codice_;

            IF finito = 1 THEN
                LEAVE scan;
            END IF;


            CASE
                WHEN codice_ = 'excessive load' THEN CALL GestioneExcessiveMemory(idServer_);
                WHEN codice_ = 'excessive memory usage' THEN CALL GestioneExcessiveMemory(idServer_);
                WHEN codice_ = 'streaming error' THEN CALL GestioneStreamingError(idServer_);
                END CASE;
        END LOOP scan;

        CLOSE checkLog;

    END;


/*------------------------------
  Funzionalità 7 Custom
  Nome: RiprendiVisualizzazione
  Descrizione:la suguente funzionalità si occupa di mostrare i contenuti la visualizzazione non è terminata,
  con i relativi minuti rimasti per la fine della visualizzazione
 ------------------------------*/

DROP PROCEDURE IF EXISTS RiprendiVisualizzazione;
DELIMITER $$

CREATE PROCEDURE RiprendiVisualizzazione(IN idUtente_ INT UNSIGNED)
BEGIN

    WITH MinutiTotaliVistiPerContenuto AS (SELECT E.idContenuto, SUM(minutiVisti) AS minutiTotaliVisti
                                           FROM Erogazione E
                                           WHERE E.idUtente = idUtente_
                                           GROUP BY E.idContenuto)
    SELECT M.idContenuto, F.titolo, (F.durata - M.minutiTotaliVisti) AS minutiRimanenti
    FROM MinutiTotaliVistiPerContenuto M
             INNER JOIN Contenuto C
                        ON M.idContenuto = C.id
             INNER JOIN Film F ON F.id = C.idFilm
    WHERE (M.minutiTotaliVisti / F.durata) BETWEEN 0.02 AND 0.9;
END $$


