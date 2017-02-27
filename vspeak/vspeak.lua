
-- ############################################################################# 
-- # Vspeak ECU Status converter - Lua application for JETI DC/DS transmitters
-- # Some Lua ideas copied from Jeti and TeroS
-- #
-- # Copyright (c) 2017, Original idea by Thomas Ekdahl (thomas@ekdahl.no) co-developed with Volker Weigt the maker of vspeak hardware.
-- # All rights reserved.
-- #
-- # License: Share alike                                       
-- # Can be used and changed non commercial, but feel free to send us changes back to be incorporated in the main code.
-- #                       
-- # V1.0 - Initial release
-- ############################################################################# 

-- Locals for the application
local statusSensor1ID,statusSensor1Pa=0,0
local Status1Text       = '';

local statusSensor2ID,statusSensor2Pa=0,0
local Status2Text        

local prevStatusID, enableAudio, enableAlarms = 0,0
local switchManualShutdown

local statusChanged  = false
local turbineRunning = false

local lang      -- read from file
local config    -- complete turbine config object read from file with manufacturer name

local sensorsAvailable  = {"..."}

local ECUTypeIn         = 1
local ECUTypeA = {
     [1] = 'pbs',
     [2] = 'jakadofsky',
     [3] = 'hornet',
     [4] = 'jetcat',
     [5] = 'evojet',
}

--------------------------------------------------------------------
-- Configure language settings
local function setLanguage()
  -- Set language
  local lng  = system.getLocale();
  local file = io.readall("Apps/vspeak/locale.jsn")
  local obj  = json.decode(file)  
  if(obj) then
    lang = obj[lng] or obj[obj.default]
  end
end

--------------------------------------------------------------------
-- Read complete turbine configuration, statuses, alarms, settings and thresholds
local function readConfig()
  local file = io.readall(string.format("Apps/vspeak/%s.jsn", ECUTypeA[ECUTypeIn])) -- read the correct config file
  print(string.format("Apps/vspeak/%s.jsn", ECUTypeA[ECUTypeIn]))
  local obj  = json.decode(file)
  if(obj) then
    config = obj
    print(string.format("statuscode: %s", config.statusrunning))
    print(string.format("statusrunning: %s", config.status[config.statusrunning].text))
    print(string.format("statuscode: %s", config.statusflameout))
    print(string.format("statusflameout: %s", config.status[config.statusflameout].text))
    print(string.format("tanksize: %s", config.tanksize))
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
local function enableAlarmsChanged(value)
    enableAlarms = not value;
    if(enableAlarms) then
        system.pSave("enableAlarms",  1)
    else 
        system.pSave("enableAlarms",  0)  
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
            list[#list+1]=string.format("%s - %s [%s]",descr,sensor.label,sensor.unit)
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
    form.addLabel({label="Enable audio status", width=200})
    form.addCheckbox(enableAudio, enableAudioChanged) 
    
    form.addRow(2)
    form.addLabel({label="Enable alarms", width=200})
    form.addCheckbox(enableAlarms, enableAlarmsChanged) 
    
    form.addRow(2)
    form.addLabel({label="Turbine off switch", width=200})
    form.addInputbox(switchManualShutdown,true, function(value) switchManualShutdown=value; system.pSave("switchManualShutdown",value) end ) 

end


----------------------------------------------------------------------
-- Re-init correct form if navigation buttons are pressed
local function keyPressed(key)
    form.reinit(1)
end

----------------------------------------------------------------------
-- 
local function readsensor(statusSensorID, statusSensorPa)
    local sensor
    local StatusText    = ''
    local value         = 0
    local switch


    if (statusSensorID > 0) then

        sensor = system.getSensorByID(statusSensorID, statusSensorPa)

        -- print(string.format("statusSensorID: %s, statusSensorPa: %s ", statusSensorID, statusSensorPa))
        if(sensor and sensor.valid) then
            value = string.format("%s", math.floor(sensor.value))
            StatusText = config.status[value].text;

            switch = system.getSwitchInfo(switchManualShutdown)
            -- print(string.format("switch: %s : %s", switch.label, switch.value))

            -------------------------------------------------------------_
            -- Check if status is changed since the last time
            if(prevStatusID ~= sensor.value) then
                statusChanged = true
            end 
            prevStatusID = sensor.value

            -------------------------------------------------------------_
            -- If turbine status has been running, all alarms are enabled until turned off by switch
            if(switch and switch.value < 0) then  -- turned off by switch
                turbineRunning = false
            elseif(config.statusrunning == value) then -- turn on when status is running only when switch is on
                turbineRunning = true
                system.messageBox(string.format("%s", StatusText), 5) -- Always announce turbine started successfully
            end

            -------------------------------------------------------------_
            -- If sensor value is negative we show status in messagebox on top of screen in 5 seconds.
            if(sensor.value < 0 and statusChanged) then
                system.messageBox(string.format("%s", StatusText), 5)
            end
            
            -------------------------------------------------------------
            -- If user has enabled alarms, the status has an alarm, the status has changed since last time and the status has been running - sound the alarm
            -- This should get rid of all annoying alarms
            if(enableAlarms and config.status[value].alarm and statusChanged and turbineRunning) then

                if(sensor.value > 0) then --To not get duplicates
                    system.messageBox(string.format("%s", StatusText), 5)
                end
            
                -- If vibration/haptic associated with status, we vibrate
                if(config.status[value].stick == 'left') then
                    system.vibration(false, config.status[value].haptic);
                end
                if(config.status[value].stick == 'right') then
                    system.vibration(true, config.status[value].haptic);
                end

                -- If audio file associated with status, we play it
                if(config.status[value].audio) then
                    system.playFile(string.format("/Apps/vspeak/audio/%s", config.status[value].audio),AUDIO_IMMEDIATE)
                end
            end

            -------------------------------------------------------------_
            -- Status has changed since last loop, announce it by audio
            if(enableAudio and statusChanged) then
                system.playFile(string.format("/Apps/vspeak/audio/%s", config.status[value].audio),AUDIO_IMMEDIATE)
                print(string.format("play: /Apps/vspeak/audio/%s", config.status[value].audio))
            end

            
        else 
            StatusText = "          -- "
        end

        -- print(string.format("statusSensorID: %s, text: %s ", statusSensorID, StatusText))
    end
    
    return StatusText 
end

----------------------------------------------------------------------
--
local function loop()
    Status1Text = readsensor(statusSensor1ID, statusSensor1Pa)
    Status2Text = readsensor(statusSensor2ID, statusSensor2Pa)
end

----------------------------------------------------------------------
--
local function VspeakStatusWindow1(width, height) 
    lcd.drawText(5,5,  string.format("%s", Status1Text), FONT_BIG)
end

----------------------------------------------------------------------
--
local function VspeakStatusWindow2(width, height) 
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
    enableAlarms     = system.pLoad("enableAlarms", 0)
    switchManualShutdown  = system.pLoad("switchManualShutdown")

    print(string.format("enableAudio: %s", enableAudio))
    print(string.format("enableAlarms: %s", enableAlarms))
    print(string.format("switchManualShutdown: %s", switchManualShutdown))

    if(statusSensor2ID > 0) then -- Then we have two turbines, and give the telemetry windows name left and right
        system.registerTelemetry(1,string.format("%s %s", lang.window, lang.left),1,VspeakStatusWindow1)
    	system.registerTelemetry(2,string.format("%s %s", lang.window, lang.right),1,VspeakStatusWindow2)
    else
    	system.registerTelemetry(1,string.format("%s", lang.window),1,VspeakStatusWindow1)
    end

     ctrlIdx = system.registerControl(1, "Turbine off switch","TurbOff")
    readConfig()
end

----------------------------------------------------------------------
--
setLanguage()
return {init=init, loop=loop, author="Thomas Ekdahl - thomas@ekdahl.no", version='0.9', name=lang.appName}