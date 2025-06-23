Tato funkce umožňuje seřízení (vyvážení) vybraných párů nebo skupiny až 4 kanálů pro zajištění jejich souběžného pohybu. Například neseřízené klapky mohou způsobit nechtěné klonění, u ploch velkých modelů ovládaných více servy může docházet k mechanickému namáhání apod.

## Přehled
Tato funkce umožňuje vytvořit křivku diferenciálního vyvážení pro každý z vybraných kanálů s volitelným počtem bodů. Umožňuje zarovnat výchylky řídicích ploch (např. klapek) ve vybraných bodech chodu tak, aby vždy chodily stejně. Konečným výsledkem jsou dokonale souběžné plochy v celém rozsahu.

## Požadavky 
Před vyvážením kanálů je doporučeno postupovat takto:
1. Nastavte směr ovládání jednotlivých serv tak, že kladné hodnoty mixu znamenají stejný směr u všech seřizovaných ploch.
2. S mixy nastavenými v neutrální poloze upravte PWM středy tak, aby páky serv byly v požadovaném úhlu.
3. Nastavte Min/Max limity a Subtrimy.
4. Nastavte libovolné další křivky (pokud jsou třeba).
5. Nastavte zpomalení (pokud je třeba).
6. Pokračujte Vyvážením kanálů pro seřízení chodu jednotlivých serv ve více bodech chodu.

## Jak funkci vyvážení použít?
Při aktivaci funkce vyberte kanály které chcete vyvážit. Kanály budou zobrazeny v pořadí výběru. Výstupy mixu jsou zobrazeny podél X os, zatímco rozdílová hodnota seřízení je zobrazena na osách Y.

Dotykem na graf kanálu (nebo skrolováním a stiskem ENTER) upravte křivku vyvážení. Klávesa PAGE přepíná mezi kanály během editace.

## Tlačítka
![Analog](FLASH:/bitmaps/system/icon_analog.png) Lze použít zdroj(e) nakonfigurovaný(é) v kanálových mixech nebo volitelně jakýkoli jiný vhodný analogový vstup. Pokud vyberete tuto možnost „Automatický analogový vstup“, bude jako zdroj pro X použita první páčka, posuvník nebo potenciometr, kterým pohnete, a to nejen v grafu, ale také v modelu. Slouží jako dočasná náhrada centrovaných páček za necentrované pro jednodušší manipulaci.

![Magnet](FLASH:/bitmaps/system/icon_magnet.png) Je-li vybrána tato funkce, automaticky se vybere nejbližší bod křivky na ose X, který lze dále upravit pomocí otočného ovladače. Pokud je funkce odznačena, lze bod křivky, který má být upraven, vybrat pomocí kláves „SYS“ a „DISP“. Před provedením nastavení je nutné nastavit vstup tak, aby se hodnota X zarovnala s bodem křivky, který chcete upravit.

![Lock](FLASH:/bitmaps/system/icon_lock.png) Stisknutím klávesy ENTER v režimu úprav grafu zapnete a vypnete režim uzamčení. Když je režim zapnutý, všechny vstupy se v dané poloze uzamknou, takže můžete uvolnit vstupní páku, což vám umožní sledovat řídicí plochy při úpravě křivky.

![Settings](FLASH:/bitmaps/system/icon_system.png) Otevře dialogové okno konfigurace vybraných kanálů. Je možné upravit počet bodů všech křivek, nebo jen některých, a zvolit, zda budou vyhlazeny, nebo ne.

[?] Tato nápověda. Může být také vyvolána pomocí MDL klávesy.
