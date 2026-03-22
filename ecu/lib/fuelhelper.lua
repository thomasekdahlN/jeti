
-- ############################################################################# 
-- # Jeti helper library
-- #
-- # Copyright (c) 2017, Original idea by Thomas Ekdahl (thomas@ekdahl.no)
-- #
-- # License: Share alike                                       
-- # Can be used and changed non commercial, but feel free to send us changes back to be incorporated in the main code.
-- #                       
-- # V0.5 - Initial release
-- ############################################################################# 

local fuelhelper = {}

local getConfig = function()
    return nil
end

local getSensors = function()
    return nil
end

local getTankSize = function()
    return 0
end

local getFuelAlarm = function()
    return nil
end

local function getFuelSensorState(tmpCfg)
    local sensors = getSensors()

    if(not tmpCfg or not sensors) then
        return nil
    end

    return sensors[tmpCfg.sensorname]
end

----------------------------------------------------------------------
-- Initialize state providers from the main application.
function fuelhelper.init(configProvider, sensorProvider, tankSizeProvider, fuelAlarmProvider)
    if(type(configProvider) == "function") then
        getConfig = configProvider
    end

    if(type(sensorProvider) == "function") then
        getSensors = sensorProvider
    end

    if(type(tankSizeProvider) == "function") then
        getTankSize = tankSizeProvider
    end

    if(type(fuelAlarmProvider) == "function") then
        getFuelAlarm = fuelAlarmProvider
    end
end

----------------------------------------------------------------------
-- Calculates: config.fuellevel.tanksize and config.fuellevel.interval and fuelpercent
function fuelhelper.initFuelSetup(tmpCfg)
    local currentConfig = getConfig()
    local tankSize = getTankSize()
    local fuelAlarm = getFuelAlarm()
    local sensorState = getFuelSensorState(tmpCfg)

    -- Calculate TankSize and Level
    if(not currentConfig or not currentConfig.converter or not currentConfig.fuel or not fuelAlarm) then
        return
    end

    if(not sensorState or not sensorState.sensor) then
        return
    end

    if(currentConfig.converter.fuel.countingdown and sensorState.sensor.value > currentConfig.fuel.tanksize) then
        -- As long as we get a higher fuel reading, we keep resetting the tanksize and intervals since tanksize is set in ECU when countingdown

        currentConfig.fuel.tanksize = sensorState.sensor.value
        fuelAlarm.tanksizeset = true

    elseif(not fuelAlarm.tanksizeset) then
        -- counting up, have to subtract, only done until low value has passed, then forgotten. TankSize read from GUI
        currentConfig.fuel.tanksize = tankSize

        fuelAlarm.tanksizeset = true
    end
end

----------------------------------------------------------------------
-- Calculate the fuel level in percent
function fuelhelper.calculateFuelPercent(tmpCfg)
    local currentConfig = getConfig()
    local sensorState = getFuelSensorState(tmpCfg)

    if(not currentConfig or not currentConfig.fuel or not currentConfig.converter) then
        return 0
    end

    if(not sensorState or not sensorState.sensor) then
        return 0
    end

    -- Calculate fuel percentage remaining
    if(currentConfig.fuel.tanksize > 0) then
        if(currentConfig.converter.fuel.countingdown) then
            return fuelhelper.calcPercent(sensorState.sensor.value, currentConfig.fuel.tanksize, 0)
        else
            return fuelhelper.calcPercent(currentConfig.fuel.tanksize - sensorState.sensor.value, currentConfig.fuel.tanksize, 0)
        end
    else
        return 0
    end
end

----------------------------------------------------------------------
-- Find the fuel threshold passed
function fuelhelper.FuelThresholdPassed(tmpCfg)
    local sensorState = getFuelSensorState(tmpCfg)
    local thresholdI, thresholdV = 0,100

    if(not tmpCfg or not sensorState) then
        return thresholdI, thresholdV
    end

    for i, tmp in ipairs(tmpCfg.alarms or {}) do
        if(tonumber(sensorState.percent or 0) <= tonumber(tmp.value)) then
            thresholdI = i
            thresholdV = tonumber(tmp.value)
            break
        end
    end
    return thresholdI, thresholdV
end

----------------------------------------------------------------------
-- Calculate percent
function fuelhelper.calcPercent(current, high, low)
    local currentValue = tonumber(current) or 0
    local highValue = tonumber(high) or 0
    local lowValue = tonumber(low) or 0
    local percent

    if(highValue == lowValue) then
        return 0
    end

    percent = ((currentValue - lowValue) / (highValue - lowValue)) * 100
    if(percent < 0) then 
        percent = 0
    elseif(percent > 100) then 
        percent = 100
    end
    return percent
end

return fuelhelper