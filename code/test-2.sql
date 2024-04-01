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



SET @latitudine1 = 37.542;
SET @longitudine1 = 126.990;
SET @ipAddress1 = '87.91.124.1';

-- Connessione da Chicago, Illinois, US
SET @latitudine2 = 41.773;
SET @longitudine2 = -87.442;
SET @ipAddress2 = '87.54.122.54';



CALL loginUtente('lorenzomoni@studenti.unipi.it', 'fdc847aa960ef3e62696f534acb09dbe4b1dff86', @ipAddress1, '10',
                 'windows', 'Desktop-PC',
                 '2C:4D:54:4C:7B:5E', 'desktop', @latitudine1, @longitudine1, @idUtente1);

CALL loginUtente('lorenzomarranini@studenti.unipi.it', '6cd9ee9cb19b1981b0e147fb1973ec9b1f3e8933', @ipAddress2, '10',
                 'osx', 'Ipad',
                 '2C:4D:54:4C:7B:5E', 'tablet', @latitudine2, @longitudine2, @idUtente2);

SET @debug = FALSE;
# CALL generaErogazioni();
SET @debug = TRUE;