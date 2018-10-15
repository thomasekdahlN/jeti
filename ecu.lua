-- ############################################################################# 
-- # Jeti ECU Telemetry
-- # Jeti Advanced ECU LUA Script. Easy telemetry displaying, advanced alarms, easy setup, very configurable, easy to setup new ecu types
-- # Some Lua ideas copied from Jeti and TeroS
-- #
-- # Copyright (c) 2017, Original idea by Thomas Ekdahl (thomas@ekdahl.no).
-- # Telemetry display code graphics borrowed from ECU data display made by Bernd Woköck
-- #
-- # License: Share alike                                       
-- # Can be used and changed non commercial, but feel free to send us changes back to be incorporated in the main code.
-- # If using parts of this project elsewhere, please give me credit for it
-- #                       
-- # Version: 2.6
-- ############################################################################# 

local loadh      = require "ecu/lib/loadhelper"
local tableh     = require "ecu/lib/tablehelper"
local alarmh     = require "ecu/lib/alarmhelper"
local sensorh    = require "ecu/lib/sensorhelper"
local fuelh      = require "ecu/lib/fuelhelper"
--local fake       = require "ecu/lib/fakesensor"
local window1    = require "ecu/lib/window1"
local window2    = require "ecu/lib/window2"
--local window3 = require "ecu/lib/window3"
--local window4 = require "ecu/lib/window4"

-----------------------------------------------------------------------------
-- Globals to be accessible also from libraries
config             = {"..."} -- Complete turbine config object dynamically assembled
sensorsOnline      = 0 -- 0 not ready yet, 1 = all sensors confirmed online, -1 one or more sensors offline
enableAlarmAudio   = true
enableAlarmHaptic  = true
enableAlarmMessage = true

--SensorT = {    -- Sensor objects is globally stored here and accessible by sensorname as configured in ecu converter

SensorT = {
    rpm    = {"..."},
    rpm2   = {"..."},
    egt    = {"..."},
    pumpv  = {"..."},
    ecuv   = {"..."},
    fuel   = {"..."},
    status = {"..."}
 }

fuelAlarm = {}
TankSize  = 0

-----------------------------------------------------------------------------
-- Locals for the application
local prevStatus = 0
local audioOffSwitch, hapticOffSwitch, messageOffSwitch = 0,0,0

local lang              = {"..."} -- Language read from file

local alarmTriggeredTime   = { -- stores latest datetime on the alarm triggered, used to not repeat alarms to often
    rpm    = 0,
    rpm2   = 0,
    egt    = 0,
    pumpv  = 0,
    ecuv   = 0,
    fuel   = 0,  -- in ml from ecu
    status = 0,
    offline= 0,
    fuelsensorproblem = 0
}

local alarmLowValuePassed = { -- enables alarms that has passed the low treshold, to not get alarms before turbine is running properly. Status alarms, high alarms, fuel alarms , and ecu voltage alarms is always enabled.
    rpm    = false,
    rpm2   = false,
    egt    = false,
    pumpv  = false,
    ecuv   = true,
    fuel   = false,  -- in ml from ecu
    status = true
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
    config.fuel      = loadh.fileJson("Apps/ecu/fuel/config.jsn")
    config.status    = loadh.fileJson(string.format("Apps/ecu/status/%s.jsn", TurbineType))
    config.converter = loadh.fileJson(string.format("Apps/ecu/converter/%s/%s/config.jsn", ConverterType, TurbineType))
end 

----------------------------------------------------------------------
--
local function ConverterTypeChanged(value)
    ConverterType  = ConverterTypeTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    print(string.format("ConverterTypeSave %s = %s", value, ConverterType))
    system.pSave("ConverterType",  ConverterType)
    TurbineTypeTable    = tableh.fromDirectory(string.format("Apps/ecu/converter/%s", ConverterType))
    loadConfig() -- reload after config change
end

----------------------------------------------------------------------
--
local function TurbineTypeChanged(value)
    TurbineType  = TurbineTypeTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("TurbineType", TurbineType)
    TurbineConfigTable  = tableh.fromFiles(string.format("Apps/ecu/turbine/%s", TurbineType))
    loadConfig() -- reload after config change
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
    local ConverterTypeIndex, TurbineTypeIndex, TurbineConfigIndex, BatteryConfigIndex, SensorMenuIndex = 1,1,1,1,1
    local SensorMenuT = {"..."}
    SensorT, SensorMenuT, SensorMenuIndex = sensorh.getSensorTable(SensorID) -- Returns only sensor names
    -- SensorT, SensorMenuT, SensorMenuIndex = sensorh.getSensorParamTable(SensorID) -- Returns all sensors with param valuye

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
    form.addLabel({label=lang.selectTurbineSensor, width=200})
    form.addSelectbox(SensorMenuT, SensorMenuIndex, true, SensorChanged)

    form.addRow(2)
    form.addLabel({label='Tank size', width=200})
    form.addIntbox(TankSize,0,10000,0,0,50,function(value) TankSize=value; system.pSave("TankSize",value) end )

    form.addRow(2)
    form.addLabel({label=lang.selectBatteryConfig, width=200})
    form.addSelectbox(BatteryConfigTable, BatteryConfigIndex, true, BatteryConfigChanged)

    form.addRow(2)
    form.addLabel({label=lang.AudioOffSwitch, width=200})
    form.addInputbox(audioOffSwitch,true, function(value) audioOffSwitch=value; system.pSave("audioOffSwitch",value) end ) 

    form.addRow(2)
    form.addLabel({label=lang.HapticOffSwitch, width=200})
    form.addInputbox(hapticOffSwitch,true, function(value) hapticOffSwitch=value; system.pSave("hapticOffSwitch",value) end ) 

    form.addRow(2)
    form.addLabel({label=lang.MessageOffSwitch, width=200})
    form.addInputbox(messageOffSwitch,true, function(value) messageOffSwitch=value; system.pSave("messageOffSwitch",value) end ) 

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
-- Process fuel Alarms
local function processFuel(tmpCfg, tmpSensorID)

    if(SensorT[tmpCfg.sensorname]) then
        if(SensorT[tmpCfg.sensorname].sensor.valid) then

            -- Repeat fuel level audio at intervals
            if(SensorT[tmpCfg.sensorname].sensor.value >= 0) then

                fuelh.initFuelSetup(tmpCfg) -- Important, runs only on startup
                SensorT[tmpCfg.sensorname].percent = fuelh.calculateFuelPercent(tmpCfg)

                ----------------------------------------------------------------------
                -- Check for alarm thresholds
                local thresholdI, thresholdV = fuelh.FuelThresholdPassed(tmpCfg)

                if(not fuelAlarm[thresholdV] and alarmTriggeredTime.fuel < system.getTime() and thresholdV < 100) then

                    fuelAlarm[thresholdV] = true -- Alarm has been given, never repeat
                    alarmh.All(tmpCfg.alarms[thresholdI],string.format("%s (%d.2 < %d.2)", tmpCfg.alarms[thresholdI].text, SensorT[tmpCfg.sensorname].percent, thresholdV))
                    alarmTriggeredTime.fuel = system.getTime() + 5 -- 5 seconds pause until next alarm
                 end
            elseif(alarmTriggeredTime.fuelsensorproblem < system.getTime()) then
                -- Reading negative fuel values, trouble with sensor
                alarmh.All(tmpCfg.sensorproblem,string.format("%s : %d.2)", tmpCfg.sensorproblem.text, SensorT[tmpCfg.sensorname].sensor.value))
                alarmTriggeredTime.fuelsensorproblem = system.getTime() + 15 -- 15 seconds pause until next alarm
            end
        else
            SensorT[tmpCfg.sensorname].percent = 0
        end
    end
end

----------------------------------------------------------------------
-- readGenericSensor high/low value alarms
-- ToDo: These alarms will be repeated to often, how to avoid that? Second counter, repeat counter?

local function processGeneric(tmpCfg, tmpSensorID)

    if(tmpCfg) then
        if(SensorT[tmpCfg.sensorname]) then
            if(SensorT[tmpCfg.sensorname].sensor and SensorT[tmpCfg.sensorname].sensor.valid) then

                -- We only enable the low alarms after they have passed the low threshold
                if(SensorT[tmpCfg.sensorname].sensor.value > tmpCfg.low.value and not alarmLowValuePassed[tmpCfg.sensorname]) then
                    alarmLowValuePassed[tmpCfg.sensorname] = true
                end

                -- calculate percentage
                SensorT[tmpCfg.sensorname].percent = fuelh.calcPercent(SensorT[tmpCfg.sensorname].sensor.value, tmpCfg.high.value, tmpCfg.low.value)

                if(alarmTriggeredTime[tmpCfg.sensorname] < system.getTime()) then 
                    if(SensorT[tmpCfg.sensorname].sensor.value > tmpCfg.high.value) then
                        alarmTriggeredTime[tmpCfg.sensorname] = system.getTime() + 30
                        alarmh.All(tmpCfg.high,string.format("%s (%d.2 > %d.2)", tmpCfg.high.text, SensorT[tmpCfg.sensorname].sensor.value, tmpCfg.high.value))
                
                    elseif(SensorT[tmpCfg.sensorname].sensor.value < tmpCfg.low.value and alarmLowValuePassed[tmpCfg.sensorname]) then
                        alarmTriggeredTime[tmpCfg.sensorname] = system.getTime() + 30
                        alarmh.All(tmpCfg.low,string.format("%s (%d.2 < %d.2)", tmpCfg.low.text, SensorT[tmpCfg.sensorname].sensor.value, tmpCfg.low.value))
                    end
                end
            else
                -- system.messageBox(string.format("PG Sensor not valid : %s", tmpSensorID), 3) -- Also happens when unpowered
            end
        else
            system.messageBox(string.format("PG Missing sensorname : %s", tmpSensorID), 3)
        end
    else
        system.messageBox(string.format("PG Missing tmpCfg : %s", tmpSensorID), 3)
    end
end


local function processStatus(tmpCfg, tmpSensorID)
    local statusint     = 0 -- sensor statusid
    local switch

    if(tmpCfg) then
        if(SensorT[tmpCfg.sensorname]) then

            if(SensorT[tmpCfg.sensorname].sensor.valid) then
                statusint    = string.format("%s", math.floor(SensorT[tmpCfg.sensorname].sensor.value))
                SensorT[tmpCfg.sensorname].text  = config.converter.statusmap[statusint] -- convert converters integers to turbine manufacturers text status

                -------------------------------------------------------------_
                -- Check if status is changed since the last time
                if(SensorT[tmpCfg.sensorname].text) then
                    if(prevStatus ~= SensorT[tmpCfg.sensorname].text and alarmTriggeredTime[tmpCfg.sensorname] < system.getTime()) then
                        print(string.format("status #%s#%s#", statusint, SensorT[tmpCfg.sensorname].text))

                        if(not config.status[SensorT[tmpCfg.sensorname].text]) then
                            system.messageBox(string.format("Unknown status config #%s#", SensorT[tmpCfg.sensorname].text), 3)
                            system.playFile("/Apps/ecu/audio/Unknown status configuration.wav", AUDIO_QUEUE)
                            prevStatus = SensorT[tmpCfg.sensorname].text

                        else
                            alarmh.All(config.status[SensorT[tmpCfg.sensorname].text], SensorT[tmpCfg.sensorname].text) -- we always show a message that will be logged on status changed
                            prevStatus = SensorT[tmpCfg.sensorname].text

                        end
                    end
                else
                    system.messageBox(string.format("Unknown status code #%s#", statusint), 2)
                end 
                -------------------------------------------------------------
                -- If user has enabled alarms, the status has an alarm, the status has changed since last time - sound the alarm
                -- This should get rid of all annoying alarms
            else 
                SensorT[tmpCfg.sensorname].text = "OFFLINE"
            end
        else
            system.messageBox(string.format("Sensor mapping error"), 2)
        end
    else
        system.messageBox(string.format("Status missing tmpCfg : %s", tmpSensorID), 3)
    end
end

----------------------------------------------------------------------
-- Check if switch to enable alarms is set, sets global enableAlarm value
local function enableAlarmCheck(OffSwitch)
    local Switch   = system.getSwitchInfo(OffSwitch)

    if(Switch) then
        if(Switch.value < 0) then  -- turned off by switch, will always override status handling
            return false
        else
            return true
        end
    end
    return true
end

----------------------------------------------------------------------
-- Reset all alarms with 10 seconds pause until telemetry systems is stabilised after first loop with all sensors read
local function resetAlarmTriggeredTime(delay)

    for tmpName, tmpValue in pairs(alarmTriggeredTime) do
        alarmTriggeredTime[tmpName] = system.getTime() + delay
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
        sensorsOnline = sensorsOnline + 1;
        if(sensorsOnline == 1) then
            resetAlarmTriggeredTime(15) -- Reset when all sensors are valid and init finshed, (but only run the first time)
        end
    elseif(sensorsOnline > 0 and alarmTriggeredTime.offline < system.getTime()) then -- Only trigger if all sensors has been online
        -- If the valid number of sensors is not equal to the configured number of sensors, the ECU is somehow offline
        -- Will only trigger again if it goes online again and then offline again. Will not repeat.
        alarmTriggeredTime.offline = system.getTime() + 30

        print(string.format("SensorsOffline: %s valid: %s", countSensors, countSensorsValid))
        sensorsOnline   = -1

        if(enableAlarmMessage) then
            system.messageBox(string.format("ECU Offline - configured: %s valid: %s", countSensors, countSensorsValid), 3)
        end

        if(enableAlarmAudio) then
            system.playFile("/Apps/ecu/audio/Ecu converter offline.wav", AUDIO_QUEUE)
        end 

        if(enableAlarmHaptic) then
            system.vibration(false, 4);
        end
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
    BatteryConfig     = system.pLoad("BatteryConfig", "lipo-2s")
    TankSize          = system.pLoad("TankSize", 3500)
    audioOffSwitch    = system.pLoad("audioOffSwitch")
    hapticOffSwitch   = system.pLoad("hapticOffSwitch")
    messageOffSwitch  = system.pLoad("messageOffSwitch")

    -- read all the config files
    loadConfig()

    system.registerTelemetry(1, lang.window1, 2,window1.show)
    system.registerTelemetry(2, lang.window2, 2, window2.show)

    --system.registerTelemetry(2, lang.window1, 2, telemetry1.window)  
    --system.registerTelemetry(2, "Large", 4, window4.show)  - Full screen 

    resetAlarmTriggeredTime(10800) -- No alarms until 3 hours after turn on, or another reset event (like all sensors online)

    collectgarbage()
    print("Init finished: ", collectgarbage("count"))
end

----------------------------------------------------------------------
-- Loop has to be the last function, so every other function is initialized
local function loop()

    --fake.makeSensorValues()
    if(SensorID ~= 0) then
        enableAlarmAudio   = enableAlarmCheck(audioOffSwitch)
        enableAlarmHaptic  = enableAlarmCheck(hapticOffSwitch)
        enableAlarmMessage = enableAlarmCheck(messageOffSwitch)

        readParamsFromSensor(SensorID)

        -- All converters has these sensors
        processFuel(config.fuel, SensorID)
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

return {init=init, loop=loop, author="Thomas Ekdahl - thomas@ekdahl.no", version='2.4', name=lang.appName}