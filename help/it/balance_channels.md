Questa funzione ti consente di bilanciare coppie selezionate o un gruppo fino a 4 canali per assicurarti che si muovano in perfetta armonia. Ad esempio, alettoni sbilanciati possono causare un rollio indesiderato, mentre motori sbilanciati su modelli a più motori possono portare a un imbardata indesiderata.

## Panoramica  
Questa funzione crea automaticamente una curva di bilanciamento differenziale per ciascun canale selezionato. È possibile scegliere il numero di punti di bilanciamento. Confrontando le posizioni fisiche delle superfici di controllo (come gli alettoni) in ciascun punto delle curve, possono essere facilmente regolati per essere uguali. Il risultato finale è che le superfici seguono perfettamente.

## Prerequisiti  
Prima di bilanciare i canali, dovrebbe essere seguita questa procedura consigliata:

Imposta le direzioni dei servo per il corretto movimento delle superfici.  
Con i mix a neutro, usa eventualmente il Centro PWM per impostare i braccetti del servo ad angolo retto.  
Configura i limiti Min/Max e il Subtrim.  
Configura eventuali altre curve.  
Configura il Slow.  
Procedi con il Bilanciamento Canali per bilanciare e rendere uguali le superfici di controllo in diversi punti di escursione.

## Come usare  
Quando attivata, vengono scelti i canali da bilanciare. I canali verranno mostrati nell'ordine di selezione. Le uscite dei mix sono visualizzate lungo l'asse X, mentre i valori differenziali dell'aggiustamento del bilanciamento sono mostrati sull'asse Y.

Tocca un grafico di un canale (o scorri fino ad esso e premi ENTER) per modificare la curva di bilanciamento. Il tasto PAGE passerà da un canale all'altro durante la modifica.

## Pulsanti  
![Analog](FLASH:/bitmaps/system/icon_analog.png) Le sorgenti configurate nei mix dei canali possono essere utilizzate, o eventualmente qualsiasi altro ingresso analogico conveniente. Se selezioni l'opzione 'Ingresso analogico automatico', il primo stick, cursore o potenziometro che muovi verrà utilizzato come sorgente per l'asse X, non solo nel grafico, ma anche nel modello.

![Magnet](FLASH:/bitmaps/system/icon_magnet.png) Quando selezionato, il punto di curva più vicino sull'asse X verrà automaticamente scelto per la regolazione con l'encoder rotativo. Quando non è selezionato, il punto di curva da regolare può essere scelto utilizzando i tasti 'SYS' e 'DISP'. L'ingresso deve essere regolato per allineare il valore X con un punto della curva prima di apportare la regolazione.

![Lock](FLASH:/bitmaps/system/icon_lock.png) Premendo il tasto ENTER mentre sei in modalità di modifica del grafico attiverai e disattiverai la modalità Blocco. Quando abilitata, tutti gli ingressi sono bloccati in modo da poter rilasciare l'input dello stick, permettendoti di osservare le superfici di controllo mentre regoli la tua curva.

![Settings](FLASH:/bitmaps/system/icon_system.png) Apri la finestra di configurazione per i canali scelti. È possibile modificare il numero di punti di tutte le curve, o solo alcune, e scegliere se debbano essere levigate o meno.

[?] Questo file di aiuto. Può essere richiamato anche con il tasto MDL.
