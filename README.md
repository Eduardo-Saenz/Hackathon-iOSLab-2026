# Aura - Hackathon iOS Lab 2026

Aura es una app de bienestar en iOS construida con SwiftUI.
Combina datos de HealthKit, metas personales y un coach conversacional para proponer microacciones diarias.

## Idea general
La experiencia de la app está pensada en 3 pasos:
1. Autenticación del usuario.
2. Onboarding con selección de metas de bienestar.
3. Uso diario desde una navegación por pestañas (Inicio, Progreso, Coach y Ajustes).

## Flujo de la app
El flujo principal se controla desde `AppFlowViewModel` y `RootView`:
- `auth`: muestra login.
- `onboarding`: permite elegir metas iniciales.
- `mainTabs`: abre la experiencia principal con tabs.

## Módulos principales
- `Features/Auth`: email/contraseña, Google (GoogleSignIn SPM) y Sign in with Apple (opcional, desactivado por defecto; ver abajo) contra AuraBE.
- `Features/Onboarding`: selección de objetivos de bienestar.
- `Features/Home`: resumen diario, estado de salud y microacciones.
- `Features/Progress`: progreso semanal, tendencias y logros.
- `Features/Coach`: chat con coach AI.
- `Features/Settings`: preferencias, HealthKit, metas y cierre de sesión.

## Capa Core
- `Core/HealthKit`: autorización y lectura de pasos, sueño y calorías activas.
- `Core/Networking`: cliente HTTP genérico (`APIClient`) y endpoints.
- `Core/Storage`: persistencia local con `UserDefaults` vía `AppPreferences`.
- `Core/DesignSystem`: colores, tipografía, spacing y esquinas reutilizables.

## Stack
- Swift
- SwiftUI
- async/await
- HealthKit
- UserDefaults

## Ejecutar el proyecto
1. Abrir `Aura/Aura.xcodeproj` en Xcode.
2. Seleccionar el scheme de `Aura`.
3. Ejecutar en simulador o dispositivo iOS.

## Autenticación (Swift ↔ AuraBE)

1. **Backend** (`../auraBE`): `npm run dev`, migraciones aplicadas, `.env` con al menos `JWT_SECRET`, `DATABASE_URL`, y para Google `GOOGLE_CLIENT_ID` (mismo ID que uses en iOS). Para Apple: `APPLE_BUNDLE_ID=me.cecigaona.Aura`.
2. **Simulador**: por defecto la app usa `http://localhost:3000`. Opcional: en *Product → Scheme → Edit Scheme → Run → Environment Variables* define `API_BASE_URL` si el API no está en localhost.
3. **Email / contraseña**: pestaña *Crear Cuenta* o *Iniciar Sesión*; mínimo 6 caracteres en la contraseña.
4. **Google**: en el target *Aura* (Build Settings), sustituye `GOOGLE_REVERSED_CLIENT_ID` por el valor *Reversed client ID* de tu cliente OAuth iOS en Google Cloud (debe coincidir con el prefijo de tu `GOOGLE_CLIENT_ID`). Opcional: copia `Aura/Aura/GoogleService-Info.plist.example` a `Aura/Aura/GoogleService-Info.plist` y rellena `CLIENT_ID` / `REVERSED_CLIENT_ID` (el plist real está en `.gitignore`).
5. **Sign in with Apple (desactivado por defecto)**: el hackathon suele usar cuentas sin Apple Developer Program de pago; el botón y la lógica siguen en el código pero compilación condicional `ENABLE_SIGN_IN_WITH_APPLE` está apagada, y `Aura.entitlements` no incluye `com.apple.developer.applesignin`, para poder instalar en dispositivo sin esa capability. Si Xcode aún muestra la capability *Sign In with Apple* en el target, quítala manualmente en *Signing & Capabilities* (el proyecto no lista capacidades aparte del plist de entitlements). **Para reactivarlo más adelante**: (1) en el target *Aura* → *Build Settings* → *Swift Compiler – Active Compilation Conditions*, añade `ENABLE_SIGN_IN_WITH_APPLE`; (2) en `Aura/Aura.entitlements` vuelve a añadir la entrada `com.apple.developer.applesignin` → `Default` (como en commits anteriores o en la documentación de Apple); (3) en *Signing & Capabilities* añade *Sign In with Apple* y un Team de pago; (4) backend con `APPLE_BUNDLE_ID` coherente con el bundle ID de la app.

### MCP (Cursor) en este repo

El archivo `Hackathon-iOSLab-2026/.mcp.json` incluye `xcode-tools` (`xcrun mcpbridge`) y `context7` además de GitHub Copilot MCP. Tras cambiarlo, recarga MCP en Cursor (**Settings → MCP**) para que aparezcan las herramientas de Xcode.

## Estado del proyecto
Proyecto base funcional para demo de hackathon, con arquitectura modular por features y dependencias core separadas para facilitar iteración rápida.
