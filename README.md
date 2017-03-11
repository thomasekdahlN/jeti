# Jeti ECU Telemetry (Beta version)
- First versjon that actually works. A but chatty on alarms, will work on that later. Jetcat, Hornet and pbs configs checked and tested a bit.

https://github.com/thomasekdahlN/jeti/blob/master/screenshots/Alarm%20Message.bmp

Jeti Advanced ECU LUA Script. Easy telemetry displaying, advanced alarms that are silent until really needed, easy setup and very configurable from configuration fiels. JetCat example configuration file: https://github.com/thomasekdahlN/jeti/blob/master/ecu/jetcat.jsn

jeti transmitter fw 4.2.2 firmware and vspeak 2.2 firmware required

vspeak lua turbine ecu status converter and alarm script 0.9 beta - developers, testers and helpers wanted. PM me.

#Supporting:
- Vspeak JetCat (new release this week) https://github.com/thomasekdahlN/jeti/blob/master/ecu/jetcat.jsn
- Vspeak Hornet https://github.com/thomasekdahlN/jeti/blob/master/ecu/hornet.jsn
- Vspeak Jakadofsky (config file format old, needs to be reconfigured, use pbs.jsn as example)
- Vspeak evoJet / Pahl  (config file format old, needs to be reconfigured, use pbs.jsn as example)
- Vspeak PBS  https://github.com/thomasekdahlN/jeti/blob/master/ecu/pbs.jsn
- Orbit (config file format OK)

Partial support for two turbines.

Supporting a new ecu converter is as easy as adding a json configuration file and you get all the bells and whistles

Only tested on DC-24.

#Implemented functionality in beta:
- Separate advanced json configuration file for each ECU type (maybe for each turbine type later, not possible to read folders in lua yet)
- Possibility to read all statuses by voice
- Possibility to turn on or off alarms globally - if you are annoyed. Some alarms like low rpm, low pumpv, low temp are not enabled until turbine status is running (configurable), the rest of the alarms are triggered on arming the turbine (configurable)
- Configurable which turbine status has audi alarms, haptic alarms or message alarms.
- Configurable which switch turns off alarms (recommended same as throttle cut)
- Individually configurable parameters for EVERY turbine STATUS (this is super cool and super flexible)
-- Alarm on status: on or off
-- Audio alarm (information in female voice, warnings in male voice), possibility to change audio file.
-- Haptic feedback, which stick, which vibration profile, on/off
-- Display warning. on/off - shows the status text as a warning.

The usual alarms, but easier setup
- Turbine RPM high
- Turbine RPM low - only enabled after turbine has reached running status 
- Shaft RPM high
- Shaft RPM low - only enabled after turbine has reached running status 
- Ecu voltage high
- Ecu voltage low - only enabled after turbine has reached running status 
- EGT high
- EGT low - only enabled after turbine has reached running status 
- Pump voltage high
- Pump voltage low - only enabled turbine has reached running status
- Fuel warning alarm (configured at 20% fuel level)
- Fuel critical alarm (configured at 10% fuel level)
- Fuel - Reading remaining 10 times pr tank (automaticially set intervals based on tanksize)
- Fuel - Automatic reading of tanksize from ECU (shown in telemetry window)
- = Fuel = Zero configuration neccessary to have very advanced information and alarms on tank level
Alarms will be repeated at most every 25 second if error condition is sustained

Telemetry display
- Turbine status (and only that)
- Reimplemented the telemetry status display code and graphics  from "ECU data display" for Orbit made by Bernd Woköck

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
So the idea is that with this lua script you will get all needed turbine alarms setup in under 5 minutes (download lua script and install it- chooce ECU type, choose status telemetry sensor - you are done), with our collective best effort on defining whats the best way to have turbine alarms.

For the people who love to tinker it is infinitely extensive and changeable in a easy manner in the configuration file pr ecu. But the distributed configuration file should be best practise for all others.

#Installation
- copy ecu.lua and ecu folder into the Apps folder on your Jeti transmitter
- add ecu.lua to applications
- choose ecu type
Then you are up and running


If you have any more ideas about needs for turbine alarms, please let me know.
