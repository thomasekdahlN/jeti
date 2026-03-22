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

local telemetry_window2 = {}

local getState = function()
    return 0, {}, {}, {allOnline = false}
end

local function hasMapping(config, sensorName)
    return config
        and config.converter
        and config.converter.sensormap
        and tonumber(config.converter.sensormap[sensorName] or 0) > 0
end

local function formatRpmThousands(value)
    return string.format("%sK", math.floor((tonumber(value) or 0) / 1000))
end

local function drawStateText(label)
    lcd.drawText(5,5, label, FONT_MAXI)
end

local function drawWindowFrame()
    lcd.drawLine(45,2,45,66)
end

----------------------------------------------------------------------
-- Initialize state provider from the main application.
function telemetry_window2.init(stateProvider)
    if(type(stateProvider) == "function") then
        getState = stateProvider
    end
end

----------------------------------------------------------------------
local function drawBatteryGauge(percentage, ox, oy)

    -- battery symbol
    lcd.drawRectangle(36+ox,29+oy,3,2)
    lcd.drawRectangle(35+ox,31+oy,5,12)
    lcd.drawText(35+ox,2+oy, "F", FONT_MINI)  
    lcd.drawText(35+ox,54+oy, "E", FONT_MINI)  
  
    drawh.DrawSegmentGauge(percentage, ox, oy)
end

----------------------------------------------------------------------
local function drawTelemetryText(sensorTable, config, ox, oy)
    local verticalSpacing = 13

    oy = oy + 10

    lcd.drawText(4+ox, 1+oy, "SENS", FONT_MINI)
    lcd.drawText(35+ox,1+oy, "NOW", FONT_MINI)
    lcd.drawText(70+ox,1+oy, "MAX", FONT_MINI)

    if(hasMapping(config, "rpm") and sensorTable.rpm and sensorTable.rpm.sensor) then
        lcd.drawText(4+ox, verticalSpacing+oy, "RPM", FONT_MINI)
        lcd.drawText(35+ox, verticalSpacing+oy, formatRpmThousands(sensorTable.rpm.sensor.value), FONT_MINI)
        lcd.drawText(70+ox, verticalSpacing+oy, formatRpmThousands(sensorTable.rpm.sensor.max), FONT_MINI)
    end

    if(hasMapping(config, "rpm2") and sensorTable.rpm2 and sensorTable.rpm2.sensor) then
        lcd.drawText(4+ox, verticalSpacing*2+oy, "RPM2", FONT_MINI)
        lcd.drawText(35+ox, verticalSpacing*2+oy, string.format("%s", sensorTable.rpm2.sensor.value), FONT_MINI)
        lcd.drawText(70+ox, verticalSpacing*2+oy, string.format("%s", sensorTable.rpm2.sensor.max), FONT_MINI)
    end

    if(hasMapping(config, "egt") and sensorTable.egt and sensorTable.egt.sensor) then
        lcd.drawText(4+ox, verticalSpacing*3+oy, "EGT", FONT_MINI)
        lcd.drawText(35+ox, verticalSpacing*3+oy, string.format("%s%s", sensorTable.egt.sensor.value, "C"), FONT_MINI)
        lcd.drawText(70+ox, verticalSpacing*3+oy, string.format("%s%s", sensorTable.egt.sensor.max, "C"), FONT_MINI)
    end
end

----------------------------------------------------------------------
-- Print the telemetry values
function telemetry_window2.show(width, height)
    local sensorID, sensorTable, config, sensorState = getState()

    if(sensorID == 0) then
        drawStateText("NO CONFIG")
        return
    end

    if(not sensorState.allOnline) then
        drawStateText("OFFLINE")
        return
    end

    drawWindowFrame()

    if(hasMapping(config, "ecuv") and sensorTable.ecuv) then
        drawBatteryGauge(sensorTable.ecuv.percent, 1, 0)
    end

    drawTelemetryText(sensorTable, config, 50, 0)
end

return telemetry_window2