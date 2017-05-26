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

local telemetry_window3 = {}
----------------------------------------------------------------------
--
function telemetry_window3.show(width, height) 
    local xcg1  = 5
    local xcg2  = tonumber((width / 2))
    local yc    = tonumber((height / 3) + 20)
    local diam  = tonumber((height / 2) - 10)
    
    if(sensorsOnline == 1) then

      -- print(string.format("width: %s, height: %s", width, height))

      -- lcd.drawText(5,5, string.format("Tanksize: %.1f%s",tonumber(config.fuellevel.tanksize/1000), "L"), FONT_BOLD)
      
      lcd.drawText(5,2, string.format("RPM"), FONT_NORMAL)
      lcd.drawCircle(xcg1,yc,diam)

      lcd.drawText(width/2,2, string.format("TEMP"), FONT_NORMAL)    
      lcd.drawCircle(xcg2,yc,diam)
      
      rpmgauge = lcd.loadImage("Apps/ecu/img/rpmgauge.png")
      tempgauge = lcd.loadImage("Apps/ecu/img/tempgauge.png")

      if(rpmgauge) then
          lcd.drawImage(xcg1, 18, rpmgauge)
      end

      if(tempgauge) then
          lcd.drawImage(xcg2, 18, tempgauge)
      end

      -- Calculate the x position of the needle in the gauge
      --print(string.format(string.format("SensorT.rpm.sensor.value: %s", SensorT.rpm.sensor.value)))
      --print(string.format(string.format("config.rpm.high.value: %s", config.rpm.high.value)))
      local rpmpercent  = (SensorT.rpm.sensor.value)  / (config.rpm.high.value  / 10000) -- to get fractional numbers

      --print(string.format(string.format("SensorT.egt.sensor.value: %s", SensorT.egt.sensor.value)))
      --print(string.format(string.format("config.egt.high.value: %s", config.egt.high.value)))
      local temppercent = (SensorT.egt.sensor.value) / (config.egt.high.value / 10000) -- to get fractional numbers

      local rpmx    = xcg1 + (rpmgauge.width  * rpmpercent) 
      local tempx   = xcg2 + (tempgauge.width * temppercent)
      -- Draw the lines for the gauge, or just reload with images with better quality gauges?
      lcd.drawLine(xcg1+(rpmgauge.width)/2,rpmgauge.height+5, rpmx,18)

      lcd.drawLine(xcg2+(tempgauge.width)/2,tempgauge.height+5, tempx,18)
      else
        lcd.drawText(5,5, 'OFFLINE', FONT_MAXI)
    end
end

return telemetry_window3