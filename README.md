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
- `Features/Auth`: acceso de usuario (Apple/Google en UI mock).
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

## Estado del proyecto
Proyecto base funcional para demo de hackathon, con arquitectura modular por features y dependencias core separadas para facilitar iteración rápida.
