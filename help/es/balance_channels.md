Esta característica le permite equilibrar un par de canales o un grupo de hasta 4 canales para asegurar que se mueven al unísono. Por ejemplo, unos flaps desequilibrados pueden producir un alabeo indeseado, mientras que unos motores con diferentes empujes en modelos multi-motores pueden producir una guiñada inesperada.

## Resumen
Esta opción crea automáticamente una curva diferencial de equilibrado para cada canal seleccionado. Se puede elegir el número de puntos de equilibrado que se necesiten. Comparando las posiciones físicas de las superficies de control (como los flaps) en cada punto de las curvas, se pueden ajustar fácilmente para que sean iguales. El resultado final son superficies moviéndose exactamente igual.

## Prerequisitos 
Antes de equilibrar canales, se recomienda seguir el siguiente proceso:
1. Ajustar las direcciones de los servos para un correcto movimiento de las superficies.
2. Con las mezclas en neutral, use el centrado PWM como sea necesario para ajustar los reenvíos de los servos en los ángulos correctos.
3. Configure los límites Min/Max y los Subtrim.
4. Configure todas las otras curvas.
5. Configure Lento.
6. Proceda con el equilibrado de los canales para para ajustar y ecualizar las superficies de control en múltiples puntos de recorrido.

## Cómo se usa
Cuando se activa, se eligen los canales a equilibrar. Los canales se mostrarán en el orden de selección. Las salidas de las mezclas se muestran a lo largo los ejes X, mientras que los valores del ajuste de equilibrado diferencial aparecerán en los ejes Y.

Toque en el gráfico del canal (o gire el selector rotatorio hasta él y presione ENTER) para editar la curva de equilibrado. La tecla PAGE permitirá el cambio entre canales mientras se está en edición.

## Botones
![Analog](FLASH:/bitmaps/system/icon_analog.png) Se pueden usar la/s fuente/s configuradas en las mezclas del canal, u optionalmente cualquier otra entrada analógica que sea conveniente. Si selecciona la opción 'Entrada analógica automática', la primera palanca, slider o pot que se mueva se usará como fuente para la X, no sólo en el gráfico, sino también en el modelo.

![Magnet](FLASH:/bitmaps/system/icon_magnet.png) Cuando se seleccione, el punto más cercano de la curva en el eje X será automáticamente seleccionado para su ajuste con el selector rotario. Cuando se deselecciona, se puede seleccionar el punto a ajustar usando las teclas 'SYS' y 'DISP'. La entrada debe ajustarse para alinear el valor de X con un punto de la curva antes de que se realice el ajuste.

![Lock](FLASH:/bitmaps/system/icon_lock.png) Tocando el icono del candado, o presionando la tecla ENTER mientras se está en el modo de edición del gráfico, se cambiará de blocado a desbloqueo. Cuando se activa, todas las entradas estarán bloqueadas para que pueda soltar la palanca de entrada, permitiéndole observar las superficies de control mientras ajusta la curva.

![Settings](FLASH:/bitmaps/system/icon_system.png) Abre el cuadro de configuración para el canal elegido. Es posible modicar el número de puntos de todas las curvas, o sólo de algunas, y elegir si se suavizan o no.

[?] Archivo de ayuda. También se puede ver presionando la tecla MDL.