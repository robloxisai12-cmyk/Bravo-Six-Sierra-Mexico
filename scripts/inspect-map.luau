-- Read-only inspection of the original place file. Never serializes or writes the map.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local mapPath = "Mapa Origen RP Roblox.rbxl"
local outputPath = "inspection/map-structure.txt"
assert(fs.isFile(mapPath), "No se encontró el mapa original: " .. mapPath)

local report = {}
local function out(line)
    table.insert(report, line)
    print(line)
end

local bytes = fs.readFile(mapPath)
out("READ-ONLY MAP INSPECTION")
out("File: " .. mapPath)
out("Bytes: " .. tostring(#bytes))
out("Lune place deserialization: starting")
local ok, dataModelOrError = pcall(function()
    return roblox.deserializePlace(bytes)
end)
if not ok then
    out("FATAL: deserializePlace failed: " .. tostring(dataModelOrError))
    fs.writeDir("inspection")
    fs.writeFile(outputPath, table.concat(report, "\n") .. "\n")
    error("No se pudo inspeccionar el mapa; no se ha modificado el archivo original.")
end

local dataModel = dataModelOrError
local replicatedStorage = dataModel:GetService("ReplicatedStorage")
local serverScriptService = dataModel:GetService("ServerScriptService")
local starterPlayer = dataModel:GetService("StarterPlayer")
local starterPlayerScripts = assert(starterPlayer:FindFirstChild("StarterPlayerScripts"), "StarterPlayerScripts no existe en el mapa")

local function listChildren(label, parent)
    out("")
    out("[" .. label .. "]")
    for _, child in parent:GetChildren() do
        out(string.format("- %s (%s)", child.Name, child.ClassName))
    end
end

listChildren("ReplicatedStorage direct children", replicatedStorage)
listChildren("ServerScriptService direct children", serverScriptService)
listChildren("StarterPlayer.StarterPlayerScripts direct children", starterPlayerScripts)

for _, pair in {
    { "ReplicatedStorage.Shared direct children", replicatedStorage:FindFirstChild("Shared") },
    { "ServerScriptService.Server direct children", serverScriptService:FindFirstChild("Server") },
    { "ReplicatedStorage.Client direct children", replicatedStorage:FindFirstChild("Client") },
} do
    if pair[2] then
        listChildren(pair[1], pair[2])
    else
        out("")
        out("[" .. pair[1] .. "] NOT FOUND")
    end
end

out("")
out("[Collision check for proposed merge children]")
local function checkCollision(label, target, names)
    out(label .. ":")
    if not target then
        out("  TARGET MISSING")
        return
    end
    for _, name in names do
        local found = target:FindFirstChild(name)
        out(string.format("  %s: %s", name, found and ("COLLISION (" .. found.ClassName .. ")") or "free"))
    end
end
checkCollision("ReplicatedStorage.Shared", replicatedStorage:FindFirstChild("Shared"), { "Config", "VehicleConfig" })
checkCollision("ServerScriptService.Server", serverScriptService:FindFirstChild("Server"), { "Bootstrap", "Services" })
checkCollision("StarterPlayer.StarterPlayerScripts", starterPlayerScripts, { "HUD", "DeployMenu", "VehicleHUD" })

out("")
out("[Scripts and relevant source lines]")
local roots = { replicatedStorage, serverScriptService, starterPlayerScripts }
local patterns = {
    "require", "GetChildren", "GetDescendants", "FindFirstChild",
    "WaitForChild", "CharacterAutoLoads", "LoadCharacter",
    "SpawnLocation", "PlayerService", "MapAccessService",
    "Bootstrapper", "TelemetryBootstrap", "StarterPlayerScripts",
}
local scriptCount = 0
for _, root in roots do
    for _, inst in root:GetDescendants() do
        if inst:IsA("LuaSourceContainer") then
            scriptCount += 1
            local fullPath = inst:GetFullName()
            out("")
            out("SCRIPT: " .. fullPath .. " (" .. inst.ClassName .. ")")
            local sourceOk, source = pcall(function()
                return inst.Source
            end)
            if not sourceOk or type(source) ~= "string" then
                out("  SOURCE UNAVAILABLE to inspector")
            else
                local lowerPath = string.lower(fullPath)
                local dumpFullSource = string.find(lowerPath, "bootstrapperlogic", 1, true)
                    or string.find(lowerPath, "playerservice", 1, true)
                    or string.find(lowerPath, "mapaccessservice", 1, true)
                    or string.find(lowerPath, "telemetrybootstrap", 1, true)
                local matched = 0
                for lineNumber, line in string.split(source, "\n") do
                    if dumpFullSource then
                        out(string.format("  L%d: %s", lineNumber, string.sub(line, 1, 300)))
                        matched += 1
                    else
                        for _, pattern in patterns do
                            if string.find(string.lower(line), string.lower(pattern), 1, true) then
                                out(string.format("  L%d: %s", lineNumber, string.sub(line, 1, 240)))
                                matched += 1
                                break
                            end
                        end
                    end
                end
                if matched == 0 then
                    out("  (no loader/spawn pattern matched)")
                end
            end
        end
    end
end
out("")
out("Total scripts scanned under inspected services: " .. tostring(scriptCount))
out("")
out("SAFETY: This script only reads the source .rbxl and writes this report. It does not serialize, overwrite, or publish the map.")

fs.writeDir("inspection")
fs.writeFile(outputPath, table.concat(report, "\n") .. "\n")
print("Wrote report: " .. outputPath)
