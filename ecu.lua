-- ############################################################################# 
-- # Jeti ECU Telemetry
-- # Jeti Advanced ECU LUA Script. Easy telemetry displaying, advanced alarms, easy setup, very configurable, easy to setup new ecu types
-- # Some Lua ideas copied from Jeti and TeroS
-- #
-- # Copyright (c) 2017, Original idea by Thomas Ekdahl (thomas@ekdahl.no) co-developed with Volker Weigt the maker of vspeak hardware.
-- # Telemetry display code graphics borrowed from ECU data display made by Bernd Woköck
-- #
-- # License: Share alike                                       
-- # Can be used and changed non commercial, but feel free to send us changes back to be incorporated in the main code.
-- #                       
-- # 0.9 - Initial release
-- ############################################################################# 

local loadh      = require "library/loadhelper"
local tableh     = require "library/tablehelper"
local alarmh     = require "library/alarmhelper"
local sensorh    = require "library/sensorhelper"
local fake       = require "library/fakesensor"
local telemetry1 = require "ecu/library/telemetry_window1"
local telemetry2 = require "ecu/library/telemetry_window2"

-- Globals to be accessible also from libraries
config          = {"..."} -- Complete turbine config object dynamically assembled
sensorsOnline   = 0 -- 0 not ready yet, 1 = all sensors confirmed online, -1 one or more sensors offline
--SensorT = {    -- Sensor objects is globally stored here and accessible by sensorname as configured in ecu converter

SensorT = {
    ["rpm"]         = {"..."},
    ["rpm2"]        = {"..."},
    ["egt"]         = {"..."},
    ["pumpv"]       = {"..."},
    ["ecuv"]        = {"..."},
    ["fuellevel"]   = {"..."},
    ["status"]      = {"..."}
 }

-- Locals for the application
local enableAlarm                 = false
local prevStatusID, prevFuelLevel = 0,0
local alarmOffSwitch

local lang              = {"..."} -- Language read from file

local alarmsTriggered   = {"..."} -- true on the alarm triggered, used to not repeat alarms to often

local alarmLowValuePassed = { -- enables alarms that has passed the low treshold, to not get alarms before turbine is running properly. Status alarms, high alarms, fuel alarms , and ecu voltage alarms is always enabled.
    rpm         = false,
    rpm2        = false,
    egt         = false,
    pumpv       = false,
    ecuv        = true,
    fuellevel   = false,  -- in ml from ecu
    status      = true
}

local SensorID              = 0
local ConverterTypeTable    = {"..."}   -- Array with all available turbine types
local ConverterType         = "vspeak"  -- the turbine type chosen

local TurbineTypeTable      = {"..."}   -- Array with all available turbine types
local TurbineType           = "hornet"  -- the turbine type chosen

local TurbineConfigTable    = {"..."}   -- Array with all available config fields
local TurbineConfig         = "generic"  -- the turbine config file chosen

local BatteryConfigTable    = {"..."}   -- Array with all available battery configs
local BatteryConfig         = "life-2s"  -- the battery config file chosen

--------------------------------------------------------------------
-- Read the config file for a spesific turbine, this is the first config that has to be run
local function loadConfig()
    -- Load main turbine config    
    config      = loadh.fileJson(string.format(string.format("Apps/ecu/turbine/%s/%s.jsn", TurbineType, TurbineConfig)))

    -- Generic config loading adding to default turbine config
    config.ecuv      = loadh.fileJson(string.format("Apps/ecu/batterypack/%s.jsn", BatteryConfig))
    config.fuellevel = loadh.fileJson("Apps/ecu/fuel/config.jsn")
    config.status    = loadh.fileJson(string.format("Apps/ecu/status/%s.jsn", TurbineType))
    config.converter = {"..."} 
    config.converter.statusmap = loadh.fileJson(string.format("Apps/ecu/converter/%s/%s/status.jsn", ConverterType, TurbineType))
    config.converter.sensormap = loadh.fileJson(string.format("Apps/ecu/converter/%s/%s/sensor.jsn", ConverterType, TurbineType))
end 

----------------------------------------------------------------------
--
local function ConverterTypeChanged(value)
    ConverterType  = ConverterTypeTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    print(string.format("ConverterTypeSave %s = %s", value, ConverterType))
    system.pSave("ConverterType",  ConverterType)
    TurbineTypeTable    = tableh.fromDirectory(string.format("Apps/ecu/converter/%s", ConverterType))
end

----------------------------------------------------------------------
--
local function TurbineTypeChanged(value)
    TurbineType  = TurbineTypeTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("TurbineType", TurbineType)
    TurbineConfigTable  = tableh.fromFiles(string.format("Apps/ecu/turbine/%s", TurbineType))
end

----------------------------------------------------------------------
--
local function TurbineConfigChanged(value)
    TurbineConfig  = TurbineConfigTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("TurbineConfig", TurbineConfig)
    loadConfig() -- reload after config change
end

----------------------------------------------------------------------
--
local function BatteryConfigChanged(value)
    BatteryConfig  = BatteryConfigTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("BatteryConfig", BatteryConfig)
    loadConfig() -- reload after config change
end

--------------------------------------------------------------------
-- Store settings when changed by user
local function SensorChanged(value)
	SensorID  = SensorT[value].id
	system.pSave("SensorID",  SensorID)

    -- Try to auto detect sensor from params later, to drop one menu element
    -- ECUconverter  = ECUconverterA[value]
    -- system.pSave("ECUconverter",  ECUconverter)
end

----------------------------------------------------------------------
--
local function initForm(subform)
    -- make all the dynamic menu items
    local ConverterTypeIndex, TurbineTypeIndex, TurbineConfigIndex, BatteryConfigIndex, SensorIndex = 1,1,1,1,1
    local SensorMenuT = {"..."}
    SensorT, SensorMenuT, SensorMenuIndex = sensorh.getSensorTable(SensorID)
    collectgarbage()

    ConverterTypeTable, ConverterTypeIndex  = tableh.fromDirectory("Apps/ecu/converter", ConverterType)
    TurbineTypeTable,   TurbineTypeIndex    = tableh.fromDirectory(string.format("Apps/ecu/converter/%s", ConverterType), TurbineType)
    TurbineConfigTable, TurbineConfigIndex  = tableh.fromFiles(string.format("Apps/ecu/turbine/%s", TurbineType), TurbineConfig)
    BatteryConfigTable, BatteryConfigIndex  = tableh.fromFiles("Apps/ecu/batterypack", BatteryConfig)
    collectgarbage()

    form.addRow(2)
    form.addLabel({label=lang.selectConverterType, width=200})
    form.addSelectbox(ConverterTypeTable, ConverterTypeIndex, true, ConverterTypeChanged)

    form.addRow(2)
    form.addLabel({label=lang.selectTurbineType, width=200})
    form.addSelectbox(TurbineTypeTable, TurbineTypeIndex, true, TurbineTypeChanged)

    form.addRow(2)
    form.addLabel({label=lang.selectTurbineConfig, width=200})
    form.addSelectbox(TurbineConfigTable, TurbineConfigIndex, true, TurbineConfigChanged)

    form.addRow(2)
    form.addLabel({label=lang.selectBatteryConfig, width=200})
    form.addSelectbox(BatteryConfigTable, BatteryConfigIndex, true, BatteryConfigChanged)

    form.addRow(2)
    form.addLabel({label=lang.selectLeftTurbineSensor, width=200})
    form.addSelectbox(SensorMenuT, SensorMenuIndex, true, SensorChanged)

    form.addRow(2)
    form.addLabel({label=lang.alarmOffSwitch, width=200})
    form.addInputbox(alarmOffSwitch,true, function(value) alarmOffSwitch=value; system.pSave("alarmOffSwitch",value) end ) 

    form.addRow(1)
    if(enableAlarm) then
        form.addLabel({label="Alarms: on"})
    else
        form.addLabel({label="Alarms: off"})
    end

    form.addRow(1)
    form.addLabel({label=string.format("ECU converter: %s",ConverterType)})

    collectgarbage()
    print("Mem after GUI: ", collectgarbage("count"))
end


----------------------------------------------------------------------
-- Re-init correct form if navigation buttons are pressed
local function keyPressed(key)
    form.reinit(1)
end

----------------------------------------------------------------------
-- Calculates: config.fuellevel.tanksize and config.fuellevel.interval and fuelpercent
local function initFuelStatistics(tmpConfig)

    if(config.fuellevel.tanksize < 50) then

        -- Init: Automatic calculations done on the first run after we read the sensor value.
        config.fuellevel.tanksize = SensorT[tmpConfig.sensorname].sensor.value -- new or max?
        config.fuellevel.interval = config.fuellevel.tanksize / 11 -- Calculate 10 fuel intervals for reporting announcing automatically of remaining tank
        prevFuelLevel = config.fuellevel.tanksize - config.fuellevel.interval -- init full tank reporting, but do not start before next interval
    end 
    
    -- Calculate fuel percentage
    SensorT[tmpConfig.sensorname].percent = (SensorT[tmpConfig.sensorname].sensor.value / config.fuellevel.tanksize) * 100
end

----------------------------------------------------------------------
--
local function processFueltank(tmpConfig, tmpSensorID)

    if(SensorT[tmpConfig.sensorname].sensor.valid) then

        initFuelStatistics(tmpConfig) -- Important

        -- We only enable the low alarms after they have passed the low threshold
        if(SensorT[tmpConfig.sensorname].sensor.value > tmpConfig.warning.value and not alarmLowValuePassed[tmpConfig.sensorname]) then
            alarmLowValuePassed[tmpConfig.sensorname] = true;
        end

        -- Repeat fuel level audio at intervals
        if(SensorT[tmpConfig.sensorname].sensor.value < prevFuelLevel and alarmLowValuePassed[tmpConfig.sensorname]) then
            prevFuelLevel = prevFuelLevel - tmpConfig.interval -- Only work in intervals, should we calculate intervals from tanksize? 10 informations pr tank?    
            system.playNumber(prevFuelLevel / 1000, tmpConfig.decimals, tmpConfig.unit, tmpConfig.label) -- Read out the numbers from the interval, not the value - to get better clearity
        end
        
        -- Check for alarm thresholds
        if(enableAlarm and alarmLowValuePassed[tmpConfig.sensorname]) then
            if(not alarmsTriggered[tmpConfig.sensorname]) then
                if(SensorT[tmpConfig.sensorname].percent < tmpConfig.critical.value) then

                    alarmsTriggered[tmpConfig.sensorname] = true
                    alarmh.Message(tmpConfig.critical.message,string.format("%s (%s < %s)", tmpConfig.critical.text, SensorT[tmpConfig.sensorname].percent, tmpConfig.critical.value))
                    alarmh.Haptic(tmpConfig.critical.haptic)
                    alarmh.Audio(tmpConfig.critical.audio)
            
                elseif(SensorT[tmpConfig.sensorname].percent < tmpConfig.warning.value) then

                    alarmsTriggered[tmpConfig.sensorname] = true
                    alarmh.Message(tmpConfig.warning.message,string.format("%s (%s < %s)", tmpConfig.warning.text, SensorT[tmpConfig.sensorname].percent, tmpConfig.warning.value))
                    alarmh.Haptic(tmpConfig.warning.haptic)
                    alarmh.Audio(tmpConfig.warning.audio)
                 end
            end
        end
    else
        SensorT[tmpConfig.sensorname].percent = 0
    end
end

----------------------------------------------------------------------
-- readGenericSensor high/low value alarms
-- ToDo: These alarms will be repeated to often, how to avoid that? Second counter, repeat counter?

local function processGeneric(tmpConfig, tmpSensorID)

    --print(string.format("sensorname : %s",tmpConfig.sensorname))
    if(SensorT[tmpConfig.sensorname].sensor and SensorT[tmpConfig.sensorname].sensor.valid) then

        -- We only enable the low alarms after they have passed the low threshold
        if(SensorT[tmpConfig.sensorname].sensor.value > tmpConfig.low.value and not alarmLowValuePassed[tmpConfig.sensorname]) then
            alarmLowValuePassed[tmpConfig.sensorname] = true;
        end

        -- calculate percentage
        SensorT[tmpConfig.sensorname].percent = ((SensorT[tmpConfig.sensorname].sensor.value - tmpConfig.low.value) / (tmpConfig.high    .value - tmpConfig.low.value)) * 100

        if(enableAlarm) then
            if(not alarmsTriggered[tmpConfig.sensorname]) then 
                if(SensorT[tmpConfig.sensorname].sensor.value > tmpConfig.high.value) then
                    alarmsTriggered[tmpConfig.sensorname] = true
                    alarmh.Message(tmpConfig.high.message,string.format("%s (%s > %s)", tmpConfig.high.text, SensorT[tmpConfig.sensorname].sensor.value, tmpConfig.high.value))
                    alarmh.Haptic(tmpConfig.high.haptic)
                    alarmh.Audio(tmpConfig.high.audio)
            
                elseif(SensorT[tmpConfig.sensorname].sensor.value < tmpConfig.low.value and alarmLowValuePassed[tmpConfig.sensorname]) then
                    alarmsTriggered[tmpConfig.sensorname] = true
                    alarmh.Message(tmpConfig.high.message,string.format("%s (%s < %s)", tmpConfig.low.text, SensorT[tmpConfig.sensorname].sensor.value, tmpConfig.low.value))
                    alarmh.Haptic(tmpConfig.low.haptic)
                    alarmh.Audio(tmpConfig.low.audio)
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- 
local function processStatus(tmpConfig, tmpSensorID)
    local statusChanged = false
    local statusint     = 0 -- sensor statusid
    local switch
    local statuscode  = ''

    if(SensorT[tmpConfig.sensorname].sensor.valid) then
        statusint    = string.format("%s", math.floor(SensorT[tmpConfig.sensorname].sensor.value))
        statuscode  = config.converter.statusmap[statusint] -- convert converters integers to turbine manufacturers text status

        if(config.status[statuscode] ~= nil) then 
            SensorT[tmpConfig.sensorname].text = config.status[statuscode].text;
        else
            SensorT[tmpConfig.sensorname].text = '';
        end
        -------------------------------------------------------------_
        -- Check if status is changed since the last time
        if(prevStatusID ~= statuscode) then
            print(string.format("statusint %s", statusint))
            print(string.format("Status changed %s != %s", prevStatusID, statuscode))
            statusChanged = true
        end 
        prevStatusID = statuscode
        -------------------------------------------------------------
        -- If user has enabled alarms, the status has an alarm, the status has changed since last time - sound the alarm
        -- This should get rid of all annoying alarms
        if(statusChanged) then
            alarmh.Message(config.status[statuscode].message, SensorT[tmpConfig.sensorname].text) -- we always show a message that will be logged on status changed
            if(enableAlarm) then
                -- ToDo: Implement repeat of alarm
                alarmh.Haptic(config.status[statuscode].haptic)
                alarmh.Audio(config.status[statuscode].audio)
             end
         end
    else 
        SensorT[tmpConfig.sensorname].text = "          -- "
    end
end

----------------------------------------------------------------------
-- Resets alarms so they will be triggered again every 30 seconds
function resetAlarmCounter()
    if(system.getTime() % 30 == 0) then
        for name,value in pairs(alarmsTriggered) do 
            alarmsTriggered[name] = false
        end
    end
end

----------------------------------------------------------------------
-- Check if switch to enable alarms is set, sets global enableAlarm value
local function enableAlarmCheck()
    switch = system.getSwitchInfo(alarmOffSwitch)
    if(switch) then
        if(switch.value < 0 and enableAlarm) then  -- turned off by switch, will always override status handling
            enableAlarm      = false
            print("switch off enableAlarms = false")
        elseif(switch.value > 0 and not enableAlarm) then
            enableAlarm      = true
            print("switch on enableAlarms = true")
        end
    end
end

----------------------------------------------------------------------
-- Read and map all sensors to names instead of param values for easier processing
local function readParamsFromSensor(tmpSensorID)

    local countSensorsValid = 0
    local countSensors      = 0

    for tmpSensorName, tmpSensorParam in pairs(config.converter.sensormap) do
        if(tonumber(tmpSensorParam) > 0) then
            --print(string.format("rsensor: %s : %s : %s", tmpSensorID, tmpSensorName, tonumber(tmpSensorParam)))
            SensorT[tmpSensorName] = {"..."} -- Have to get rid of this, to get speed up.
            SensorT[tmpSensorName].sensor = system.getSensorByID(tmpSensorID, tonumber(tmpSensorParam))

            if(SensorT[tmpSensorName].sensor) then
                countSensors = countSensors + 1

                if(SensorT[tmpSensorName].sensor.valid) then
                    countSensorsValid = countSensorsValid + 1
                else 
                    -- The sensor exist, but is not valid yet.
                    SensorT[tmpSensorName].sensor.value = 0
                    SensorT[tmpSensorName].percent      = 0
                end
            else
                -- The sensor does not exist, ignore it. (not counting, no values)
            end
        else 
            -- Parm is zero, so this sensor does not exist for this converter, we fake it with zero values.
            SensorT[tmpSensorName].sensor.value = 0
            SensorT[tmpSensorName].percent      = 0
        end
    end

    --print(string.format("configured: %s valid: %s", #config.converter.sensormap, countSensorsValid))
    if(countSensorsValid == countSensors) then
        sensorsOnline   = 1

    elseif(sensorsOnline == 1 and enableAlarm and not alarmsTriggered.offline) then -- Only trigger if all sensors has been online
        -- If the valid number of sensors is not equal to the configured number of sensors, the ECU is somehow offline
        -- Will only trigger again if it goes online again and then offline again. Will not repeat.
        alarmsTriggered.offline = true

        print(string.format("SensorsOffline: %s valid: %s", countSensors, countSensorsValid))
        sensorsOnline   = -1
        system.messageBox(string.format("ECU Offline - configured: %s valid: %s", countSensors, countSensorsValid), 10)
        system.playFile("/Apps/ecu/audio/ECU reboot.wav",AUDIO_IMMEDIATE)
        system.vibration(false, 4);
    end
end

----------------------------------------------------------------------
-- Application initialization. Has to be the second last function so all other functions is initialized
local function init()
    -- Load translation files  
    system.registerForm(1,MENU_APPS,lang.appName, initForm, keyPressed)

    SensorID          = system.pLoad("SensorID", 0)
    ConverterType     = system.pLoad("ConverterType", "vspeak")
    TurbineType       = system.pLoad("TurbineType", "jetcat")
    TurbineConfig     = system.pLoad("TurbineConfig", "generic")
    BatteryConfig     = system.pLoad("BatteryConfig", "life-2s")
    alarmOffSwitch    = system.pLoad("alarmOffSwitch")

    -- read all the config files
    loadConfig()

    system.registerTelemetry(1, string.format("%s", lang.window2),2,telemetry2.window)
    system.registerTelemetry(2, lang.window1, 2, telemetry1.window)  

    ctrlIdx = system.registerControl(1, "Turbine off switch","TurbOff")
    collectgarbage()
    print("Init finished: ", collectgarbage("count"))
end

----------------------------------------------------------------------
-- Loop has to be the last function, so every other function is initialized
local function loop()

    fake.makeSensorValues()
    if(SensorID ~= 0) then
        resetAlarmCounter()
        enableAlarmCheck()
        readParamsFromSensor(SensorID)

        -- All converters has these sensors
        processFueltank(config.fuellevel, SensorID)
        processGeneric(config.rpm,   SensorID)
        processGeneric(config.egt,   SensorID)
        processGeneric(config.pumpv, SensorID)
        processGeneric(config.ecuv,  SensorID)

        -- Check if converter has these sensor before processing them, since the availibility varies
        if(config.converter.sensormap.status) then
            processStatus(config.status, SensorID)
        end
        if(config.converter.sensormap.rpm2) then
            processGeneric(config.rpm2,  SensorID)
        end
    end
end

lang = loadh.fileJson(string.format("Apps/ecu/locale/%s.jsn", system.getLocale()))

return {init=init, loop=loop, author="Thomas Ekdahl - thomas@ekdahl.no", version='0.95', name=lang.appName}