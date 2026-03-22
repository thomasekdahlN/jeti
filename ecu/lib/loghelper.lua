
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

local loghelper = {}

local appName = "ECU"

local function writeLog(level, scope, message, seconds)
    local safeMessage = tostring(message)
    local prefix

    if(scope and scope ~= "") then
        prefix = string.format("[%s][%s][%s] %s", appName, level, scope, safeMessage)
    else
        prefix = string.format("[%s][%s] %s", appName, level, safeMessage)
    end

    print(prefix)

    if(seconds and seconds > 0) then
        system.messageBox(safeMessage, seconds)
    end
end

function loghelper.init(name)
    if(type(name) == "string" and name ~= "") then
        appName = name
    end
end

function loghelper.info(scope, message)
    writeLog("INFO", scope, message)
end

function loghelper.warn(scope, message, seconds)
    writeLog("WARN", scope, message, seconds)
end

function loghelper.error(scope, message, seconds)
    writeLog("ERROR", scope, message, seconds)
end

return loghelper