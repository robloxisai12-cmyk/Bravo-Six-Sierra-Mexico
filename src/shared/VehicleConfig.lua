-- Vehicle definitions shared by the server and client.
-- Team names must match Config.Teams in src/shared/Config.lua.
local VehicleConfig = {}

VehicleConfig.RemotesFolderName = "BravoSixRemotes"
VehicleConfig.RequestRemoteName = "VehicleRequest"
VehicleConfig.StateRemoteName = "VehicleState"

VehicleConfig.MaxActiveVehicles = 6
VehicleConfig.RequestCooldown = 3
VehicleConfig.EmptyVehicleLifetime = 45
VehicleConfig.DestroyedRespawnDelay = 20
VehicleConfig.SpawnFolderName = "VehicleSpawns"
VehicleConfig.SpawnSearchRadius = 28
VehicleConfig.FallbackSpawnDistance = 20
VehicleConfig.VehicleNamePrefix = "BravoVehicle_"

VehicleConfig.Teams = {
    Government = "Fuerza Federal",
    Sierra = "Fuerza Sierra",
}

VehicleConfig.Types = {
    GovernmentTactical = {
        DisplayName = "Camioneta táctica federal",
        TeamKey = "Government",
        Kind = "Car",
        BodyColor = Color3.fromRGB(43, 76, 62),
        MaxSpeed = 74,
        Acceleration = 4.5,
        TurnRate = 2.2,
        SpawnOffset = Vector3.new(0, 5, 0),
        Parts = "Light",
    },
    CartelPickup = {
        DisplayName = "Camioneta Sierra",
        TeamKey = "Sierra",
        Kind = "Car",
        BodyColor = Color3.fromRGB(70, 65, 58),
        MaxSpeed = 78,
        Acceleration = 4.8,
        TurnRate = 2.0,
        SpawnOffset = Vector3.new(0, 5, 0),
        Parts = "Light",
    },
    LogisticsTruck = {
        DisplayName = "Camión logístico",
        TeamKey = "Government",
        Kind = "Truck",
        BodyColor = Color3.fromRGB(76, 91, 72),
        MaxSpeed = 48,
        Acceleration = 2.8,
        TurnRate = 1.25,
        SpawnOffset = Vector3.new(0, 5, 0),
        Parts = "Truck",
    },
    PatrolBoat = {
        DisplayName = "Lancha de patrulla",
        TeamKey = "Government",
        Kind = "Boat",
        BodyColor = Color3.fromRGB(35, 76, 92),
        MaxSpeed = 58,
        Acceleration = 3.6,
        TurnRate = 1.6,
        SpawnOffset = Vector3.new(0, 4, 0),
        Parts = "Boat",
    },
}

function VehicleConfig.CanUse(player, vehicleType)
    local definition = VehicleConfig.Types[vehicleType]
    if not definition or not player or not player.Team then
        return false
    end
    return player.Team.Name == VehicleConfig.Teams[definition.TeamKey]
end

return VehicleConfig
