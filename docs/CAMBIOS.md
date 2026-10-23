# Parche: equipos, unidades y despliegue

Reemplaza/añade estos archivos (mismas rutas que en el repo):
- src/shared/Config.lua              (reemplaza)
- src/server/Bootstrap.server.lua    (reemplaza)
- src/server/Services/TerritoryService.lua (reemplaza)
- src/client/HUD.client.lua          (reemplaza)
- src/client/DeployMenu.client.lua   (NUEVO)

Qué cambia
1. 2 equipos (Gobierno de México / Cárteles) y 8 unidades elegibles.
2. Los jugadores ya no aparecen solos: eligen unidad en el menú.
3. Solo se puede desplegar sin personaje vivo (no se puede cambiar de bando para
   huir de un combate ni recuperar vida). Cooldown de 120 s entre bandos, bloqueo
   de 15 s tras combate (atributo de jugador "LastCombat" = os.clock()) y límite
   de desbalance entre equipos.
4. Spawns por bando: SpawnLocation con tag "BravoSpawn" y atributo Team =
   "Government" | "Cartels". Mientras no existan, se usa el spawn por defecto del mapa.
5. Capturar territorio exige estar VIVO.

Sin probar en Roblox. Revisar el Output al correr una partida de prueba.
