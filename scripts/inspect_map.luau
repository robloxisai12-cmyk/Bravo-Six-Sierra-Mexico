-- Read-only inspection. This script never writes to the original .rbxl.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local input = "Mapa Origen RP Roblox.rbxl"
assert(fs.isFile(input), "ERROR: no existe el mapa de entrada: " .. input)

local place = roblox.deserializePlace(fs.readFile(input))

local function listChildren(parent, indent)
    local children = parent:GetChildren()
    table.sort(children, function(a, b)
        if a.Name == b.Name then
            return a.ClassName < b.ClassName
        end
        return a.Name < b.Name
    end)
    for _, child in children do
        print(string.rep("  ", indent) .. "- " .. child.Name .. " [" .. child.ClassName .. "]")
    end
end

local function getPath(path)
    local current = place
    for part in string.gmatch(path, "[^%.]+") do
        current = current:FindFirstChild(part)
        if not current then return nil end
    end
    return current
end

print("READ-ONLY MAP INSPECTION")
print("Input: " .. input)
print("No instance is changed and no output place is created.")
print("")

local paths = {
    "ReplicatedStorage",
    "ServerScriptService",
    "StarterPlayer.StarterPlayerScripts",
    "ReplicatedStorage.Shared",
    "ServerScriptService.Server",
    "ReplicatedStorage.Client",
}
for _, path in paths do
    local instance = getPath(path)
    print("## " .. path .. (instance and (" [" .. instance.ClassName .. "]") or " [MISSING]"))
    if instance then listChildren(instance, 1) end
    print("")
end

local expected = {
    ["ReplicatedStorage.Shared"] = {"Config", "VehicleConfig"},
    ["ServerScriptService.Server"] = {"Bootstrap", "Services"},
    ["StarterPlayer.StarterPlayerScripts"] = {"HUD", "DeployMenu", "VehicleHUD"},
}
print("## Proposed injection name-collision check (direct children only)")
for path, names in expected do
    local parent = getPath(path)
    if not parent then
        print("BLOCKED: destination missing: " .. path)
    else
        for _, name in names do
            local existing = parent:FindFirstChild(name)
            print(path .. "/" .. name .. ": " .. (existing and ("COLLISION [" .. existing.ClassName .. "]") or "free"))
        end
    end
end
print("")

print("## Template scripts and loader/character-spawn indicators")
local scripts = {}
for _, instance in place:GetDescendants() do
    if instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
        table.insert(scripts, instance)
    end
end
table.sort(scripts, function(a, b) return a:GetFullName() < b:GetFullName() end)
print("Script/LocalScript/ModuleScript instances found: " .. tostring(#scripts))
for _, instance in scripts do
    local sourceOk, source = pcall(function() return instance.Source end)
    local indicators = {}
    if sourceOk and type(source) == "string" then
        local patterns = {
            {"require(", "require("},
            {"GetDescendants(", "GetDescendants("},
            {"GetChildren(", "GetChildren("},
            {"CharacterAutoLoads", "CharacterAutoLoads"},
            {"LoadCharacter", "LoadCharacter"},
            {"SpawnLocation", "SpawnLocation"},
            {"CharacterAdded", "CharacterAdded"},
            {"Bootstrapper", "Bootstrapper"},
            {"WaitForChild", "WaitForChild"},
        }
        for _, entry in patterns do
            if string.find(source, entry[1], 1, true) then
                table.insert(indicators, entry[2])
            end
        end
        print("- " .. instance:GetFullName() .. " [" .. instance.ClassName .. "]" ..
            (#indicators > 0 and (" | indicators: " .. table.concat(indicators, ", ")) or ""))
        if #indicators > 0 then
            for line in string.gmatch(source, "[^\n]+") do
                if string.find(line, "require(", 1, true)
                    or string.find(line, "CharacterAutoLoads", 1, true)
                    or string.find(line, "LoadCharacter", 1, true)
                    or string.find(line, "SpawnLocation", 1, true)
                    or string.find(line, "GetChildren(", 1, true)
                    or string.find(line, "GetDescendants(", 1, true) then
                    print("    " .. string.sub(line, 1, 240))
                end
            end
        end
    else
        print("- " .. instance:GetFullName() .. " [" .. instance.ClassName .. "] | SOURCE_UNREADABLE")
    end
end
