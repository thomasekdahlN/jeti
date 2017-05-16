# Jeti ECU Telemetry (Beta version)
Jeti Advanced ECU LUA Script. Easy setup based on best practise, advanced alarms that are silent until really needed and very configurable from configuration files if you need to (default best practise setup should be enough for most people).

NOTE: You do not have to edit configuration files, standard config files for your turbine has best practise set up right out of the box, just choose ecu converter, turbine type, battery pack, ecu sensor and kill switch - and you will probably have the most advanced turbine surveilance available to RC turbine models today.

NOTE II: ecu_16.lc is the most recently maintained. A lot of configuration has been sacrifised for convention - to save enough memory to make it run on -16 transmitters.

Now supports vspeak ecu converter (my personal favorite ECU converter), Digitech ecu converter, jetcat ecu converter and experimental support for CB-Electroniks and Xicoy converters (needs testers).

Only works with Jeti transmitter FW 4.22. 

![alarm - ecu offline](https://cloud.githubusercontent.com/assets/26059207/25081407/87552642-234a-11e7-897d-e4f2ae4de45f.jpg)
![gui - configuration](https://cloud.githubusercontent.com/assets/26059207/25081408/875af9a0-234a-11e7-8c05-8a3d246c3d4a.jpg)
![alarm - rc off](https://cloud.githubusercontent.com/assets/26059207/25081412/8a63e396-234a-11e7-821d-f0bab51e141d.jpg)
![alarm - shaft rpm low](https://cloud.githubusercontent.com/assets/26059207/25081413/8a64ccf2-234a-11e7-8d4c-b7ea80fa20b6.jpg)
![display - ecu battery and fuel indicators](https://cloud.githubusercontent.com/assets/26059207/25081414/8a7c2f32-234a-11e7-832a-1a6286d56952.jpg)
![display - ecu offline](https://cloud.githubusercontent.com/assets/26059207/25081415/8a7fcb42-234a-11e7-8dcd-ee8d33662952.jpg)

![alarm shaft rpm low](https://cloud.githubusercontent.com/assets/26059207/24649940/f58155b8-1928-11e7-94e5-781be6503be5.png)
![flightogg - keros full](https://cloud.githubusercontent.com/assets/26059207/24649948/fb132074-1928-11e7-9d7e-8c54485448e0.jpg)
![normal - runreg4](https://cloud.githubusercontent.com/assets/26059207/24649952/fda3b114-1928-11e7-889e-91476eb2ab75.jpg)
![status - keros full](https://cloud.githubusercontent.com/assets/26059207/24649955/fff2e55c-1928-11e7-9ca3-790427c19f9d.jpg)


Developers, testers and helpers wanted. PM me.

#Now supporting the following ecu converters and turbines:
- Vspeak - FW 1.0 - JetCat
- Vspeak - FW 2.2 - Hornet
- Vspeak - FW 2.1 - Jakadofsky
- Vspeak - FW 2.1 - evoJet / Pahl 
- Vspeak - FW 1.1 - PBS
- Digitech - FW 1.2 - Evojet
- Digitech - FW 1.2  - Graupner G-Booster
- Digitech - FW 1.2  - Hammer
- Digitech - FW 1.2  - Hornet
- Digitech - FW 1.2  - JetCat
- Digitech - FW 1.2  - Kingtech g1
- Digitech - FW 1.2  - Kingtech g2
- Digitech - FW 1.2  - Lambert
- Digitech - FW 1.2  - Xicoy v6
- Digitech - FW 1.2  - Xicoy v10
- CB-Electroniks - FW ??  - Xicoy v10 (Experimental)
- CB-Electroniks - FW ??  - Xicoy v6 (Experimental)
- CB-Electroniks - FW ??  - JetCat (Experimental)
- Xicoy - FW ??  - Xicoy v6 (Experimental)
- Xicoy - FW ??  - Xicoy v10 (Experimental)
- Orbit 

- Just make a copy of a config file, adjust the parameters and put it in the ecu folder, and you can start using a new make of turbine or your own special config. Config files are read dynamically from ecu folder.

Supporting a new ecu converter is as easy as adding some json configuration files and you get all the bells and whistles

#Turbine status functionality:
- Configurable which ECU statuses to be read by voice, shown on the display and logged to the flight logg and vibrate (not for -16)
- All alarms enabled with one switch (recommed to use the same switch as throttle cut for turbine, then alarms are on when turbine is armed)
- Status alarms only given on status change
- Configurable which turbine status has audio alarms, haptic alarms (not for -16) or message alarms.
- Status - Individually configurable parameters for EVERY turbine STATUS (not for -16)
- Status - Audio alarm (information in female voice, warnings in male voice), possibility to change audio file. Configurable (not for -16)
- Status - Haptic feedback, which stick, which vibration profile, on/off. Configurable (not for -16).
- Status - Display warning. on/off - shows the status text as a warning. Will also log the turbine status to the normal Jeti flight log (this is super cool). Configurable (not for -16).
- Hundreds og audio files included with all statuses and alarms ready to be said.

The usual alarms (rpm, rpm2, egt, ecuv, fuellevel), but easier setup
- Some alarms like low rpm, low rpm2, low pumpvolt, low temp are not enabled until the low threshold is exceeded. This makes for no annoying low alarms before turbine is running, but they will also be shut off by the global switch.
- Turbine RPM high
- Turbine RPM low - only enabled after RPM has exceeded Turbine RPM low
- Shaft RPM high
- Shaft RPM low - only enabled after shaft RPM has exceeded Shaft RPM low
- Ecu voltage high (not for -16)
- Ecu voltage low - only enabled after ECU voltage has exceeded Ecu voltage low (not for -16)
- EGT high
- EGT low - only enabled after EGT has exceeded EGT low 
- Pump voltage high
- Pump voltage low - only enabled after Pump voltage has exceeded Pump voltage low
- Fuel warning alarm (configured at 20% fuel level)
- Fuel critical alarm (configured at 10% fuel level)
- Fuel - Audio messaage with remaining fuellevel 10 times pr tank (automaticially set intervals based on tanksize read from ECU)
- Fuel - Automatic reading of tanksize from ECU (shown in telemetry window)
- = Fuel = Zero configuration neccessary to have very advanced information and alarms on tank level
- Calculates  percentages from the interval between high and low config values)
Alarms will be repeated every 30 second if error condition is sustained

Other alarms
- Monitors that all sensors are online and gives a offline alarm (due to converter not working, ecu not working or ecu without power). will only sound once pr offline incidence.

Configuration possibilities
- Separate configuration file for each ECU converter type (sensor mapping and status mapping to common format)
- Separate configuration file for each Turbine type with best practise configuration.
- Separate configuration file for each Turbine types statuses with best practise configuration. (not for -16)
- Separate configuration file for each BatteryPack type with best practise configuration. (2s-lipo, 3s-lipo, 2s-life, 3s-life, 2-s-a123, 3s-a123) (not for -16)
- Separate configuration file for fuellevel setup with best practise configuration.

Telemetry display visual
- Fuel gauge, pump volt, ECU volt and status double window , code borrowed from "ECU data display" for Orbit made by Bernd Woköck
- Battery gauge, RPM, RPM2, EGT and status double window , code borrowed from "ECU data display" for Orbit made by Bernd Woköck (not for -16)
- Experimental RPM and TEMP round gauge (very cool, but not tested) (not for -16)

Thinking of implementing:
- Warning if you try to shutdown turbine while it is too hot (if possible to implement)
- Sound volume control connected to warnings and critical alarms
- Any alarms that should be enabled even when shut down?
- Even smarter battery monitoring based on lookup tables on voltages and percent left (p.t it only calculates battery percentages from the interval between high and low values)

#Help needed:
- Translation
- Configuration of "best practice" turbine alarms and setup for the supported ecus.
- Generation of audio files for all statuses and situations
- Testing
- Jeti Params for different ECUs (we only have to choose one sensor, we find the rest automatically by param)
- Making videos of running system

#Idea and goals
So the idea is that with this lua script you will get all needed turbine alarms setup in under 5 minutes (download lua script and install it- chooce ECU type, choose status telemetry sensor - you are done), with our collective best effort on defining whats the best way to have turbine alarms and telemetry.

For the people who love to tinker it is infinitely extensive and changeable in a easy manner in the configuration file pr ecu. But the distributed configuration file should be best practise for all others.

#Installation
- copy ecu_16.lc (not .lua, for memory optimization) and ecu folder into the Apps folder on your Jeti transmitter
- add ecu.lua to Applications
- choose ecu converter type
- choose turbine manufacturer type
- choose turbine type
- choose battery pack type
- choose kill switch
- you may have to reboot your transmitter once, to read all parameters correctly

Then you are up and running with the most advanced ecu monitoring available today


If you have any more ideas about needs for turbine alarms, please let me know.
