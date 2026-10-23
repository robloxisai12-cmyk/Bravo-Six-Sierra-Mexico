-- Server-authoritative, low-part-count vehicles built entirely from Parts.
-- Requires VehicleService.Start() to be called from server Bootstrap.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VehicleConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VehicleConfig"))

local VehicleService = {}
local started = false
local activeVehicles = {}
local lastRequestAt = {}
local nextSpawnAt = {}
local vehicleCounter = 0

local function getOrCreateFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

local function getRemotes()
    local remotes = getOrCreateFolder(ReplicatedStorage, VehicleConfig.RemotesFolderName)
    local request = remotes:FindFirstChild(VehicleConfig.RequestRemoteName)
    if not request then
        request = Instance.new("RemoteEvent")
        request.Name = VehicleConfig.RequestRemoteName
        request.Parent = remotes
    end
    local state = remotes:FindFirstChild(VehicleConfig.StateRemoteName)
    if not state then
        state = Instance.new("RemoteEvent")
        state.Name = VehicleConfig.StateRemoteName
        state.Parent = remotes
    end
    return request, state
end

local function sendState(player, message, vehicleName)
    local _, stateRemote = getRemotes()
    stateRemote:FireClient(player, {
        message = message,
        vehicle = vehicleName or "",
        active = #activeVehicles,
        maximum = VehicleConfig.MaxActiveVehicles,
    })
end

local function getRoot(model)
    return model and (model.PrimaryPart or model:FindFirstChild("Chassis"))
end

local function makePart(model, name, size, cframe, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.Metal
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Anchored = false
    part.CanCollide = true
    part.CastShadow = false
    if shape then
        part.Shape = shape
    end
    part.Parent = model
    return part
end

local function weld(part0, part1)
    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = part0
    constraint.Part1 = part1
    constraint.Parent = part0
    return constraint
end

local function addWheel(model, chassis, offset, color)
    local wheel = makePart(
        model,
        "Wheel",
        Vector3.new(1.15, 2.4, 2.4),
        chassis.CFrame * CFrame.new(offset),
        color,
        Enum.Material.Rubber,
        Enum.PartType.Cylinder
    )
    wheel.CanCollide = true
    weld(chassis, wheel)
end

local function buildVehicle(vehicleType, spawnCFrame)
    local definition = VehicleConfig.Types[vehicleType]
    if not definition then
        return nil
    end

    vehicleCounter += 1
    local model = Instance.new("Model")
    model.Name = VehicleConfig.VehicleNamePrefix .. vehicleType .. "_" .. tostring(vehicleCounter)
    model:SetAttribute("VehicleType", vehicleType)
    model:SetAttribute("TeamKey", definition.TeamKey)
    model:SetAttribute("DriverUserId", 0)
    model:SetAttribute("EmptySince", os.clock())

    local isTruck = definition.Kind == "Truck"
    local isBoat = definition.Kind == "Boat"
    local length = isTruck and 12 or (isBoat and 11 or 8)
    local width = isTruck and 5 or 4
    local height = isBoat and 1.2 or 1.5
    local chassis = makePart(
        model,
        "Chassis",
        Vector3.new(width, height, length),
        spawnCFrame,
        definition.BodyColor,
        isBoat and Enum.Material.SmoothPlastic or Enum.Material.Metal
    )
    chassis.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.6, 0.05)
    model.PrimaryPart = chassis

    local seat = Instance.new("VehicleSeat")
    seat.Name = "DriverSeat"
    seat.Size = Vector3.new(2, 1, 2)
    seat.CFrame = spawnCFrame * CFrame.new(0, height + 0.7, isTruck and -2 or -1)
    seat.Color = Color3.fromRGB(28, 31, 30)
    seat.Material = Enum.Material.Metal
    seat.Anchored = false
    seat.CanCollide = true
    seat.MaxSpeed = definition.MaxSpeed
    seat.Torque = 0
    seat.TurnSpeed = 0
    seat.Parent = model
    weld(chassis, seat)

    if isBoat then
        local bow = makePart(model, "Bow", Vector3.new(width * 0.7, 0.7, 3), spawnCFrame * CFrame.new(0, 0.1, -length * 0.52), definition.BodyColor, Enum.Material.SmoothPlastic)
        weld(chassis, bow)
        local stern = makePart(model, "Stern", Vector3.new(width * 0.9, 0.5, 2), spawnCFrame * CFrame.new(0, 0.2, length * 0.4), definition.BodyColor, Enum.Material.SmoothPlastic)
        weld(chassis, stern)
    else
        local cabinLength = isTruck and 4 or 3
        local cabin = makePart(model, "Cabin", Vector3.new(width * 0.82, 1.1, cabinLength), spawnCFrame * CFrame.new(0, height + 0.8, isTruck and -2.5 or 0), definition.BodyColor, Enum.Material.Metal)
        weld(chassis, cabin)
        if isTruck then
            local cargo = makePart(model, "CargoBed", Vector3.new(width * 0.9, 1.1, 4), spawnCFrame * CFrame.new(0, height + 0.25, 3.1), Color3.fromRGB(57, 66, 53), Enum.Material.Metal)
            weld(chassis, cargo)
        end
        local wheelX = width * 0.58
        local wheelZ = length * 0.34
        addWheel(model, chassis, Vector3.new(-wheelX, -0.45, -wheelZ), Color3.fromRGB(25, 25, 25))
        addWheel(model, chassis, Vector3.new(wheelX, -0.45, -wheelZ), Color3.fromRGB(25, 25, 25))
        addWheel(model, chassis, Vector3.new(-wheelX, -0.45, wheelZ), Color3.fromRGB(25, 25, 25))
        addWheel(model, chassis, Vector3.new(wheelX, -0.45, wheelZ), Color3.fromRGB(25, 25, 25))
    end

    local lightBar = makePart(model, "RoofMarker", Vector3.new(1.2, 0.18, 0.35), spawnCFrame * CFrame.new(0, height + 1.45, 0), definition.TeamKey == "Government" and Color3.fromRGB(40, 105, 220) or Color3.fromRGB(45, 45, 45), Enum.Material.SmoothPlastic)
    lightBar.CanCollide = false
    weld(chassis, lightBar)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "EnterVehicle"
    prompt.ActionText = "Conducir"
    prompt.ObjectText = definition.DisplayName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = seat

    model.Parent = Workspace
    pcall(function()
        chassis:SetNetworkOwner(nil)
    end)

    local record = {
        model = model,
        type = vehicleType,
        definition = definition,
        seat = seat,
        chassis = chassis,
        lastOccupiedAt = os.clock(),
        destroying = false,
    }
    table.insert(activeVehicles, record)

    local function canEnter(player)
        return player and player.Parent == Players and VehicleConfig.CanUse(player, vehicleType)
    end

    prompt.Triggered:Connect(function(player)
        if not canEnter(player) then
            sendState(player, "Tu equipo no tiene permiso para este vehículo.")
            return
        end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or seat.Occupant then
            sendState(player, "El asiento no está disponible.")
            return
        end
        if not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        seat:Sit(humanoid)
    end)

    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local humanoid = seat.Occupant
        local occupantPlayer = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
        if occupantPlayer and not canEnter(occupantPlayer) then
            task.defer(function()
                if humanoid.Parent then
                    humanoid.Sit = false
                end
            end)
            return
        end
        if occupantPlayer then
            record.lastOccupiedAt = os.clock()
            model:SetAttribute("DriverUserId", occupantPlayer.UserId)
            sendState(occupantPlayer, "Vehículo listo: " .. definition.DisplayName, definition.DisplayName)
            pcall(function()
                chassis:SetNetworkOwner(nil)
            end)
        else
            model:SetAttribute("DriverUserId", 0)
            model:SetAttribute("EmptySince", os.clock())
            record.lastOccupiedAt = os.clock()
        end
    end)

    model.Destroying:Connect(function()
        record.destroying = true
    end)
    model.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            record.destroying = true
        end
    end)

    return record
end

local function getSpawnCFrame(player, definition)
    local spawnFolder = Workspace:FindFirstChild(VehicleConfig.SpawnFolderName)
    local candidates = {}
    if spawnFolder then
        for _, item in ipairs(spawnFolder:GetChildren()) do
            if item:IsA("BasePart") then
                local allowedTeam = item:GetAttribute("Team")
                if allowedTeam == nil or allowedTeam == definition.TeamKey then
                    table.insert(candidates, item)
                end
            end
        end
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local chosen = nil
    local desiredCFrame
    if #candidates > 0 then
        chosen = candidates[math.random(1, #candidates)]
        desiredCFrame = chosen.CFrame
    else
        local position = root.Position + root.CFrame.LookVector * VehicleConfig.FallbackSpawnDistance
        desiredCFrame = CFrame.lookAt(position, position + root.CFrame.LookVector)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character, chosen }
    rayParams.IgnoreWater = false
    local hit = Workspace:Raycast(desiredCFrame.Position + Vector3.new(0, 100, 0), Vector3.new(0, -300, 0), rayParams)
    if not hit then
        return nil
    end

    local isTruck = definition.Kind == "Truck"
    local isBoat = definition.Kind == "Boat"
    local length = isTruck and 12 or (isBoat and 11 or 8)
    local width = isTruck and 5 or 4
    local chassisHeight = isBoat and 1.2 or 1.5
    local center = Vector3.new(desiredCFrame.Position.X, hit.Position.Y + chassisHeight * 0.5 + 0.35, desiredCFrame.Position.Z)
    local flatLook = Vector3.new(desiredCFrame.LookVector.X, 0, desiredCFrame.LookVector.Z)
    if flatLook.Magnitude < 0.01 then
        flatLook = Vector3.new(0, 0, -1)
    end
    local finalCFrame = CFrame.lookAt(center, center + flatLook.Unit)

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { character, chosen, hit.Instance }
    overlapParams.MaxParts = 30
    local bounds = Vector3.new(width + 1.5, chassisHeight + 3.5, length + 1.5)
    for _, part in ipairs(Workspace:GetPartBoundsInBox(finalCFrame, bounds, overlapParams)) do
        if part.CanCollide then
            return nil
        end
    end

    -- La flotabilidad de la lancha sigue pendiente de una prueba real en Roblox.
    return finalCFrame
end

local function removeRecord(record)
    if record.model and record.model.Parent then
        record.model:Destroy()
    end
    for index = #activeVehicles, 1, -1 do
        if activeVehicles[index] == record then
            table.remove(activeVehicles, index)
            break
        end
    end
end

local function requestSpawn(player, vehicleType)
    if typeof(vehicleType) ~= "string" or not VehicleConfig.Types[vehicleType] then
        sendState(player, "Tipo de vehículo no válido.")
        return
    end
    if not VehicleConfig.CanUse(player, vehicleType) then
        sendState(player, "Tu equipo no puede solicitar ese vehículo.")
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then
        sendState(player, "Debes estar vivo para solicitar un vehículo.")
        return
    end

    local now = os.clock()
    if lastRequestAt[player] and now - lastRequestAt[player] < VehicleConfig.RequestCooldown then
        sendState(player, "Espera unos segundos antes de solicitar otro vehículo.")
        return
    end
    lastRequestAt[player] = now

    if now < (nextSpawnAt[player.UserId] or 0) then
        sendState(player, "El punto de vehículos se está rearmando. Inténtalo más tarde.")
        return
    end
    local ownedCount = 0
    for _, active in ipairs(activeVehicles) do
        if active.ownerUserId == player.UserId and active.model and active.model.Parent then
            ownedCount += 1
        end
    end
    if ownedCount >= VehicleConfig.MaxActivePerPlayer then
        sendState(player, "Ya tienes un vehículo activo. Espera a que se retire antes de pedir otro.")
        return
    end

    if #activeVehicles >= VehicleConfig.MaxActiveVehicles then
        sendState(player, "Servidor lleno de vehículos (" .. tostring(VehicleConfig.MaxActiveVehicles) .. " máximo).")
        return
    end

    local definition = VehicleConfig.Types[vehicleType]
    local spawnCFrame = getSpawnCFrame(player, definition)
    if not spawnCFrame then
        sendState(player, "No se encontró una superficie libre para colocar el vehículo.")
        return
    end
    local record = buildVehicle(vehicleType, spawnCFrame)
    if not record then
        sendState(player, "No se pudo crear el vehículo.")
        return
    end
    record.ownerUserId = player.UserId
    record.lastOccupiedAt = now
    sendState(player, "Vehículo creado: " .. definition.DisplayName, definition.DisplayName)
end

function VehicleService.Start()
    if started then
        return
    end
    started = true
    local requestRemote = getRemotes()
    requestRemote.OnServerEvent:Connect(function(player, action, vehicleType)
        if action ~= "Spawn" then
            return
        end
        requestSpawn(player, vehicleType)
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        local now = os.clock()
        for index = #activeVehicles, 1, -1 do
            local record = activeVehicles[index]
            local model = record.model
            local chassis = record.chassis
            local seat = record.seat
            if record.destroying or not model or not model.Parent or not chassis or not chassis.Parent then
                if record.ownerUserId then
                    nextSpawnAt[record.ownerUserId] = now + VehicleConfig.DestroyedRespawnDelay
                    local owner = Players:GetPlayerByUserId(record.ownerUserId)
                    if owner then
                        sendState(owner, "Vehículo destruido; espera antes de solicitar otro.")
                    end
                end
                table.remove(activeVehicles, index)
            else
                local humanoid = seat.Occupant
                local driver = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
                if driver then
                    if not VehicleConfig.CanUse(driver, record.type) then
                        humanoid.Sit = false
                    else
                        local throttle = seat.ThrottleFloat
                        local steer = seat.SteerFloat
                        local current = chassis.AssemblyLinearVelocity
                        local forward = chassis.CFrame.LookVector
                        local speed = record.definition.MaxSpeed
                        local desired = forward * (throttle * speed)
                        local alpha = math.clamp(deltaTime * record.definition.Acceleration, 0, 1)
                        chassis.AssemblyLinearVelocity = Vector3.new(
                            current.X + (desired.X - current.X) * alpha,
                            current.Y,
                            current.Z + (desired.Z - current.Z) * alpha
                        )
                        if math.abs(throttle) < 0.05 then
                            local damping = math.max(0, 1 - deltaTime * 1.5)
                            chassis.AssemblyLinearVelocity = Vector3.new(current.X * damping, current.Y, current.Z * damping)
                        end
                        if math.abs(steer) > 0.05 and math.abs(throttle) > 0.05 then
                            chassis.AssemblyAngularVelocity = Vector3.new(0, -steer * record.definition.TurnRate, 0)
                        else
                            chassis.AssemblyAngularVelocity = Vector3.new(0, chassis.AssemblyAngularVelocity.Y * 0.5, 0)
                        end
                        if record.definition.Kind == "Boat" then
                            chassis.AssemblyLinearVelocity = Vector3.new(
                                chassis.AssemblyLinearVelocity.X,
                                math.max(chassis.AssemblyLinearVelocity.Y, -2),
                                chassis.AssemblyLinearVelocity.Z
                            )
                        end
                        record.lastOccupiedAt = now
                    end
                elseif record.model:GetAttribute("EmptySince") and record.model:GetAttribute("EmptySince") > 0 then
                    if now - record.model:GetAttribute("EmptySince") >= VehicleConfig.EmptyVehicleLifetime then
                        local ownerId = record.ownerUserId
                        removeRecord(record)
                        if ownerId then
                            nextSpawnAt[ownerId] = now + VehicleConfig.DestroyedRespawnDelay
                            local owner = Players:GetPlayerByUserId(ownerId)
                            if owner then
                                sendState(owner, "Vehículo vacío retirado. Puedes solicitar otro más tarde.")
                            end
                        end
                    end
                end
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        lastRequestAt[player] = nil
        nextSpawnAt[player.UserId] = nil
    end)

    print("[Bravo Six] VehicleService started.")
end

return VehicleService
