
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

local tablehelper = {}
local logh = require "ecu/lib/loghelper"

--------------------------------------------------------------------
-- Read all folders and put it in a table to be used to create a menu
function tablehelper.fromDirectory(path, choice)
    local tmpTable = {"..."}
    local tmpIndex = 1
    local ok
    local iterator
    local state
    local control

    if(type(path) ~= "string" or path == "") then
        logh.error("tablehelper.fromDirectory", string.format("Invalid directory path: %s", tostring(path)))
        return tmpTable, tmpIndex
    end

    ok, iterator, state, control = pcall(dir, path)
    if(not ok) then
        logh.error("tablehelper.fromDirectory", string.format("Directory scan failed: %s (%s)", path, tostring(iterator)))
        return tmpTable, tmpIndex
    end

    if(not iterator) then
        logh.error("tablehelper.fromDirectory", string.format("Directory iterator missing: %s", path))
        return tmpTable, tmpIndex
    end

    for name, filetype, _ in iterator, state, control do
        if(filetype == "folder" and string.sub(name, 1, 1) ~= ".") then
            tmpTable[#tmpTable + 1] = name

            if(name == choice) then
                tmpIndex=#tmpTable
            end
        end
    end
    collectgarbage()

    return tmpTable, tmpIndex
end

--------------------------------------------------------------------
-- Read all files in a folder and put it in a table to be used to create a menu
function tablehelper.fromFiles(path, choice)
    local tmpTable = {"..."}
    local tmpIndex = 1
    local ok
    local iterator
    local state
    local control

    collectgarbage()

    if(type(path) ~= "string" or path == "") then
        logh.error("tablehelper.fromFiles", string.format("Invalid file path: %s", tostring(path)))
        return tmpTable, tmpIndex
    end

    ok, iterator, state, control = pcall(dir, path)
    if(not ok) then
        logh.error("tablehelper.fromFiles", string.format("File scan failed: %s (%s)", path, tostring(iterator)))
        return tmpTable, tmpIndex
    end

    if(not iterator) then
        logh.error("tablehelper.fromFiles", string.format("File iterator missing: %s", path))
        return tmpTable, tmpIndex
    end

    for name, _, _ in iterator, state, control do
        if(string.sub(name, -3, -1) == "jsn" and string.sub(name, 1, 1) ~= ".") then
            tmpTable[#tmpTable + 1] = string.sub(name, 1, -5)
            
            if (choice) then
                if(string.sub(name, 1, -5) == choice) then
                    tmpIndex=#tmpTable
                end
            end
        end
    end

    return tmpTable, tmpIndex
end

return tablehelper