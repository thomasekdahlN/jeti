
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

-- Locals for the application
local statusSensor1ID,statusSensor1Pa=0,0
local Status1Text       = '';

local statusSensor2ID,statusSensor2Pa=0,0
local Status2Text        

local prevStatusID, prevFuelLevel, enableAudio, enableAlarmCheckbox = 0,0,0,0
local switchManualShutdown

local statusChanged        = false
local enableAlarmByState   = false

local lang      -- read from file
local config    -- complete turbine config object read from file with manufacturer name

local sensorsAvailable  = {"..."}
local sensorValues      = {"..."} -- Sensor values is globally stored here in a hash by sensorname as configured

local ECUTypeIn         = 1

-- IDEA - read all config files dunamically from folder would make it even more flexible
local ECUTypeA = {
     [1] = 'pbs',
     [2] = 'jakadofsky',
     [3] = 'hornet',
     [4] = 'jetcat',
     [5] = 'evojet',
     [6] = 'orbit',
}

--------------------------------------------------------------------
-- Configure language settings
local function setLanguage()
  -- Set language
  local lng  = system.getLocale();
  local file = io.readall("Apps/ecu/locale.jsn")
  print(string.format("Apps/ecu/locale.jsn"))
  local obj  = json.decode(file)  
  if(obj) then
    lang = obj[lng] or obj[obj.default]
  end
end

--------------------------------------------------------------------
-- Read complete turbine configuration, statuses, alarms, settings and thresholds
local function readConfig()
  local file = io.readall(string.format("Apps/ecu/%s.jsn", ECUTypeA[ECUTypeIn])) -- read the correct config file
  print(string.format("Apps/ecu/%s.jsn", ECUTypeA[ECUTypeIn]))
  local obj  = json.decode(file)
  if(obj) then
    config = obj
    print(string.format("statusCodeEnableAlarm: %s", config.statusCodeEnableAlarm))
    print(string.format("statusCodeEnableAlarmText: %s", config.status[config.statusCodeEnableAlarm].text))
    print(string.format("fueltanksize: %s", config.fuellevel.tanksize))
    -- for key,value in pairs(config.status) do print(key,value) end
    
    prevFuelLevel = config.fuellevel.tanksize -- init full tank

  end
end

----------------------------------------------------------------------
-- Store settings when changed by user
local function statusSensor1Changed(value)

	statusSensor1ID  = sensorsAvailable[value].id
	statusSensor1Pa  = sensorsAvailable[value].param
	
	system.pSave("statusSensor1ID",  statusSensor1ID)
	system.pSave("statusSensor1Pa",  statusSensor1Pa)
end

----------------------------------------------------------------------
--
local function statusSensor2Changed(value)

	statusSensor2ID  = sensorsAvailable[value].id
	statusSensor2Pa  = sensorsAvailable[value].param

	system.pSave("statusSensor2ID",  statusSensor2ID)
	system.pSave("statusSensor2Pa",  statusSensor2Pa)
end

----------------------------------------------------------------------
--
local function ECUTypeChanged(value)
    ECUTypeIn  = value --The value is local to this function and not global to script, hence it must be set explicitly.
	system.pSave("ECUTypeIn",  ECUTypeIn)
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
    local curIndex1, curIndex2=-1,-1
    local descr = ""
    for index,sensor in ipairs(available) do 
        if(sensor.param == 0) then
            descr = sensor.label
        else
            list[#list+1]=string.format("%s - %s [%s]",descr,sensor.label,sensor.param) -- added param for debug purposes
            -- list[#list+1]=string.format("%s - %s [%s]",descr,sensor.label,sensor.unit) -- This is production

            sensorsAvailable[#sensorsAvailable+1] = sensor
            if(sensor.id==statusSensor1ID and sensor.param==statusSensor1Pa) then
                curIndex1=#sensorsAvailable
            end
            if(sensor.id==statusSensor2ID and sensor.param==statusSensor2Pa) then
                curIndex2=#sensorsAvailable
            end
        end
    end

    form.addRow(2)
    form.addLabel({label=lang.selectECU, width=200})
    form.addSelectbox(ECUTypeA, ECUTypeIn, true, ECUTypeChanged)

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

end


----------------------------------------------------------------------
-- Re-init correct form if navigation buttons are pressed
local function keyPressed(key)
    form.reinit(1)
end

----------------------------------------------------------------------
-- 
local function readStatusSensor(statusconfig, statusSensorID)
    local StatusText    = ''
    local value         = 0 -- sensor value
    local switch
    local sensor = system.getSensorByID(statusSensorID, statusconfig.sensorparam)

    if(sensor and sensor.valid) then
        value = string.format("%s", math.floor(sensor.value))
        sensorValues[statusconfig.sensorname] = value
        StatusText = config.status[value].text;

        switch = system.getSwitchInfo(switchManualShutdown)
        -- print(string.format("switch: %s : %s", switch.label, switch.value))

        -------------------------------------------------------------_
        -- Check if status is changed since the last time
        if(prevStatusID ~= value) then
            statusChanged = true
        end 
        prevStatusID = value

        -------------------------------------------------------------_
        -- If configured turbine status has been reached, all alarms are enabled until turned off by throttle kill switch
        if(switch and switch.value < 0) then  -- turned off by switch
            enableAlarmByState = false
            print(string.format("enableAlarmByState = false"))
        elseif(config.statuscode.statusCodeEnableAlarm == value) then -- turn on when status is running only when switch is on
            enableAlarmByState = true
            print(string.format("enableAlarmByState = true"))
        end
    
        -------------------------------------------------------------
        -- If user has enabled alarms, the status has an alarm, the status has changed since last time and the configured status code has been reached - sound the alarm
        -- This should get rid of all annoying alarms
        if(enableAlarmCheckbox and enableAlarmByState and statusChanged) then
            -- ToDo: Implement repeat of alarm
            -- STATUS alarms

            AlarmMessage(config.status[value].message, StatusText)
        
            AlarmHaptic(config.status[value].haptic)
        
            AlarmAudio(config.status[value].audio)
        end

    else 
        StatusText = "          -- "
    end

    -- print(string.format("statusSensorID: %s, text: %s ", statusSensorID, StatusText))

    return StatusText 
end


----------------------------------------------------------------------
-- readGenericSensor high/low value alarms
-- ToDo: These alarms will be repeated to often, how to avoid that? Second counter, repeat counter?

local function readGenericSensor(genericConfig, statusSensorID)

    local sensor = system.getSensorByID(statusSensorID, genericConfig.sensorparam)

    -- print(string.format("statusSensorID: %s, statusSensorPa: %s ", statusSensorID, statusSensorPa))
    if(sensor and sensor.valid) then

        sensorValues[genericConfig.sensorname] = sensor.value -- could be the entire sensor object if needed.

        if(sensor.value > genericConfig.high.value) then
            AlarmMessage(genericConfig.message, genericConfig.high.text)
            AlarmHaptic(genericConfig.haptic)
            AlarmAudio(genericConfig.audio)
            
        elseif(sensor.value < genericConfig.low.value) then
            AlarmMessage(genericConfig.message, genericConfig.low.text)
            AlarmHaptic(genericConfig.haptic)
            AlarmAudio(genericConfig.audio)
        end
    end
end


----------------------------------------------------------------------
-- 
local function AlarmMessage(messageconfig, StatusText)

    if(messageconfig.enable) then
        system.messageBox(string.format("%s", StatusText), messageconfig.seconds)
        print(string.format("messageBox: %s", StatusText))
    end    
end


----------------------------------------------------------------------
-- 
local function AlarmHaptic(hapticconfig)

    if(hapticconfig.enable) then
        -- If vibration/haptic associated with status, we vibrate
        if(hapticconfig.stick == 'left') then
            print(string.format("Vibrate left %s", hapticconfig.vibrationProfile))
            system.vibration(false, hapticconfig.vibrationProfile);
        end
        if(hapticconfig.stick == 'right') then
            print(string.format("Vibrate right %s", hapticconfig.vibrationProfile))
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
--
local function readFueltankSensor(fuelconfig, statusSensorID)

    local sensor = system.getSensorByID(statusSensorID, fuelconfig.sensorparam)

    -- print(string.format("readFueltankSensor: statusSensorID: %s, statusSensorPa: %s ", statusSensorID, statusSensorPa))
    if(sensor and sensor.valid) then

        sensorValues[genericConfig.sensorname] = sensor.value

        -- Repeat at intervals from config
        if(fuelconfig.enable and sensor.value < prevFuelLevel) then
            -- If audio file associated with status, we play it
            prevFuelLevel = prevFuelLevel - fuelconfig.interval -- Only work in intervals
            
            if(sensor.value < fuelconfig.critical.value) then
                AlarmMessage(fuelconfig.message, fuelconfig.critical.text)
                AlarmHaptic(fuelconfig.haptic)
                AlarmAudio(fuelconfig.audio)
            elseif(sensor.value < fuelconfig.warning.value) then
                AlarmMessage(fuelconfig.message, fuelconfig.warning.text)
                AlarmHaptic(fuelconfig.haptic)
                AlarmAudio(fuelconfig.audio)
            elseif(sensor.value < fuelconfig.info.value) then
                AlarmMessage(fuelconfig.message, fuelconfig.info.text)
                AlarmHaptic(fuelconfig.haptic)
                AlarmAudio(fuelconfig.audio)
            end
            
            system.playNumber(sensorvalue, fuelconfig.decimals, fuelconfig.unit, fuelconfig.label) -- Read out the numbers
        end
    end
end

----------------------------------------------------------------------
--
local function loop()

    -- Turbine 1
    if(statusSensor1ID > 1) then
        Status1Text = readStatusSensor(config.status, statusSensor1ID)
        if(enableAlarmCheckbox and enableAlarmByState) then
            readFueltankSensor(config.fuellevel, statusSensor1ID)
            readGenericSensor(config.rpmturbine, statusSensor1ID)
            readGenericSensor(config.rpmshaft, statusSensor1ID)
            readGenericSensor(config.temperature, statusSensor1ID)
            readGenericSensor(config.pumpvolt, statusSensor1ID)
            readGenericSensor(config.ecuvolt, statusSensor1ID)
        end
    end
    -- Turbine 2
    if(statusSensor2ID > 1) then
        Status2Text = readStatusSensor(statusSensor2ID, statusSensor2Pa)
    end
end

----------------------------------------------------------------------
--
local function TelemetryStatusWindow1(width, height) 
    lcd.drawText(5,5,  string.format("%s", Status1Text), FONT_BIG)
end

----------------------------------------------------------------------
--
local function TelemetryStatusWindow2(width, height) 
    lcd.drawText(5,5, string.format("%s", Status2Text), FONT_BIG)
end

----------------------------------------------------------------------
-- Application initialization
local function init()

	system.registerForm(1,MENU_APPS,lang.appName, initForm, keyPressed)

    statusSensor1ID  = system.pLoad("statusSensor1ID", 0)
    statusSensor1Pa  = system.pLoad("statusSensor1Pa", 0)
    statusSensor2ID  = system.pLoad("statusSensor2ID", 0)
    statusSensor2Pa  = system.pLoad("statusSensor2Pa", 0)
    ECUTypeIn        = system.pLoad("ECUTypeIn", 1)
    enableAudio      = system.pLoad("enableAudio", 0)
    enableAlarmCheckbox   = system.pLoad("enableAlarmCheckbox", 0)
    switchManualShutdown  = system.pLoad("switchManualShutdown")

    print(string.format("enableAudio: %s", enableAudio))
    print(string.format("enableAlarmByStates: %s", enableAlarmByStates))
    print(string.format("switchManualShutdown: %s", switchManualShutdown))

    if(statusSensor2ID > 0) then -- Then we have two turbines, and give the telemetry windows name left and right
        system.registerTelemetry(1,string.format("%s %s", lang.window, lang.left),1,TelemetryStatusWindow1)
    	--system.registerTelemetry(2,string.format("%s %s", lang.window, lang.right),1,TelemetryStatusWindow2)
    else
    	system.registerTelemetry(1,string.format("%s", lang.window),1,TelemetryStatusWindow1)
    end

    system.registerTelemetry( 2, "Fuel/ECU/Voltage", 2, OnPrint)  

     ctrlIdx = system.registerControl(1, "Turbine off switch","TurbOff")
    readConfig()
end


local function DrawFuelGauge(percentage, ox, oy) 

    print(string.format("DrawFuelGauge: percentage:%s", percentage))

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

  -- numerical percentage display
  -- if( percentage <= 80 ) then 
  --   lcd.drawText(23+ox,4+oy, string.format("%d%s",percentage,"%"), FONT_MINI)  
  -- end	
end

local function DrawTurbineStatus(status, rpm, ox, oy) 

    print(string.format("DrawTurbineStatus: status:%s Status1Text: %s", status, rpm))

    lcd.drawText(4+ox,2+oy, "Turbine", FONT_MINI)  
  
    if (status ~= 2 ) then
      lcd.drawText(4+ox,15+oy, Status1Text, FONT_BOLD)  
    --else
      --lcd.drawText(4+ox,15+oy, string.format("%.1f",rpm), FONT_BOLD)  
      --lcd.drawText(35+ox,19+oy, "T/min", FONT_MINI)  
    end	  
end

local function DrawBattery(u_rc, u_ecu, ox, oy) 

    print(string.format("DrawBattery: u_rc:%s u_ecu: %s", u_rc, u_ecu))

  lcd.drawText(4+ox,1+oy, "RC", FONT_MINI)  
  lcd.drawText(40+ox,1+oy, "ECU", FONT_MINI)  
  lcd.drawText(4+ox,12+oy, string.format("%.1f%s",u_rc,"V"), FONT_BOLD)  
  lcd.drawText(40+ox,12+oy, string.format("%.1f%s",u_ecu,"V"), FONT_BOLD)  
end

local function DrawFuelLow(fuelPercentage, ox, oy) 

    print(string.format("DrawFuelLow: fuelPercentage: %s ", fuelPercentage))


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
  if( fuelPercentage < 10 ) then percentX = 23 end
  lcd.drawText(percentX+ox,28+oy, string.format("%d%s",fuelPercentage,"%"), FONT_BOLD)  
  lcd.drawText(1+ox,49+oy, "Fuel Low", FONT_BOLD)  
  
end

-- Print the telemetry values
local function OnPrint(width, height) 

  print(string.format("OnPrint"))

  -- field separator lines
  lcd.drawLine(70,2,70,66)  
  lcd.drawLine(70,36,148,36)  
 
  -- fuel - 1700 (=tankSize) ml is 0%
  local fuelPercentage = (config.fuellevel.tanksize - fuel )/(config.fuellevel.tanksize/100)
  if( fuelPercentage > 99 ) then fuelPercentage = 99 end
  if( fuelPercentage < 0 ) then fuelPercentage = 0 end
  
  print(string.format("fuelPercentage: %s, rpm: %s ", fuelPercentage, sensorValues.turbinerpm))
  
  if( fuelPercentage > warningPercent or initAnimation ) then
    DrawFuelGauge(fuelPercentage, 1, 0)   
  else
    DrawFuelLow(fuelPercentage, 1, 0) 
  end  

  -- turbine
  DrawTurbineStatus(Status1Text, sensorValues.turbinerpm, 74, 0) 

  -- battery
  DrawBattery(nil, sensorValues.ecuvolt, 74, 37) 
  
end


----------------------------------------------------------------------
--
setLanguage()
return {init=init, loop=loop, author="Thomas Ekdahl - thomas@ekdahl.no", version='1.5', name=lang.appName}