
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

local loadhelper = {}
local logh = require "ecu/lib/loghelper"

--------------------------------------------------------------------
-- Load generic fuel config 
function loadhelper.fileJson(filename)
    local decodeOk
    local structure
    local file = io.readall(filename)

    collectgarbage()

    if(not file) then
        logh.error("loadhelper.fileJson", string.format("File not found: %s", filename))
        return nil
    end

    decodeOk, structure = pcall(json.decode, file)
    if(not decodeOk) then
        logh.error("loadhelper.fileJson", string.format("JSON decode failed: %s (%s)", filename, structure))
        return nil
    end

    if(structure) then
        return structure
    end

    logh.error("loadhelper.fileJson", string.format("Invalid jsn format: %s", filename))
    return nil
end

return loadhelper