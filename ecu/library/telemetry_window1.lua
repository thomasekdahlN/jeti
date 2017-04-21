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

local telemetry_window1 = {}
----------------------------------------------------------------------
--

----------------------------------------------------------------------
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
    lcd.drawFilledRectangle (5+ox,y+oy,25,11*nFracBar) 

    --lcd.drawText(4+ox,15+oy, config.fuellevel.tanksize, FONT_BOLD)
    --lcd.drawText(1+ox,49+oy, string.format("Fulltank: %.1f",tonumber(config.fuellevel.tanksize/1000)), FONT_BOLD)
end

----------------------------------------------------------------------
local function DrawTurbineStatus(status, ox, oy) 
    lcd.drawText(4+ox,2+oy, "Turbine", FONT_MINI)  
    lcd.drawText(4+ox,15+oy, status, FONT_BOLD)  
end


----------------------------------------------------------------------
local function DrawBattery(u_pump, u_ecu, ox, oy) 
  lcd.drawText(4+ox,1+oy, "PUMP", FONT_MINI)  
  lcd.drawText(45+ox,1+oy, "ECU", FONT_MINI)  
  lcd.drawText(4+ox,12+oy,  string.format("%.1f%s",u_pump,"V"), FONT_BOLD)
  lcd.drawText(45+ox,12+oy, string.format("%.1f%s",u_ecu,"V"), FONT_BOLD)
end

----------------------------------------------------------------------
local function DrawFuelLow(ox, oy) 

  if( system.getTime() % 2 == 0) then -- blink every second
    -- triangle
  lcd.drawLine(6+ox,47+oy,32+ox,3+oy)
  lcd.drawLine(32+ox,3+oy,45+ox,47+oy)
  lcd.drawLine(60+ox,47+oy,6+ox,47+oy)

  lcd.drawLine(7+ox,47+oy,33+ox,3+oy)
  lcd.drawLine(33+ox,3+oy,45+ox,47+oy)
  lcd.drawLine(61+ox,46+oy,6+ox,46+oy)

  lcd.drawLine(8+ox,47+oy,34+ox,3+oy)
  lcd.drawLine(34+ox,3+oy,45+ox,47+oy)
  lcd.drawLine(62+ox,46+oy,8+ox,46+oy)
  lcd.drawText(31+ox,10+oy, "!", FONT_BIG)  
  end  
  
  -- percentage and warning
  local percentX = 20
  if( SensorT.fuellevel.percent < 10 ) then percentX = 23 end
  lcd.drawText(percentX+ox,28+oy, string.format("%d%s",SensorT.fuellevel.percent,"%"), FONT_BOLD)  
  lcd.drawText(1+ox,49+oy, "Low", FONT_BOLD)  
  
end

----------------------------------------------------------------------
-- Print the telemetry values
function telemetry_window1.window(width, height) 
  
    if(sensorsOnline > 0) then
      -- field separator lines
      lcd.drawLine(45,2,45,66)  
      lcd.drawLine(45,36,148,36)  

      if(SensorT.fuellevel.sensor) then
        if(SensorT.fuellevel.percent > config.fuellevel.warning.value) then
          DrawFuelGauge(SensorT.fuellevel.percent, 1, 0)   
        else
          DrawFuelLow(SensorT.fuellevel.percent, 1, 0) 
        end
      end

      -- turbine
      if(SensorT.status.sensor) then
        DrawTurbineStatus(SensorT.status.text, 50, 0)
      end

      -- battery
      DrawBattery(SensorT.pumpv.sensor.value, SensorT.ecuv.sensor.value, 50, 37)
    else
        lcd.drawText(5,5, 'OFFLINE', FONT_MAXI)
    end
end

return telemetry_window1