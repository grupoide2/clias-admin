# clias-admin

Panel administrativo web del sistema **CLIAS** (telemedicina — automuestreo de VPH, Universidad de Cuenca).

- **Framework:** Flutter (target **web**). Nombre del paquete: `telemedicina_web`.
- **Autenticación:** JWT de administrador (se guarda en `localStorage`).
- **Backend:** consume `clias-backend` (`http://…:9001`, sin prefijo `/api` en los catálogos).

## Funcionalidades

| Módulo | Descripción |
|---|---|
| Dashboard de uso | KPIs de pacientes, automuestreos, chatbot y tiempos (`hh:mm:ss`) |
| Catálogos | Ocupaciones y **rangos de tiempo por pregunta** (Menstruación / Papanicolaou / VPH): crear, editar, activar/desactivar, eliminar |
| Recursos multimedia | Subir/reemplazar videos e imágenes de la app y del sitio, agrupados por destino (`APP` / `WEB`) |
| Ubicaciones | Alta y carga masiva de puntos de entrega |
| Folleto | Registro asistido de pacientes del grupo folleto (asistente de 4 pasos) |
| Resultados | Búsqueda y consulta de resultados de examen |

## Requisitos

- Flutter SDK (canal stable)
- Un `clias-backend` accesible

## Configuración

La URL del backend se define en `lib/config/env.dart`.

## Ejecutar

```bash
flutter pub get
flutter run -d chrome           # desarrollo
flutter build web               # compila a build/web/
```

El resultado de `build/web/` puede servirse de forma independiente o embebido en
`clias-backend` (`src/main/resources/static/`).

## Estructura

```
lib/
  config/          Configuración (URL del backend)
  pages/           Pantallas del panel
  services/        Clientes HTTP hacia clias-backend
  models/          Modelos + fromJson
  main.dart        Rutas y arranque
```

## Relación con el resto de CLIAS

Cliente administrativo de `clias-backend`. Documentación del sistema en **clias-docs**.
