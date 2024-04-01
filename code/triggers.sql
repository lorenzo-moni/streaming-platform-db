USE filmsphere;


DELIMITER $$

/*------------------------------
  Trigger 1
  Nome: controlloEtaUtente
  Descrizione: il seguente trigger gestisce il vincolo di tupla sull'età minima consentita per la registrazione di un utente.

 ------------------------------*/
DROP TRIGGER IF EXISTS controlloEtaUtente $$

CREATE TRIGGER controlloEtaUtente
    BEFORE INSERT
    ON Utente
    FOR EACH ROW
BEGIN
    IF NEW.dataDiNascita + INTERVAL 10 YEAR > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'l\'età minima consentita per la registrazione è di 10 anni';
    END IF;
END $$


/*------------------------------
  Trigger 2
  Nome: setGiornoFatturazione
  Descrizione: il seguente trigger si occupa di gestire il giorno di fatturazione durante la creazione di un abbonamento,
            se l'abbonamento viene creato dopo il 28 del mese, il giorno di fatturazione deve essere impostato al 28.

 ------------------------------*/
DROP TRIGGER IF EXISTS setGiornoFatturazione $$

CREATE TRIGGER setGiornoFatturazione
    BEFORE INSERT
    ON Abbonamento
    FOR EACH ROW
BEGIN
    -- i giorni di fatturazione variano da 1 a 28 per evitare problemi nei mesi come febbraio
    IF DAY(CURRENT_DATE) > 28 THEN
        SET NEW.giornoFatturazione = 28;
    ELSE
        SET NEW.giornoFatturazione = DAY(CURRENT_DATE);
    END IF;
END $$

/*------------------------------
  Trigger 3
  Nome: checkDataRilascioContenuto
  Descrizione: il seguente trigger si occupa di controllare che la data di rilascio di un contenuto non sia maggiore della data attuale
            e l'anno non sia inferiore all'anno di produzione del relativo Film.

 ------------------------------*/
DROP TRIGGER IF EXISTS checkDataRilascioContenuto $$

CREATE TRIGGER checkDataRilascioContenuto
    BEFORE INSERT
    ON Contenuto
    FOR EACH ROW
BEGIN

    DECLARE annoProduzione SMALLINT UNSIGNED;

    IF NEW.dataRilascio > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = ' Il contenuto non può essere stato rilasciato nel futuro';
    END IF;

    SELECT F.annoProduzione INTO annoProduzione FROM Film F WHERE F.id = NEW.idFilm;

    IF YEAR(NEW.dataRilascio) < annoProduzione THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = ' Il contenuto non può essere rilasciato prima della produzione del relativo film';
    END IF;


END $$

/*------------------------------
  Trigger 4
  Nome: checkCollegamento
  Descrizione: il seguente trigger si occupa di controllare l'inserimento di un Collegamento.
 ------------------------------*/
DROP TRIGGER IF EXISTS checkCollegamento $$

CREATE TRIGGER checkCollegamento
    BEFORE INSERT
    ON Collegamento
    FOR EACH ROW
BEGIN

    -- prima di inserire una nuova istanza in collegamento si controlla se esista già un collegamento con la stessa erogazione che è già terminata
-- ( e quindi non può essere riattivata ) oppure è attiva in quel momento, e non ce ne possono essere due attive in contemporanea

    IF EXISTS (SELECT 1
               FROM Collegamento C
               WHERE C.idErogazione = NEW.idErogazione
                 AND (C.stato = 'attivo' OR C.stato = 'terminato')) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'un \'erogazione non può essere collegata a più server nello stesso momento';
    END IF;


END $$

/*------------------------------
  Trigger 5
  Nome: checkCodecContenutoInsert
  Descrizione: il seguente trigger si occupa di controllare che un Contenuto abbia un Codec Audio e un CodecVideo
            in inserimento.

 ------------------------------*/
DROP TRIGGER IF EXISTS checkCodecContenutoInsert $$

CREATE TRIGGER checkCodecContenutoInsert
    BEFORE INSERT
    ON Contenuto
    FOR EACH ROW
BEGIN

    DECLARE checkCodecVideo VARCHAR(255);
    DECLARE checkCodecAudio VARCHAR(255);
    SELECT tipologia INTO checkCodecVideo FROM Codec C WHERE C.id = NEW.idCodecVideo;
    SELECT tipologia INTO checkCodecAudio FROM Codec C WHERE C.id = NEW.idCodecAudio;

    IF (checkCodecVideo <> 'video' OR checkCodecAudio <> 'audio') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'I codec selezionati per il contenuto inserito non sono della tipologia corretta';
    END IF;
END $$

/*------------------------------
  Trigger 6
  Nome: checkCodecContenutoUpdate
  Descrizione: il seguente trigger si occupa di controllare che un Contenuto abbia un Codec Audio e un CodecVideo
            in aggiornamento.

 ------------------------------*/
DROP TRIGGER IF EXISTS checkCodecContenutoUpdate $$

CREATE TRIGGER checkCodecContenutoUpdate
    BEFORE UPDATE
    ON Contenuto
    FOR EACH ROW
BEGIN
    DECLARE checkCodecVideo VARCHAR(255);
    DECLARE checkCodecAudio VARCHAR(255);
    SELECT tipologia INTO checkCodecVideo FROM Codec C WHERE C.id = NEW.idCodecVideo;
    SELECT tipologia INTO checkCodecAudio FROM Codec C WHERE C.id = NEW.idCodecAudio;

    IF (checkCodecVideo <> 'video' OR checkCodecAudio <> 'audio') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'I codec selezionati per il contenuto inserito non sono della tipologia corretta';
    END IF;
END $$

/*------------------------------
  Trigger 7
  Nome: checkRecensioneUtente
  Descrizione: il seguente trigger si occupa di controllare che un utente abbia visualizzato un film
            per più del 25% della sua durata prima di inserire una recensione.

 ------------------------------*/

DROP TRIGGER IF EXISTS checkRecensioneUtente $$

CREATE TRIGGER checkRecensioneUtente
    BEFORE INSERT
    ON RecensioneUtente
    FOR EACH ROW
BEGIN

    DECLARE durataContenuto_ SMALLINT UNSIGNED;

    SELECT durata INTO durataContenuto_ FROM Film F WHERE F.id = NEW.idFilm;
-- si fa un check dell'attributo minutiVisti in erogazione
    IF NOT EXISTS(SELECT 1
                  FROM Erogazione E
                           INNER JOIN Contenuto C ON E.idContenuto = C.id
                  WHERE C.idFilm = NEW.idFilm
                    AND E.idUtente = NEW.idUtente
                    AND E.fine IS NOT NULL
                    AND DATE(E.fine) <= NEW.data
                    AND (E.minutiVisti / durataContenuto_) > 0.25) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non è possibile recensire un film se prima non è stato visualizzato almeno per il 25% della durata totale';
    END IF;

END $$

/*------------------------------
  Trigger 8
  Nome: checkPremiazioneFilm
  Descrizione: il seguente trigger si occupa di controllare la corretta aggiunta di una premiazione per un film.

 ------------------------------*/
DROP TRIGGER IF EXISTS checkPremiazioneFilm $$

CREATE TRIGGER checkPremiazioneFilm
    BEFORE INSERT
    ON PremiazioneFilm
    FOR EACH ROW
BEGIN

    DECLARE categoriaPremio VARCHAR(255);
    DECLARE annoProduzione SMALLINT UNSIGNED;

    SELECT P.categoria
    INTO categoriaPremio
    FROM Premio P
    WHERE NEW.idPremio = P.id;

    IF categoriaPremio <> 'film' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non possibile inserire in PremiazioneFilm questo premio perchè non è rivolto ai film';
    END IF;

    SELECT F.annoProduzione INTO annoProduzione FROM Film F WHERE F.id = NEW.idFilm;

    IF YEAR(NEW.data) < annoProduzione THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile premiare un film prima della sua commercializzazione';
    END IF;


END $$

/*------------------------------
  Trigger 9
  Nome: checkPremiazioneRegista
  Descrizione: il seguente trigger si occupa di controllare la corretta aggiunta di una premiazione per un regista.

 ------------------------------*/

DROP TRIGGER IF EXISTS checkPremiazioneRegista $$

CREATE TRIGGER checkPremiazioneRegista
    BEFORE INSERT
    ON PremiazioneRegista
    FOR EACH ROW
BEGIN

    DECLARE categoriaPremio VARCHAR(255);
    DECLARE annoProduzione SMALLINT UNSIGNED;

    SELECT P.categoria
    INTO categoriaPremio
    FROM Premio P
    WHERE NEW.idPremio = P.id;

    IF categoriaPremio <> 'regista' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non possibile inserire in PremiazioneRegista questo premio perchè non è rivolto ai registi';
    END IF;

    IF NOT EXISTS(SELECT 1 FROM Direzione D WHERE D.idFilm = NEW.idFilm AND D.idArtista = NEW.idArtista) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile premiare un regista per un film che non ha diretto';
    END IF;

    SELECT F.annoProduzione INTO annoProduzione FROM Film F WHERE F.id = NEW.idFilm;


    IF YEAR(NEW.data) < annoProduzione THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile premiare un regista per un film non ancora commercializzato.';
    END IF;

END $$


/*------------------------------
  Trigger 10
  Nome: checkPremiazioneAttore
  Descrizione: il seguente trigger si occupa di controllare la corretta aggiunta di una premiazione per un attore.

 ------------------------------*/

DROP TRIGGER IF EXISTS checkPremiazioneAttore $$

CREATE TRIGGER checkPremiazioneAttore
    BEFORE INSERT
    ON PremiazioneAttore
    FOR EACH ROW
BEGIN

    DECLARE categoriaPremio VARCHAR(255);
    DECLARE annoProduzione SMALLINT UNSIGNED;

    SELECT P.categoria
    INTO categoriaPremio
    FROM Premio P
    WHERE NEW.idPremio = P.id;

    IF categoriaPremio <> 'attore' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non possibile inserire in PremiazioneAttore questo premio perchè non è rivolto agli attori';
    END IF;

    IF NOT EXISTS(SELECT 1 FROM Interpretazione I WHERE I.idFilm = NEW.idFilm AND I.idArtista = NEW.idArtista) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile premiare un attore per un film che non ha interpretato';
    END IF;

    SELECT F.annoProduzione INTO annoProduzione FROM Film F WHERE F.id = NEW.idFilm;

    IF YEAR(NEW.data) < annoProduzione THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile premiare un attore per un film non ancora commercializzato.';
    END IF;


END $$


/*------------------------------
  Trigger 11
  Nome: checkPacchetto
  Descrizione: il seguente trigger si occupa di controllare che un utente sia abilitato a usufruire di un pacchetto della piattaforma.

 ------------------------------*/
DROP TRIGGER IF EXISTS checkPacchetto $$

CREATE TRIGGER checkPacchetto
    BEFORE INSERT
    ON Abbonamento
    FOR EACH ROW
BEGIN

    DECLARE eta TINYINT UNSIGNED;
    DECLARE etaMinimaPacchetto TINYINT UNSIGNED;
    DECLARE nazione VARCHAR(2);
-- c
    SELECT (TIMESTAMPDIFF(YEAR, U.dataDiNascita, NOW())), U.nazionalita
    INTO eta,nazione
    FROM Utente U
    WHERE NEW.idUtente = U.id;

    SELECT IF(P.etaMinima IS NULL, 0, P.etaMinima)
    INTO etaMinimaPacchetto
    FROM Pacchetto P
    WHERE NEW.nomePacchetto = P.nome;

-- controllo sull'eta minima richiesta
    IF etaMinimaPacchetto > eta THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non possibile abilitare questo pacchetto nell\'abbonamento perchè non rispetta l\'età minima richiesta';
    END IF;

-- controllo sull'esistenza o meno di una restrizione per lo stato
    IF EXISTS (SELECT 1
               FROM RestrizionePacchetto RP
               WHERE NEW.nomePacchetto = RP.nomePacchetto
                 AND nazione = RP.codiceStato)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non possibile abilitare questo pacchetto nell\'abbonamento perchè non è disponibile nello Stato di nazionalità dell\'Utente';
    END IF;

END $$

/*------------------------------
  Trigger 12
  Nome: checkRestrizioneContenuto
  Descrizione: il seguente trigger si occupa di controllare che il Contenuto richiesto da un Utente non sia ristretto
            nel suo Stato di registrazione.

 ------------------------------*/
#

DROP TRIGGER IF EXISTS checkRestrizioneContenuto $$

CREATE TRIGGER checkRestrizioneContenuto
    BEFORE INSERT
    ON Erogazione
    FOR EACH ROW
BEGIN
    DECLARE statoRegistrazioneUtente VARCHAR(2);

    SELECT U.nazionalita
    INTO statoRegistrazioneUtente
    FROM Utente U
    WHERE U.id = NEW.idUtente;

-- controllo sull'esistenza o meno di una restrizione per lo stato
    IF EXISTS(SELECT 1
              FROM RestrizioneContenuto RC
              WHERE RC.idContenuto = NEW.idContenuto
                AND RC.codiceStato = statoRegistrazioneUtente) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'il contenuto richesto non è accessibile nello Stato di registrazione';
    END IF;
END $$

/*------------------------------
  Trigger 13
  Nome: checkPossibilitaCollegamento
  Descrizione: il seguente trigger si occupa di controllare che il Contenuto richiesto da un Erogazione sia archiviato sul Server selezionato
  e che il server abbia abbastanza banda libera per streammarlo.

 ------------------------------*/
DROP TRIGGER IF EXISTS checkPossibilitaCollegamento $$

CREATE TRIGGER checkPossibilitaCollegamento
    BEFORE INSERT
    ON Collegamento
    FOR EACH ROW
BEGIN
    DECLARE idContenuto INT UNSIGNED;
    DECLARE bitrateContenuto INT UNSIGNED;
    DECLARE bandaMaxServer FLOAT;
    DECLARE bandaUsataServer FLOAT;

    SELECT E.idContenuto INTO idContenuto FROM Erogazione E WHERE E.id = NEW.idErogazione;

    IF NOT EXISTS(SELECT 1
                  FROM Archiviazione A
                  WHERE A.idContenuto = idContenuto
                    AND A.idServer = NEW.idServer) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'non è possibile collegarsi ad un server che non possiede il contenuto richiesto';
    END IF;

    SELECT bandaMax, bandaUsata INTO bandaMaxServer, bandaUsataServer FROM Server S WHERE S.id = NEW.idServer;
    SELECT bitrate INTO bitrateContenuto FROM Contenuto C WHERE C.id = idContenuto;

    IF bandaUsataServer + bitrateContenuto > bandaMaxServer THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Il server selezionato non è in grado di streammare il contenuto richiesto';
    END IF;

END $$


/*------------------------------
  Trigger 14
  Nome: checkCriticReview
  Descrizione: il seguente trigger si occupa di controllare che un critico non pubblichi una recensione di un film prima che venga pubblicato.

 ------------------------------*/
DROP TRIGGER IF EXISTS checkCriticReview $$

CREATE TRIGGER checkCriticReview
    BEFORE INSERT
    ON RecensioneCritico
    FOR EACH ROW
BEGIN

    DECLARE annoProduzione SMALLINT UNSIGNED;

    SELECT F.annoProduzione INTO annoProduzione FROM Film F WHERE F.id = NEW.idFilm;

    IF YEAR(NEW.data) < annoProduzione THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile recensire un film non ancora commercializzato.';
    END IF;

END $$


/*------------------------------
  Trigger 15
  Nome: checkScadenzaCarta
  Descrizione: il seguente trigger si occupa di controllare che la CartaDiPagamento inserita non sia scaduta

 ------------------------------*/
DROP TRIGGER IF EXISTS checkScadenzaCarta $$

CREATE TRIGGER checkScadenzaCarta
    BEFORE INSERT
    ON CartaDiPagamento
    FOR EACH ROW
BEGIN

    IF (NEW.scadenza < CURRENT_DATE) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile inserire una carta scaduta';
    END IF;

END $$


/*------------------------------
  Trigger 16
  Nome: checkConnessioneNuovaErogazione
  Descrizione: il seguente trigger si occupa di controllare che una nuova erogazione sia associata ad una connessione iniziata e non finita

 ------------------------------*/
DROP TRIGGER IF EXISTS checkFineConnessione $$

CREATE TRIGGER checkFineConnessione
    BEFORE INSERT
    ON Erogazione
    FOR EACH ROW
BEGIN
    IF EXISTS(SELECT 1
              FROM Connessione C
              WHERE NEW.inizioConnessione = C.inizio
                AND NEW.ipDispositivo = C.ipDispositivo
                AND NEW.idUtente = C.idUtente
                AND C.fine IS NOT NULL)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile creazione un\'erogazione se la connessione è terminata';
    END IF;

END $$


/*------------------------------
  Trigger 17
  Nome: checkSaldoFattura
  Descrizione: il seguente trigger si occupa di controllare che l'utente utilizzi una propria carta per effettuare il saldo di una fattura
            a suo carico e che questa non sia scaduta.

 ------------------------------*/
DROP TRIGGER IF EXISTS checkSaldoFattura $$

CREATE TRIGGER checkSaldoFattura
    BEFORE UPDATE
    ON Fattura
    FOR EACH ROW
BEGIN
    DECLARE scadenza_ DATE;
-- controllo sull'intestatario
    IF NOT EXISTS(SELECT 1
                  FROM MetodoDiPagamento MP
                  WHERE NEW.numeroCartaSaldo = MP.numeroCarta
                    AND NEW.idUtente = MP.idUtente)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non è possibile saldare una fattura con una carta non appartenente all\'utente intestatario della fattura';
    END IF;

-- controllo sulla scadenza della carta
    SELECT scadenza INTO scadenza_ FROM CartaDiPagamento WHERE numero = NEW.numeroCartaSaldo;
    IF (scadenza_ < NEW.dataSaldo) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non è possibile saldare una fattura con una carta scaduta!';
    END IF;
END $$

/*------------------------------
  Trigger 18
  Nome: checkMinutiVisti
  Descrizione: il seguente trigger si occupa di controllare che i minuti visti di un contenuto non superino la durata del contenuto stesso

 ------------------------------*/

DROP TRIGGER IF EXISTS checkMinutiVisti $$

CREATE TRIGGER checkMinutiVisti
    BEFORE UPDATE
    ON Erogazione
    FOR EACH ROW
BEGIN

    DECLARE durataContenuto_ SMALLINT UNSIGNED;

    SELECT F.durata
    INTO durataContenuto_
    FROM Contenuto C
             INNER JOIN Film F ON F.id = C.idFilm
    WHERE C.id = NEW.idContenuto;

    IF NEW.minutiVisti > durataContenuto_ THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Non è possibile visualizzare un contenuto per più della sua durata totale';
    END IF;

END $$


/*------------------------------
  Trigger 19
  Nome: checkMemoriaDisponibile
  Descrizione: il seguente trigger si occupa di controllare che prima di aggiungere un contenuto in un server ci sia abbastanza memoria disponibile

 ------------------------------*/

DROP TRIGGER IF EXISTS checkMemoriaDisponibile $$

CREATE TRIGGER checkMemoriaDisponibile
    BEFORE INSERT
    ON Archiviazione
    FOR EACH ROW
BEGIN

    DECLARE dimensioneContenuto_ FLOAT;
    DECLARE memoriaDisponibileServer_ FLOAT;

    SELECT (S.memoriaMax - S.memoriaUsata) AS memoriaLibera
    INTO memoriaDisponibileServer_
    FROM Server S
    WHERE S.id = NEW.idServer;

    SELECT dimensione
    INTO dimensioneContenuto_
    FROM Contenuto
    WHERE id = NEW.idContenuto;


    IF dimensioneContenuto_ > memoriaDisponibileServer_ THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non è possibile aggiungere il contenuto perchè non c\'è abbastanza memoria disponibile nel server';
    END IF;

END $$


/*------------------------------
  Trigger 20
  Nome: eliminazioneContenutoStreaming
  Descrizione: il seguente trigger si occupa di controllare che prima di eliminare un contenuto da un server, questo non sia in streaming in quel momento

 ------------------------------*/

DROP TRIGGER IF EXISTS eliminazioneContenutoStreaming $$

CREATE TRIGGER eliminazioneContenutoStreaming
    BEFORE DELETE
    ON Archiviazione
    FOR EACH ROW
BEGIN

    IF EXISTS (SELECT 1
               FROM Collegamento C
                        INNER JOIN Erogazione E ON C.idErogazione = E.id
               WHERE C.idServer = OLD.idServer
                 AND E.idContenuto = OLD.idContenuto
                 AND C.stato = 'attivo') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                    'Non è possibile eliminare il contenuto dal server perchè è in streaming attualmente da un utente';
    END IF;
END $$


/*------------------------------
  Trigger 21
  Nome: CheckFunzionalita
  Descrizione: il seguente trigger si occupa di controllare
  l'aggiunta delle funzionalità extra per vedere se è valida l'aggiunta di quest'ultima

 ------------------------------*/

DROP TRIGGER IF EXISTS CheckFunzionalita $$

CREATE TRIGGER CheckFunzionalita
    BEFORE INSERT
    ON OffertaFunzionalita
    FOR EACH ROW
BEGIN


    IF (NEW.nomeFunzionalita = 'Download') THEN
        IF EXISTS (SELECT 1
                   FROM Abbonamento A
                   WHERE A.idUtente = NEW.idUtente
                     AND A.nomePacchetto IN ('pro', 'deluxe', 'ultimate')) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Funzionalità già inclusa nel piano di abbonamento';
        END IF;
    END IF;

    IF (NEW.nomeFunzionalita = '8K') THEN
        IF EXISTS (SELECT 1
                   FROM Abbonamento A
                   WHERE A.idUtente = NEW.idUtente
                     AND A.nomePacchetto = 'ultimate') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Funzionalità già inclusa nel piano di abbonamento';
        END IF;

        IF EXISTS(SELECT 1
                  FROM OffertaFunzionalita O
                  WHERE O.idUtente = NEW.idUtente
                    AND O.nomeFunzionalita = '4K') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Disabilita l\'offerta 4K prima di abilitare la fruizione di contentuti in 8K';
        END IF;
    END IF;

    IF (NEW.nomeFunzionalita = '4K') THEN
        IF EXISTS (SELECT 1
                   FROM Abbonamento A
                   WHERE A.idUtente = NEW.idUtente
                     AND A.nomePacchetto IN ('deluxe', 'ultimate')) OR EXISTS (SELECT 1
                                                                               FROM OffertaFunzionalita O
                                                                               WHERE O.idUtente = NEW.idUtente
                                                                                 AND O.nomeFunzionalita = '8K') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Funzionalità già inclusa nel piano di abbonamento';
        END IF;

    END IF;

    IF (NEW.nomeFunzionalita = 'No pubblicità') THEN
        IF EXISTS (SELECT 1
                   FROM Abbonamento A
                   WHERE A.idUtente = NEW.idUtente
                     AND A.nomePacchetto <> 'basic') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Funzionalità già inclusa nel piano di abbonamento';
        END IF;
    END IF;

END $$











