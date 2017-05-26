
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
  SensorT.fuel             = {"..."}
  SensorT.ecuv             = {"..."}
  SensorT.pumpv            = {"..."}
  SensorT.status           = {"..."}

  SensorT.rpm.sensor       = {"..."}
  SensorT.rpm2.sensor      = {"..."}
  SensorT.egt.sensor       = {"..."}
  SensorT.fuel.sensor      = {"..."}
  SensorT.ecuv.sensor      = {"..."}
  SensorT.pumpv.sensor     = {"..."}
  SensorT.status.sensor    = {"..."}

  -- Should have a random number generator here.
  if(system.getTime() % 5 == 0) then
    SensorT.rpm.sensor.value  = 121239
    SensorT.rpm.sensor.max    = 156693

    SensorT.rpm2.sensor.value = 2534
    SensorT.rpm2.sensor.max   = 5556

    SensorT.egt.sensor.value  = 634
    SensorT.egt.sensor.max    = 856

    SensorT.fuel.sensor.value  = 0
    SensorT.fuel.sensor.max    = 2501
    SensorT.fuel.percent       = 70

    SensorT.ecuv.sensor.value  = 7.1
    SensorT.ecuv.sensor.max    = 7.6
    SensorT.ecuv.percent       = 30

    SensorT.pumpv.sensor.value  = 0.9
    SensorT.pumpv.sensor.max    = 2.5

    SensorT.status.sensor.value  = 0
    SensorT.status.sensor.max    = 0
    SensorT.status.text          = 'RC Off'
  else
    SensorT.rpm.sensor.value  = 99999
    SensorT.rpm.sensor.max    = 156693

    SensorT.rpm2.sensor.value = 2433
    SensorT.rpm2.sensor.max   = 5252

    SensorT.egt.sensor.value  = 435
    SensorT.egt.sensor.max    = 757

    SensorT.fuel.sensor.value  = 2501
    SensorT.fuel.sensor.max    = 2501
    SensorT.fuel.percent       = 30

    SensorT.ecuv.sensor.value  = 7.0
    SensorT.ecuv.sensor.max    = 7.5
    SensorT.ecuv.percent       = 20

    SensorT.pumpv.sensor.value  = 0.7
    SensorT.pumpv.sensor.max    = 2.0

    SensorT.status.sensor.value  = 0
    SensorT.status.sensor.max    = 0
    SensorT.status.text          = 'Idle'
  end


end


return fakesensor