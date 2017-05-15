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

-- Globals to be accessible also from libraries
local config          = {"..."} -- Complete turbine config object dynamically assembled
--SensorT = {    -- Sensor objects is globally stored here and accessible by sensorname as configured in ecu converter

SensorT = {
    rpm      = {"..."},
    rpm2     = {"..."},
    egt      = {"..."},
    pumpv    = {"..."},
    ecuv     = {"..."},
    fuel     = {"..."},
    throttle = {"..."},
    status   = {"..."}
 }

-- Locals for the application
local enableAlarm                 = false
local prevStatusID, prevFuel = 0,0
local alarmOffSwitch

local lang              = {"..."} -- Language read from file

local alarmsTriggered   = {"..."} -- true on the alarm triggered, used to not repeat alarms to often

local alarmLowValuePassed = { -- enables alarms that has passed the low treshold, to not get alarms before turbine is running properly. Status alarms, high alarms, fuel alarms , and ecu voltage alarms is always enabled.
    rpm    = false,
    rpm2   = false,
    egt    = false,
    pumpv  = false,
    ecuv   = true,
    fuel   = true,
    status = true
}

local SensorID              = 0
local ConverterTypeTable    = {"..."}   -- Array with all available turbine types
local ConverterType         = "vspeak"  -- the turbine type chosen

local TurbineTypeTable      = {"..."}   -- Array with all available turbine types
local TurbineType           = "hornet"  -- the turbine type chosen

local TurbineConfigTable    = {"..."}   -- Array with all available config fields
local TurbineConfig         = "generic"  -- the turbine config file chosen

function fileJson(filename)
    local structure
    local file = io.readall(filename)

    if(file) then
        structure = json.decode(file)
        if(structure) then
            collectgarbage()
            print(string.format("fileJson: %s - mem %s ", filename, collectgarbage("count")))
            return structure
        else
            print(string.format("Invalid jsn format: %s", filename))
        end
    else
        print(string.format("File not found: %s", filename))
    end
end 

function fromDirectory(path, choice)
    local tmpTable = {"..."}
    local tmpIndex = 1

    for name, filetype, size in dir(path) do
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
    print(string.format("fromDirectory: %s - mem: %s", path, collectgarbage("count")))

    return tmpTable, tmpIndex
end

--------------------------------------------------------------------
-- Read all files in a folder and put it in a table to be used to create a menu
function fromFiles(path, choice)
    local tmpTable = {"..."}
    local tmpIndex = 1

    collectgarbage()
    print(string.format("fromFiles: %s - mem: %s", path, collectgarbage("count")))

    for name, filetype, size in dir(path) do
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

function getSensorParamTable(sensorID, sensorParam)
    local tmpSensorTable = {"..."}
    local tmpMenuTable   = {"..."}
    local tmpIndex       = 1
    local descr          = ""

    for index,sensor in ipairs(system.getSensors()) do 
        if(sensor.param == 0) then
            descr = sensor.label
        else
            tmpSensorTable[#tmpSensorTable+1] = sensor -- global sensor array
            tmpMenuTable[#tmpMenuTable+1]=string.format("%s - %s [%s]",descr,sensor.label,sensor.param) -- Menu table, added param for config purposes

            --print(string.format("SensorID: %s=%s, param: %s=%s", sensor.id, statusSensor1ID, sensor.param, tonumber(config.status.sensor.param)))
            if(sensor.id==sensorID and sensor.param==tonumber(sensorParam)) then
                tmpIndex=#tmpMenuTable
            end      
        end
    end
    collectgarbage()

    return tmpSensorTable, tmpMenuTable, tmpIndex
end

--------------------------------------------------------------------
-- Generates a sensor menu, returns sensor table and index choice for GUI generation
function getSensorTable(sensorID)
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
    --lcd.drawFilledRectangle (5+ox,y+oy,25,11*nFracBar) -- FIX THIS
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
function window(width, height)  
      -- field separator lines
      lcd.drawLine(45,2,45,66)  
      lcd.drawLine(45,36,148,36)  

        if(config.converter.sensormap.fuel and SensorT.fuel.percent) then
            DrawFuelGauge(SensorT.fuel.percent, 1, 0)
        end

      -- turbine
        if(config.converter.sensormap.status and SensorT.status.text) then
            DrawTurbineStatus(SensorT.status.text, 50, 0)
        else
            DrawTurbineStatus("UNCONFIGURED", 50, 0)
        end

      -- battery
      if(config.converter.sensormap.pumpv and SensorT.pumpv.sensor.value and SensorT.ecuv.sensor.value) then
          DrawBattery(SensorT.pumpv.sensor.value, SensorT.ecuv.sensor.value, 50, 37)
      end
end
local function loadConfig()
    -- Load main turbine config    
    config      = fileJson(string.format(string.format("Apps/ecu/turbine_16/%s/%s.jsn", TurbineType, TurbineConfig)))
    collectgarbage()

    -- Generic config loading adding to default turbine config
    config.converter = {"..."} 
    --config.ecuv      = loadh.fileJson(string.format("Apps/ecu/batterypack/%s_16.jsn", BatteryConfig))
    config.fuel = fileJson("Apps/ecu/fuel_16/config.jsn")
    config.converter.statusmap = fileJson(string.format("Apps/ecu/converter/%s/%s/status.jsn", ConverterType, TurbineType))
    config.converter.sensormap = fileJson(string.format("Apps/ecu/converter/%s/%s/sensor.jsn", ConverterType, TurbineType))
    collectgarbage()
end 

----------------------------------------------------------------------
--
local function ConverterTypeChanged(value)
    ConverterType  = ConverterTypeTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    print(string.format("ConverterTypeSave %s = %s", value, ConverterType))
    system.pSave("ConverterType",  ConverterType)
    TurbineTypeTable    = fromDirectory(string.format("Apps/ecu/converter/%s", ConverterType), nil)
end

----------------------------------------------------------------------
--
local function TurbineTypeChanged(value)
    TurbineType  = TurbineTypeTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("TurbineType", TurbineType)
    TurbineConfigTable  = fromFiles(string.format("Apps/ecu/turbine_16/%s", TurbineType), nil)
end

----------------------------------------------------------------------
--
local function TurbineConfigChanged(value)
    TurbineConfig  = TurbineConfigTable[value] --The value is local to this function and not global to script, hence it must be set explicitly.
    system.pSave("TurbineConfig", TurbineConfig)
    loadConfig() -- reload after config change
end

--------------------------------------------------------------------
-- Store settings when changed by user
local function SensorChanged(value)
	SensorID  = SensorT[value].id
	system.pSave("SensorID",  SensorID)
end

----------------------------------------------------------------------
--
local function initForm(subform)
    -- make all the dynamic menu items
    local ConverterTypeIndex, TurbineTypeIndex, TurbineConfigIndex, SensorIndex = 1,1,1,1,1
    local SensorMenuT = {"..."}
    SensorT, SensorMenuT, SensorMenuIndex = getSensorTable(SensorID)
    collectgarbage()

    ConverterTypeTable, ConverterTypeIndex  = fromDirectory("Apps/ecu/converter", ConverterType)
    TurbineTypeTable,   TurbineTypeIndex    = fromDirectory(string.format("Apps/ecu/converter/%s", ConverterType), TurbineType)
    TurbineConfigTable, TurbineConfigIndex  = fromFiles(string.format("Apps/ecu/turbine_16/%s", TurbineType), TurbineConfig)
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
    form.addLabel({label=lang.alarmOffSwitch, width=200})
    form.addInputbox(alarmOffSwitch,true, function(value) alarmOffSwitch=value; system.pSave("alarmOffSwitch",value) end ) 

    collectgarbage()
    print("Mem after GUI: ", collectgarbage("count"))
end


----------------------------------------------------------------------
-- Re-init correct form if navigation buttons are pressed
local function keyPressed(key)
    form.reinit(1)
end

local function calcPercent(current, high, low)
    local percent = ((current - low) / (high - low)) * 100
    if(percent < 0) then 
            percent = 0
    end
    return percent
end

local function initFuelStatistics(tmpCfg)

    -- print(string.format("fuel.value : %s",SensorT[tmpCfg.sensorname].sensor.value))

    if(config.fuel.tanksize < 50) then

        -- Init: Automatic calculations done on the first run after we read the sensor value.
        config.fuel.tanksize = SensorT[tmpCfg.sensorname].sensor.value -- new or max?
        config.fuel.interval = config.fuel.tanksize / 11 -- Calculate 10 fuel intervals for reporting announcing automatically of remaining tank
        prevFuel = config.fuel.tanksize - config.fuel.interval -- init full tank reporting, but do not start before next interval
    end 

    -- Calculate fuel percentage
    SensorT[tmpCfg.sensorname].percent = calcPercent(SensorT[tmpCfg.sensorname].sensor.value, config.fuel.tanksize, 0)
end

----------------------------------------------------------------------
--
local function processFueltank(tmpCfg, tmpSensorID)

    if(SensorT[tmpCfg.sensorname].sensor.valid) then

        initFuelStatistics(tmpCfg) -- Important

        -- We only enable the low alarms after they have passed the low threshold
        if(SensorT[tmpCfg.sensorname].sensor.value > tmpCfg.warning and not alarmLowValuePassed[tmpCfg.sensorname]) then
            alarmLowValuePassed[tmpCfg.sensorname] = true;
        end

        -- Repeat fuel level audio at intervals
        if(SensorT[tmpCfg.sensorname].sensor.value < prevFuel and alarmLowValuePassed[tmpCfg.sensorname]) then
            prevFuel = prevFuel - tmpCfg.interval -- Only work in intervals, should we calculate intervals from tanksize? 10 informations pr tank?    
            system.playNumber(prevFuel / 1000, tmpCfg.decimals, tmpCfg.unit, tmpCfg.label) -- Read out the numbers from the interval, not the value - to get better clearity
        end
        
        -- Check for alarm thresholds
        if(enableAlarm and alarmLowValuePassed[tmpCfg.sensorname]) then
            if(not alarmsTriggered[tmpCfg.sensorname]) then
                if(SensorT[tmpCfg.sensorname].percent < tmpCfg.critical) then

                    alarmsTriggered[tmpCfg.sensorname] = true
                    system.messageBox(string.format("%s (%s < %s)", 'fuel critical', SensorT[tmpCfg.sensorname].percent, tmpCfg.critical))
                    system.playFile("/Apps/ecu/audio/generic/fuel_critical.wav",AUDIO_IMMEDIATE)
            
                elseif(SensorT[tmpCfg.sensorname].percent < tmpCfg.warning) then

                    alarmsTriggered[tmpCfg.sensorname] = true
                    system.messageBox(string.format("%s (%s < %s)", 'fuel warning', SensorT[tmpCfg.sensorname].percent, tmpCfg.warning))
                    system.playFile("/Apps/ecu/audio/generic/fuel_warning.wav",AUDIO_IMMEDIATE)
                 end
            end
        end
    else
        SensorT[tmpCfg.sensorname].percent = 0
    end
end

----------------------------------------------------------------------
-- readGenericSensor high/low value alarms
-- ToDo: These alarms will be repeated to often, how to avoid that? Second counter, repeat counter?

local function processGeneric(tmpCfg, tmpSensorID)

    if(tmpCfg) then
        if(SensorT[tmpCfg.sensorname].sensor and SensorT[tmpCfg.sensorname].sensor.valid) then
            --print(string.format("sensorname : %s",tmpCfg.sensorname))
            --print(string.format("low  : %s",tmpCfg.low))

            -- We only enable the low alarms after they have passed the low threshold
            if(SensorT[tmpCfg.sensorname].sensor.value > tmpCfg.low and not alarmLowValuePassed[tmpCfg.sensorname]) then
                alarmLowValuePassed[tmpCfg.sensorname] = true;
            end

            -- calculate percentage
            SensorT[tmpCfg.sensorname].percent = calcPercent(SensorT[tmpCfg.sensorname].sensor.value, tmpCfg.high, tmpCfg.low)

            if(enableAlarm) then
                if(not alarmsTriggered[tmpCfg.sensorname]) then 
                    if(SensorT[tmpCfg.sensorname].sensor.value > tmpCfg.high) then
                        alarmsTriggered[tmpCfg.sensorname] = true
                        system.messageBox(string.format("%s high (%s > %s)", tmpCfg.sensorname, SensorT[tmpCfg.sensorname].sensor.value, tmpCfg.high), 5)
                        system.playFile(string.format("/Apps/ecu/audio/generic/%s_high.wav", tmpCfg.sensorname),AUDIO_IMMEDIATE)
                
                    elseif(SensorT[tmpCfg.sensorname].sensor.value < tmpCfg.low and alarmLowValuePassed[tmpCfg.sensorname]) then
                        alarmsTriggered[tmpCfg.sensorname] = true
                        system.messageBox(string.format("%s low (%s < %s)", tmpCfg.sensorname, SensorT[tmpCfg.sensorname].sensor.value, tmpCfg.low), 5)
                        system.playFile(string.format("/Apps/ecu/audio/generic/%s_low.wav", tmpCfg.sensorname),AUDIO_IMMEDIATE)
                    end
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- 
local function processStatus(tmpCfg, tmpSensorID)
    local statusint     = 0 -- sensor statusid
    local switch

    if(SensorT[tmpCfg.sensorname].sensor.valid) then
        statusint    = string.format("%s", math.floor(SensorT[tmpCfg.sensorname].sensor.value))
        SensorT[tmpCfg.sensorname].text  = config.converter.statusmap[statusint] -- convert converters integers to turbine manufacturers text status

        -------------------------------------------------------------_
        -- Check if status is changed since the last time
        if(prevStatusID ~= SensorT[tmpCfg.sensorname].text) then
            print(string.format("statusint #%s#", statusint))

            if(SensorT[tmpCfg.sensorname].text) then
                system.messageBox(SensorT[tmpCfg.sensorname].text, 5) -- we always show a message that will be logged on status changed
                print(string.format("/Apps/ecu/audio/%s/%s.wav", TurbineType, SensorT[tmpCfg.sensorname].text))
                system.playFile(string.format("/Apps/ecu/audio/%s/%s.wav", TurbineType, SensorT[tmpCfg.sensorname].text),AUDIO_IMMEDIATE)
            else
                system.messageBox(string.format("Unmapped status int: %s", statusint), 5) -- we always show a message that will be logged on status changed
            end
        end 
        prevStatusID = SensorT[tmpCfg.sensorname].text
        -------------------------------------------------------------
        -- If user has enabled alarms, the status has an alarm, the status has changed since last time - sound the alarm
        -- This should get rid of all annoying alarms
    else 
        SensorT[tmpCfg.sensorname].text = "OFFLINE"
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

                if(not SensorT[tmpSensorName].sensor.valid) then
                    -- The sensor exist, but is not valid yet.
                    SensorT[tmpSensorName].sensor.value = 0
                    SensorT[tmpSensorName].percent      = 0
                end
            else
                -- The sensor does not exist, ignore it. (not counting, no values)
            end
        else 
            -- Param is zero, so this sensor does not exist for this converter, we fake it with zero values.
            SensorT[tmpSensorName].sensor.value = 0
            SensorT[tmpSensorName].percent      = 0
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
    alarmOffSwitch    = system.pLoad("alarmOffSwitch")
    -- read all the config files
    loadConfig()
    system.registerTelemetry(1, string.format("%s", lang.window1),2,window)
    ctrlIdx = system.registerControl(1, "Turbine off switch","TurbOff")
    collectgarbage()
    print("Init finished: ", collectgarbage("count"))
end
----------------------------------------------------------------------
-- Loop has to be the last function, so every other function is initialized
local function loop()

    if(SensorID ~= 0) then
        resetAlarmCounter()
        enableAlarmCheck()
        readParamsFromSensor(SensorID) -- Real sensor values
        -- All converters has these sensors
        processFueltank(config.fuel, SensorID)
        processGeneric(config.rpm, SensorID)
        processGeneric(config.egt, SensorID)
        processGeneric(config.pumpv, SensorID)
        -- processGeneric(config.ecuv, SensorID) -- ecuv not supported on -16
        -- Check if converter has these sensor before processing them, since the availibility varies
        if(config.converter.sensormap.status) then
            processStatus(config.status, SensorID)
        end
    end
end
lang = fileJson(string.format("Apps/ecu/locale/%s.jsn", system.getLocale()))
return {init=init, loop=loop, author="Thomas Ekdahl - thomas@ekdahl.no", version='0.90', name=string.format("%s -16", lang.appName)}