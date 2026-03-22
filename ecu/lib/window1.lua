-- ############################################################################# 
-- # Jeti helper library - supporting internal generic alarm format
-- #
-- # Copyright (c) 2017, Original idea by Thomas Ekdahl (thomas@ekdahl.no)
-- #
-- # License: Share alike                                       
-- # Can be used and changed non commercial, but feel free to send us changes back to be incorporated in the main code.
-- #                       
-- # V0.5 - Initial release
-- ############################################################################# 

local drawh = require "ecu/lib/drawhelper"

local telemetry_window1 = {}

local getState = function()
    return 0, {}, {}, {allOnline = false}
end

local function hasMapping(config, sensorName)
    return config
        and config.converter
        and config.converter.sensormap
        and tonumber(config.converter.sensormap[sensorName] or 0) > 0
end

----------------------------------------------------------------------
-- Initialize state provider from the main application.
function telemetry_window1.init(stateProvider)
    if(type(stateProvider) == "function") then
        getState = stateProvider
    end
end
----------------------------------------------------------------------
--

----------------------------------------------------------------------
local function drawFuelGauge(percentage, ox, oy)

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
  
    drawh.DrawSegmentGauge(percentage, ox, oy)

    --lcd.drawText(4+ox,15+oy, config.fuel.tanksize, FONT_BOLD)
    --lcd.drawText(1+ox,49+oy, string.format("Fulltank: %.1f",tonumber(config.fuel.tanksize/1000)), FONT_BOLD)
end

----------------------------------------------------------------------
local function drawTurbineStatus(status, ox, oy)
    lcd.drawText(4+ox,2+oy, "Turbine", FONT_MINI)  
    lcd.drawText(4+ox,15+oy, status, FONT_BOLD)  
end


----------------------------------------------------------------------
local function drawBattery(pumpVoltage, ecuVoltage, ox, oy)
    lcd.drawText(4+ox,1+oy, "PUMP", FONT_MINI)
    lcd.drawText(45+ox,1+oy, "ECU", FONT_MINI)
    lcd.drawText(4+ox,12+oy, string.format("%.1f%s", pumpVoltage, "V"), FONT_BOLD)
    lcd.drawText(45+ox,12+oy, string.format("%.1f%s", ecuVoltage, "V"), FONT_BOLD)
end

----------------------------------------------------------------------
local function drawFuelLow(percentage, ox, oy)
    local safePercentage = math.floor((tonumber(percentage) or 0) + 0.5)

    if(system.getTime() % 2 == 0) then
        lcd.drawLine(21+ox,5+oy,2+ox,35+oy)
        lcd.drawLine(2+ox,35+oy,41+ox,35+oy)
        lcd.drawLine(41+ox,35+oy,21+ox,5+oy)
        lcd.drawText(20+ox,11+oy, "!", FONT_BIG)
    end

    lcd.drawText(1+ox,49+oy, string.format("%d%%", safePercentage), FONT_BOLD)
end

----------------------------------------------------------------------
local function drawWindowFrame()
    lcd.drawLine(45,2,45,66)
    lcd.drawLine(45,36,148,36)
end

----------------------------------------------------------------------
local function drawOfflineState()
    lcd.drawText(5,5, "OFFLINE", FONT_MAXI)
end

----------------------------------------------------------------------
-- Print the telemetry values
function telemetry_window1.show(width, height)
    local sensorID, sensorTable, config, sensorState = getState()
    local fuelPercent

    if(sensorID == 0) then
        drawTurbineStatus("NO CONFIG", 50, 0)
        return
    end

    if(not sensorState.allOnline) then
        drawOfflineState()
        return
    end

    drawWindowFrame()

    if(hasMapping(config, "fuel") and sensorTable.fuel and sensorTable.fuel.percent) then
        fuelPercent = sensorTable.fuel.percent
        if(fuelPercent > 20) then
            drawFuelGauge(fuelPercent, 1, 0)
        else
            drawFuelLow(fuelPercent, 1, 0)
        end
    end

    if(hasMapping(config, "status")) then
        drawTurbineStatus(sensorTable.status and sensorTable.status.text or "UNKNOWN", 50, 0)
    else
        drawTurbineStatus("UNCONFIG", 50, 0)
    end

    if(hasMapping(config, "pumpv") and sensorTable.pumpv and sensorTable.pumpv.sensor and sensorTable.ecuv and sensorTable.ecuv.sensor) then
        drawBattery(sensorTable.pumpv.sensor.value, sensorTable.ecuv.sensor.value, 50, 37)
    end
end

return telemetry_window1