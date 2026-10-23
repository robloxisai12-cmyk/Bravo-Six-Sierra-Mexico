-- Shared configuration. Keep gameplay decisions authoritative on the server.
local Config = {}

-- Dos equipos de Roblox; las unidades/subfacciones se eligen dentro de cada uno.
Config.Teams = {
    Government = {
        Name = "Gobierno de México",
        BrickColor = "Dark green",
        AutoAssignable = false,
    },
    Cartels = {
        Name = "Cárteles",
        BrickColor = "Bright red",
        AutoAssignable = false,
    },
}

Config.Units = {
    { Id = "Ejercito", Team = "Government", Name = "Ejército Mexicano" },
    { Id = "Marina", Team = "Government", Name = "Secretaría de Marina" },
    { Id = "GuardiaNacional", Team = "Government", Name = "Guardia Nacional" },
    { Id = "FuerzasEspeciales", Team = "Government", Name = "Fuerzas Especiales" },
    { Id = "CartelNorte", Team = "Cartels", Name = "Cártel del Norte" },
    { Id = "CartelSierra", Team = "Cartels", Name = "Cártel de la Sierra" },
    { Id = "CartelDesierto", Team = "Cartels", Name = "Cártel del Desierto" },
    { Id = "CartelCosta", Team = "Cartels", Name = "Cártel de la Costa" },
}

Config.Deploy = {
    SwitchCooldown = 120, -- segundos mínimos entre cambios de bando
    CombatLock = 15, -- segundos sin cambiar de bando tras un combate
    MaxImbalance = 2, -- diferencia máxima de jugadores entre bandos
    RespawnDelay = 5, -- segundos antes de mostrar el menú tras morir
    RequestInterval = 1.5, -- anti-spam de solicitudes
    SpawnTag = "BravoSpawn", -- SpawnLocation con atributo Team = "Government" | "Cartels"
}

Config.Territories = {
    FolderName = "Territories",
    DefaultCaptureTime = 10,
    ScanInterval = 1,
    ContestRadiusPadding = 0,
}

Config.RemotesFolderName = "BravoSixRemotes"
Config.TerritoryUpdateRemoteName = "TerritoryUpdate"
Config.TeamUpdateRemoteName = "TeamUpdate" -- servidor -> cliente: {action="ShowDeploy"} | {action="Result", ok, msg}
Config.TeamRequestRemoteName = "TeamRequest" -- cliente -> servidor: unitId (string) | "Ready"

return Config
