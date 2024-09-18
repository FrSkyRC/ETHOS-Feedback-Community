Cette option permet d'équilibrer de 2 à 4 voies afin d'assurer une synchronisation des sorties. Par exemple, des volets avec 2 servos sur chaque gouverne, 2 moteurs thermiques pour une réponse linéaire de puissance, etc...

## Principes d'utilisation
Création automatique d'une courbe jusqu'à 21 points de compensation pour chaque voie sélectionnée en comparant physiquement chaque point afin d'obtenir un ajustement parfait des surfaces controlées.

## Préconnisation de configuration 
Avant l'équilibrage des voies, les recommandations sont les suivantes : 
1. Définir correctement la direction de chaque servos.
2. Avec la commande au neutre, utiliser le centre PWM pour positionner les palonniers au bon angle.
3. Configurer les limites Min/Max et éventuellent le Subtrim.
4. Configurer tout autre courbe utile.
5. Configurer la vitesse de déplacemet.
6. Exécuter l'équilibrage des voies.

## Utilisation
Les voies à équilibrer doivent  être sélectionnées.  Les voies mixées sont affichées selon l'axe X, pendant que les valeurs corrigées sont affichées selon l'axe Y.

## Icônes
![Analog](/bitmaps/system/icon_analog.png) Une source des voies peut-être selectionné pour l'équilibrage mais également toute autre source analogique. Dans le cas 'Auto', la première source analogique détectée servira à la configuration.

![Magnet](/bitmaps/system/icon_magnet.png) En sélectionnant l'option, le point de la courbe le plus proche de la position de l'axe X va être sélectionné et ensuite modifié avec l'encodeur rotatif. Non sélectionné, le point de la courbe est modifié par les touches 'SYS' et 'DISP'. La source doit être ajustée pour ajuster une valeur X avec un point de la courbe avant modification.

![Lock](/bitmaps/system/icon_lock.png) L'appuie sur ENTER en mode édition ou en sélectionnant l'icône verrouille toutes les entrées à la position de la source. Dans la position données, vous pouvez ajuster la courbe.

![Settings](/bitmaps/system/icon_system.png) Boite de dialogue de configuation des voies sélectionnées. Choix possible du nombre de points pour toutes les courbes ou seulement certaines ainsi que le lissage ou pas des courbes.

[?] Ce fichier d'Aide.