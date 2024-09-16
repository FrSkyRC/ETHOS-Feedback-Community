This feature allows you to balance selected pairs or a group of up to 4 channels to ensure that they move in unison. For example, unbalanced flaps can result in unwanted roll, while unbalanced throttles on multi-engine models can result in unwanted yaw.

## Overview
This feature automatically creates a differential balance curve for each channel selected. The number of balance points may be chosen. By comparing the physical positions of control surfaces (such as flaps) at each point of the curves, they can be easily adjusted to be equal. The final result is perfectly tracking surfaces.

## Prerequisites 
Prior to balancing channels, this recommended process should be followed:
1. Set the servo directions.
2. With mixes at neutral, optionally use PWM Center to set servo horns at right angles.
3. Configure the Min/Max limits and Subtrim.
4. Configure any other curves.
5. Configure Slow.
6. Proceed with Balance Channels to balance and equalise control surfaces at multiple points of travel.

## Settings
- When activated, the channels to be balanced are chosen, as well as the number of balance curve points, and whether to smooth the curves,
- [Joystick icon] Input options: The source(s) configured in the channel mixes may be used, or optionally any other convenient analog input. If you select 'Auto analog input', the first stick, slider or pot you move will be used as the source for X, not only in the graph, but also in the plane.
- [Magnet icon] When selected, the nearest curve point on the X axis will be adjusted. When off, the input must be adjusted to align the X value with a curve point before adjustment is made.
- [Lock icon] When selected, both inputs are locked so that you can release the stick input, allowing you to observe the control surfaces while you adjust your curve.
- [Gear icon ] takes you back to the configuration dialog.