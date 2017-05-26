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

local telemetry_window2 = {}

----------------------------------------------------------------------
local function DrawGauge(percentage, ox, oy) 
    
    -- battery symbol
    lcd.drawRectangle(36+ox,29+oy,3,2)
    lcd.drawRectangle(35+ox,31+oy,5,12)
    --lcd.drawLine(36+ox,34+oy,54+ox,34+oy)
    --lcd.drawLine(34+ox,39+oy,56+ox,39+oy)
    --lcd.drawLine(57+ox,31+oy,59+ox,33+oy)
    --lcd.drawLine(59+ox,33+oy,59+ox,37+oy)
    lcd.drawText(35+ox,2+oy, "F", FONT_MINI)  
    lcd.drawText(35+ox,54+oy, "E", FONT_MINI)  
  
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

----------------------------------------------------------------------
local function DrawText(ox, oy) 
  local vs      = 13 -- vertical space
  oy = oy + 10 -- vertical space start

  lcd.drawText(4+ox, 1+oy, "SENS", FONT_MINI)  
  lcd.drawText(35+ox,1+oy, "NOW", FONT_MINI)  
  lcd.drawText(70+ox,1+oy, "MAX", FONT_MINI)  

  if(config.converter.sensormap.rpm and SensorT.rpm.sensor) then
    lcd.drawText(4+ox, vs*1+oy, 'RPM', FONT_MINI)
    lcd.drawText(35+ox,vs*1+oy, string.format("%s%s",math.floor(SensorT.rpm.sensor.value/1000),"K"), FONT_MINI)
    lcd.drawText(70+ox,vs*1+oy, string.format("%s%s",math.floor(SensorT.rpm.sensor.max/1000),"K"), FONT_MINI)
  end

  if(config.converter.sensormap.rpm2 and SensorT.rpm2.sensor) then
    lcd.drawText(4+ox, vs*2+oy, 'RPM2', FONT_MINI)
    lcd.drawText(35+ox,vs*2+oy, string.format("%s",SensorT.rpm2.sensor.value), FONT_MINI)
    lcd.drawText(70+ox,vs*2+oy, string.format("%s",SensorT.rpm2.sensor.max), FONT_MINI)
  end
  
  if(config.converter.sensormap.egt and SensorT.egt.sensor) then
    lcd.drawText(4+ox, vs*3+oy, 'EGT', FONT_MINI)
    lcd.drawText(35+ox,vs*3+oy, string.format("%s%s",SensorT.egt.sensor.value,"C"), FONT_MINI)
    lcd.drawText(70+ox,vs*3+oy, string.format("%s%s",SensorT.egt.sensor.max,"C"), FONT_MINI)
  end
end

----------------------------------------------------------------------
-- Print the telemetry values
function telemetry_window2.show(width, height) 

    if(sensorsOnline == 1) then
      -- field separator lines
      lcd.drawLine(45,2,45,66)  
      --lcd.drawLine(70,36,148,36)  
 
      if(config.converter.sensormap.ecuv and SensorT.ecuv) then
        DrawGauge(SensorT.ecuv.percent, 1, 0)
      end

      -- turbine
      DrawText(50, 0)

    else
      lcd.drawText(5,5, 'OFFLINE', FONT_MAXI)
    end
end

return telemetry_window2