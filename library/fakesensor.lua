
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

  sensorsOnline            = true
  sensorT.rpm              = {"..."}
  sensorT.rpm2             = {"..."}
  sensorT.egt              = {"..."}
  sensorT.fuellevel        = {"..."}
  sensorT.ecuv             = {"..."}
  sensorT.pumpv            = {"..."}
  sensorT.status           = {"..."}

  sensorT.rpm.sensor       = {"..."}
  sensorT.rpm2.sensor      = {"..."}
  sensorT.egt.sensor       = {"..."}
  sensorT.fuellevel.sensor = {"..."}
  sensorT.ecuv.sensor      = {"..."}
  sensorT.pumpv.sensor     = {"..."}
  sensorT.status.sensor    = {"..."}

  -- Should have a random number generator here.

  sensorT.rpm.sensor.value  = 121239
  sensorT.rpm.sensor.max    = 156693

  sensorT.rpm2.sensor.value = 2534
  sensorT.rpm2.sensor.max   = 5556

  sensorT.egt.sensor.value  = 634
  sensorT.egt.sensor.max    = 856

  sensorT.fuellevel.sensor.value  = 2008
  sensorT.fuellevel.sensor.max    = 2501
  sensorT.fuellevel.percent       = 67

  sensorT.ecuv.sensor.value  = 7.1
  sensorT.ecuv.sensor.max    = 7.6
  sensorT.ecuv.percent       = 30

  sensorT.pumpv.sensor.value  = 0.9
  sensorT.pumpv.sensor.max    = 2.5

  sensorT.status.sensor.value  = 0
  sensorT.status.sensor.max    = 0
  sensorT.status.text          = 'RC Off'

end


return fakesensor