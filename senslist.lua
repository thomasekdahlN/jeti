-- #############################################################################
-- # senslist.lua - Jeti sensor discovery utility
-- #
-- # Prints every telemetry sensor with full metadata and live values.
-- # Writes one JSON discovery file per top-level sensor to Apps/<label>.jsn
-- # The file is overwritten each run ("w" mode truncates existing content).
-- #
-- # Usage: install as a temporary app, power the ECU/converter so live
-- # telemetry is available, then run. Check the debug console for output.
-- #
-- # V1.1 - Extended: all descriptor fields, live values, valid JSON output
-- #############################################################################

-- GPS-type sensors (5, 9) have non-numeric data structures and are skipped.
local GPS_TYPES = { [5] = true, [9] = true }

local sensorGroups = {}  -- list of { id, label, children = { ... } }
local done         = false

-- ---------------------------------------------------------------------------
local function writeFile(group)
    local path = string.format("Apps/%s.jsn", group.label)
    local file = io.open(path, "w")  -- "w" creates or truncates (overwrites)

    if not file then
        print(string.format("[senslist] ERROR: cannot open for writing: %s", path))
        return
    end

    io.write(file, "{\n")
    io.write(file, string.format("    \"id\"      : %s,\n", tostring(group.id)))
    io.write(file, string.format("    \"label\"   : \"%s\",\n", tostring(group.label)))
    io.write(file, "    \"sensors\" : {\n")

    local children = group.children
    for i, s in ipairs(children) do
        local last   = (i == #children)
        local comma  = last and "" or ","

        io.write(file, string.format("        \"%s\" : {\n", tostring(s.label)))
        io.write(file, string.format("            \"param\"    : %s,\n",    tostring(s.param)))
        io.write(file, string.format("            \"unit\"     : \"%s\",\n", tostring(s.unit     or "")))
        io.write(file, string.format("            \"type\"     : %s,\n",    tostring(s.type     or 0)))
        io.write(file, string.format("            \"decimals\" : %s,\n",    tostring(s.decimals or 0)))
        io.write(file, string.format("            \"value\"    : %s,\n",    tostring(s.value    or 0)))
        io.write(file, string.format("            \"max\"      : %s,\n",    tostring(s.max      or 0)))
        io.write(file, string.format("            \"valid\"    : %s\n",     tostring(s.valid    or false)))
        io.write(file, string.format("        }%s\n", comma))
    end

    io.write(file, "    }\n")
    io.write(file, "}\n")

    -- Protect close against Jeti returning a non-standard file handle
    pcall(function() io.close(file) end)
    print(string.format("[senslist] Written: %s", path))
end

-- ---------------------------------------------------------------------------
local function printGroup(group)
    print(string.format("=== %s  (id=%s) ===", group.label, tostring(group.id)))
    for _, s in ipairs(group.children) do
        print(string.format(
            "  param=%-3s  label=%-14s  unit=%-6s  type=%s  dec=%s  value=%-10s  max=%-10s  valid=%s",
            tostring(s.param),
            tostring(s.label),
            tostring(s.unit     or ""),
            tostring(s.type     or ""),
            tostring(s.decimals or ""),
            tostring(s.value    or ""),
            tostring(s.max      or ""),
            tostring(s.valid    or false)
        ))
    end
end

-- ---------------------------------------------------------------------------
local function init()
    local raw    = system.getSensors()
    local parent = nil

    for _, sensor in ipairs(raw) do
        if not GPS_TYPES[sensor.type] then
            if sensor.param == 0 then
                -- Top-level sensor entry (device label)
                parent = {
                    id       = sensor.id,
                    label    = sensor.label,
                    children = {}
                }
                sensorGroups[#sensorGroups + 1] = parent
            elseif parent then
                -- Sub-sensor: store all descriptor fields now; live values added in loop()
                parent.children[#parent.children + 1] = {
                    param    = sensor.param,
                    label    = sensor.label,
                    unit     = sensor.unit,
                    type     = sensor.type,
                    decimals = sensor.decimals,
                    id       = sensor.id
                }
            end
        end
    end

    print(string.format("[senslist] Found %d sensor group(s) - waiting for live data...", #sensorGroups))
end

-- ---------------------------------------------------------------------------
local function loop()
    if done then return end

    -- Fetch live values for every sub-sensor
    for _, group in ipairs(sensorGroups) do
        for _, child in ipairs(group.children) do
            local live = system.getSensorByID(group.id, child.param)
            if live then
                child.value = live.value
                child.max   = live.max
                child.valid = live.valid
            end
        end
    end

    -- Print to debug console and write one file per top-level sensor group
    for _, group in ipairs(sensorGroups) do
        printGroup(group)
        writeFile(group)
    end

    done = true
    print("[senslist] Done.")
end

-- ---------------------------------------------------------------------------
return {
    init    = init,
    loop    = loop,
    author  = "Thomas Ekdahl",
    version = "1.1",
    name    = "SensorList"
}