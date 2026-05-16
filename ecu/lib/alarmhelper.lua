
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

local alarmhelper = {}
local logh = require "ecu/lib/loghelper"

local canMessage = function()
    return true
end

local canHaptic = function()
    return true
end

local canAudio = function()
    return true
end

local audioRoot = "Apps/ecu/audio"

----------------------------------------------------------------------
-- Initialize state providers from the main application.
function alarmhelper.init(messageProvider, hapticProvider, audioProvider, appRoot)
    if(type(messageProvider) == "function") then
        canMessage = messageProvider
    end

    if(type(hapticProvider) == "function") then
        canHaptic = hapticProvider
    end

    if(type(audioProvider) == "function") then
        canAudio = audioProvider
    end

    if(appRoot) then
        audioRoot = string.format("%s/audio", appRoot)
    end
end


----------------------------------------------------------------------
-- 
function alarmhelper.All(tmpConfig, StatusText)
    if(not tmpConfig) then
        return
    end

    alarmhelper.Message(tmpConfig.message, StatusText)
    alarmhelper.Haptic(tmpConfig.haptic)
    alarmhelper.Audio(tmpConfig.audio)
end

----------------------------------------------------------------------
-- 
function alarmhelper.Message(tmpConfig, StatusText)
    if(tmpConfig and tmpConfig.enable and canMessage()) then
        system.messageBox(string.format("ECU: %s", StatusText), tmpConfig.seconds)
    end
end

----------------------------------------------------------------------
-- 
function alarmhelper.Haptic(tmpConfig)
    if(tmpConfig and tmpConfig.enable and canHaptic()) then
        -- If vibration/haptic associated with status, we vibrate
        if(tmpConfig.stick == 'left') then
            system.vibration(false, tmpConfig.vibrationProfile)
        elseif(tmpConfig.stick == 'right') then
            system.vibration(true, tmpConfig.vibrationProfile)
        end
    end
end


----------------------------------------------------------------------
-- 
function alarmhelper.Audio(tmpConfig)
    local audioPath
    local audioFile

    if(tmpConfig and tmpConfig.enable and canAudio() and tmpConfig.file) then
        audioPath = string.format("/%s/%s", audioRoot, tmpConfig.file)
        audioFile = io.open(audioPath, "r")

        if(audioFile) then
            pcall(function() audioFile:close() end)
            system.playFile(audioPath, AUDIO_QUEUE)
        else
            logh.warn("alarmhelper.Audio", string.format("Missing audio file: %s", audioPath))
        end
    end
end

return alarmhelper