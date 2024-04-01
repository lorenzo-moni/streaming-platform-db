USE filmsphere;

# ---------------------
#   Test Operazione 1: registrazioneUtente
# ---------------------

-- Test dataNascita
CALL registrazioneUtente('Lorenzo', 'Moni', 'lorenzomoni@studenti.unipi.it', 'fdc847aa960ef3e62696f534acb09dbe4b1dff86',
                         'IT', '2015-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni', @idUtente1);

-- Test Restrizione Pacchetto

SELECT *
FROM RestrizionePacchetto
WHERE codiceStato = 'IT';

CALL registrazioneUtente('Lorenzo', 'Moni', 'lorenzomoni@studenti.unipi.it', 'fdc847aa960ef3e62696f534acb09dbe4b1dff86',
                         'IT', '2003-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni', @idUtente1);

-- Test età minima Pacchetto

SELECT etaMinima
FROM Pacchetto
WHERE nome = 'Ultimate';

CALL registrazioneUtente('Lorenzo', 'Moni', 'lorenzomoni@studenti.unipi.it', 'fdc847aa960ef3e62696f534acb09dbe4b1dff86',
                         'IT', '2008-04-23',
                         'Ultimate', '1234567891234561278', '2030-02-20', 'visa', 'Lorenzo Moni', @idUtente1);

-- Test CartaDiPagamento Scaduta


-- Test Inserimento Corretto con la stessa CartaDiPagamento

SET @numeroCarta1 = '1234567891234561278';
SET @dataScadenza1 = '2030-12-06';
SET @circuito1 = 'visa';
SET @intestatario1 = 'Lorenzo Moni';

SET @numeroCarta2 = '1234567821234561278';
SET @dataScadenza2 = '2032-12-01';
SET @circuito2 = 'american express';
SET @intestatario2 = 'Mario Rossi';

CALL registrazioneUtente('Lorenzo',
                         'Moni',
                         'lorenzomoni@studenti.unipi.it',
                         'fdc847aa960ef3e62696f534acb09dbe4b1dff86',
                         'IT',
                         '2003-04-23',
                         'premium',
                         @numeroCarta1,
                         @dataScadenza1,
                         @circuito1,
                         @intestatario1,
                         @idUtente1);

CALL registrazioneUtente('Lorenzo', 'Marranini',
                         'lorenzomarranini@studenti.unipi.it',
                         '6cd9ee9cb19b1981b0e147fb1973ec9b1f3e8933',
                         'US', '2003-02-24',
                         'ultimate',
                         @numeroCarta1,
                         @dataScadenza1,
                         @circuito1,
                         @intestatario1,
                         @idUtente2);

CALL registrazioneUtente('Mario', 'Rossi',
                         'mariorossi@studenti.unipi.it',
                         '81f1c9c599cad89ed055a6676a94e62ab8ca1fe4',
                         'GE', '1996-02-24',
                         'Basic',
                         @numeroCarta2,
                         @dataScadenza2,
                         @circuito2,
                         @intestatario2,
                         @idUtente3);

SELECT *
FROM CartaDiPagamento;

SELECT U.id, U.mail, CDP.*
FROM MetodoDiPagamento MDP
         INNER JOIN CartaDiPagamento CDP ON MDP.numeroCarta = CDP.numero
         INNER JOIN Utente U ON U.id = MDP.idUtente;

-- Generazione Automatica Costo Mensile in base all'abbonamento

SELECT *
FROM Pacchetto
WHERE nome IN ('Premium', 'Deluxe');

SELECT *
FROM Abbonamento
WHERE idUtente IN (@idUtente1, @idUtente2);

-- Aggiunta Funzionalità Extra

SELECT *
FROM FunzionalitaExtra;

-- Tentativo di aggiunta di funzionalità già inclusa nel pacchetto
-- La funzionalità 4K è già presente nel piano Deluxe

SELECT *
FROM Abbonamento
WHERE idUtente = @idUtente2;

CALL aggiuntaFunzionalitaExtra(@idUtente2, '4K');

-- Aggiunta funzionalità corretta

CALL aggiuntaFunzionalitaExtra(@idUtente1, '4K');

SELECT *
FROM Abbonamento
WHERE idUtente IN (@idUtente1, @idUtente2);

# ---------------------
#   Test Operazione 2: loginUtente
# ---------------------

SELECT *
FROM Connessione;

-- Connessione da Seul, South Korea
SET @latitudine1 = 37.542;
SET @longitudine1 = 126.990;
SET @ipAddress1 = '87.91.124.1';

-- Connessione da Chicago, Illinois, US
SET @latitudine2 = 41.773;
SET @longitudine2 = -87.442;
SET @ipAddress2 = '87.54.122.54';

-- Mail inesistente
CALL loginUtente('mail@gmail.com', 'dsafnadsfmn24knfkldasn', @ipAddress1, '10', 'windows', 'Desktop-PC',
                 '2C:4D:54:4C:7B:5E', 'desktop', @latitudine1, @longitudine1, @idUtente1);

-- Password Errata
CALL loginUtente('lorenzomoni@studenti.unipi.it', 'dsafnadsfmn24knfkldasn', @ipAddress1, '10', 'windows', 'Desktop-PC',
                 '2C:4D:54:4C:7B:5E', 'desktop', @latitudine1, @longitudine1, @idUtente1);

-- Login corretto

CALL loginUtente('lorenzomoni@studenti.unipi.it', 'fdc847aa960ef3e62696f534acb09dbe4b1dff86', @ipAddress1, '10',
                 'windows', 'Desktop-PC',
                 '2C:4D:54:4C:7B:5E', 'desktop', @latitudine1, @longitudine1, @idUtente1);

CALL loginUtente('lorenzomarranini@studenti.unipi.it', '6cd9ee9cb19b1981b0e147fb1973ec9b1f3e8933', @ipAddress2, '10',
                 'osx', 'Ipad',
                 '2C:4D:54:4C:7B:5E', 'tablet', @latitudine2, @longitudine2, @idUtente2);

-- Controllo Connessioni in Corso
SELECT *
FROM Connessione
WHERE idUtente IN (@idUtente1, @idUtente2);

# ---------------------
#   Test Operazione 3: EmissioneFatture
# ---------------------

SELECT *
FROM Fattura;

SELECT *
FROM Fattura
WHERE idUtente IN (@idUtente1, @idUtente2);

CALL emissioneFatture(DAY(CURRENT_DATE));

SELECT *
FROM Fattura
WHERE idUtente IN (@idUtente1, @idUtente2);

SELECT codice
INTO @codiceFattura1
FROM Fattura
WHERE idUtente = @idUtente1;
# SELECT codice INTO @codiceFattura2 FROM Fattura WHERE idUtente = @idUtente2;

-- Saldo fattura con carta non appartenente all'utente

CALL SaldaFattura(@codiceFattura1, '12345678914121564', @idUtente1);

-- Saldo fattura di un altro utente

CALL SaldaFattura(@codiceFattura1, '12345678914121564', @idUtente2);

-- Saldo fattura corretto

CALL SaldaFattura(@codiceFattura1, @numeroCarta, @idUtente1);

SELECT *
FROM Fattura
WHERE idUtente IN (@idUtente1, @idUtente2);

# ---------------------
#   Test Operazione 4: VisualizzazioneContenuto
# ---------------------

-- Test Abbonamento non attivo / Utente non esistente

CALL VisualizzazioneContenuto(500, 4);

-- Utente non loggato

CALL VisualizzazioneContenuto(@idUtente3, 4);

-- Visualizzazione Contenuto Ristretto nello Stato

SELECT nazionalita
FROM Utente
WHERE id = @idUtente1;
SELECT *
FROM RestrizioneContenuto;

CALL VisualizzazioneContenuto(@idUtente1, 4);

-- Visualizzazione Contenuto non visualizzabile con l'abbonamento corrente

CALL VisualizzazioneContenuto(@idUtente1, 1);

-- Generazione di Erogazioni per test funzionalità BestServer

CALL generaErogazioni();

SELECT *
FROM Server S;

SELECT *
FROM Erogazione;

-- Il contenuto 42 si trova sul server localizzato a Paris, France

SELECT S.*
FROM Archiviazione A
         INNER JOIN Server S ON S.id = A.idServer
WHERE A.idContenuto = 42;

-- Prime due visualizzazioni da Parigi, poi il contenuto viene spostato a New York.
CALL VisualizzazioneContenuto(55, 42);
SELECT *
FROM Server;

-- Generazione Erogazioni

SET @debug = FALSE;
CALL generaErogazioni();

SELECT *
FROM Erogazione;
SELECT *
FROM Server;

SELECT S.*
FROM Archiviazione A
         INNER JOIN Server S ON S.id = A.idServer
WHERE A.idContenuto = 39;

CALL VisualizzazioneContenuto(55, 39);
SELECT *
FROM Server;

# ---------------------
#   Test Operazione 5: Aggiornamento Rating e Classifiche Genere
# ---------------------

UPDATE Erogazione E
SET fine        = NOW(),
    minutiVisti = 80
WHERE fine IS NULL;



SELECT id, titolo, rating, numeroLike
FROM Film;

SELECT *
FROM PremiazioneFilm;
SELECT *
FROM PremiazioneAttore;
SELECT *
FROM PremiazioneRegista;
SELECT *
FROM RecensioneUtente;
SELECT C.id, C.watchtime, C.visualizzazioni
FROM Contenuto C;

CALL AggiornamentoRating();

SELECT id, titolo, rating
FROM Film;

SELECT *
FROM ClassificaGenere;

CALL CreazioneClassificaGenere();

CALL MostraClassificaGenere(37, 2023);

# ---------------------
#   Test Operazione 6
# ---------------------

SET @idFilm = 1;
SET @dataInizio = DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR);
SET @dataFine = CURRENT_DATE();
CALL Operazione6(@idFilm, @dataInizio, @dataFine, @idServer);

SELECT @idServer;

# ---------------------
#   Test Operazione 7
# ---------------------
CALL Operazione7();

# ---------------------
#   Test Operazione 8
# ---------------------
CALL Operazione8(@idFilm, @dataInizio, @dataFine);


# ---------------------
#   Test Funzionalità Raccomandazione Contenuti
# ---------------------

SET @idUtente1 = 55;

SELECT F.id, F.titolo, C.id, F.durata, G.nome
FROM Contenuto C
         INNER JOIN Film F ON F.id = C.idFilm
         INNER JOIN Classificazione CLF ON CLF.idFilm = F.id
         INNER JOIN Genere G ON G.id = CLF.idGenere
WHERE F.titolo = 'Oppenheimer'
   OR F.titolo = 'Barbie';

-- Aumento Compatibilità

CALL VisualizzazioneContenuto(@idUtente1, 29);

UPDATE Erogazione E
SET fine        = NOW(),
    minutiVisti = 170
WHERE idContenuto = 29
  AND idUtente = @idUtente1
  AND fine IS NULL;

CALL MostraCompatibilitaUtente(@idUtente1);

-- Inserimento recensione prima di effettuare la visualizzazione

INSERT INTO RecensioneUtente(idUtente, idFilm, data, votazione)
VALUES (@idUtente1, 15, '2020-12-12', 1);

-- Inserimento recensione corretta

INSERT INTO RecensioneUtente(idUtente, idFilm, data, votazione)
VALUES (@idUtente1, 15, CURRENT_DATE, 1);

CALL MostraCompatibilitaUtente(@idUtente1);

-- Diminuzione Compatibilità

CALL VisualizzazioneContenuto(@idUtente1, 38);

UPDATE Erogazione E
SET fine        = NOW(),
    minutiVisti = 50
WHERE idContenuto = 38
  AND idUtente = @idUtente1
  AND fine IS NULL;

CALL MostraCompatibilitaUtente(@idUtente1);

# ---------------------
#   Test Funzionalità Classifiche
# ---------------------

-- Creazione Classifica Stato
CALL CreazioneClassificaStato();

CALL MostraClassificaStato(NULL, NULL);

-- Creazione Classifica Pacchetto
CALL CreazioneClassificaPacchetto();

CALL MostraClassificaPacchetto(NULL, NULL);

# ---------------------
#   Test Funzionalità Caching
# ---------------------

CALL MostraCompatibilitaUtente(@idUtente1);

SELECT C.id as idContenuto, F.id as idFilm, F.titolo, S.latitudine, S.longitudine, S.localita
FROM Archiviazione A
         INNER JOIN Contenuto C ON C.id = A.idContenuto
         INNER JOIN Server S ON S.id = A.idServer
         INNER JOIN Film F ON F.id = C.idFilm
WHERE F.titolo = 'Interstellar' OR F.titolo = 'Inception' OR F.titolo = 'The Flash';

CALL VisualizzazioneContenuto(@idUtente1, 16);

UPDATE Erogazione E
SET fine        = NOW(),
    minutiVisti = 148
WHERE idContenuto = 16
  AND idUtente = @idUtente1
  AND fine IS NULL;

INSERT INTO RecensioneUtente(idUtente, idFilm, data, votazione)
VALUES (@idUtente1, 22, CURRENT_DATE, 1);

CALL MostraCompatibilitaUtente(@idUtente1);

SELECT * FROM Server;

CALL CachingContenutiRaccomandati();

SELECT C.id as idContenuto, F.id as idFilm, F.titolo, S.latitudine, S.longitudine, S.localita
FROM Archiviazione A
         INNER JOIN Contenuto C ON C.id = A.idContenuto
         INNER JOIN Server S ON S.id = A.idServer
         INNER JOIN Film F ON F.id = C.idFilm
WHERE idServer = 4;
