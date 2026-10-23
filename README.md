# Bravo Six: Sierra México

Proyecto Roblox de mundo abierto inspirado en una región ficticia de México. El mapa original generado con Studs.gg se conserva como place base; Rojo administra los scripts y recursos en texto.

## Estado actual

- [x] Archivo base: `Mapa Origen RP Roblox.rbxl`
- [x] Estructura inicial de Rojo
- [x] Equipos de juego creados en servidor
- [x] Captura inicial de territorios basada en zonas configuradas
- [x] HUD cliente adaptable a pantalla pequeña
- [x] Workflow de validación/build para Rojo
- [ ] Prueba en Roblox Studio y en un servidor publicado
- [ ] Vincular las zonas de territorio con partes reales del mapa
- [ ] Sistemas posteriores: vehículos, misiones, inventario y persistencia

## Requisitos

- Roblox Studio (Windows/macOS) para abrir y probar el place.
- Rojo 7.x para sincronizar la carpeta de código.
- Git para versionar cambios.

> Roblox Studio no tiene una versión oficial para Android. Desde Android puedes administrar GitHub y el archivo, pero la prueba de Studio requiere un ordenador o un flujo remoto compatible.

## Cómo conectar el código al mapa existente

1. Descarga `Mapa Origen RP Roblox.rbxl` desde este repositorio y ábrelo en Roblox Studio.
2. En el ordenador, instala Rojo 7.x y ejecuta desde la raíz del repositorio: `rojo serve default.project.json`.
3. Con el plugin Rojo conectado, sincroniza el proyecto con el place abierto.
4. Guarda una copia nueva del place antes de probar cambios.
5. En Workspace crea una carpeta llamada `Territories`. Para cada punto capturable, añade una pieza invisible anclada, sin colisión y con nombre descriptivo. Ajusta `Size` para definir el área y agrega el atributo numérico `CaptureTime` (opcional; por defecto 10 segundos). La pieza será la zona de control.
6. Ejecuta **Test** con varios jugadores. Comprueba los equipos, los mensajes de captura y que el mapa original siga intacto.

## Estructura

```
default.project.json
src/
  shared/Config.lua
  server/Bootstrap.server.lua
  server/Services/TerritoryService.lua
  client/HUD.client.lua
.github/workflows/validate.yml
Mapa Origen RP Roblox.rbxl
```

## Seguridad y autoridad del servidor

Los equipos y el estado de los territorios se deciden en el servidor. El cliente solo muestra el estado; no debe decidir capturas, recompensas ni daño. Las facciones y los conflictos del juego son ficticios.

## Build local

```sh
rojo build default.project.json --output build.rbxlx
```

El archivo construido es una salida de código de Rojo, no una conversión del mapa original. Para conservar el mapa generado por Studs.gg, abre el place original y sincroniza el código con el plugin de Rojo; no reemplaces el place con el archivo de build sin revisarlo.
