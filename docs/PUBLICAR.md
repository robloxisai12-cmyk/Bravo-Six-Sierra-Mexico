# Crear una versión de prueba desde GitHub (Android)

Este flujo combina el código de Rojo con el mapa original `Mapa Origen RP Roblox.rbxl`, genera el archivo `BravoSix-merged.rbxl` y lo guarda como artefacto de GitHub Actions. El mapa original del repositorio no se sobrescribe.

El flujo **no se ejecuta con cada commit**. Solo se ejecuta cuando lo inicias manualmente desde GitHub Actions. La opción predeterminada es `Saved`, que guarda una versión en Roblox sin publicarla. `Published` publica la versión del lugar seleccionado; úsala solo cuando quieras actualizar esa versión en Roblox.

## 1. Crear una clave de Open Cloud

1. Abre [Roblox Creator Hub](https://create.roblox.com/) en el navegador del celular e inicia sesión.
2. Abre la sección **Open Cloud / API Keys**.
3. Crea una API key con el acceso mínimo necesario para publicar lugares.
4. En permisos de la clave, selecciona la experiencia correcta y concede permiso **Write** para la API de lugares de la experiencia (`universe-places`). No concedas permisos de otras APIs que no se necesitan.
5. Copia la clave una sola vez y guárdala en un lugar privado. No la pegues en archivos, issues, comentarios ni mensajes públicos.

La clave debe poder crear una versión del lugar indicado. La documentación oficial está en [Place publishing](https://create.roblox.com/docs/cloud/guides/usage-place-publishing).

## 2. Encontrar los IDs

- **Universe ID:** en Creator Hub, abre la experiencia correcta y copia su Universe ID.
- **Place ID:** abre el lugar específico de esa experiencia y copia el Place ID. Una experiencia puede contener varios lugares; verifica que sea el que quieres actualizar.

No intercambies el Universe ID con el Place ID.

## 3. Guardar los tres secretos en GitHub desde Android

1. Abre el repositorio `robloxisai12-cmyk/Bravo-Six-Sierra-Mexico`.
2. Entra en **Settings**.
3. Abre **Secrets and variables → Actions**.
4. Pulsa **New repository secret** y crea cada secreto con el nombre exacto:

| Nombre del secreto | Valor |
|---|---|
| `ROBLOX_API_KEY` | La clave de Open Cloud |
| `ROBLOX_UNIVERSE_ID` | El Universe ID numérico |
| `ROBLOX_PLACE_ID` | El Place ID numérico |

No escribas los valores en el código ni los incluyas en capturas públicas. Si falta alguno, el flujo falla antes de llamar a Roblox y no publica nada.

## 4. Ejecutar el flujo manualmente

1. Abre la pestaña **Actions** del repositorio.
2. Selecciona **Build and publish Bravo Six test**.
3. Pulsa **Run workflow**.
4. Para la primera prueba, deja `Saved` seleccionado.
5. Pulsa **Run workflow** y espera a que termine.

El flujo valida el proyecto, construye el código con Rojo, combina solo los hijos permitidos con el mapa y se detiene si encuentra una colisión de nombres en el destino. No reemplaza las carpetas existentes ni elimina scripts de la plantilla.

## 5. Descargar el archivo de respaldo

En la ejecución terminada, abre **Artifacts** y descarga `BravoSix-merged-place`. El artefacto contiene `BravoSix-merged.rbxl` y se conserva durante 14 días. Descárgalo en tu Android si quieres guardar una copia adicional.

## 6. Publicar después de revisar

Cuando estés listo para actualizar la versión del lugar, vuelve a iniciar el mismo flujo y selecciona `Published`. Eso publica una versión nueva del lugar indicado; no cambia la visibilidad pública/privada de la experiencia por sí solo, pero sí actualiza la versión publicada de ese lugar. Revisa cuidadosamente los IDs antes de hacerlo.

## Límites de la validación

Que GitHub Actions termine correctamente confirma que Rojo construyó los scripts, que el archivo del lugar pudo procesarse y que Roblox aceptó la solicitud de Open Cloud cuando se selecciona una opción de publicación. No sustituye una prueba dentro de Roblox: después de publicar, entra al juego y comprueba despliegue, equipos, territorios, HUD y vehículos. La flotabilidad de las lanchas también necesita prueba real.
