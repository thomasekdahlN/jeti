
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
-- # V1.5 - Initial release
-- ############################################################################# 

--Low RPM, Low pump V and Low temp alarms should not be enabled before after starting.

-- Locals for the application
local statusSensor1ID=0
local Status1Text       = '';

local statusSensor2ID=0
local Status2Text        

local prevStatusID, prevFuelLevel, enableAudio, enableAlarmCheckbox = 0,0,0,0
local switchManualShutdown

local enableSelectedAlarms, enableAllAlarms = false,false

local lang      -- read from file
local config    -- complete turbine config object read from file with manufacturer name

local sensorsAvailable  = {"..."}
local alarmsTriggered   = {"..."}
local sensorValues      = {
    ["rpmturbine"]  = 0,
    ["rpmshaft"]    = 0,
    ["temperature"] = 0,
    ["pumpvolt"]    = 0,
    ["ecuvolt"]     = 0,
    ["fuellevel"]   = 0,  -- in ml from ecu
    ["fuelpercent"] = 0,  -- calculated
    ["status"]      = 0,
} -- Sensor values is globally stored here in a hash by sensorname as configured

local ECUconfig = "jetcat.jsn"  -- the config file chosen
local ECUconfigA  = {"..."}     -- Array with all available config fiels

--------------------------------------------------------------------
-- Configure language settings
local function setLanguage()
  -- Set language
  local lng  = system.getLocale();
  local file = io.readall(string.format("Apps/ecu/locale/%s.jsn", lng))
  print(string.format(string.format("#Apps/ecu/locale/%s.jsn#", lng)))
  local obj  = json.decode(file)  
  if(obj) then
    lang = obj
  end
  collectgarbage()
end

--------------------------------------------------------------------
-- Read all config files an put it in a table to be shown in user interface
local function setConfigFileChoices()

    for name, filetype, size in dir("Apps/ecu/") do
        --print(name, filetype, size)
        if(filetype ~= 'folder') then
            table.insert(ECUconfigA, name)
        end
    end
end

--------------------------------------------------------------------
-- Read complete turbine configuration, statuses, alarms, settings and thresholds
local function readConfig()
    print("Mem before config: ", collectgarbage("count"))
    local file = io.readall(string.format("Apps/ecu/%s", ECUconfig)) -- read the correct config file
    print(string.format("Loading config: Apps/ecu/%s#", ECUconfig))
    if(file) then
        local obj  = json.decode(file)
        if(obj) then
          config = obj
          --print(string.format("EnableSelectedAlarmsAtStatus: %s", config.EnableSelectedAlarmsAtStatus))
          --print(string.format("EnableSelectedAlarmsAtStatus: %s", config.status[config.EnableSelectedAlarmsAtStatus].text))
          --print(string.format("EnableAllAlarmsAtStatus: %s", config.EnableAllAlarmsAtStatus))
          --print(string.format("EnableAllAlarmsAtStatus: %s", config.status[config.EnableAllAlarmsAtStatus].text))
          config.fuellevel.tanksize = 0 -- Just init variable, will be calculated automatically.
          -- for key,value in pairs(config.status) do print(key,value) end    
        end
    end
    collectgarbage()
    print("Mem after config: ", collectgarbage("count"))
end

----------------------------------------------------------------------
-- Store settings when changed by user
local function statusSensor1Changed(value)

	statusSensor1ID  = sensorsAvailable[value].id
	system.pSave("statusSensor1ID",  statusSensor1ID)
end

----------------------------------------------------------------------
--
local function statusSensor2Changed(value)

	statusSensor2ID  = sensorsAvailable[value].id
	system.pSave("statusSensor2ID",  statusSensor2ID)
end

----------------------------------------------------------------------
--
local function ECUconfigChanged(value)
    ECUconfig  = ECUconfigA[value] --The value is local to this function and not global to script, hence it must be set explicitly.
	system.pSave("ECUconfig",  ECUconfig)
	readConfig() -- reload statuses if they are changed
end

----------------------------------------------------------------------
--
local function enableAudioChanged(value)
    enableAudio = not value;
    if(enableAudio) then
        system.pSave("enableAudio",  1)
    else 
        system.pSave("enableAudio",  0)  
    end
end

----------------------------------------------------------------------
--
local function enableAlarmCheckboxChanged(value)
    enableAlarmCheckbox = not value;
    if(enableAlarmCheckbox) then
        system.pSave("enableAlarmCheckbox",  1)
    else 
        system.pSave("enableAlarmCheckbox",  0)  
    end
end

----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm(subform)

    -- saves memory to only init list in GUI mode
    sensorsAvailable = {}
    local available = system.getSensors();
    local list={}
    local curIndex1, curIndex2, curIndex3=-1,1,1
    local descr = ""
    for index,sensor in ipairs(available) do 
        if(sensor.param == 0) then
            descr = sensor.label
        else
            list[#list+1]=string.format("%s - %s [%s]",descr,sensor.label,sensor.param) -- added param for config purposes
            -- list[#list+1]=string.format("%s - %s [%s]",descr,sensor.label,sensor.unit) -- This is production

            sensorsAvailable[#sensorsAvailable+1] = sensor
            --print(string.format("SensorID: %s=%s, param: %s=%s", sensor.id, statusSensor1ID, sensor.param, tonumber(config.status.sensorparam)))
            if(sensor.id==statusSensor1ID and sensor.param==tonumber(config.status.sensorparam)) then
                curIndex1=#sensorsAvailable
            end
            if(sensor.id==statusSensor2ID and sensor.param==tonumber(config.status.sensorparam)) then
                curIndex2=#sensorsAvailable
            end
        end
    end

    for index, config in ipairs(ECUconfigA) do 
        if(config == ECUconfig) then
            curIndex3 = index
        end
    end
    collectgarbage()


    form.addRow(2)
    form.addLabel({label=lang.selectECU, width=200})
    form.addSelectbox(ECUconfigA, curIndex3, true, ECUconfigChanged)

    form.addRow(2)
    form.addLabel({label=lang.selectSensor1, width=200})
    form.addSelectbox(list, curIndex1, true, statusSensor1Changed)

    form.addRow(2)
    form.addLabel({label=lang.selectSensor2, width=200})
    form.addSelectbox(list, curIndex2, true, statusSensor2Changed)

    form.addRow(2)
    form.addLabel({label=lang.enableAudioStatus, width=200})
    form.addCheckbox(enableAudio, enableAudioChanged) 
    
    form.addRow(2)
    form.addLabel({label=lang.enableAlarms, width=200})
    form.addCheckbox(enableAlarmCheckbox, enableAlarmCheckboxChanged) 
    
    form.addRow(2)
    form.addLabel({label=lang.throttleKillSwitch, width=200})
    form.addInputbox(switchManualShutdown,true, function(value) switchManualShutdown=value; system.pSave("switchManualShutdown",value) end ) 

    collectgarbage()
    print("Mem after GUI: ", collectgarbage("count"))
end


----------------------------------------------------------------------
-- Re-init correct form if navigation buttons are pressed
local function keyPressed(key)
    form.reinit(1)
end

----------------------------------------------------------------------
-- 
local function AlarmMessage(messageconfig,StatusText)

    if(messageconfig.enable) then
        system.messageBox(string.format("%s", StatusText),messageconfig.seconds)
        print(string.format("messageBox: %s", StatusText))
    end    
end


----------------------------------------------------------------------
-- 
local function AlarmHaptic(hapticconfig)

    if(hapticconfig.enable) then
        -- If vibration/haptic associated with status, we vibrate
        if(hapticconfig.stick == 'left') then
            --print(string.format("Vibrate left %s",hapticconfig.vibrationProfile))
            system.vibration(false, hapticconfig.vibrationProfile);
        end
        if(hapticconfig.stick == 'right') then
            --print(string.format("Vibrate right %s",hapticconfig.vibrationProfile))
            system.vibration(true, hapticconfig.vibrationProfile);
        end
    end
end


----------------------------------------------------------------------
-- 
local function AlarmAudio(audioconfig)

    if(audioconfig.enable) then
        -- If audio file associated with status, we play it
        if(audioconfig.file) then
            print(string.format("/Apps/ecu/audio/%s", audioconfig.file))
            system.playFile(string.format("/Apps/ecu/audio/%s", audioconfig.file),AUDIO_IMMEDIATE)
        end
    end
end

----------------------------------------------------------------------
-- Calculates: config.fuellevel.tanksize and config.fuellevel.interval and fuelpercent
local function initFuelStatistics()

    if(config.fuellevel.tanksize < 100) then
        -- Automatic calculations done on the first run after we read the sensor value.
       
        config.fuellevel.tanksize = sensorValues[fuelconfig.sensorname]
        config.fuellevel.interval = config.fuellevel.tanksize / 10 -- Calculate 10 fuel intervals for reporting announcing automatically of remaining tank
        print(string.format("config.fuellevel.tanksize: %s", config.fuellevel.tanksize))
        print(string.format("config.fuellevel.interval: %s", config.fuellevel.interval))
        prevFuelLevel = config.fuellevel.tanksize - config.fuellevel.interval -- init full tank reporting, but do not start before next interval
    end 
    
    -- Calculate fuel percentage
    sensorValues['fuelpercent'] = (config.fuellevel.tanksize - sensorValues['fuellevel'])/(config.fuellevel.tanksize/100)
    if( sensorValues['fuelpercent'] > 99 ) then sensorValues['fuelpercent'] = 99 end
    if( sensorValues['fuelpercent'] < 0 ) then sensorValues['fuelpercent'] = 0 end
    
    --print(string.format("tanksize=%s, fuellevel=%s, fuelpercent: %s, ", config.fuellevel.tanksize, sensorValues['fuellevel'], sensorValues['fuelpercent']))
end

----------------------------------------------------------------------
--
local function readFueltankSensor(fuelconfig, statusSensorID)

    local sensor = system.getSensorByID(statusSensorID, tonumber(fuelconfig.sensorparam))

    if(sensor and sensor.valid) then

        sensorValues[fuelconfig.sensorname] = sensor.value
        initFuelStatistics() -- Important

        -- Repeat fuel level audio at intervals
        if(sensor.value < prevFuelLevel) then
            prevFuelLevel = prevFuelLevel - fuelconfig.interval -- Only work in intervals, should we calculate intervals from tanksize? 10 informations pr tank?    
            system.playNumber(sensor.value/1000, fuelconfig.decimals, fuelconfig.unit, fuelconfig.label) -- Read out the numbers (ml/1000)
        end
        
        -- Check for alarm thresholds
        if(sensorValues['fuelpercent'] < fuelconfig.critical.value) then
            alarmsTriggered[fuelconfig.sensorname] = true
            AlarmMessage(fuelconfig.critical.message,fuelconfig.critical.text)
            AlarmHaptic(fuelconfig.critical.haptic)
            AlarmAudio(fuelconfig.critical.audio)
            
        elseif(sensorValues['fuelpercent'] < fuelconfig.warning.value) then
            alarmsTriggered[fuelconfig.sensorname] = true
            AlarmMessage(fuelconfig.warning.message,fuelconfig.warning.text)
            AlarmHaptic(fuelconfig.warning.haptic)
            AlarmAudio(fuelconfig.warning.audio)
        end
        
    else
        print(string.format("FuelSensor not read"))
    end
end

----------------------------------------------------------------------
-- readGenericSensor high/low value alarms
-- ToDo: These alarms will be repeated to often, how to avoid that? Second counter, repeat counter?

local function readGenericSensor(genericConfig, statusSensorID)

    local sensor = system.getSensorByID(statusSensorID,tonumber(genericConfig.sensorparam))

    --print(string.format("param: %s, genericConfig.high.text: %s, genericConfig.low.text: %s ", genericConfig.sensorname, genericConfig.high.text, genericConfig.low.text))
    if(sensor and sensor.valid) then

        sensorValues[genericConfig.sensorname] = sensor.value -- could be the entire sensor object if needed.

        if(sensor.value > genericConfig.high.value and not alarmsTriggered[genericConfig.sensorname]) then
            alarmsTriggered[genericConfig.sensorname] = true
            AlarmMessage(genericConfig.high.message,genericConfig.high.text)
            AlarmHaptic(genericConfig.high.haptic)
            AlarmAudio(genericConfig.high.audio)
            
        elseif(sensor.value < genericConfig.low.value and enableAllAlarms and not alarmsTriggered[genericConfig.sensorname]) then
            alarmsTriggered[genericConfig.sensorname] = true
        
            --'rpmturbine, rpmshaft,temperature, pumpvolt', enableAllAlarms -- Only enable low alarms after turbine has properly started. Battery could be given before, but not a problem to be generic        
            --print(string.format("genericConfig.low.message.enable: %s", genericConfig.low.message.enable))
            AlarmMessage(genericConfig.low.message,genericConfig.low.text)
            AlarmHaptic(genericConfig.low.haptic)
            AlarmAudio(genericConfig.low.audio)
        end
    end
end


----------------------------------------------------------------------
-- 
local function readStatusSensor(statusconfig, statusSensorID)
    local StatusText    = ''
    local statusChanged = false
    local value         = 0 -- sensor value
    local switch
    local sensor = system.getSensorByID(statusSensorID, tonumber(statusconfig.sensorparam))

    if(sensor and sensor.valid) then
        value = string.format("%s", math.floor(sensor.value))
        sensorValues[statusconfig.sensorname] = value
        if(config.status[value] ~= nil) then 
            StatusText = config.status[value].text;
        end 
        switch = system.getSwitchInfo(switchManualShutdown)
        --print(string.format("StatusValue: %s", value))
        --print(string.format("StatusText: %s", StatusText))

        -------------------------------------------------------------_
        -- Check if status is changed since the last time
        if(prevStatusID ~= value) then
            statusChanged = true
        end 
        prevStatusID = value

        -------------------------------------------------------------_
        -- If configured turbine status has been reached, all alarms are enabled until turned off by throttle kill switch
        if(config.status.EnableSelectedAlarmsAtStatus == value) then -- turn on when status is running only when switch is on
            enableSelectedAlarms = true
            print(string.format("enableSelectedAlarms = true"))
        end
        
        if(config.status.EnableAllAlarmsAtStatus == value) then -- turn on when status is running only when switch is on
            enableAllAlarms = true
            print(string.format("enableAllAlarms = true"))
        end

        if(switch and switch.value < 0) then  -- turned off by switch, will always override status handling
            enableSelectedAlarms = false
            enableAllAlarms      = false
            print(string.format("enableSelectedAlarms = false"))
            print(string.format("enableAllAlarms = false"))
        end   
        -------------------------------------------------------------
        -- If user has enabled alarms, the status has an alarm, the status has changed since last time and the configured status code has been reached - sound the alarm
        -- This should get rid of all annoying alarms
        if(enableAlarmCheckbox and enableSelectedAlarms and statusChanged) then
            -- ToDo: Implement repeat of alarm
            -- STATUS alarms

            AlarmMessage(config.status[value].message,StatusText)
        
            AlarmHaptic(config.status[value].haptic)
        
            AlarmAudio(config.status[value].audio)
        end

    else 
        --print(string.format("StatusSensorNotFound: %s", value))
        StatusText = "          -- "
    end

    -- print(string.format("statusSensorID: %s, text: %s ", statusSensorID, StatusText))

    return StatusText 
end


----------------------------------------------------------------------
--
local function TelemetryStatusWindow1(width, height) 
    --lcd.drawText(5,5,  string.format("%s", Status1Text), FONT_BIG)
    local xcg1  = 5
    local xcg2  = tonumber((width / 2))
    local yc    = tonumber((height / 3) + 20)
    local diam  = tonumber((height / 2) - 10)
    
    print(string.format("width: %s, height: %s", width, height))

    -- lcd.drawText(5,5, string.format("Tanksize: %.1f%s",tonumber(config.fuellevel.tanksize/1000), "L"), FONT_BOLD)
    
    lcd.drawText(5,2, string.format("RPM"), FONT_NORMAL)
    lcd.drawCircle(xcg1,yc,diam)

    lcd.drawText(width/2,2, string.format("TEMP"), FONT_NORMAL)    
    lcd.drawCircle(xcg2,yc,diam)
    
    rpmgauge = lcd.loadImage("Apps/ecu/img/rpmgauge.png")
    tempgauge = lcd.loadImage("Apps/ecu/img/tempgauge.png")

    if(rpmgauge) then
        lcd.drawImage(xcg1, 18, rpmgauge)
    end

    if(tempgauge) then
        lcd.drawImage(xcg2, 18, tempgauge)
    end

    -- Calculate the x position of the needle in the gauge
    rpmpercent  = (sensorValues.rpmturbine)  / (config.rpmturbine.high.value  / 10000) -- to get fractional numbers
    temppercent = (sensorValues.temperature) / (config.temperature.high.value / 10000) -- to get fractional numbers

    rpmx    = xcg1 + (rpmgauge.width  * rpmpercent) 
    tempx   = xcg2 + (tempgauge.width * temppercent)
    -- Draw the lines for the gauge, or just reload with images with better quality gauges?
    lcd.drawLine(xcg1+(rpmgauge.width)/2,rpmgauge.height+5, rpmx,18)

    lcd.drawLine(xcg2+(tempgauge.width)/2,tempgauge.height+5, tempx,18)


    --os.exit()
end

----------------------------------------------------------------------
--
local function TelemetryStatusWindow2(width, height) 
    lcd.drawText(5,5, string.format("%s", Status2Text), FONT_BIG)
end

----------------------------------------------------------------------
local function DrawFuelGauge(percentage, ox, oy) 

    -- triangle
    lcd.drawLine(6+ox,5+oy,17+ox,5+oy)
    lcd.drawLine(17+ox,5+oy,17+ox,63+oy)
    lcd.drawLine(17+ox,63+oy,14+ox,63+oy)
    lcd.drawLine(14+ox,63+oy,6+ox,5+oy)
    
    -- gas station symbol
    lcd.drawRectangle(51+ox,31+oy,5,9)  
    lcd.drawLine(52+ox,34+oy,54+ox,34+oy)
    lcd.drawLine(50+ox,39+oy,56+ox,39+oy)
    lcd.drawLine(57+ox,31+oy,59+ox,33+oy)
    lcd.drawLine(59+ox,33+oy,59+ox,37+oy)
    lcd.drawPoint(58+ox,38+oy)  
    lcd.drawLine(57+ox,38+oy,57+ox,35+oy)  
    lcd.drawPoint(56+ox,35+oy)  
    lcd.drawText(51+ox,2+oy, "F", FONT_MINI)  
    lcd.drawText(51+ox,54+oy, "F", FONT_MINI)  
  
    -- fuel bar 
    lcd.drawRectangle (21+ox,53+oy,25,11)  -- lowest bar segment
    lcd.drawRectangle (21+ox,41+oy,25,11)  
    lcd.drawRectangle (21+ox,29+oy,25,11)  
    lcd.drawRectangle (21+ox,17+oy,25,11)  
    lcd.drawRectangle (21+ox,5+oy,25,11)   -- uppermost bar segment
    
    -- calc bar chart values
    local nSolidBar = math.floor( percentage / 20 )
    local nFracBar = (percentage - nSolidBar * 20) / 20  -- 0.0 ... 1.0 for fractional bar
    local i
    -- solid bars
    for i=0, nSolidBar - 1, 1 do 
      lcd.drawFilledRectangle (21+ox,53-i*12+oy,25,11) 
    end  
    --  fractional bar
    local y = math.floor( 53-nSolidBar*12+(1-nFracBar)*11 + 0.5)
    lcd.drawFilledRectangle (21+ox,y+oy,25,11*nFracBar) 

    lcd.drawText(4+ox,15+oy, config.fuellevel.tanksize, FONT_BOLD)
    --lcd.drawText(1+ox,49+oy, string.format("Fulltank: %.1f",tonumber(config.fuellevel.tanksize/1000)), FONT_BOLD)
end

----------------------------------------------------------------------
local function DrawTurbineStatus(status, ox, oy) 
    lcd.drawText(4+ox,2+oy, "Turbine", FONT_MINI)  
    lcd.drawText(4+ox,15+oy, status, FONT_BOLD)  
end


----------------------------------------------------------------------
local function DrawBattery(rpmturbine, u_ecu, ox, oy) 
  lcd.drawText(4+ox,1+oy, "RPM", FONT_MINI)  
  lcd.drawText(40+ox,1+oy, "ECU", FONT_MINI)  
  lcd.drawText(4+ox,12+oy, string.format("%s",tonumber(rpmturbine)), FONT_BOLD)
  lcd.drawText(40+ox,12+oy, string.format("%.1f%s",u_ecu,"V"), FONT_BOLD)
end

----------------------------------------------------------------------
local function DrawFuelLow(ox, oy) 

  if( system.getTime() % 2 == 0) then -- blink every second
    -- triangle
	lcd.drawLine(6+ox,47+oy,32+ox,3+oy)
	lcd.drawLine(32+ox,3+oy,60+ox,47+oy)
	lcd.drawLine(60+ox,47+oy,6+ox,47+oy)

	lcd.drawLine(7+ox,47+oy,33+ox,3+oy)
	lcd.drawLine(33+ox,3+oy,61+ox,47+oy)
	lcd.drawLine(61+ox,46+oy,6+ox,46+oy)

	lcd.drawLine(8+ox,47+oy,34+ox,3+oy)
	lcd.drawLine(34+ox,3+oy,62+ox,47+oy)
	lcd.drawLine(62+ox,46+oy,8+ox,46+oy)
	lcd.drawText(31+ox,10+oy, "!", FONT_BIG)  
  end  
  
  -- percentage and warning
  local percentX = 20
  if( sensorValues['fuelpercent'] < 10 ) then percentX = 23 end
  lcd.drawText(percentX+ox,28+oy, string.format("%d%s",sensorValues['fuelpercent'],"%"), FONT_BOLD)  
  lcd.drawText(1+ox,49+oy, "Fuel Low", FONT_BOLD)  
  
end

----------------------------------------------------------------------
-- Print the telemetry values
local function OnPrint(width, height) 
  -- field separator lines
  lcd.drawLine(70,2,70,66)  
  lcd.drawLine(70,36,148,36)  
  
  if( sensorValues.fuelpercent > config.fuellevel.warning.value) then
    DrawFuelGauge(sensorValues.fuelpercent, 1, 0)   
  else
    DrawFuelLow(sensorValues.fuelpercent, 1, 0) 
  end  

  -- turbine
  DrawTurbineStatus(Status1Text, 74, 0) 

  -- battery
  DrawBattery(sensorValues.rpmturbine, sensorValues.ecuvolt, 74, 37)
  
end

----------------------------------------------------------------------
-- Resets alarms so they will triggered again every 25 seconds
function resetAlarmCounter()
    if(system.getTime() % 30 == 0) then
        alarmsTriggered   = {  -- 
            ["rpmturbine"]  = false,
            ["rpmshaft"]    = false,
            ["temperature"] = false,
            ["pumpvolt"]    = false,
            ["ecuvolt"]     = false,
            ["fuellevel"]   = false,  -- in ml from ecu
            ["fuelpercent"] = false,  -- calculated
            ["status"]      = false,
        }    
    end
end

----------------------------------------------------------------------
-- Application initialization. Has to be the second last function so all other functions is initialized
local function init()

    resetAlarmCounter()

	system.registerForm(1,MENU_APPS,lang.appName, initForm, keyPressed)

    statusSensor1ID  = system.pLoad("statusSensor1ID", 0)
    statusSensor2ID  = system.pLoad("statusSensor2ID", 0)
    ECUconfig        = system.pLoad("ECUconfig", 1)
    enableAudio      = system.pLoad("enableAudio", 0)
    enableAlarmCheckbox   = system.pLoad("enableAlarmCheckbox", 0)
    switchManualShutdown  = system.pLoad("switchManualShutdown")

    --print(string.format("enableAudio: %s", enableAudio))
    --print(string.format("enableAlarmByStates: %s", enableAlarmByStates))
    --print(string.format("switchManualShutdown: %s", switchManualShutdown))

    if(statusSensor2ID > 0) then -- Then we have two turbines, and give the telemetry windows name left and right
        system.registerTelemetry(1,string.format("%s %s", lang.window1, lang.left),2,TelemetryStatusWindow1)
    	--system.registerTelemetry(2,string.format("%s %s", lang.window, lang.right),1,TelemetryStatusWindow2)
    else
    	system.registerTelemetry(1,string.format("%s", lang.window1),2,TelemetryStatusWindow1)
    end

    system.registerTelemetry( 2, lang.window2, 2, OnPrint)  

     ctrlIdx = system.registerControl(1, "Turbine off switch","TurbOff")
    readConfig()
    collectgarbage()
    print("Init finished: ", collectgarbage("count"))
end

----------------------------------------------------------------------
-- Loop has to be the last function, so every other function is initialized
local function loop()

    -- Turbine 1
    if(statusSensor1ID ~= 0) then
        Status1Text = readStatusSensor(config.status,statusSensor1ID)
        readFueltankSensor(config.fuellevel,statusSensor1ID)
        readGenericSensor(config.rpmturbine,statusSensor1ID)
        readGenericSensor(config.rpmshaft,statusSensor1ID)
        readGenericSensor(config.temperature,statusSensor1ID)
        readGenericSensor(config.pumpvolt,statusSensor1ID)
        readGenericSensor(config.ecuvolt,statusSensor1ID)
    end
    
    -- Print all sensor values
    --for key,value in pairs(sensorValues) do print(key,value) end
    
    -- Turbine 2
    if(statusSensor2ID ~= 0) then
        Status2Text = readStatusSensor(config.status,statusSensor2ID)
    end
    
    -- reset alarms
    resetAlarmCounter()
end

----------------------------------------------------------------------
--
setLanguage()
setConfigFileChoices()
return {init=init, loop=loop, author="Thomas Ekdahl - thomas@ekdahl.no", version='0.8', name=lang.appName}