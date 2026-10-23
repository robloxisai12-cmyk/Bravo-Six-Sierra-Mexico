-- Merge only the approved Bravo Six code instances into the original map.
-- The source map is read-only; only BravoSix-merged.rbxl is written.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local MAP_PATH = "Mapa Origen RP Roblox.rbxl"
local BUILD_PATH = "build/BravoSix-src.rbxl"
local OUTPUT_PATH = "BravoSix-merged.rbxl"

local function child(parent, name, context)
    assert(parent ~= nil, "Missing parent while locating " .. context)
    local result = parent:FindFirstChild(name)
    assert(result ~= nil, "Missing required instance " .. context .. "." .. name)
    return result
end

local function path(root, names, context)
    local current = root
    for _, name in ipairs(names) do
        current = child(current, name, context)
        context = context .. "." .. name
    end
    return current
end

local function checkAndCopy(sourceParent, destinationParent, names, context)
    local pending = {}
    for _, name in ipairs(names) do
        local source = child(sourceParent, name, context .. " source")
        assert(
            destinationParent:FindFirstChild(name) == nil,
            "Collision: " .. context .. "." .. name .. " already exists in the original map; refusing to overwrite it."
        )
        table.insert(pending, source)
    end

    for _, source in ipairs(pending) do
        local copy = source:Clone()
        copy.Parent = destinationParent
        print("Injected " .. context .. "." .. source.Name .. " (" .. source.ClassName .. ")")
    end
end

local originalBytes = fs.readFile(MAP_PATH)
local sourceBytes = fs.readFile(BUILD_PATH)
assert(string.len(originalBytes) > 0, "Original map file is empty.")
assert(string.len(sourceBytes) > 0, "Rojo build file is empty.")

local original = roblox.deserializePlace(originalBytes)
local built = roblox.deserializePlace(sourceBytes)

local originalShared = path(original, {"ReplicatedStorage", "Shared"}, "original")
local originalServer = path(original, {"ServerScriptService", "Server"}, "original")
local originalStarterScripts = path(original, {"StarterPlayer", "StarterPlayerScripts"}, "original")

local builtShared = path(built, {"ReplicatedStorage", "Shared"}, "Rojo build")
local builtServer = path(built, {"ServerScriptService", "Server"}, "Rojo build")
local builtStarterScripts = path(built, {"StarterPlayer", "StarterPlayerScripts", "Client"}, "Rojo build")

-- These are the only approved top-level children. Never replace existing map folders.
checkAndCopy(builtShared, originalShared, {"Config", "VehicleConfig"}, "ReplicatedStorage.Shared")
checkAndCopy(builtServer, originalServer, {"Bootstrap", "Services"}, "ServerScriptService.Server")
checkAndCopy(builtStarterScripts, originalStarterScripts, {"HUD", "DeployMenu", "VehicleHUD"}, "StarterPlayer.StarterPlayerScripts")

-- Check that the service folder contains exactly the two expected service modules.
local services = child(originalServer, "Services", "ServerScriptService.Server")
assert(child(services, "TerritoryService", "ServerScriptService.Server.Services"), "Missing TerritoryService")
assert(child(services, "VehicleService", "ServerScriptService.Server.Services"), "Missing VehicleService")

local mergedBytes = roblox.serializePlace(original)
assert(mergedBytes ~= nil and string.len(mergedBytes) > 0, "Serialization produced an empty place.")
fs.writeFile(OUTPUT_PATH, mergedBytes)

print("Merge complete. Original map was not modified.")
print("Output: " .. OUTPUT_PATH .. " (" .. tostring(string.len(mergedBytes)) .. " bytes)")
