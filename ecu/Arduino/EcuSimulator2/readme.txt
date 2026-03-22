
Needed for JetiEX connectivity
1 x Arduino Pro mini
1 x 2.4KOhm resistor

Extract the JetiEX libraries from this project: https://github.com/RC-Thoughts/Jeti_GPS-Sensor

Needed for simulator functionality.
6 x 10 Kohm Potentiometers
2 x buttons
2 x 10 Kohm resistor (used for pulldown on buttons, did not draw that)
1 x https://www.adafruit.com/product/419. Added on digital pins 2 until 8.




int pot0Pin = 0; //Potmeter that changes RPM2 from 0 - 10.000 RPM
int pot1Pin = 1; //Potmeter that changes EGT from -10 - 1000 Degrees (temperature can be negative upon start)
int pot2Pin = 2; //Potmeter that changes RPM from 0 - 250.000 RPM
int pot3Pin = 3; //Potmeter that changes PUMPV from 0 - 4V
int pot4Pin = 4; //Potmeter that changes BATT from 0 - 20V
int pot5Pin = 5; //Potmeter that chanhes FUEL from -0.5 - 10L (some sensors gives negatvie fuel in error situations, so have to test it)

int offlinePin = 11; //Button that sets all sensors to offline status to test offline handling

Keypad to set Turbine status.
- Punch the status code to test. Confirm with #. If negative value, start with *.
