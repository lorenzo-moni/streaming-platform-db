USE filmsphere;



SELECT *
FROM Film;

CALL registrazioneUtente('lorenzo', 'pino', 'lorenzo@gmail.com', 'dsafnadsfmn24knfkldasn', 'GB', '2002-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni');
CALL registrazioneUtente('lorenzo', 'marra', 'lollo123', 'dsafnadsfmn24knfkldasn', 'IT', '2002-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni');
CALL registrazioneUtente('lorenzo', 'pino', 'lorenzo123@gmail.com', 'dsafnadsfmn24knfkldasn', 'GB', '2002-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni');
CALL registrazioneUtente('lorenzo', 'gino', 'lorenzo23@gmail.com', 'dsafnadsfmn24knfkldasn', 'GB', '2002-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni');
CALL registrazioneUtente('lorenzo', 'rino', 'lorenzo12345@gmail.com', 'dsafnadsfmn24knfkldasn', 'GB', '2002-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni');

DELETE
FROM Utente
WHERE mail = 'lorenzo@gmail.com';
SELECT *
FROM Utente
WHERE mail = 'lorenzo@gmail.com';

CALL aggiuntaFunzionalitaExtra('306', '4K');

UPDATE Abbonamento
SET giornoFatturazione = 20
WHERE idUtente = '306';

DELETE
FROM OffertaFunzionalita
WHERE idUtente = '299';

INSERT INTO restrizionePacchetto(codiceStato, nomePacchetto)
VALUES ('IT', 'Deluxe');

SELECT *
FROM restrizionePacchetto;

SELECT *
FROM Abbonamento;

SELECT *
FROM CartaDiPagamento;

SELECT *
FROM MetodoDiPagamento;

SELECT *
FROM OffertaFunzionalita FO
         INNER JOIN FunzionalitaExtra FE ON FE.nome = FO.nomeFunzionalita;


CALL loginUtente('lorenzo@gmail.com', 'dsafnadsfmn24knfkldasn', '123.123.12.245', '10', 'Windows', 'Lorenzo-PC',
                 '20:20:20:20:20', 'desktop', '60', '167', @idUtente);

SELECT @idUtente;

SELECT *
FROM Connessione;

UPDATE Connessione
SET fine = NOW()
WHERE idUtente = 299;

SELECT NOW();

SELECT *
FROM Dispositivo;


-- TEST EMISSIONE FATTURE

CALL emissioneFatture(DAY(CURRENT_DATE));

SELECT *
FROM Fattura;

UPDATE Fattura
SET dataSaldo        = '2020-04-04',
    numeroCartaSaldo = '1234567891234561278'
WHERE codice = '2';

SELECT *
FROM MetodoDiPagamento
WHERE idUtente = 301;

SELECT *
FROM Film;

SELECT *
FROM Contenuto;


-- TEST BestServer
SELECT *
FROM Utente;



SELECT *
FROM Connessione;

SELECT latitudine, longitudine, idUtente
INTO @latitudine, @longitudine, @idUtente
FROM Connessione
WHERE ipDispositivo = '192.168.1.50';

SELECT latitudine, longitudine
INTO @latitudineS, @longitudineS
FROM Server
WHERE id = 4;

SELECT @latitudineS, @longitudineS;


SELECT *
FROM Contenuto C
         INNER JOIN Film F ON F.id = C.idFilm;

SELECT @latitudine, @longitudine, @idUtente;

# 29: Oppenheimer

CALL BestServer(29, @latitudine, @longitudine, @bestServerId);

SELECT @bestServerId;

INSERT INTO Archiviazione(idContenuto, idServer)
VALUES (29, 4);

SELECT *
FROM Archiviazione
WHERE idContenuto = 29;


SET @distanzaUtenteServer_ =
        ST_DISTANCE(POINT(@latitudine, @longitudine), POINT(@latitudineS, @longitudineS));
SET @costoStreaming_ = @distanzaUtenteServer_ * 0.2 + 100 * 0.3 + 100 * 0.5;

SELECT @costoStreaming_;

SELECT @distanzaUtenteServer_;

CALL VisualizzazioneContenuto(14, 1);

SELECT *
FROM Server;

DELETE
FROM Archiviazione

SELECT *
FROM Collegamento;

SELECT *
FROM Erogazione;

UPDATE Erogazione
SET fine        = NOW(),
    minutiVisti = 80;

UPDATE Erogazione
SET fine        = NOW(),
    minutiVisti = 80
WHERE idUtente = 14
  AND fine IS NULL;

SELECT *
FROM Utente;

SELECT *
FROM Compatibilita
WHERE idUtente = 14;



SELECT *
FROM Erogazione;

SELECT *
FROM Film;

UPDATE Erogazione
SET fine        = NOW(),
    minutiVisti = 100
WHERE id = 16;

SELECT *
FROM Erogazione;

SELECT *
FROM Compatibilita;

DELETE
FROM Compatibilita;

SELECT *
FROM Server
WHERE id = 3

SELECT *
FROM Abbonamento;

SELECT *
FROM Fattura;

CALL emissioneFatture(DAY(CURRENT_DATE))

SELECT *
FROM Erogazione E
         INNER JOIN Collegamento C ON C.idErogazione = E.id;

SELECT *
FROM Erogazione;

SELECT F.durata
FROM Contenuto C
         INNER JOIN Film F ON F.id = C.idFilm
WHERE C.id = 2;

UPDATE Erogazione E
SET E.fine      = NOW(),
    minutiVisti = 1
WHERE E.id = 1;

SELECT *
FROM Server;

SELECT *
FROM Collegamento;

SELECT *
FROM Archiviazione;

SELECT *
FROM Archiviazione
WHERE idServer = 7;

INSERT INTO Server(memoriaMax, bandaMax, tipo, ipAddress, latitudine, longitudine, localita)
VALUES (100, 60, 'edge', '192.167.2.4', 20, 20, 'IT');

SELECT *
FROM Erogazione;

DELETE
FROM Archiviazione
WHERE idServer = 7;

INSERT INTO Archiviazione(idContenuto, idServer)
VALUES (21, 7);
INSERT INTO Collegamento(idErogazione, idServer)
VALUES (4, 7);

UPDATE Collegamento
SET stato = 'interrotto'
WHERE idErogazione = 4;

SELECT *
FROM Collegamento;

SELECT *
FROM Contenuto;


SELECT F.numeroLike, SUM(C.visualizzazioni) AS views, SUM(C.watchtime) AS WatchTimeTotale, F.durata
FROM Film F
         INNER JOIN Contenuto C ON F.id = C.idFilm
WHERE F.id = 2;

# SELECT * FROM Contenuto;
UPDATE Contenuto
SET visualizzazioni = 312
WHERE idFilm = 2
  AND id = 17;

SELECT F.numeroLike,
       durata,
       (SELECT SUM(C.visualizzazioni) AS views
        FROM Contenuto C
        WHERE C.idFilm = F.id)
FROM Film F
WHERE F.id = 2;

SELECT idFilm, COUNT(*)
FROM Contenuto
GROUP BY idFilm;

CALL AggiornamentoRating();
CALL AggiornamentoClassificaGenere();



SELECT *
FROM ClassificaGenere
ORDER BY settimana, anno, idGenere, posizione;

UPDATE Contenuto
SET visualizzazioni = 15
WHERE idFilm = 4;

UPDATE Film
SET numeroLike = 25
WHERE id = 4;

SELECT *
FROM Contenuto;

SET @percentuale = 20;

SELECT *
FROM Compatibilita;


INSERT INTO Compatibilita(idFilm, idUtente, percentualeCompatibilita)
SELECT D.id,
       2,
       50 - (lambda(50) * (100 - @percentuale) / 10) AS NuovaPercentuale
FROM (SELECT *
      FROM Film F
      WHERE EXISTS(SELECT 1
                   FROM Classificazione C1
                   WHERE C1.idFilm = F.id
                     AND C1.idGenere IN (SELECT idGenere
                                         FROM Classificazione C2
                                         WHERE C2.idFilm = 2))) AS D
ON DUPLICATE KEY UPDATE percentualeCompatibilita = percentualeCompatibilita -
                                                   (lambda(100 - percentualeCompatibilita) * (100 - @percentuale) / 10)
;

DELETE
FROM Compatibilita;

SELECT DISTINCT idFilm
FROM Classificazione C
         INNER JOIN Film F ON F.id = C.idFilm
WHERE idGenere IN (2, 4, 9);

CALL aggiornaCompatibilitaFilmStessoGenere
    (2, 14, 10, 'incremento');



UPDATE Compatibilita
SET percentualeCompatibilita = 60
WHERE idFilm = 8
  AND idUtente = 14


SELECT F.durata, F.id
FROM Film F
         INNER JOIN Contenuto C ON C.idFilm = F.id
WHERE C.id = 9;



INSERT INTO RecensioneUtente(idUtente, idFilm, votazione)
VALUES (14, 2, 1);

DELETE
FROM RecensioneUtente;

SELECT *
FROM Compatibilita;

SELECT *
FROM Collegamento
         INNER JOIN Erogazione ON Collegamento.idErogazione = Erogazione.id;

CALL Operazione6('2', '2020-04-04', CURRENT_DATE(), @idServer);

SELECT @idServer;

SET @dataInizio_ = '2020-04-04';
SET @dataFine_ = CURRENT_DATE();

WITH ServerErogazioni AS (SELECT CL.idServer, COUNT(CL.idErogazione) AS numeroErogazioni
                          FROM Collegamento CL
                                   INNER JOIN Erogazione E ON CL.idErogazione = E.id
                                   INNER JOIN Contenuto C ON C.id = E.idContenuto

                          WHERE C.idFilm = 2
                            AND (E.inizio BETWEEN @dataInizio_ AND @dataFine_)
                            AND (E.fine BETWEEN @dataInizio_ AND @dataFine_)
                          GROUP BY CL.idServer)
SELECT *
FROM ServerErogazioni SE
#WHERE SE.numeroErogazioni >= ALL (SELECT numeroErogazioni
# FROM ServerErogazioni)
#LIMIT 1;

SELECT CL.idServer, COUNT(*)
FROM Collegamento CL
         INNER JOIN Erogazione E ON CL.idErogazione = E.id
         INNER JOIN Contenuto C ON C.id = E.idContenuto
WHERE C.idFilm = 2
  AND (DATE(E.inizio) BETWEEN @dataInizio_ AND @dataFine_)
  AND (DATE(E.fine) BETWEEN @dataInizio_ AND @dataFine_)
GROUP BY CL.idServer;



CALL Operazione7(@stato);

SELECT @stato;

SET @idFilm_ = 10;
SET @dataInizio_ = '2020-02-20';
SET @dataFine_ = CURRENT_DATE;



CALL registrazioneUtente('lorenzo', 'marranini', 'lorenzomarra@gmail.com', 'dsafnadsfmn24knfkldasn', 'IT', '2002-04-23',
                         'Deluxe', '1234567829123456178', '2030-02-20', 'visa', 'Lorenzo Moni');

CALL loginUtente('lorenzomarra@gmail.com', 'dsafnadsfmn24knfkldasn', '192.168.1.50', '10', 'windows', 'Marra-PC',
                 '2C:4D:54:4C:7B:5E', 'desktop', '37.5731', '126.97870', @userId);

INSERT INTO Contenuto(dimensione, aspectRateo, risoluzione, bitrate, idFilm, idFormato, idCodecAudio, idCodecVideo,
                      dataRilascio)
VALUES (1000, '16:10', '3840x2160', 1000, 1, 1, 3, 12, '2023-08-31');

SELECT *
FROM Archiviazione
WHERE idServer = 7;

INSERT INTO Archiviazione(idContenuto, idServer)
VALUES (42, 6)

SELECT *
FROM ServerLog

SELECT *
FROM Collegamento

SELECT *
FROM Contenuto

SELECT AVG(durata)
FROM Film

SELECT *
FROM Server;

SELECT *
FROM Fattura

SELECT *
FROM ServerLog

CALL VisualizzazioneContenuto(14, 42);

CALL GestioneExcessiveLoad(5);

SELECT *
FROM Collegamento

SELECT *
FROM Server
WHERE id <> -1;


SELECT *
FROM Erogazione E
         INNER JOIN Collegamento CL ON CL.idErogazione = E.id;

SELECT *
FROM Connessione

SELECT *
FROM Contenuto C
WHERE C.id IN (SELECT A.idContenuto FROM Archiviazione A WHERE A.idServer = 6)
SELECT *
FROM Archiviazione
WHERE idContenuto = 1
SELECT *
FROM Server
SELECT *
FROM Contenuto
SELECT *
FROM Erogazione;

CALL Operazione8(10, @dataInizio_, @dataFine_);

UPDATE Erogazione
SET fine        = NOW(),
    minutiVisti = 10
WHERE id IN (17, 18, 19);


# TEST BEST SERVER
UPDATE Utente
SET nazionalita = 'GB'
WHERE mail = 'lorenzomarra@gmail.com'



SELECT latitudine, longitudine, idUtente
INTO @latitudine, @longitudine, @idUtente
FROM Connessione
WHERE idUtente = 14

SELECT @latitudine, @longitudine, @idUtente;

SET @idContenuto = 4;

SELECT *
FROM Archiviazione
WHERE idContenuto = @idContenuto;

DELETE
FROM Archiviazione
WHERE idServer = 1;
DELETE
FROM Server
WHERE id = 1;

UPDATE Server
SET bandaUsata = 0
WHERE id = 5;
UPDATE Server
SET bandaUsata = 7000
WHERE id = 5;

SET @idBestServer = NULL;

CALL BestServer(3, @latitudine, @longitudine, @idBestServer);


SELECT *
FROM Server;

SELECT @idBestServer;

SELECT *
FROM Connessione;

SELECT *
FROM Utente;

SELECT *
FROM Contenuto
WHERE idFilm = 18;

CALL VisualizzazioneContenuto(14, 28);

SELECT *
FROM Archiviazione;

SELECT *
FROM Erogazione;

SELECT *
FROM Collegamento;

SELECT *
FROM Server;


SELECT *
FROM Erogazione E
         INNER JOIN Collegamento CL ON CL.idErogazione = E.id;

SELECT *
FROM Erogazione E
         INNER JOIN Utente U ON E.idUtente = U.id;


SELECT *
FROM Archiviazione A
WHERE A.idContenuto = 2
  AND A.idServer = 3;

SELECT *
FROM Connessione;

SELECT *
FROM Server;

CALL registrazioneUtente('lorenzo', 'moni', 'lorenzo@gmail.com', 'dsafnadsfmn24knfkldasn', 'IT', '2002-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni');

CALL loginUtente('lorenzo@gmail.com', 'dsafnadsfmn24knfkldasn', '192.168.1.50', '10', 'windows', 'Lorenzo-PC',
                 '2C:4D:54:4C:7B:5E', 'desktop', '41.920082', '-87.687521', @userId);

SELECT *
FROM Connessione
WHERE idUtente = 14;

SELECT *
FROM Connessione C
WHERE C.idUtente = 14
  AND C.fine IS NOT NULL

CALL registrazioneUtente('lorenzo', 'marranini', 'lorenzomarra@gmail.com', 'dsafnadsfmn24knfkldasn', 'GB', '2002-04-23',
                         'Deluxe', '1234567829123456178', '2030-02-20', 'visa', 'Lorenzo Moni');

CALL loginUtente('lorenzomarra@gmail.com', 'dsafnadsfmn24knfkldasn', '192.168.1.51', '10', 'windows', 'Marra-PC',
                 '2C:4D:54:4C:7B:5E', 'desktop', '37.5731', '126.97870', @userId);


UPDATE Erogazione
SET fine        = NOW(),
    minutiVisti = 30
WHERE fine IS NULL;


# SVILUPPO CLASSIFICHE

WITH CTE AS (SELECT E.*, F.durata, C.risoluzione, C.idFilm, U.nazionalita
             FROM Erogazione E
                      INNER JOIN Utente U ON E.idUtente = U.id
                      INNER JOIN Contenuto C ON C.id = E.idContenuto
                      INNER JOIN Film F ON F.id = C.idFilm),
     WatchtimePerRisoluzione AS (SELECT CTE.idFilm, CTE.nazionalita, CTE.risoluzione, SUM(CTE.minutiVisti) AS WatchTime
                                 FROM CTE
                                 GROUP BY CTE.idFilm, CTE.nazionalita, CTE.risoluzione)

SELECT WPR.idFilm,
       WPR.nazionalita,
       SUM(WPR.WatchTime),
       (SELECT WPR1.risoluzione
        FROM WatchtimePerRisoluzione WPR1
        WHERE WPR1.nazionalita = WPR.nazionalita
        GROUP BY WPR1.risoluzione
        HAVING MAX(WPR1.WatchTime)
        LIMIT 1) AS WatchTime
FROM WatchtimePerRisoluzione WPR
GROUP BY WPR.idFilm,
         WPR.nazionalita
             AND WPR1.idFilm = WPR.idFilm
;

CALL CreazioneClassificaStato();

SELECT *
FROM ClassificaStato
ORDER BY settimana, anno, codiceStato, posizione;



WITH CTE AS (SELECT E.*, F.durata, C.risoluzione, C.idFilm, U.nazionalita
             FROM Erogazione E
                      INNER JOIN Utente U ON E.idUtente = U.id
                      INNER JOIN Contenuto C ON C.id = E.idContenuto
                      INNER JOIN Film F ON F.id = C.idFilm),
     WatchtimePerRisoluzione AS (SELECT CTE.idFilm, CTE.nazionalita, CTE.risoluzione, SUM(CTE.minutiVisti) AS WatchTime
                                 FROM CTE
                                 GROUP BY CTE.idFilm, CTE.nazionalita, CTE.risoluzione)
SELECT WPR1.risoluzione, WatchTime
FROM WatchtimePerRisoluzione WPR1
WHERE WPR1.nazionalita = 'IT'
  AND WPR1.idFilm = 18
GROUP BY WPR1.risoluzione;


SELECT *
FROM ClassificaStato;


WITH CTE AS (SELECT E.*, F.durata, C.risoluzione, C.idFilm, U.nazionalita, C.watchtime
             FROM Erogazione E
                      INNER JOIN Utente U ON E.idUtente = U.id
                      INNER JOIN Contenuto C ON C.id = E.idContenuto
                      INNER JOIN Film F ON F.id = C.idFilm),
     WatchtimePerRisoluzione AS (SELECT CTE.idFilm, CTE.nazionalita, CTE.risoluzione, SUM(CTE.minutiVisti) AS WatchTime
                                 FROM CTE
                                 GROUP BY CTE.idFilm, CTE.nazionalita, CTE.risoluzione),
     WatchtimeMaxPerFilmENazione AS (SELECT W.idFilm, W.nazionalita, MAX(W.WatchTime) AS MaxWatchtime
                                     FROM WatchtimePerRisoluzione W
                                     GROUP BY W.idFilm, W.nazionalita),
     RisoluzioniPerFilmENazione AS (SELECT W.idFilm,
                                           W.nazionalita,
                                           WW.risoluzione,
                                           ROW_NUMBER() OVER (PARTITION BY W.idFilm,W.nazionalita) AS numero
                                    FROM WatchtimeMaxPerFilmENazione W
                                             INNER JOIN WatchtimePerRisoluzione WW ON W.idFilm = WW.idFilm
                                    WHERE W.nazionalita = WW.nazionalita
                                      AND W.MaxWatchtime = WW.WatchTime),
     RisoluzioneUnicaPerFilmENazione AS (SELECT *
                                         FROM RisoluzioniPerFilmENazione
                                         WHERE numero = 1),
     FilmNazioneScore AS (SELECT C.idFilm, C.nazionalita, (SUM(C.watchtime) / C.durata) AS score
                          FROM CTE C
                          GROUP BY C.idFilm, C.nazionalita)
SELECT F.nazionalita,
       F.idFilm,
       DENSE_RANK() OVER (PARTITION BY F.nazionalita ORDER BY F.score DESC) AS posizione,
       R.risoluzione,
       WEEK(CURRENT_DATE)                                                   AS settimana,
       YEAR(CURRENT_DATE)                                                   AS anno
FROM FilmNazioneScore F
         INNER JOIN RisoluzioneUnicaPerFilmENazione R ON (F.idFilm = R.idFilm AND F.nazionalita = R.nazionalita);



WITH CTE AS (SELECT E.*, F.durata, C.risoluzione, C.idFilm, A.nomePacchetto, C.watchtime
             FROM Erogazione E
                      INNER JOIN Utente U ON E.idUtente = U.id
                      INNER JOIN Contenuto C ON C.id = E.idContenuto
                      INNER JOIN Film F ON F.id = C.idFilm
                      INNER JOIN Abbonamento A ON A.idUtente = U.id),
     WatchtimePerRisoluzione AS (SELECT CTE.idFilm,
                                        CTE.nomePacchetto,
                                        CTE.risoluzione,
                                        SUM(CTE.minutiVisti) AS WatchTime
                                 FROM CTE
                                 GROUP BY CTE.idFilm, CTE.nomePacchetto, CTE.risoluzione),
     WatchtimeMaxPerFilmENazione AS (SELECT W.idFilm, W.nomePacchetto, MAX(W.WatchTime) AS MaxWatchtime
                                     FROM WatchtimePerRisoluzione W
                                     GROUP BY W.idFilm, W.nomePacchetto),
     RisoluzioniPerFilmENazione AS (SELECT W.idFilm,
                                           W.nomePacchetto,
                                           WW.risoluzione,
                                           ROW_NUMBER() OVER (PARTITION BY W.idFilm,W.nomePacchetto) AS numero
                                    FROM WatchtimeMaxPerFilmENazione W
                                             INNER JOIN WatchtimePerRisoluzione WW ON W.idFilm = WW.idFilm
                                    WHERE W.nomePacchetto = WW.nomePacchetto
                                      AND W.MaxWatchtime = WW.WatchTime),
     RisoluzioneUnicaPerFilmENazione AS (SELECT *
                                         FROM RisoluzioniPerFilmENazione
                                         WHERE numero = 1),
     FilmNazioneScore AS (SELECT C.idFilm, C.nomePacchetto, (SUM(C.watchtime) / C.durata) AS score
                          FROM CTE C
                          GROUP BY C.idFilm, C.nomePacchetto)
SELECT F.nomePacchetto,
       F.idFilm,
       DENSE_RANK() OVER (PARTITION BY F.nomePacchetto ORDER BY F.score DESC) AS posizione,
       R.risoluzione,
       WEEK(CURRENT_DATE)                                                     AS settimana,
       YEAR(CURRENT_DATE)                                                     AS anno
FROM FilmNazioneScore F
         INNER JOIN RisoluzioneUnicaPerFilmENazione R ON (F.idFilm = R.idFilm AND F.nomePacchetto = R.nomePacchetto);



CALL loginUtente('lorenzomarra@gmail.com', 'dsafnadsfmn24knfkldasn', '192.168.1.50', '10', 'windows', 'Marra-PC',
                 '2C:4D:54:4C:7B:5E', 'desktop', '70.5731', '126.97870', @userId);


CALL CreazioneClassificaPacchetto();

SELECT anno, settimana, nomePacchetto, posizione, idFilm, risoluzione
FROM ClassificaPacchetto
ORDER BY anno, settimana, nomePacchetto, posizione;

UPDATE Connessione
SET fine = NOW();

WITH Conessioni AS (SELECT *
                    FROM Utente U
                             INNER JOIN Connessione C ON C.idUtente = U.id)

SELECT *
FROM Conessioni C
WHERE C.inizio = (SELECT MAX(inizio)
                  FROM Conessioni C1
                  WHERE C1.idUtente = C.idUtente)

SET @idUtente = 14;
SET @idServerVicino_ = 2;

WITH FilmPiuCompatibili AS (SELECT *
                            FROM Compatibilita C
                            WHERE C.idUtente = @idUtente
                              AND percentualeCompatibilita > 70
                            ORDER BY C.percentualeCompatibilita DESC
                            LIMIT 3)
SELECT @idServerVicino_, C.id
FROM FilmPiuCompatibili FC
         INNER JOIN Contenuto C ON FC.idFilm = C.idFilm;

SELECT *
FROM Server;

CALL CachingContenutiRaccomandati();

SELECT *
FROM Archiviazione
WHERE idServer = 2;

INSERT IGNORE INTO Archiviazione(idContenuto, idServer)
WITH FilmPiuCompatibili AS (SELECT C.idFilm
                            FROM Compatibilita C
                            WHERE C.idUtente = 14
                              AND percentualeCompatibilita > 70
                            ORDER BY C.percentualeCompatibilita DESC
                            LIMIT 3)
SELECT C.id, 2
FROM FilmPiuCompatibili FC
         INNER JOIN Contenuto C ON FC.idFilm = C.idFilm;

SELECT *
FROM Archiviazione
WHERE idServer = 2;

WITH Connessioni AS (SELECT *
                     FROM Utente U
                              INNER JOIN Connessione C ON C.idUtente = U.id)
SELECT idUtente, latitudine, longitudine
FROM Connessioni C
WHERE C.inizio = (SELECT MAX(inizio)
                  FROM Connessioni C1
                  WHERE C1.idUtente = C.idUtente);

SELECT latitudine, longitudine
INTO @latitudine, @longitudine
FROM Connessione
WHERE idUtente = 15
  AND fine IS NOT NULL;

WITH ServerDistanze AS (SELECT S.id,
                               ST_DISTANCE(POINT(@latitudine, @longitudine),
                                           POINT(S.latitudine, S.longitudine)) AS distanza
                        FROM Server S)
SELECT S.id, S.distanza

FROM ServerDistanze S;


WITH ServerDistanze AS (SELECT S.id,
                               ST_DISTANCE(POINT(@latitudine, @longitudine),
                                           POINT(S.latitudine, S.longitudine)) AS distanza
                        FROM Server S)
SELECT S.id, S.distanza
FROM ServerDistanze S
WHERE S.distanza = (SELECT MIN(S1.distanza) FROM ServerDistanze S1);

CALL CachingContenutiRaccomandati();

SELECT *
FROM Server;

DELETE
FROM Archiviazione
WHERE idServer = 4
  AND idContenuto = 2;

SELECT *
FROM Archiviazione
WHERE idServer = 4;

SELECT *
FROM Erogazione;

SELECT *
FROM Compatibilita C
WHERE C.idUtente = 14
  AND percentualeCompatibilita > 70
  AND NOT EXISTS(SELECT 1
                 FROM Erogazione E
                 WHERE E.idUtente = 14
                   AND E.idContenuto IN (SELECT CO.id
                                         FROM Contenuto CO
                                         WHERE CO.idFilm = C.idFilm))
ORDER BY C.percentualeCompatibilita DESC
LIMIT 3;

CALL CachingContenutiRaccomandati();

SELECT *
FROM Server;

SELECT *
FROM Compatibilita;

DELETE
FROM Archiviazione
WHERE idContenuto = 3
  AND idServer = 4;



SELECT *
FROM ServerLog;

UPDATE Erogazione
SET fine        = NOW(),
    minutiVisti = 70
WHERE fine IS NULL;

SELECT *
FROM Erogazione
WHERE fine IS NOT NULL;

SELECT *
FROM Compatibilita;


SELECT *
FROM Server;

SELECT *
FROM Collegamento C
         INNER JOIN Erogazione E ON C.idErogazione = E.id
         INNER JOIN Connessione CE ON (E.idUtente = CE.idUtente AND E.ipDispositivo = CE.ipDispositivo AND
                                       E.inizioConnessione = CE.inizio)
WHERE C.idServer = 2
  AND C.stato = 'attivo'
ORDER BY E.inizio
        DESC;

SET @idserver_ = 6;

SELECT *
FROM Collegamento
WHERE idServer = 4
  AND stato = 'attivo';

SELECT *
FROM Collegamento
WHERE idServer = 6;

SELECT D.idContenuto, numeroErogazioni
FROM (SELECT E.idcontenuto, COUNT(*) AS numeroErogazioni
      FROM Erogazione E
               INNER JOIN Collegamento CL ON CL.idErogazione = E.id
      WHERE CL.idServer = 6
        AND CL.stato <> 'attivo'
      GROUP BY E.idContenuto) AS D

ORDER BY D.numeroErogazioni;

UPDATE Erogazione
SET fine        = NOW(),
    minutiVisti =20
WHERE fine IS NULL;


SELECT *
FROM Server;

SELECT *
FROM Contenuto
WHERE dimensione < 20;

INSERT IGNORE INTO Archiviazione(idContenuto, idServer)
SELECT idContenuto, 7
FROM Archiviazione;

INSERT INTO Archiviazione(idContenuto, idServer)
VALUES (25, 7);

SELECT *
FROM ServerLog;

SELECT *
FROM Server;

CALL GestioneExcessiveMemory(7);


WITH ErogazioniContenuto AS (SELECT *
                             FROM Erogazione E
                                      INNER JOIN Collegamento CL ON E.id = CL.idServer
                             WHERE CL.idServer = 6)

SELECT A.idContenuto, SUM(IF(E1.idErogazione IS NULL, 0, 1)) AS Erogazioni
FROM Archiviazione A
         LEFT JOIN ErogazioniContenuto E1 ON E1.idContenuto = A.idContenuto
WHERE A.idServer = 6
GROUP BY A.idContenuto
ORDER BY Erogazioni;



WITH ErogazioniContenuto AS (SELECT *
                             FROM Erogazione E
                                      INNER JOIN Collegamento CL ON E.id = CL.idServer
                             WHERE CL.idServer = 6),
     Result AS (SELECT A.idContenuto, SUM(IF(E1.idErogazione IS NULL, 0, 1)) AS Erogazioni
                FROM Archiviazione A
                         LEFT JOIN ErogazioniContenuto E1 ON E1.idContenuto = A.idContenuto
                WHERE A.idServer = 6
                GROUP BY A.idContenuto
                ORDER BY Erogazioni)
SELECT R.idContenuto
FROM Result R;

SELECT *
FROM Erogazione;

SELECT -COUNT(*) / 2
FROM Utente;

SELECT memoriaUsata / Server.memoriaMax
FROM Server;

SELECT *
FROM ServerLog;


WITH ContenutiNonRistretti AS (SELECT C.*, ROW_NUMBER() OVER () AS numero
                               FROM Contenuto C
                               WHERE NOT EXISTS(SELECT 1
                                                FROM RestrizioneContenuto RC
                                                WHERE RC.idContenuto = C.id)
                                 AND risoluzione IN ('FHD', 'HD'))
SELECT CNR.id
FROM ContenutiNonRistretti CNR
WHERE CNR.numero;


WITH dispositivi AS (SELECT D.*, ROW_NUMBER() OVER () AS numero
                     FROM Dispositivo D)
SELECT *
FROM dispositivi D1

SELECT *
FROM Utente U
         INNER JOIN Abbonamento A ON A.idUtente = U.id
WHERE NOT EXISTS(SELECT 1 FROM Connessione C1 WHERE C1.idUtente = U.id AND C1.fine IS NULL)



SELECT C.id, COUNT(*)
FROM Archiviazione A
         INNER JOIN Contenuto C ON C.id = A.idContenuto
GROUP BY C.id

SELECT *
FROM Abbonamento


SELECT ST_DISTANCE_SPHERE(POINT(-118, 34), POINT(-70, 40)) AS distanza;


SET @distanzaUtenteServer_ =
            ST_DISTANCE_SPHERE(POINT(longitudineUtente_, latitudineUtente_),
                               POINT(longitudineServer_, latitudineServer_)) / 1000;
SET @costoStreaming_ =
                (@distanzaUtenteServer_ / 20000) * 0.3 + (bitrateContenuto_ * durataContenuto_ / 10) * 0.2 +
                (@bandausata_ / bandaMax_ * 100) * 0.5;

SELECT COUNT(*)
FROM Contenuto;

SET @idServerFull_ = 1;

SELECT id, bandaUsata, memoriaUsata, latitudine, longitudine, bandaMax, memoriaMax
FROM Server
WHERE id <> IFNULL(@idServerFull_, 0);

SELECT dimensione
FROM Contenuto
WHERE id = 42
SELECT *
FROM Server

SELECT *
FROM Genere;

SELECT *
FROM Film
WHERE titolo = 'Inceptionj'
SELECT *
FROM Artista
WHERE cognome = 'Nolan'

SELECT C.idUtente,
       F.titolo,
       CONCAT(C.percentualeCompatibilita, '%')     AS compatibilita,
       GROUP_CONCAT(DISTINCT G.nome ORDER BY G.id) AS Generi
FROM Compatibilita C
         INNER JOIN Film F ON F.id = C.idFilm
         INNER JOIN Classificazione CLF ON CLF.idFilm = F.id
         INNER JOIN Genere G ON G.id = CLF.idGenere
WHERE idUtente = 55
GROUP BY C.idUtente, F.titolo, compatibilita
ORDER BY compatibilita DESC;

SELECT *
FROM Film F
WHERE NOT EXISTS(SELECT 1
                 FROM Contenuto C
                 WHERE C.idFilm = F.id)

SELECT *
FROM Contenuto C
WHERE NOT EXISTS(SELECT 1
                 FROM Archiviazione A
                 WHERE A.idContenuto = C.id)
SELECT COUNT(*) FROM Contenuto