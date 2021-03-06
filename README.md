# Jeti ECU Turbine Telemetry Lua Script
Jeti ECU LUA Script. Silent/Black-Cockpit alarms (sound/alert/haptic/logg) that are silent until needed on Turbine Status, RPM, RPM2, PUMPV, BATT, FUEL, EGT, Flameout. Dashboard presentation of all turbine parameters and visualised fuel and battery. The idea is no alarms on the ground, only alarms when the shit hits the fan to help to save your costly model. Easy setup based on choise of best practise configuration files. 

NOTE: You do not have to edit configuration files, standard config files for your turbine has best practise set up right out of the box, just choose ecu converter, turbine type, battery pack, ecu sensor and throttle kill switch - and you will have the most advanced turbine surveilance available to RC turbine models today.

Supports vspeak ecu converter (my personal favorite ECU converter), Digitech ecu converter, jetcat ecu converter and experimental support for CB-Electroniks and Xicoy converters (needs testers). Manufactures of turbine ECU converters are welcome to contact me, to add support for their equipment. The idea is to support all Turbines and Turbine ECU converters that exists - with

Only works with Jeti transmitter FW 4.22 or better. 

#### Video of installation and setup
https://youtu.be/tsEkAW4Y2tU

#### Video simulating normal usage
https://youtu.be/evyAzlbLs68

#### Video simulation a flight with lots of alarms triggered
https://youtu.be/_tN6GDu43rU

#### Video of how this advanced lua script is tested with an ECU simulator made with Arduino Pro Mini
https://youtu.be/EmGTHrpVQJE

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
- Vspeak - FW 1.0 - AMT
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
- Orbit (Experimental)

#Turbine status functionality:
- Waits 15 seconds to stabilize all telemetric input before alarms are activated
- Configuration files for which ECU statuses to be read by voice, shown on the display and logged to the flight logg and vibrate (not for -16)
- Alarms audio/haptic/alert turned off with separate switches (recommed to use the same switch as throttle cut for turbine, then alarms are on when turbine is armed)
- Status alarms only given on status change
- Configurable which turbine status has audio alarms, haptic alarms (not for -16) or message alarms.
- Status - Individually configurable in configuration files parameters for EVERY turbine STATUS (not for -16)
- Status - Audio alarm, possibility to change audio file. Configurable (not for -16)
- Status - Haptic feedback, which stick, which vibration profile, on/off. Configurable (not for -16).
- Status - Display warning. on/off - shows the status text as a warning. Will also log the turbine status to the normal Jeti flight log (this is super cool). Configurable (not for -16).
- 139 audio files included with all statuses and alarms.

The usual alarms (rpm, rpm2, egt, ecuv, fuellevel), but easier setup
- Some alarms like low rpm, low rpm2, low pumpvolt, low temp are not enabled until the low threshold is exceeded. This makes for no annoying low alarms before turbine is running, but they will also be shut off by the global switch.
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
- Fuel alarms default setup: 75% (audio), 50% (audio), 30% (audio), 20% (audio and haptic), 10% (audio and haptic), 5% (audio and haptic)
- Fuel alarms customizable in configuration file to what % of fuel level you need an alarm, the audio file, haptich profile and message to bo shown and logged.
- Fuel - Automatic reading of tanksize from ECU (shown in telemetry window)
- Fuel sensor problem warning if fuelsensor goes below 0
- = Fuel = Zero configuration neccessary on vspeak with jetcat, hornet, and all digitech - the rest have to input TankSize
- Calculates  percentages from the interval between high and low config values)
Alarms will only be repeated every 30 second if error condition is sustained

Other alarms
- Monitors that all sensors are online and gives a offline alarm (due to converter not working, ecu not working or ecu without power).

Configuration possibilities
- Separate customizable file for each ECU converter type (sensor mapping and status mapping to common format)
- Separate customizable file for each Turbine type with best practise configuration.
- Separate customizable file for each Turbine types statuses with best practise configuration. (not for -16)
- Separate customizable file for each BatteryPack type with best practise configuration. (2s-lipo, 3s-lipo, 2s-life, 3s-life, 2-s-a123, 3s-a123) (not for -16)
- Separate configuration file for fuellevel setup with best practise configuration.

Telemetry display visual
- Fuel gauge, pump volt, ECU volt and status double window , based on code from "ECU data display" for Orbit made by Bernd Woköck
- Battery gauge, RPM, RPM2, EGT and status double window , based on code from "ECU data display" for Orbit made by Bernd Woköck (not for -16)
- Experimental RPM and TEMP round gauge (very cool, but not tested) (not for -16)
- Experimental full screen GUI (Only for -24)

Thinking of implementing:
1. Smarter battery monitoring based smoothing out voltages to not get alarms on short battery dips
2. Warning if you try to shutdown turbine while it is too hot (if possible to implement)
3. Sound volume control connected to warnings and critical alarms

#Help needed:
- Translation
- Configuration of "best practice" turbine alarms and setup for the supported ecus.
- Testing
- Jeti Params for different ECUs (we only have to choose one sensor, we find the rest automatically by param)
- Turbine setups for different turbines
- Making videos of running system

#Idea and goals
So the idea is that with this lua script you will get all needed turbine alarms setup in under 5 minutes (download lua script and install it- chooce ECU type, choose status telemetry sensor - you are done), with our collective best effort on defining whats the best way to have turbine alarms and telemetry.

For the people who love to tinker it is infinitely extensive and changeable in a easy manner in the configuration file pr ecu. But the distributed configuration file should be best practise for all others.

#Installation
- Download Jeti Studio from http://www.jetimodel.com/en/JETI-Studio-2/
- Connect transmitter to PC/Mac
- Go to menu: Tools => Transmitter Wizard => Lua App Manager. Choose the ECU App and press install.
- Disconnect transmitter from PC/Mac
Disconnect USB from transmitter, start transmitter normally and choose the Application menu<br>
![install - 12 - choose application menu on transmitter](https://user-images.githubusercontent.com/26059207/31859261-ac5fabf8-b709-11e7-9470-003703fc3d70.png)<br><br>
Choose user application menu on transmitter<br>
![install - 13 - choose user applications on transmitter](https://user-images.githubusercontent.com/26059207/31859262-ac78476c-b709-11e7-9009-1ec81c33a3e4.png)<br><br>
Press + (plus) sign to add application<br>
![install - 14 - press plus sign on transmitter](https://user-images.githubusercontent.com/26059207/31859263-ac92cdc6-b709-11e7-81b0-8ef1f92ed9c7.png)<br>
Copy the ecu.lc file to Apps folder on transmitter if you have ds-24 or dc-24<br>
![install - 15 - choose ecu if you have a ds-24 or dc-24](https://user-images.githubusercontent.com/26059207/31859264-acacc7da-b709-11e7-9c44-d7d78ac191ab.png)<br>
Copy the ecu_16.lc file to Apps folder on transmitter if you have ds-16 or dc-16<br>
![install - 15 - choose ecu_16 if you have a ds-16 or dc-16 png](https://user-images.githubusercontent.com/26059207/31859265-acc57ca8-b709-11e7-930c-6e74ea00fc0f.png)<br><br>
If it says Err instead of OK on the App status. Press the CMD button to see the debug log. Important: If reporting errors to me, you have to include a screenshot of this debug screen.<br>
![install - 16 - application added and running](https://user-images.githubusercontent.com/26059207/31859266-ace26e62-b709-11e7-8dd3-b01205e7d07a.png)<br><br>
Answear yes<br>
![install - 17 - answear yes](https://user-images.githubusercontent.com/26059207/31859267-acfb08b4-b709-11e7-9282-8a951d3ddc21.png)<br><br>
Debug console log screen - you have to send me a screendump of this console log if you have problems running the app<br>
![install - 18 - debug info after pressing the command button](https://user-images.githubusercontent.com/26059207/31859268-ad135fd6-b709-11e7-8338-7fd456c0731d.png)<br><br>
![install - 19 - after choosing the applicatiomn](https://user-images.githubusercontent.com/26059207/31859269-ad2ce8de-b709-11e7-912c-3512f655e07d.png)<br><br>
![install - 20 - choose telemetry converter](https://user-images.githubusercontent.com/26059207/31859270-ad46d6ea-b709-11e7-9cb6-bac3a4210ffd.png)<br><br>
![install - 21 - choose ecu type](https://user-images.githubusercontent.com/26059207/31859271-ad60c0aa-b709-11e7-8a4b-a453fc5410e3.png)<br><br>
![install - 22 - choose ecu](https://user-images.githubusercontent.com/26059207/31859272-ad7bacda-b709-11e7-92da-fdc63814e50d.png)<br><br>
![install - 23 - choose turbine config generic](https://user-images.githubusercontent.com/26059207/31859273-ad94b90a-b709-11e7-91ab-423dadd7eb15.png)<br><br>
![install - 24 - choose battery type](https://user-images.githubusercontent.com/26059207/31859274-adadf56e-b709-11e7-8d72-439fd461da98.png)<br><br>
![install - 25 - choose battery type](https://user-images.githubusercontent.com/26059207/31859275-adc5fde4-b709-11e7-8ad7-b4ac63837835.png)<br><br>
![install - 26 - choose ecu sensor](https://user-images.githubusercontent.com/26059207/31859276-adde240a-b709-11e7-8779-741c5ca2eae8.png)<br><br>
![install - 27 - choose alarms off switch - same as throttle kill recommended](https://user-images.githubusercontent.com/26059207/31859277-adf65c5a-b709-11e7-8cdf-59f457522c7a.png)<br>


If you have any more ideas about needs for turbine alarms, please let me know.
