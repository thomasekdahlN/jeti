-- ############################################################################# 
-- # Jeti helper library - shared telemetry drawing helpers
-- #
-- # Copyright (c) 2017, Original idea by Thomas Ekdahl (thomas@ekdahl.no)
-- #
-- # License: Share alike
-- ############################################################################# 

local drawhelper = {}

----------------------------------------------------------------------
-- Draw a 5-step segmented gauge with fractional fill.
function drawhelper.DrawSegmentGauge(percentage, ox, oy)
    local safePercentage = tonumber(percentage) or 0
    local nSolidBar
    local nFracBar
    local y
    local i

    if(safePercentage < 0) then
        safePercentage = 0
    elseif(safePercentage > 100) then
        safePercentage = 100
    end

    lcd.drawRectangle(5 + ox, 53 + oy, 25, 11)
    lcd.drawRectangle(5 + ox, 41 + oy, 25, 11)
    lcd.drawRectangle(5 + ox, 29 + oy, 25, 11)
    lcd.drawRectangle(5 + ox, 17 + oy, 25, 11)
    lcd.drawRectangle(5 + ox, 5 + oy, 25, 11)

    nSolidBar = math.floor(safePercentage / 20)
    nFracBar = (safePercentage - nSolidBar * 20) / 20

    for i = 0, nSolidBar - 1, 1 do
        lcd.drawFilledRectangle(5 + ox, 53 - i * 12 + oy, 25, 11)
    end

    y = math.floor(53 - nSolidBar * 12 + (1 - nFracBar) * 11 + 0.5)
    lcd.drawFilledRectangle(5 + ox, y + oy, 25, 11 * nFracBar)
end

return drawhelper