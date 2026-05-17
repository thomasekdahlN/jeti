-- #############################################################################
-- # senslist.lua - Sensor discovery utility
-- #
-- # Shows all telemetry sensors with live values in the Applications menu.
-- # F1 = Refresh display   F5 = Write JSON files to Apps/<label>.jsn
-- #
-- # V3.0 - Applications menu only, no telemetry window
-- #############################################################################

-- GPS-type sensors (5, 9) have non-numeric data structures and are skipped.
local GPS_TYPES = { [5] = true, [9] = true }

local sensorGroups = {}  -- { id, label, children={param,label,unit,type,decimals,value,max,valid} }
local statusMsg    = ""
local statusExpiry = 0

-- ---------------------------------------------------------------------------
local function collectSensors()
    local raw    = system.getSensors()
    local parent = nil
    sensorGroups = {}

    for _, s in ipairs(raw) do
        if not GPS_TYPES[s.type] then
            if s.param == 0 then
                parent = { id = s.id, label = s.label, children = {} }
                sensorGroups[#sensorGroups + 1] = parent
            elseif parent then
                parent.children[#parent.children + 1] = {
                    param    = s.param,
                    label    = s.label,
                    unit     = s.unit     or "",
                    type     = s.type     or 0,
                    decimals = s.decimals or 0,
                    value    = 0,
                    max      = 0,
                    valid    = false,
                }
            end
        end
    end

    print(string.format("[senslist] Found %d sensor group(s)", #sensorGroups))
end

-- ---------------------------------------------------------------------------
local function pollValues()
    for _, g in ipairs(sensorGroups) do
        for _, c in ipairs(g.children) do
            local live = system.getSensorByID(g.id, c.param)
            if live then
                c.value = live.value
                c.max   = live.max
                c.valid = live.valid
            end
        end
    end
end

-- ---------------------------------------------------------------------------
local function writeFile(group)
    local path = string.format("Apps/%s.jsn", group.label)
    local file = io.open(path, "w")
    if not file then
        print(string.format("[senslist] ERROR: cannot open: %s", path))
        return
    end
    local ch = group.children
    io.write(file, "{\n")
    io.write(file, string.format("    \"id\"      : %s,\n",     tostring(group.id)))
    io.write(file, string.format("    \"label\"   : \"%s\",\n", tostring(group.label)))
    io.write(file, "    \"sensors\" : {\n")
    for i, s in ipairs(ch) do
        local comma = (i == #ch) and "" or ","
        local fmt   = "%." .. tostring(s.decimals) .. "f"
        io.write(file, string.format("        \"%s\" : {\n",           tostring(s.label)))
        io.write(file, string.format("            \"param\"    : %s,\n",    tostring(s.param)))
        io.write(file, string.format("            \"unit\"     : \"%s\",\n", tostring(s.unit)))
        io.write(file, string.format("            \"type\"     : %s,\n",    tostring(s.type)))
        io.write(file, string.format("            \"decimals\" : %s,\n",    tostring(s.decimals)))
        io.write(file, string.format("            \"value\"    : %s,\n",    string.format(fmt, s.value or 0)))
        io.write(file, string.format("            \"max\"      : %s,\n",    string.format(fmt, s.max   or 0)))
        io.write(file, string.format("            \"valid\"    : %s\n",     tostring(s.valid or false)))
        io.write(file, "        }" .. comma .. "\n")
    end
    io.write(file, "    }\n}\n")
    pcall(function() io.close(file) end)
    print(string.format("[senslist] Written: %s", path))
end

-- ---------------------------------------------------------------------------
local function writeAllFiles()
    local count = 0
    for _, group in ipairs(sensorGroups) do
        writeFile(group)
        count = count + 1
    end
    statusMsg    = string.format("Saved %d file(s) - see Apps/*.jsn", count)
    statusExpiry = system.getTime() + 10
    print(string.format("[senslist] %s", statusMsg))
end

-- ---------------------------------------------------------------------------
local function initForm(subform)
    -- Status line or instructions
    if statusExpiry > system.getTime() then
        form.addLabel({ label = statusMsg, font = FONT_MINI })
    else
        form.addLabel({ label = "F1=Refresh  F5=Save JSON files", font = FONT_MINI })
    end

    -- One row per sensor
    for _, g in ipairs(sensorGroups) do
        form.addLabel({ label = string.format("--- %s (id=%s) ---", g.label, tostring(g.id)), font = FONT_MINI })
        for _, c in ipairs(g.children) do
            local fmt = "%." .. tostring(c.decimals) .. "f"
            local val = string.format(fmt, c.value or 0)
            local flg = c.valid and "" or " ?"
            form.addLabel({ label = string.format("P%-2s %-10s %s%s %s", c.param, c.label, val, flg, c.unit), font = FONT_MINI })
        end
    end

    if #sensorGroups == 0 then
        form.addLabel({ label = "No sensors found", font = FONT_MINI })
    end
end

-- ---------------------------------------------------------------------------
local function keyPressed(key)
    if key == KEY_5 then
        writeAllFiles()
    end
    form.reinit(1)  -- always refresh the form so values and status update
end

-- ---------------------------------------------------------------------------
local function init()
    collectSensors()
    system.registerForm(1, MENU_APPS, "SensorList", initForm, keyPressed)
end

local function loop()
    pollValues()
end

-- ---------------------------------------------------------------------------
return {
    init    = init,
    loop    = loop,
    author  = "Thomas Ekdahl",
    version = "3.0",
    name    = "SensorList"
}