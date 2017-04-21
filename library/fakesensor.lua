
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

local fakesensor = {}

--------------------------------------------------------------------
-- Generates fake sensor values
function fakesensor.makeSensorValues()

  sensorsOnline            = 1
  SensorT.rpm              = {"..."}
  SensorT.rpm2             = {"..."}
  SensorT.egt              = {"..."}
  SensorT.fuellevel        = {"..."}
  SensorT.ecuv             = {"..."}
  SensorT.pumpv            = {"..."}
  SensorT.status           = {"..."}

  SensorT.rpm.sensor       = {"..."}
  SensorT.rpm2.sensor      = {"..."}
  SensorT.egt.sensor       = {"..."}
  SensorT.fuellevel.sensor = {"..."}
  SensorT.ecuv.sensor      = {"..."}
  SensorT.pumpv.sensor     = {"..."}
  SensorT.status.sensor    = {"..."}

  -- Should have a random number generator here.

  SensorT.rpm.sensor.value  = 121239
  SensorT.rpm.sensor.max    = 156693

  SensorT.rpm2.sensor.value = 2534
  SensorT.rpm2.sensor.max   = 5556

  SensorT.egt.sensor.value  = 634
  SensorT.egt.sensor.max    = 856

  SensorT.fuellevel.sensor.value  = 0
  SensorT.fuellevel.sensor.max    = 2501
  SensorT.fuellevel.percent       = -10

  SensorT.ecuv.sensor.value  = 7.1
  SensorT.ecuv.sensor.max    = 7.6
  SensorT.ecuv.percent       = 30

  SensorT.pumpv.sensor.value  = 0.9
  SensorT.pumpv.sensor.max    = 2.5

  SensorT.status.sensor.value  = 0
  SensorT.status.sensor.max    = 0
  SensorT.status.text          = 'RC Off'

end


return fakesensor