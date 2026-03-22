
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

local sensorhelper = {}

--------------------------------------------------------------------
-- Generates a sensor menu, returns sensor table and index choice for GUI generation
function sensorhelper.getSensorTable(sensorID)
    local tmpSensorTable = {"..."}
    local tmpMenuTable   = {"..."}
    local tmpIndex = 1

    for _, sensor in ipairs(system.getSensors()) do
        if(sensor.param == 0) then

            tmpSensorTable[#tmpSensorTable + 1] = sensor
            tmpMenuTable[#tmpMenuTable + 1] = sensor.label

            if(sensor.id==sensorID) then
                tmpIndex=#tmpMenuTable
            end      
        end
    end
    collectgarbage()

    return tmpSensorTable, tmpMenuTable, tmpIndex
end


return sensorhelper