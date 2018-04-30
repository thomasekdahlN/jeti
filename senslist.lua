-- #############################################################################                  
-- #                       
-- # V1.0 - Initial release
-- #############################################################################

local function init() 
  local sensors = system.getSensors()
  local file

  for i,sensor in ipairs(sensors) do

    if(sensor.type ~= 9 and sensor.type ~= 5) then

      if(sensor.param == 0) then
        -- Sensor label

        if(file) then
          io.close (file)
        end

        print (string.format("%s",sensor.label))
        file = io.open (string.format("Apps/%s.jsn", sensor.label),"w")
        io.write(file, "\"statusmap\" : {\n")
      else  
        -- Other numeric value
        print (string.format("%s = %s", sensor.label, sensor.param))
        io.write(file, string.format("\t\"%s\" : \"%s\",\n", sensor.label, sensor.param))
      end

    end

  end
  io.close (file)
end
--------------------------------------------------------------------------------
return { init=init, loop=loop, author="Thomas Ekdahl", version="0.1",name="WriteSensParam"}