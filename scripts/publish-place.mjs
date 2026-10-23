import { readFile } from "node:fs/promises";

const apiKey = process.env.ROBLOX_API_KEY;
const universeId = process.env.ROBLOX_UNIVERSE_ID;
const placeId = process.env.ROBLOX_PLACE_ID;
const versionType = process.env.VERSION_TYPE ?? "Saved";
const filePath = "BravoSix-merged.rbxl";

if (!apiKey || !universeId || !placeId) {
  throw new Error(
    "Missing required GitHub Secrets: ROBLOX_API_KEY, ROBLOX_UNIVERSE_ID, and/or ROBLOX_PLACE_ID. Nothing was published."
  );
}

if (!["Saved", "Published"].includes(versionType)) {
  throw new Error("VERSION_TYPE must be Saved or Published.");
}

if (!/^\d+$/.test(universeId) || !/^\d+$/.test(placeId)) {
  throw new Error("ROBLOX_UNIVERSE_ID and ROBLOX_PLACE_ID must contain numeric IDs.");
}

const placeFile = await readFile(filePath);
if (placeFile.length === 0) {
  throw new Error("Merged place file is empty. Nothing was published.");
}

const endpoint =
  `https://apis.roblox.com/universes/v1/${universeId}/places/${placeId}/versions?versionType=${versionType}`;

const response = await fetch(endpoint, {
  method: "POST",
  headers: {
    "x-api-key": apiKey,
    "Content-Type": "application/octet-stream",
  },
  body: placeFile,
});

if (!response.ok) {
  // Do not print request headers, IDs, or secret values.
  throw new Error(`Roblox Open Cloud rejected the upload (HTTP ${response.status}). Check the API key permissions, IDs, and selected version type.`);
}

console.log(
  versionType === "Saved"
    ? "Roblox accepted the Saved version. It was saved but not published."
    : "Roblox accepted the Published version. The place version was published."
);
