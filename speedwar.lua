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
-- # Version: 2.2
-- ############################################################################# 

local OffSwitch             = 0
local sensorsAvailable      = {"..."}
local SensorID              = 0
local SensorParam           = 0

local OverSpeedI;      
local MinimumSafeSpeedI;
local TakeOffSpeedI;
local StallSpeedI;

local alarmTriggeredTime   = { -- stores latest datetime on the alarm triggered, used to not repeat alarms to often
    over    = 0,
    minimum = 0,
    takeoff = 0,
    stall   = 0,
}

local tresholdPassed = { -- enables alarms that has passed the low treshold, to not get alarms before turbine is running properly. Status alarms, high alarms, fuel alarms , and ecu voltage alarms is always enabled.
    over     = true,
    minimum  = false,
    takeoff  = true,
    stall    = false,
}

local function OverSpeedHapticChanged(value) 
    OverSpeedHaptic=not value 
    form.setValue(OverSpeedI,OverSpeedHaptic)

    if(OverSpeedHaptic) then
        system.pSave("OverSpeedHaptic", 1)
        else
        system.pSave("OverSpeedHaptic", 0)
    end
end

local function StallSpeedChanged(value) 
    StallSpeedHaptic=not value 
    form.setValue(OverSpeedI,StallSpeedHaptic)

    if(OverSpeedHaptic) then
        system.pSave("StallSpeedHaptic", 1)
        else
        system.pSave("StallSpeedHaptic", 0)
    end
end

local function MinimumSafeSpeedHapticChanged(value) 
    MinimumSafeSpeedHaptic=not value 
    form.setValue(OverSpeedI,MinimumSafeSpeedHaptic)

    if(MinimumSafeSpeedHaptic) then
        system.pSave("MinimumSafeSpeedHaptic", 1)
        else
        system.pSave("MinimumSafeSpeedHaptic", 0)
    end
end

local function TakeOffSpeedHapticChanged(value) 
    TakeOffSpeedHaptic=not value 
    form.setValue(OverSpeedI,TakeOffSpeedHaptic)

    if(TakeOffSpeedHaptic) then
        system.pSave("TakeOffSpeedHaptic", 1)
        else
        system.pSave("TakeOffSpeedHaptic", 0)
    end
end

--------------------------------------------------------------------
-- Store settings when changed by user
local function sensorChanged(value)
    SensorID        = sensorsAvailable[value].id
    SensorParam     = sensorsAvailable[value].param
    system.pSave("SensorID", SensorID)
    system.pSave("SensorParam", SensorParam)
end

----------------------------------------------------------------------
--
local function initForm(subform)
    -- make all the dynamic menu items

    sensorsAvailable = {}
    local sensors   = system.getSensors();
    local list      ={}
    local curIndex  = -1
    local descr     = ""
    for index,sensor in ipairs(sensors) do 
        if(sensor.param == 0) then
            descr = sensor.label
            else
            list[#list + 1] = string.format("%s - %s", descr, sensor.label)
            sensorsAvailable[#sensorsAvailable + 1] = sensor
            if(sensor.id == SensorID and sensor.param == SensorParam ) then
                curIndex =# sensorsAvailable
            end
        end
    end
    
    collectgarbage()

    form.addRow(2)
    form.addLabel({label='Choose speed sensor', width=200})
    form.addSelectbox(list, curIndex, true, sensorChanged)

    form.addRow(2)
    form.addLabel({label='-----------------------------------------------------------------------', width=300})

    form.addRow(2)
    form.addLabel({label='Over speed (m/s)', width=200})
    form.addIntbox(OverSpeed,0,150,0,0,1, function(value) OverSpeed=value; system.pSave("OverSpeed",value) end )

    form.addRow(2)
    form.addLabel({label='Audio alarm', width=200})
    form.addAudioFilebox(OverSpeedFile or "", function(value) OverSpeedFile=value; system.pSave("OverSpeedFile",value) end )

    form.addRow(2)
    form.addLabel({label='Haptisk varsling', width=200})
    OverSpeedI = form.addCheckbox(OverSpeedHaptic, OverSpeedHapticChanged)

    form.addRow(2)
    form.addLabel({label='-----------------------------------------------------------------------', width=300})

    form.addRow(2)
    form.addLabel({label='Minimum safe speed (m/s)', width=200})
    form.addIntbox(MinimumSafeSpeed,0,150,0,0,1, function(value) MinimumSafeSpeed=value; system.pSave("MinimumSafeSpeed",value) end )

    form.addRow(2)
    form.addLabel({label='Audio alarm', width=200})
    form.addAudioFilebox(MinimumSafeSpeedFile or "", function(value) MinimumSafeSpeedFile=value; system.pSave("MinimumSafeSpeedFile",value) end )

    form.addRow(2)
    form.addLabel({label='Haptisk varsling', width=200})
    MinimumSafeSpeedI = form.addCheckbox(MinimumSafeSpeedHaptic, MinimumSafeSpeedHapticChanged)

    form.addRow(2)
    form.addLabel({label='-----------------------------------------------------------------------', width=300})

    form.addRow(2)
    form.addLabel({label='Stall speed (m/s)', width=200})
    form.addIntbox(StallSpeed,0,150,0,0,1, function(value) StallSpeed=value; system.pSave("StallSpeed",value) end )

    form.addRow(2)
    form.addLabel({label='Audio alarm', width=200})
    form.addAudioFilebox(StallSpeedFile or "", function(value) StallSpeedFile=value; system.pSave("StallSpeedFile",value) end )

    form.addRow(2)
    form.addLabel({label='Haptisk varsling', width=200})
    StallSpeedI = form.addCheckbox(StallSpeedHaptic, StallSpeedHapticChanged)

    form.addRow(2)
    form.addLabel({label='-----------------------------------------------------------------------', width=300})

    form.addRow(2)
    form.addLabel({label='Take off speed (m/s)', width=200})
    form.addIntbox(TakeOffSpeed,0,150,0,0,1, function(value) TakeOffSpeed=value; system.pSave("TakeOffSpeed",value) end )

    form.addRow(2)
    form.addLabel({label='Audio alarm', width=200})
    form.addAudioFilebox(TakeOffSpeedFile or "", function(value) TakeOffSpeedFile=value; system.pSave("TakeOffSpeedFile",value) end )

    form.addRow(2)
    form.addLabel({label='Haptisk varsling', width=200})
    TakeOffSpeedI = form.addCheckbox(TakeOffSpeedHaptic, TakeOffSpeedHapticChanged)

    form.addRow(2)
    form.addLabel({label='-----------------------------------------------------------------------', width=300})

    form.addRow(2)
    form.addLabel({label="Off switch", width=200})
    form.addInputbox(OffSwitch,true, function(value) OffSwitch=value; system.pSave("OffSwitch",value) end ) 

    collectgarbage()
    -- print("Mem after GUI: ", collectgarbage("count"))
end


----------------------------------------------------------------------
-- Re-init correct form if navigation buttons are pressed
local function keyPressed(key)
    form.reinit(1)
end

----------------------------------------------------------------------
-- Application initialization. Has to be the second last function so all other functions is initialized
local function init()
    -- Load translation files  
    system.registerForm(1,MENU_APPS,"Speed warnings", initForm, keyPressed)

    SensorID                = system.pLoad("SensorID", 0)
    SensorParam             = system.pLoad("SensorParam", 0)

    OverSpeed               = system.pLoad("OverSpeed", 0)
    OverSpeedFile           = system.pLoad("OverSpeedFile", "")
    OverSpeedHaptic         = system.pLoad("OverSpeedHaptic", 0)

    if(OverSpeedHaptic == 1) then
        OverSpeedHaptic = true
    else
        OverSpeedHaptic = false
    end

    MinimumSafeSpeed        = system.pLoad("MinimumSafeSpeed", 0)
    MinimumSafeSpeedFile    = system.pLoad("MinimumSafeSpeedFile", "")
    MinimumSafeSpeedHaptic  = system.pLoad("MinimumSafeSpeedHaptic", 0)

    if(OverSpeedHaptic == 1) then
        OverSpeedHaptic = true
    else
        OverSpeedHaptic = false
    end

    TakeOffSpeed            = system.pLoad("TakeOffSpeed", 0)
    TakeOffSpeedFile        = system.pLoad("TakeOffSpeedFile", "")
    TakeOffSpeedHaptic      = system.pLoad("TakeOffSpeedHaptic", 0)

    if(TakeOffSpeedHaptic == 1) then
        TakeOffSpeedHaptic = true
    else
        TakeOffSpeedHaptic = false
    end

    StallSpeed              = system.pLoad("StallSpeed", 0)    
    StallSpeedFile          = system.pLoad("StallSpeedFile", "")    
    StallSpeedHaptic        = system.pLoad("StallSpeedHaptic", 0)    

    if(StallSpeedHaptic == 1) then
        StallSpeedHaptic = true
    else
        StallSpeedHaptic = false
    end

    OffSwitch               = system.pLoad("OffSwitch")

    ctrlIdx = system.registerControl(1, "Speed off switch","SpeedOff")
    collectgarbage()
end

----------------------------------------------------------------------
-- Loop has to be the last function, so every other function is initialized
local function loop()

    if(SensorID ~= 0) then
        local sensor = system.getSensorByID(SensorID, SensorParam)

        if(sensor.valid) then
            local speed = sensor.value

            print(string.format("Speed : #%s#", speed))

            if (speed > MinimumSafeSpeed) then
                tresholdPassed.minimum  = true
            end 

            if (speed > StallSpeed) then
                --Run once, activate after it has been below
                tresholdPassed.stall  = true
            end

            if(tresholdPassed.minimum and speed < MinimumSafeSpeed) then
                tresholdPassed.minimum = false
                system.playFile(MinimumSafeSpeedFile, AUDIO_QUEUE)
                system.messageBox('MinimumSafeSpeed', 2)

                if(MinimumSafeSpeedHaptic) then
                    system.vibration(false, 1);
                end
            end

            if(tresholdPassed.stall and speed < StallSpeed) then
                tresholdPassed.stall = false
                system.playFile(StallSpeedFile, AUDIO_QUEUE)
                system.messageBox('StallSpeed', 2)

                if(StallSpeedHaptic) then
                    system.vibration(false, 1);
                end
            end

            if(tresholdPassed.over and speed > OverSpeed and alarmTriggeredTime.over < system.getTime()) then
                alarmTriggeredTime.over = system.getTime() + 5
                system.playFile(OverSpeedFile, AUDIO_QUEUE)
                system.messageBox('OverSpeed', 2)

                if(OverSpeedHaptic) then
                    system.vibration(false, 1);
                end
            end

            -- Kjøres en gang, inntil 10 sekunder under satt verdi, da aktiveres den igjen.
            if(tresholdPassed.takeoff and speed >= TakeOffSpeed) then
                tresholdPassed.takeoff = false
                system.playFile(TakeOffSpeedFile, AUDIO_QUEUE)
                system.messageBox('TakeOffSpeed', 2)

                if(TakeOffSpeedHaptic) then
                    system.vibration(false, 1);
                end

            elseif (speed > TakeOffSpeed) then
                alarmTriggeredTime.takeoff = system.getTime()
            end

            if(not tresholdPassed.takeoff and speed < TakeOffSpeed) then

                if(system.getTime() - alarmTriggeredTime.takeoff > 10) then
                    system.messageBox('TakeOffSpeed reset', 2)
                    tresholdPassed.takeoff = true
                end
            end
        end
    end
end

return {init=init, loop=loop, author="Thomas Ekdahl - thomas@ekdahl.no", version='0.1', name="Speed warning"}