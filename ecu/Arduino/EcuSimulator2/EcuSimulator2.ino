/*
  -----------------------------------------------------------
            Jeti GPS Sensor v 1.5
  -----------------------------------------------------------

   Based on the "Jeti EX MegaSensor for Teensy 3.x"
   from Bernd Wokoeck 2016

   Uses affordable Arduino Pro Mini + Ublox NEO-6M GPS-module

   Libraries needed
   - AltSoftSerial by Paul Stoffregen
   - Jeti Sensor EX Telemetry C++ Library by Bernd Wokoeck

   Tero Salminen RC-Thoughts.com (c) 2017 www.rc-thoughts.com

  -----------------------------------------------------------

                    Versatile features:

  -----------------------------------------------------------
      Shared under MIT-license by Tero Salminen (c) 2017
  -----------------------------------------------------------
*/

#include "Arduino.h"
#include <Keypad.h>
#include <JetiExSerial.h>
#include <JetiExProtocol.h>
#include <EEPROM.h>

JetiExProtocol jetiEx;

int pot0Pin = 0; //Potmeter that changes RPM2 from 0 - 10.000RPM
int pot1Pin = 1; //Potmeter that changes EGT from -10 - 1000Degrees (temperature can be negative upon start)
int pot2Pin = 2; //Potmeter that changes RPM from 0 - 250.000RPM
int pot3Pin = 3; //Potmeter that changes PUMPV from 0 - 4V
int pot4Pin = 4; //Potmeter that changes BATT from 0 - 20V
int pot5Pin = 5; //Potmeter that chanhes FUEL from -0.5 - 10L (some sensors gives negatvie fule, so have to test it)

int offlinePin = 11; //Button that sets all sensors to offline status

unsigned long previousMillis = 0; // last time update

unsigned long interval = 15000; // interval at which to do something (milliseconds)
int statuscounter = 0;

enum
{
  ID_EGT       = 1,
  ID_RPM       = 2,
  ID_STATUS    = 3,
  ID_PUMPV     = 4,
  ID_BATT      = 5,
  ID_FUEL      = 6,
  ID_THROTTLE  = 7,
  ID_SPEED     = 8,
  ID_RPM2      = 9,
};

// For sensors
int sens1 = 0; //EGT
unsigned long sens2 = 0; //RPM
int sens3 = 0; //STATUS
int sens4 = 0; //PUMPV
int sens5 = 0; //BATT
long sens6 = 0; //FUEL
int sens7 = 0; //THROTTLE
int sens8 = 0; //SPEED
unsigned long sens9 = 0; //RPM2

int buttonOffline = 0; 

JETISENSOR_CONST sensors[] PROGMEM =
{
  // id             name          unit          data type           precision
  { ID_EGT,         "Egt",        "\xB0\x43",   JetiSensor::TYPE_14b, 0 },
  { ID_RPM,         "Rpm",        "/min",       JetiSensor::TYPE_22b, 0 },
  { ID_STATUS,      "Status",     " ",          JetiSensor::TYPE_14b, 0 },
  { ID_PUMPV,       "Pumpv",      "V",          JetiSensor::TYPE_14b, 2 },
  { ID_BATT,        "Batt",       "V",          JetiSensor::TYPE_14b, 2 },
  { ID_FUEL,        "Fuel",       " ",          JetiSensor::TYPE_22b, 0 },
  { ID_THROTTLE,    "Throttle",   " ",          JetiSensor::TYPE_14b, 0 },
  { ID_SPEED,       "Speed",      "m/s",        JetiSensor::TYPE_14b, 0 },
  { ID_RPM2,        "Rpm2",       "/min",       JetiSensor::TYPE_22b, 0 },
  { 0 }
};

const byte ROWS = 4; //four rows
const byte COLS = 3; //three columns
char keys[ROWS][COLS] = {
  {'1','2','3'},
  {'4','5','6'},
  {'7','8','9'},
  {'*','0','#'}
};

byte rowPins[ROWS] = {8, 7, 6, 5}; //connect to the row pinouts of the keypad
byte colPins[COLS] = {4, 3, 2}; //connect to the column pinouts of the keypad

Keypad keypad = Keypad( makeKeymap(keys), rowPins, colPins, ROWS, COLS );

String entryStr = "";
int    entryCtr = 0;


void setup()
{
  pinMode(offlinePin, INPUT);
  jetiEx.SetDeviceId( 0x75, 0x31 );
  jetiEx.Start( "ECU", sensors, JetiExProtocol::SERIAL2 );
}

void loop()
{
    // Read digital pins
    buttonOffline  = digitalRead(offlinePin);
  
    // Read potentiometers
    sens1 = map(analogRead(pot1Pin), 0, 1023, -10, 1000);   //EGT
    sens2 = map(analogRead(pot2Pin), 0, 1023, 0, 250000);   //RPM
    readStatusFromKeyPad();                                 //STATUS - varaible set globally
    sens4 = map(analogRead(pot3Pin), 0, 1023, 0, 400);      //PUMPV
    sens5 = map(analogRead(pot4Pin), 0, 1023, 0, 2000);     //BATT
    sens6 = map(analogRead(pot5Pin), 0, 1023, -500, 10000); //FUEL
    sens7 = 1510;                                           //THRO
    sens8 = 200;                                            //SPEED
    sens9 = map(analogRead(pot0Pin), 0, 1023, 0, 10000);    //RPM2

    if (buttonOffline == LOW) {
      jetiEx.SetSensorValue( ID_EGT,    sens1);
      jetiEx.SetSensorValue( ID_RPM,    sens2);
      jetiEx.SetSensorValue( ID_STATUS, sens3);
      jetiEx.SetSensorValue( ID_PUMPV,  sens4 );
      jetiEx.SetSensorValue( ID_BATT,   sens5);
      jetiEx.SetSensorValue( ID_FUEL,   sens6);
      jetiEx.SetSensorValue( ID_THROTTLE, sens7);
      jetiEx.SetSensorValue( ID_SPEED,  sens8);
      jetiEx.SetSensorValue( ID_RPM2,   sens9);

      jetiEx.DoJetiSend();
    }
}

void readStatusFromKeyPad() {

  char key = keypad.getKey();

  if (key){ 
     if (key == '*'){
        //We use * for setting negative values
        entryStr += (char) '-';

     } else if (isDigit(key)) {
        //All other number values
        entryStr += (char) key - 48; //-48 to correct for that we get the ASCI value of the key
        
     } else if (key == '#'){
        //We send the entered text to Jeti EX Bus
        entryStr += (char) '\0'; //Terminate array
        sens3     = entryStr.toInt();
        entryStr  = ""; //Reset
     }
     delay(250); //To allow for slower input rate
  }
}

