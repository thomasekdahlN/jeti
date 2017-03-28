# Jeti ECU Telemetry (Beta version)
This version actually works pretty good - impressive functionality for the future of turbine telemetry. Jetcat and Hornet config files almost complete with adjusted setup.

![Alt text](https://raw.github.com/thomasekdahlN/jeti/tree/master/screenshots/Alarm%20Shaft%20RPM%20low.png?raw=true "Optional Title")
![Alt text](https://raw.github.com/thomasekdahlN/jeti/tree/master/screenshots/Flight%20logg%20-%20preheat%20status.png?raw=true "Optional Title")


Jeti Advanced ECU LUA Script. Easy telemetry displaying, advanced alarms that are silent until really needed, easy setup and very configurable from configuration files if you need to (default setup should be enough for most people). JetCat example configuration file: https://github.com/thomasekdahlN/jeti/blob/master/ecu/jetcat.jsn

NOTE: You do not have to edit configuration files, standard config files for your turbine has best practise set up right out of the box, just choose turbine type, sensor and kill switch - and you will have the most advanced turbine surveillance available to RC modellers today.

jeti transmitter fw 4.2.2 firmware required

vspeak lua turbine ecu status converter and alarm script 0.9 beta - developers, testers and helpers wanted. PM me.

#Supporting:
- Vspeak 2.2 JetCat (very good) https://github.com/thomasekdahlN/jeti/blob/master/ecu/jetcat.jsn
- Vspeak 2.2 Hornet (very good) https://github.com/thomasekdahlN/jeti/blob/master/ecu/hornet.jsn
- Vspeak 2.2 Jakadofsky (config file format old, needs to be reconfigured, use pbs.jsn as example)
- Vspeak 2.2 evoJet / Pahl  (config file format old, needs to be reconfigured, use pbs.jsn as example)
- Vspeak 2.2 PBS  https://github.com/thomasekdahlN/jeti/blob/master/ecu/pbs.jsn
- Orbit (config file format OK)
- Just make a copy of a config file, adjust the parameters and put it in the ecu folder, and you can start using a new make of turbine or your own special config. Confiog files are read dynamically from ecu folder.
Partial support for two turbines.

Supporting a new ecu converter is as easy as adding a json configuration file and you get all the bells and whistles

Only works on Jeti DC-24. Jeti DS/DC-16 and DC/DS-14 has to little memory available (and I cant test it since I have a DC-24)

#Implemented functionality in beta:
- Separate advanced json configuration file for each ECU type (or for each turbine type if you want. You do not have to edit configuration files, standard config files for your turbine has best practise set up right out of the box, just choose turbine type, sensor and alarms off switch - and you will have the most advanced turbine surveillance available to RC modellers today.
- Possibility to read all ECU statuses by voice (not as alarms, but as information i.e. during startup)
- All alarms enabled with one switch (recommed to use the same switch as throttle cut for turbine, then alarms are on when turbine is armed)
- Some alarms like low rpm, low rpm2, low pumpvolt, low temp are not enabled until the low threshold is exceeded. This makes for no annoying low alarms before turbine is running, but they will also be shut off by the global switch.
- Configurable which turbine status has audio alarms, haptic alarms or message alarms.
- Status - Individually configurable parameters for EVERY turbine STATUS (this is super cool and super flexible)
- Status alarms only given on status change
- Status - Audio alarm (information in female voice, warnings in male voice), possibility to change audio file. Configurable.
- Status - Haptic feedback, which stick, which vibration profile, on/off. Configurable.
- Status - Display warning. on/off - shows the status text as a warning. Will also log the turbien status to the normal Jeti flight log (this is super cool). Configurable.
- 91 audio files included with all statuses and alarms

The usual alarms, but easier setup
- Turbine RPM high
- Turbine RPM low - only enabled after RPM has exceeded Turbine RPM low
- Shaft RPM high
- Shaft RPM low - only enabled after shaft RPM has exceeded Shaft RPM low
- Ecu voltage high
- Ecu voltage low - only enabled after ECU voltage has exceeded Ecu voltage low
- EGT high
- EGT low - only enabled after EGT has exceeded EGT low 
- Pump voltage high
- Pump voltage low - only enabled after Pump voltage has exceeded Pump voltage low
- Fuel warning alarm (configured at 20% fuel level)
- Fuel critical alarm (configured at 10% fuel level)
- Fuel - Audio messaage with remaining fuellevel 10 times pr tank (automaticially set intervals based on tanksize)
- Fuel - Automatic reading of tanksize from ECU (shown in telemetry window)
- = Fuel = Zero configuration neccessary to have very advanced information and alarms on tank level
Alarms will be repeated every 30 second if error condition is sustained

Telemetry display visual
- Fuel gauge, RPM, ECU volt and status double window  from "ECU data display" for Orbit made by Bernd Woköck
- Experimental RPM and TEMP gauge (very cool, but not tested)

Thinking of implementing:
- Warning if you try to shutdown turbine while it is too hot (if possible to implement)
- Sound volume control connected to warnings and critical alarms

#Help needed:
- Translation
- Configuration of "best practice" turbine alarms and setup for the supported ecus.
- Generation of audio files for all statuses
- Testing
- Jeti Params for different ECUs (we only have to choose one sensor, we find the rest automatically by param)
- Making videos of running system

#Idea and goals
So the idea is that with this lua script you will get all needed turbine alarms setup in under 5 minutes (download lua script and install it- chooce ECU type, choose status telemetry sensor - you are done), with our collective best effort on defining whats the best way to have turbine alarms and telemetry.

For the people who love to tinker it is infinitely extensive and changeable in a easy manner in the configuration file pr ecu. But the distributed configuration file should be best practise for all others.

#Installation
- copy ecu.lua and ecu folder into the Apps folder on your Jeti transmitter
- add ecu.lua to applications
- choose ecu type
Then you are up and running


If you have any more ideas about needs for turbine alarms, please let me know.
