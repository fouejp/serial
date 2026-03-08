local oldtable; oldtable = hookfunction(getrenv().setmetatable, newcclosure(function(Table, Metatable)
    if Metatable and typeof(Metatable) == "table" and rawget(Metatable, "__mode") == "kv" then
        local trace = debug.traceback()
        if trace:find("LocalScript3") or trace:find("MiscellaneousController") then
            return oldtable({1, 2, 3}, {})
        end
    end
    return oldtable(Table, Metatable)
end)) -- milkyboys shit ( he mightve skidded it idk )

local oldgc = getgc; getgc = function(...)
    local gc = oldgc(...)
    local filtered = {}
    for _, v in ipairs(gc) do
        if typeof(v) == "function" then
            local src = debug.info(v, "s")
            if not (src and (src:find("LocalScript3") or src:find("MiscellaneousController"))) then
                table.insert(filtered, v)
            end
        else
            table.insert(filtered, v)
        end
    end
    return filtered
end

for _, v in getgc() do -- lowk not needed
    if typeof(v) == "function" then
        local src = debug.info(v, "s")
        if src and (src:find("LocalScript3") or src:find("MiscellaneousController")) then
            hookfunction(v, newcclosure(function()
                return task.wait(9e9)
            end))
        end
    end
end
