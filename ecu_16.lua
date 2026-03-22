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
-- # 2.6 - Initial release
-- ############################################################################# 

local APP_ROOT = "Apps/ecu"
local logh = require "ecu/lib/loghelper"

logh.init("ECU-16")

local function newSensorEntry()
    return {
        sensor = {value = 0, max = 0, valid = false},
        percent = 0,
        text = nil
    }
end

local function newSensorTable()
    return {
        rpm = newSensorEntry(),
        rpm2 = newSensorEntry(),
        egt = newSensorEntry(),
        pumpv = newSensorEntry(),
        ecuv = newSensorEntry(),
        fuel = newSensorEntry(),
        status = newSensorEntry()
    }
end

local function newAlarmLowValuePassed()
    return {
        rpm = false,
        rpm2 = false,
        egt = false,
        pumpv = false,
        ecuv = true,
        fuel = false,
        status = true
    }
end

local function newAlarmTriggeredTime()
    return {
        rpm = 0,
        rpm2 = 0,
        egt = 0,
        pumpv = 0,
        ecuv = 0,
        fuel = 0,
        status = 0
    }
end

-- Runtime state shared across legacy functions.
local config = {} -- Complete turbine config object dynamically assembled
local SensorT = newSensorTable()

-- Locals for the application
local enableAlarm = false
local prevStatusID, prevFuelLevel, TankSize = 0,0,0
local alarmOffSwitch
local configValid = false

local lang              = {"..."} -- Language read from file

local alarmTriggeredTime = newAlarmTriggeredTime()
local alarmLowValuePassed = newAlarmLowValuePassed()

local SensorID              = 0
local ConverterTypeTable    = {"..."}   -- Array with all available turbine types
local ConverterType         = "vspeak"  -- the turbine type chosen

local TurbineTypeTable      = {"..."}   -- Array with all available turbine types
local TurbineType           = "hornet"  -- the turbine type chosen

local TurbineConfigTable    = {"..."}   -- Array with all available config fields
local TurbineConfig         = "generic"  -- the turbine config file chosen

local BatteryConfigTable    = {"..."}   -- Array with all available config fields
local BatteryConfig         = "life-2s"  -- the battery config file chosen
local SensorMenuSensors     = {"..."}

local function hasMapping(sensorName)
    return config
        and config.converter
        and config.converter.sensormap
        and tonumber(config.converter.sensormap[sensorName] or 0) > 0
end

local function resetMonitoringState()
    SensorT = newSensorTable()
    alarmTriggeredTime = newAlarmTriggeredTime()
    alarmLowValuePassed = newAlarmLowValuePassed()
    prevStatusID = 0
    prevFuelLevel = 0
    enableAlarm = false
end

local function validateConfig()
    local requiredConfig = {"converter", "fuel"}
    local mappedSensors = {"rpm", "rpm2", "egt", "pumpv", "ecuv", "fuel", "status"}

    if(not config or not next(config)) then
        logh.error("validateConfig", "ECU config missing", 3)
        return false
    end

    for _, configKey in ipairs(requiredConfig) do
        if(not config[configKey]) then
            logh.error("validateConfig", string.format("Missing config: %s", configKey), 3)
            return false
        end
    end

    if(not config.converter.sensormap) then
        logh.error("validateConfig", "Missing converter sensor map", 3)
        return false
    end

    for _, sensorName in ipairs(mappedSensors) do
        if(hasMapping(sensorName) and not config[sensorName]) then
            logh.error("validateConfig", string.format("Missing sensor config: %s", sensorName), 3)
            return false
        end
    end

    if(hasMapping("fuel") and not config.converter.fuel) then
        logh.error("validateConfig", "Missing converter fuel config", 3)
        return false
    end

    if(hasMapping("status") and not config.converter.statusmap) then
        logh.error("validateConfig", "Missing status config", 3)
        return false
    end

    return true
end

local function refreshTurbineConfigSelection()
    local TurbineConfigIndex
    local configPath

    if(type(TurbineType) ~= "string" or TurbineType == "") then
        logh.error("refreshTurbineConfigSelection", string.format("Invalid turbine type: %s", tostring(TurbineType)), 3)
        return
    end

    configPath = string.format("%s/turbine_16/%s", APP_ROOT, TurbineType)
    TurbineConfigTable, TurbineConfigIndex = fromFiles(configPath, TurbineConfig)
    TurbineConfig = TurbineConfigTable[TurbineConfigIndex] or TurbineConfigTable[1] or TurbineConfig
    system.pSave("TurbineConfig", TurbineConfig)
end

local function refreshTurbineSelections()
    local TurbineTypeIndex
    local converterPath

    if(type(ConverterType) ~= "string" or ConverterType == "") then
        logh.error("refreshTurbineSelections", string.format("Invalid converter type: %s", tostring(ConverterType)), 3)
        return
    end

    converterPath = string.format("%s/converter/%s", APP_ROOT, ConverterType)
    TurbineTypeTable, TurbineTypeIndex = fromDirectory(converterPath, TurbineType)
    TurbineType = TurbineTypeTable[TurbineTypeIndex] or TurbineTypeTable[1] or TurbineType
    system.pSave("TurbineType", TurbineType)

    refreshTurbineConfigSelection()
end

local function playAudioIfExists(fileName)
    local audioPath = string.format("/%s/audio/%s", APP_ROOT, fileName)
    local audioFile = io.open(audioPath, "r")

    if(audioFile) then
        audioFile:close()
        system.playFile(audioPath, AUDIO_IMMEDIATE)
    else
        logh.warn("playAudioIfExists", string.format("Missing audio file: %s", audioPath))
    end
end

local function fileJson(filename)
    local decodeOk
    local structure
    local file = io.readall(filename)

    if(not file) then
        logh.error("fileJson", string.format("File not found: %s", filename))
        return nil
    end

    decodeOk, structure = pcall(json.decode, file)
    if(not decodeOk) then
        logh.error("fileJson", string.format("JSON decode failed: %s (%s)", filename, structure))
        return nil
    end

    if(structure) then
        collectgarbage()
        return structure
    end

    logh.error("fileJson", string.format("Invalid jsn format: %s", filename))
    return nil
end 

local function fromDirectory(path, choice)
    local tmpTable = {"..."}
    local tmpIndex = 1
    local ok
    local iterator
    local state
    local control

    if(type(path) ~= "string" or path == "") then
        logh.error("fromDirectory", string.format("Invalid directory path: %s", tostring(path)))
        return tmpTable, tmpIndex
    end

    ok, iterator, state, control = pcall(dir, path)
    if(not ok) then
        logh.error("fromDirectory", string.format("Directory scan failed: %s (%s)", path, tostring(iterator)))
        return tmpTable, tmpIndex
    end

    if(not iterator) then
        logh.error("fromDirectory", string.format("Directory iterator missing: %s", path))
        return tmpTable, tmpIndex
    end

    for name, filetype, size in iterator, state, control do
        if(filetype == "folder" and string.sub(name, 1, 1) ~= ".") then
            table.insert(tmpTable, name)

            if (choice) then
                if(name == choice) then
                    tmpIndex=#tmpTable
                end
            end
        end
    end
    collectgarbage()

    return tmpTable, tmpIndex
end

--------------------------------------------------------------------
-- Read all files in a folder and put it in a table to be used to create a menu
local function fromFiles(path, choice)
    local tmpTable = {"..."}
    local tmpIndex = 1
    local ok
    local iterator
    local state
    local control

    collectgarbage()

    if(type(path) ~= "string" or path == "") then
        logh.error("fromFiles", string.format("Invalid file path: %s", tostring(path)))
        return tmpTable, tmpIndex
    end

    ok, iterator, state, control = pcall(dir, path)
    if(not ok) then
        logh.error("fromFiles", string.format("File scan failed: %s (%s)", path, tostring(iterator)))
        return tmpTable, tmpIndex
    end

    if(not iterator) then
        logh.error("fromFiles", string.format("File iterator missing: %s", path))
        return tmpTable, tmpIndex
    end

    for name, filetype, size in iterator, state, control do
        if(string.sub(name, -3, -1) == "jsn" and string.sub(name, 1, 1) ~= ".") then
            table.insert(tmpTable, string.sub(name, 1, -5))
            
            if (choice) then
                if(string.sub(name, 1, -5) == choice) then
                    tmpIndex=#tmpTable
                end
            end
        end
    end

    return tmpTable, tmpIndex
end

--------------------------------------------------------------------
-- Generates a sensor menu, returns sensor table and index choice for GUI generation
local function getSensorTable(sensorID)
    local tmpSensorTable = {"..."}
    local tmpMenuTable   = {"..."}
    local tmpIndex = 1

    for index,sensor in ipairs(system.getSensors()) do 
        if(sensor.param == 0) then

            tmpSensorTable[#tmpSensorTable+1] = sensor -- global sensor array
            tmpMenuTable[#tmpMenuTable+1]=string.format("%s",sensor.label) -- added param for config purposes

            if(sensor.id==sensorID) then
                tmpIndex=#tmpMenuTable
            end      
        end
    end
    collectgarbage()

    return tmpSensorTable, tmpMenuTable, tmpIndex
end

local function DrawFuelGauge(percentage, ox, oy) 
    
    -- gas station symbol
    lcd.drawRectangle(34+ox,31+oy,5,9)  
    lcd.drawLine(35+ox,34+oy,37+ox,34+oy)
    lcd.drawLine(33+ox,39+oy,39+ox,39+oy)
    lcd.drawLine(40+ox,31+oy,42+ox,33+oy)
    lcd.drawLine(42+ox,33+oy,42+ox,37+oy)
    lcd.drawPoint(40+ox,38+oy)  
    lcd.drawLine(40+ox,38+oy,40+ox,35+oy)  
    lcd.drawPoint(39+ox,35+oy)
    lcd.drawText(34+ox,2+oy, "F", FONT_MINI)  
    lcd.drawText(34+ox,54+oy, "E", FONT_MINI)  
  
    -- fuel bar 
    lcd.drawRectangle (5+ox,53+oy,25,11)  -- lowest bar segment
    lcd.drawRectangle (5+ox,41+oy,25,11)  
    lcd.drawRectangle (5+ox,29+oy,25,11)  
    lcd.drawRectangle (5+ox,17+oy,25,11)  
    lcd.drawRectangle (5+ox,5+oy,25,11)   -- uppermost bar segment
    
    -- calc bar chart values
    local nSolidBar = math.floor( percentage / 20 )
    local nFracBar = (percentage - nSolidBar * 20) / 20  -- 0.0 ... 1.0 for fractional bar
    local i
    -- solid bars
    for i=0, nSolidBar - 1, 1 do 
      lcd.drawFilledRectangle (5+ox,53-i*12+oy,25,11) 
    end  
    --  fractional bar
    local y = math.floor( 53-nSolidBar*12+(1-nFracBar)*11 + 0.5)
    lcd.drawFilledRectangle (5+ox,y+oy,25,11*nFracBar)
end
local function DrawTurbineStatus(status, ox, oy) 
    lcd.drawText(4+ox,2+oy, "Turbine", FONT_MINI)  
    lcd.drawText(4+ox,15+oy, status, FONT_BOLD)  
end
local function DrawBattery(u_pump, u_ecu, ox, oy) 
  lcd.drawText(4+ox,1+oy, "PUMP", FONT_MINI)  
  lcd.drawText(45+ox,1+oy, "ECU", FONT_MINI)  
  lcd.drawText(4+ox,12+oy,  string.format("%.1f%s",u_pump,"V"), FONT_BOLD)
  lcd.drawText(45+ox,12+oy, string.format("%.1f%s",u_ecu,"V"), FONT_BOLD)
end
local function window(width, height)  
    -- field separator lines
    lcd.drawLine(45,2,45,66)  
    lcd.drawLine(45,36,148,36)  

    if(SensorID ~= 0) then

        if(hasMapping("fuel")) then 
            if(SensorT.fuel.percent) then
                DrawFuelGauge(SensorT.fuel.percent, 1, 0)
            end
        end

        -- turbine
        if(hasMapping("status")) then
            if(SensorT.status.text) then
                DrawTurbineStatus(SensorT.status.text, 50, 0)
            else
                DrawTurbineStatus("UNKNOWN", 50, 0)
            end
        else
            DrawTurbineStatus("UNCONFIG", 50, 0)
        end

        -- battery
        if(hasMapping("pumpv") and hasMapping("ecuv") and SensorT.pumpv.sensor.value and SensorT.ecuv.sensor.value) then
            DrawBattery(SensorT.pumpv.sensor.value, SensorT.ecuv.sensor.value, 50, 37)
        end
    else
        DrawTurbineStatus("NO CONFIG", 50, 0)
    end
end

local function loadConfig()
    local selectionValues = {
        ConverterType = ConverterType,
        TurbineType = TurbineType,
        TurbineConfig = TurbineConfig,
        BatteryConfig = BatteryConfig
    }
    local currentConfig = fileJson(string.format("%s/turbine_16/%s/%s.jsn", APP_ROOT, TurbineType, TurbineConfig)) or {}
    collectgarbage()

    for selectionName, selectionValue in pairs(selectionValues) do
        if(type(selectionValue) ~= "string" or selectionValue == "") then
            logh.error("loadConfig", string.format("Invalid %s selection: %s", selectionName, tostring(selectionValue)), 3)
            config = {}
            resetMonitoringState()
            return false
        end
    end

    -- Generic config loading adding to default turbine config
    currentConfig.ecuv = fileJson(string.format("%s/batterypack_16/%s.jsn", APP_ROOT, BatteryConfig))
    currentConfig.fuel = fileJson(string.format("%s/fuel_16/config.jsn", APP_ROOT))
    currentConfig.status = fileJson(string.format("%s/status/%s.jsn", APP_ROOT, TurbineType))
    currentConfig.converter = fileJson(string.format("%s/converter/%s/%s/config.jsn", APP_ROOT, ConverterType, TurbineType))

    config = currentConfig
    resetMonitoringState()
    collectgarbage()

    return validateConfig()
end 

----------------------------------------------------------------------
-- Validate selectbox values before applying runtime changes.
local function getSelectionValue(options, value, scope, selectionName)
    local index = tonumber(value)
    local selection

    if(not index) then
        logh.error(scope, string.format("Invalid %s selection index: %s", selectionName, tostring(value)), 3)
        return nil
    end

    selection = options and options[index]
    if(not selection) then
        logh.error(scope, string.format("Missing %s selection for index: %s", selectionName, tostring(value)), 3)
        return nil
    end

    return selection
end

----------------------------------------------------------------------
-- Reload config and keep callback-time errors visible in the logger.
local function reloadConfig(scope)
    local ok
    local result

    ok, result = pcall(loadConfig)
    if(ok) then
        configValid = result
        return result
    end

    configValid = false
    logh.error(scope, string.format("Configuration reload failed: %s", tostring(result)), 3)
    return false
end

----------------------------------------------------------------------
-- Rebuild the form after menu changes that affect dependent selections.
local function reinitForm(scope)
    local ok
    local result

    ok, result = pcall(form.reinit, 1)
    if(not ok) then
        logh.error(scope, string.format("Form reinit failed: %s", tostring(result)), 3)
    end
end

----------------------------------------------------------------------
--
local function ConverterTypeChanged(value)
    local selection = getSelectionValue(ConverterTypeTable, value, "ConverterTypeChanged", "converter type")

    if(not selection) then
        return
    end

    ConverterType  = selection --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("ConverterType",  ConverterType)
    refreshTurbineSelections()
    reloadConfig("ConverterTypeChanged")
    reinitForm("ConverterTypeChanged")
end

----------------------------------------------------------------------
--
local function TurbineTypeChanged(value)
    local selection = getSelectionValue(TurbineTypeTable, value, "TurbineTypeChanged", "turbine type")

    if(not selection) then
        return
    end

    TurbineType  = selection --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("TurbineType", TurbineType)
    refreshTurbineConfigSelection()
    reloadConfig("TurbineTypeChanged")
    reinitForm("TurbineTypeChanged")
end

----------------------------------------------------------------------
--
local function TurbineConfigChanged(value)
    local selection = getSelectionValue(TurbineConfigTable, value, "TurbineConfigChanged", "turbine config")

    if(not selection) then
        return
    end

    TurbineConfig  = selection --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("TurbineConfig", TurbineConfig)
    reloadConfig("TurbineConfigChanged")
end

----------------------------------------------------------------------
--
local function BatteryConfigChanged(value)
    local selection = getSelectionValue(BatteryConfigTable, value, "BatteryConfigChanged", "battery config")

    if(not selection) then
        return
    end

    BatteryConfig  = selection --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("BatteryConfig", BatteryConfig)
    reloadConfig("BatteryConfigChanged")
end

--------------------------------------------------------------------
-- Store settings when changed by user
local function SensorChanged(value)
	if(SensorMenuSensors[value]) then
	    SensorID = SensorMenuSensors[value].id
	    system.pSave("SensorID", SensorID)
	    resetMonitoringState()
	else
	    logh.warn("SensorChanged", string.format("Missing sensor selection for index: %s", tostring(value)), 3)
	end
end

----------------------------------------------------------------------
--
local function initForm(subform)
    local ok
    local result

    ok, result = pcall(function()
        -- make all the dynamic menu items
        local ConverterTypeIndex, TurbineTypeIndex, TurbineConfigIndex, BatteryConfigIndex, SensorMenuIndex = 1,1,1,1,1
        local SensorMenuT = {"..."}
        SensorMenuSensors, SensorMenuT, SensorMenuIndex = getSensorTable(SensorID)
        collectgarbage()

        ConverterTypeTable, ConverterTypeIndex  = fromDirectory(string.format("%s/converter", APP_ROOT), ConverterType)
        TurbineTypeTable,   TurbineTypeIndex    = fromDirectory(string.format("%s/converter/%s", APP_ROOT, ConverterType), TurbineType)
        TurbineConfigTable, TurbineConfigIndex  = fromFiles(string.format("%s/turbine_16/%s", APP_ROOT, TurbineType), TurbineConfig)
        BatteryConfigTable, BatteryConfigIndex  = fromFiles(string.format("%s/batterypack_16", APP_ROOT), BatteryConfig)
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
        form.addLabel({label=lang.selectLeftTurbineSensor, width=200})
        form.addSelectbox(SensorMenuT, SensorMenuIndex, true, SensorChanged)

        form.addRow(2)
        form.addLabel({label=lang.selectBatteryConfig, width=200})
        form.addSelectbox(BatteryConfigTable, BatteryConfigIndex, true, BatteryConfigChanged)

        form.addRow(2)
        form.addLabel({label='Tank size', width=200})
        form.addIntbox(TankSize,0,10000,0,0,50,function(value) TankSize=value; system.pSave("TankSize",value) end )

        form.addRow(2)
        form.addLabel({label=lang.alarmOffSwitch, width=200})
        form.addInputbox(alarmOffSwitch,true, function(value) alarmOffSwitch=value; system.pSave("alarmOffSwitch",value) end ) 

        collectgarbage()
    end)

    if(not ok) then
        logh.error("initForm", string.format("Form build failed: %s", tostring(result)), 3)
    end
end


----------------------------------------------------------------------
-- Re-init correct form if navigation buttons are pressed
local function keyPressed(key)
    form.reinit(1)
end

local function calcPercent(current, high, low)
    local percent

    if(high == low) then
        return 0
    end

    percent = ((current - low) / (high - low)) * 100
    if(percent < 0) then 
        percent = 0
    elseif(percent > 100) then
        percent = 100
    end
    return percent
end

----------------------------------------------------------------------
-- Calculates: config.fuellevel.tanksize and config.fuellevel.interval and fuelpercent
local function initFuelStatistics(tmpCfg)

    -- We only enable the low alarms after they have passed the low threshold
    if(SensorT[tmpCfg.sensorname].sensor.value > tmpCfg.warning and not alarmLowValuePassed[tmpCfg.sensorname]) then
        alarmLowValuePassed[tmpCfg.sensorname] = true;
    end

    if(config.fuel.tanksize < 50 and alarmLowValuePassed[tmpCfg.sensorname]) then -- Configure TankSize during first 50 cycles
        if(config.converter.fuel.countingdown) then

            -- Init: Automatic calculations done on the first run after we read the sensor value.
            config.fuel.tanksize = SensorT[tmpCfg.sensorname].sensor.value -- new or max?
            TankSize             = config.fuel.tanksize 
            config.fuel.interval = config.fuel.tanksize / 10 -- Calculate 10 fuel intervals for reporting announcing automatically of remaining tank
            prevFuelLevel        = config.fuel.tanksize - config.fuel.interval -- init full tank reporting, but do not start before next interval
        else
            -- counting up, have to subtract
            config.fuel.tanksize = TankSize -- TankSize read from GUI not from ECU when counting up usage
            config.fuel.interval = config.fuel.tanksize / 10 -- Calculate 10 fuel intervals for reporting announcing automatically of remaining tank
            prevFuelLevel        = config.fuel.tanksize - config.fuel.interval -- init full tank reporting, but do not start before next interval
        end 
    end

    -- Calculate fuel percentage remaining
    if(config.fuel.tanksize > 50 and alarmLowValuePassed[tmpCfg.sensorname]) then
        if(config.converter.fuel.countingdown) then
            SensorT[tmpCfg.sensorname].percent = calcPercent(SensorT[tmpCfg.sensorname].sensor.value, config.fuel.tanksize, 0)
        else
            SensorT[tmpCfg.sensorname].percent = calcPercent(config.fuel.tanksize - SensorT[tmpCfg.sensorname].sensor.value, config.fuel.tanksize, 0)
        end
    else
        SensorT[tmpCfg.sensorname].percent = 0
    end
end

----------------------------------------------------------------------
--
local function processFuel(tmpCfg)
    local sensorEntry

    if(not tmpCfg) then
        logh.error("processFuel", "Missing fuel configuration", 3)
        return
    end

    sensorEntry = SensorT[tmpCfg.sensorname]
    if(not sensorEntry or not sensorEntry.sensor) then
        logh.error("processFuel", string.format("Missing sensor mapping: %s", tostring(tmpCfg.sensorname)), 3)
        return
    end

    if(sensorEntry.sensor.valid) then

        initFuelStatistics(tmpCfg) -- Important

        -- We only enable the low alarms after they have passed the low threshold
        if(sensorEntry.sensor.value > tmpCfg.warning and not alarmLowValuePassed[tmpCfg.sensorname]) then
            alarmLowValuePassed[tmpCfg.sensorname] = true;
        end

        -- Repeat fuel level audio at intervals
        if(sensorEntry.sensor.value < prevFuelLevel and alarmLowValuePassed[tmpCfg.sensorname]) then
            prevFuelLevel = prevFuelLevel - tmpCfg.interval -- Only work in intervals, should we calculate intervals from tanksize? 10 informations pr tank?    
            system.playNumber(prevFuelLevel / 1000, tmpCfg.decimals, tmpCfg.unit, tmpCfg.label) -- Read out the numbers from the interval, not the value - to get better clearity
        end
        
        -- Check for alarm thresholds
        if(enableAlarm and alarmLowValuePassed[tmpCfg.sensorname]) then
            if(alarmTriggeredTime[tmpCfg.sensorname] < system.getTime()) then
                if(sensorEntry.percent < tmpCfg.critical) then

                    alarmTriggeredTime[tmpCfg.sensorname] = system.getTime() + 20
                    system.messageBox(string.format("%s (%s < %s)", 'fuel critical', sensorEntry.percent, tmpCfg.critical))
                    playAudioIfExists("fuel_critical.wav")
            
                elseif(sensorEntry.percent < tmpCfg.warning) then

                    alarmTriggeredTime[tmpCfg.sensorname]  = system.getTime() + 15
                    system.messageBox(string.format("%s (%s < %s)", 'fuel warning', sensorEntry.percent, tmpCfg.warning))
                    playAudioIfExists("fuel_warning.wav")
                 end
            end
        end
    else
        sensorEntry.percent = 0
    end
end

----------------------------------------------------------------------
-- readGenericSensor high/low value alarms
-- ToDo: These alarms will be repeated to often, how to avoid that? Second counter, repeat counter?

local function processGeneric(tmpCfg)
    local sensorEntry

    if(not tmpCfg) then
        logh.error("processGeneric", "Missing sensor configuration", 3)
        return
    end

    sensorEntry = SensorT[tmpCfg.sensorname]
    if(not sensorEntry or not sensorEntry.sensor) then
        logh.error("processGeneric", string.format("Missing sensor mapping: %s", tostring(tmpCfg.sensorname)), 3)
        return
    end

    if(sensorEntry.sensor.valid) then
        --print(string.format("sensorname : %s",tmpCfg.sensorname))
        --print(string.format("low  : %s",tmpCfg.low))

        -- We only enable the low alarms after they have passed the low threshold
        if(sensorEntry.sensor.value > tmpCfg.low and not alarmLowValuePassed[tmpCfg.sensorname]) then
            alarmLowValuePassed[tmpCfg.sensorname] = true;
        end

        -- calculate percentage
        sensorEntry.percent = calcPercent(sensorEntry.sensor.value, tmpCfg.high, tmpCfg.low)

        if(enableAlarm) then
            if(alarmTriggeredTime[tmpCfg.sensorname] < system.getTime()) then 
                if(sensorEntry.sensor.value > tmpCfg.high) then
                    alarmTriggeredTime[tmpCfg.sensorname] = system.getTime() + 30
                    system.messageBox(string.format("%s high (%s > %s)", tmpCfg.sensorname, sensorEntry.sensor.value, tmpCfg.high), 5)
                    playAudioIfExists(string.format("%s_high.wav", tmpCfg.sensorname))
            
                elseif(sensorEntry.sensor.value < tmpCfg.low and alarmLowValuePassed[tmpCfg.sensorname]) then
                    alarmTriggeredTime[tmpCfg.sensorname] = system.getTime() + 30
                    system.messageBox(string.format("%s low (%s < %s)", tmpCfg.sensorname, sensorEntry.sensor.value, tmpCfg.low), 5)
                    playAudioIfExists(string.format("%s_low.wav", tmpCfg.sensorname))
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- 
local function processStatus(tmpCfg)
    local sensorEntry
    local statusText
    local statusConfig
    local statusint = 0 -- sensor statusid

    if(not tmpCfg) then
        logh.error("processStatus", "Missing status configuration", 3)
        return
    end

    sensorEntry = SensorT[tmpCfg.sensorname]
    if(not sensorEntry or not sensorEntry.sensor) then
        logh.error("processStatus", string.format("Missing sensor mapping: %s", tostring(tmpCfg.sensorname)), 3)
        return
    end

    if(sensorEntry.sensor.valid and config.converter and config.converter.statusmap) then
        statusint = string.format("%s", math.floor(sensorEntry.sensor.value))
        statusText = config.converter.statusmap[statusint]
        if(not statusText) then
            logh.warn("processStatus", string.format("Unknown status code: %s", statusint))
            statusText = string.format("Status %s", statusint)
        end

        sensorEntry.text = statusText

        if(prevStatusID ~= sensorEntry.text) then
            statusConfig = config.status and config.status[sensorEntry.text]
            if(not statusConfig) then
                logh.warn("processStatus", string.format("Missing status config: %s", sensorEntry.text))
            end

            system.messageBox(
                sensorEntry.text,
                statusConfig and statusConfig.message and statusConfig.message.seconds or 5
            )

            if(enableAlarm) then
                if(statusConfig and statusConfig.audio and statusConfig.audio.enable and statusConfig.audio.file) then
                    playAudioIfExists(statusConfig.audio.file)
                else
                    playAudioIfExists(string.format("%s.wav", sensorEntry.text))
                end
            end
        end

        prevStatusID = sensorEntry.text
    else
        sensorEntry.text = "OFFLINE"
    end
end

----------------------------------------------------------------------
-- Check if switch to enable alarms is set, sets global enableAlarm value
local function enableAlarmCheck()
    local switch

    if(not alarmOffSwitch) then
        enableAlarm = true
        return
    end

    switch = system.getSwitchInfo(alarmOffSwitch)
    if(switch) then
        if(switch.value < 0) then  -- turned off by switch, will always override status handling
            enableAlarm      = false
        else
            enableAlarm      = true
        end
    else
        enableAlarm      = true
    end
end

----------------------------------------------------------------------
-- Read and map all sensors to names instead of param values for easier processing
local function readParamsFromSensor(tmpSensorID)
    local sensorEntry

    for tmpSensorName, tmpSensorParam in pairs(config.converter.sensormap) do
        sensorEntry = SensorT[tmpSensorName] or newSensorEntry()
        SensorT[tmpSensorName] = sensorEntry

        if(tonumber(tmpSensorParam) > 0) then
            --print(string.format("rsensor: %s : %s : %s", tmpSensorID, tmpSensorName, tonumber(tmpSensorParam)))
            sensorEntry.sensor = system.getSensorByID(tmpSensorID, tonumber(tmpSensorParam))

            if(sensorEntry.sensor) then

                if(not sensorEntry.sensor.valid) then
                    -- The sensor exist, but is not valid yet.
                    sensorEntry.sensor.value = 0
                    sensorEntry.percent = 0
                end
            else
                -- The sensor does not exist, ignore it. (not counting, no values)
                sensorEntry.sensor = {value = 0, max = 0, valid = false}
                sensorEntry.percent = 0
            end
        else 
            -- Param is zero, so this sensor does not exist for this converter, we fake it with zero values.
            sensorEntry.sensor = sensorEntry.sensor or {value = 0, max = 0, valid = false}
            sensorEntry.sensor.value = 0
            sensorEntry.sensor.max = 0
            sensorEntry.sensor.valid = false
            sensorEntry.percent = 0
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
    TurbineType       = system.pLoad("TurbineType", "hornet")
    TurbineConfig     = system.pLoad("TurbineConfig", "generic")
    BatteryConfig     = system.pLoad("BatteryConfig", 'lipo-2s')
    TankSize          = system.pLoad("TankSize", 0)
    alarmOffSwitch    = system.pLoad("alarmOffSwitch")
    refreshTurbineSelections()
    -- read all the config files
    configValid = loadConfig()
    system.registerTelemetry(1, string.format("%s - 16", lang.window1),2,window)
    system.registerControl(1, "Turbine off switch","TurbOff")
    collectgarbage()
end
----------------------------------------------------------------------
-- Loop has to be the last function, so every other function is initialized
local function loop()

    if(SensorID ~= 0 and configValid) then
        enableAlarmCheck()
        readParamsFromSensor(SensorID) -- Real sensor values
        -- All converters has these sensors
        if(hasMapping("fuel")) then
            processFuel(config.fuel)
        end
        if(hasMapping("rpm")) then
            processGeneric(config.rpm)
        end
        if(hasMapping("rpm2")) then
            processGeneric(config.rpm2)
        end
        if(hasMapping("egt")) then
            processGeneric(config.egt)
        end
        if(hasMapping("pumpv")) then
            processGeneric(config.pumpv)
        end
        if(hasMapping("ecuv")) then
            processGeneric(config.ecuv)
        end
        -- Check if converter has these sensor before processing them, since the availibility varies
        if(hasMapping("status")) then
            processStatus(config.status)
        end
    end
end
lang = fileJson(string.format("%s/locale/%s.jsn", APP_ROOT, system.getLocale()))
    or fileJson(string.format("%s/locale/en.jsn", APP_ROOT))
    or {appName = "ECU", window1 = "ECU"}
return {init=init, loop=loop, author="Thomas Ekdahl - thomas@ekdahl.no", version='1.0', name=string.format("%s -16", lang.appName)}