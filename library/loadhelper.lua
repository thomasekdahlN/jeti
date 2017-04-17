
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

--------------------------------------------------------------------
-- Load generic fuel config 
function loadhelper.fileJson(filename)
    -- print("Mem before config: ", collectgarbage("count"))
    local structure
    local file = io.readall(filename)
    if(file) then
          structure = json.decode(file)
        if(structure) then
            return structure
        else
            print(string.format("Invalid jsn format: %s", filename))
        end
    else
        print(string.format("File not found: %s", filename))
    end
    collectgarbage()
    print(string.format("%s - mem: %s", filename, collectgarbage("count")))
end 

return loadhelper