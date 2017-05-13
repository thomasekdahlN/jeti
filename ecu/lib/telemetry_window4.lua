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

local telemetry_window4 = {}

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
    lcd.drawText(ox,15+oy, status, FONT_BIG)  
end


----------------------------------------------------------------------
local function DrawBattery(u_pump, u_ecu, ox, oy) 
  lcd.drawText(ox,oy, "PUMP", FONT_BIG)  
  lcd.drawText(ox+55,oy,  string.format("%.1f%s",u_pump,"V"), FONT_BIG)

  lcd.drawText(ox,oy+20, "ECU", FONT_BIG)  
  lcd.drawText(ox+55,oy+20, string.format("%.1f%s",u_ecu,"V"), FONT_BIG)
end

----------------------------------------------------------------------
local function DrawFuelLow(percentage, ox, oy) 

  if( system.getTime() % 2 == 0) then -- blink every second
    -- triangle
    lcd.drawLine(21+ox,5+oy,2+ox,35+oy)
    lcd.drawLine(2+ox,35+oy,41+ox,35+oy)
    lcd.drawLine(41+ox,35+oy,21+ox,5+oy)
    lcd.drawText(20+ox,11+oy, "!", FONT_BIG)  
  end  
  
  -- percentage and warning
  lcd.drawText(1+ox,49+oy, string.format("%s%s",tonumber(percentage),"%"), FONT_BIG)    
end

function rpmGauge(x, y)
    local xcg1  = 5
    --local xcg2  = tonumber((width / 2))
    --local yc    = tonumber((height / 3) + 20)
    --local diam  = tonumber((height / 2) - 10)

      lcd.drawText(x,y, string.format("RPM"), FONT_NORMAL)
      --lcd.drawCircle(xcg1,yc,diam)
      
      rpmgauge = lcd.loadImage("Apps/ecu/img/rpmgauge.png")

      if(rpmgauge) then
          lcd.drawImage(x, y + 15, rpmgauge)
      end


      -- Calculate the x position of the needle in the gauge
      --print(string.format(string.format("SensorT.rpm.sensor.value: %s", SensorT.rpm.sensor.value)))
      --print(string.format(string.format("config.rpm.high.value: %s", config.rpm.high.value)))
      local rpmpercent  = (SensorT.rpm.sensor.value)  / (config.rpm.high.value  / 10000) -- to get fractional numbers

      --print(string.format(string.format("SensorT.egt.sensor.value: %s", SensorT.egt.sensor.value)))
      --print(string.format(string.format("config.egt.high.value: %s", config.egt.high.value)))

      --local rpmx    = xcg1 + (rpmgauge.width  * rpmpercent) 
      -- Draw the lines for the gauge, or just reload with images with better quality gauges?
      --lcd.drawLine(xcg1+(rpmgauge.width)/2,rpmgauge.height+5, rpmx,18)
end


function egtGauge(x, y)
    --local xcg1  = 5
    --local xcg2  = tonumber((width / 2))
    --local yc    = tonumber((height / 3) + 20)
    --local diam  = tonumber((height / 2) - 10)


      lcd.drawText(x, y,  string.format("TEMP"), FONT_NORMAL)    
      --lcd.drawCircle(x,y,diam)
      
      egtgauge = lcd.loadImage("Apps/ecu/img/egtgauge.png")

      if(egtgauge) then
          lcd.drawImage(x, y + 15, egtgauge)

      -- Calculate the x position of the needle in the gauge
      --print(string.format(string.format("SensorT.rpm.sensor.value: %s", SensorT.rpm.sensor.value)))
      --print(string.format(string.format("config.rpm.high.value: %s", config.rpm.high.value)))

      --print(string.format(string.format("SensorT.egt.sensor.value: %s", SensorT.egt.sensor.value)))
      --print(string.format(string.format("config.egt.high.value: %s", config.egt.high.value)))
      local temppercent = (SensorT.egt.sensor.value) / (config.egt.high.value / 10000) -- to get fractional numbers

      --local tempx   = xcg2 + (egtgauge.width * temppercent)
      -- Draw the lines for the gauge, or just reload with images with better quality gauges?

      --lcd.drawLine(xcg2+(egtgauge.width)/2,egtgauge.height+5, tempx,18)
      end
end

----------------------------------------------------------------------
local function DrawBatteryGauge(percentage, ox, oy) 
    
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

  lcd.drawText(4+ox, vs*1+oy, 'RPM', FONT_MINI)
  lcd.drawText(35+ox,vs*1+oy, string.format("%s%s",math.floor(SensorT.rpm.sensor.value/1000),"K"), FONT_MINI)
  lcd.drawText(70+ox,vs*1+oy, string.format("%s%s",math.floor(SensorT.rpm.sensor.max/1000),"K"), FONT_MINI)

  lcd.drawText(4+ox, vs*2+oy, 'RPM2', FONT_MINI)
  lcd.drawText(35+ox,vs*2+oy, string.format("%s",SensorT.rpm2.sensor.value), FONT_MINI)
  lcd.drawText(70+ox,vs*2+oy, string.format("%s",SensorT.rpm2.sensor.max), FONT_MINI)

  lcd.drawText(4+ox, vs*3+oy, 'EGT', FONT_MINI)
  lcd.drawText(35+ox,vs*3+oy, string.format("%s%s",SensorT.egt.sensor.value,"C"), FONT_MINI)
  lcd.drawText(70+ox,vs*3+oy, string.format("%s%s",SensorT.egt.sensor.max,"C"), FONT_MINI)
end

----------------------------------------------------------------------
--
function telemetry_window4.window(width, height) 
    local xcg1  = 5
    local xcg2  = tonumber((width / 2))
    local yc    = tonumber((height / 3) + 20)
    local diam  = tonumber((height / 2) - 10)
    
    -- field separator lines
    --lcd.drawLine(45,2,45,66)  
    --lcd.drawLine(45,36,148,36)  

    -- to the left
    DrawFuelGauge(SensorT.fuellevel.percent, 0, 0)   
    DrawBatteryGauge(SensorT.ecuv.percent, 50,0)

    -- to the middle
    DrawTurbineStatus(SensorT.status.text, 100, 0)
    DrawBattery(SensorT.pumpv.sensor.value, SensorT.ecuv.sensor.value, 100, 40)
    DrawText(0,80)

    -- to the right
    rpmGauge(200,0)
    egtGauge(200, 90)


end

return telemetry_window4