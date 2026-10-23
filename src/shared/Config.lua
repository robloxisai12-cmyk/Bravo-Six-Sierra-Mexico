-- Shared configuration. Keep gameplay decisions authoritative on the server.
local Config = {}

Config.Teams = {
    Government = {
        Name = "Fuerza Federal",
        BrickColor = "Bright blue",
        AutoAssignable = true,
    },
    Sierra = {
        Name = "Fuerza Sierra",
        BrickColor = "Bright red",
        AutoAssignable = false,
    },
}

Config.Territories = {
    FolderName = "Territories",
    DefaultCaptureTime = 10,
    ScanInterval = 1,
    ContestRadiusPadding = 0,
}

Config.RemotesFolderName = "BravoSixRemotes"
Config.TerritoryUpdateRemoteName = "TerritoryUpdate"
Config.TeamUpdateRemoteName = "TeamUpdate"

return Config
