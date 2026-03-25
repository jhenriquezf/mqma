# MQMA — Networking Gastronómico

Plataforma que conecta personas en mesas de restaurante usando matching por intereses, personalidad y objetivos.

**Stack:** Flutter 3 + Django 5 + PostgreSQL + Redis + Celery + Docker

---

## Estructura del repositorio

```
mqma/
├── lib/                    ← Código Dart (Flutter)
│   ├── core/               ← Router, tema, API client, servicios
│   └── features/           ← auth, events, booking, matching, profile, reviews
├── android/
├── ios/
├── pubspec.yaml
│
└── backend/                ← Django REST API
    ├── apps/
    │   ├── users/          ← Auth, perfiles, FCM tokens
    │   ├── events/         ← Eventos de restaurantes
    │   ├── matching/       ← Motor de matching + grupos
    │   ├── payments/       ← Pago con Flow Chile
    │   └── reviews/        ← NPS + valoraciones
    ├── mqma/               ← settings, urls, celery
    ├── docker-compose.yml
    ├── Dockerfile
    ├── requirements.txt
    └── .env.example        ← Plantilla de variables de entorno
```

---

## Requisitos previos

| Herramienta | Versión mínima | Descarga |
|---|---|---|
| Git | cualquiera | https://git-scm.com |
| Docker Desktop | 4.x | https://www.docker.com/products/docker-desktop |
| Flutter SDK | 3.3+ | https://docs.flutter.dev/get-started/install |
| Android Studio | cualquiera | https://developer.android.com/studio (para el emulador) |

> **Nota:** Flutter debe estar en el PATH. Verificar con `flutter doctor`.

---

## Inicio rápido (Windows)

```bat
git clone https://github.com/jhenriquezf/mqma.git
cd mqma
setup.bat
```

El script automatiza todo: copia el `.env`, instala dependencias Flutter, construye las imágenes Docker, aplica migraciones y levanta el backend.

---

## Setup manual paso a paso

### 1 — Clonar el repositorio

```bat
git clone https://github.com/jhenriquezf/mqma.git
cd mqma
```

### 2 — Configurar variables de entorno del backend

```bat
copy backend\.env.example backend\.env
```

Editar `backend\.env` y completar:

| Variable | Descripción | Ejemplo |
|---|---|---|
| `SECRET_KEY` | Clave secreta Django | genera con `python -c "import secrets; print(secrets.token_hex(50))"` |
| `FLOW_API_KEY` | API Key de Flow Chile | desde el panel sandbox de Flow |
| `FLOW_SECRET_KEY` | Secret Key de Flow Chile | desde el panel sandbox de Flow |
| `FLOW_API_URL` | Entorno Flow | `https://sandbox.flow.cl/api` (pruebas) |
| `FRONTEND_URL` | Deep link de retorno | `mqma://payment/return` |
| `FIREBASE_CREDENTIALS` | Ruta al service account JSON | opcional — solo para notificaciones push |

> Las demás variables (`DATABASE_URL`, `REDIS_URL`) ya apuntan a los contenedores Docker y no necesitan cambio para desarrollo local.

### 3 — Levantar el backend

```bat
cd backend
docker compose up --build
```

Servicios que levanta:

| Servicio | Puerto | Descripción |
|---|---|---|
| `web` | 8000 | API Django (gunicorn) |
| `db` | 5432 | PostgreSQL + PostGIS |
| `redis` | 6379 | Cache + broker Celery |
| `celery` | — | Worker (colas: default, matching, notifications) |
| `celery-beat` | — | Tareas programadas |

Para cargar datos de prueba:

```bat
docker compose exec web python manage.py seed_data
```

Para crear un superusuario (admin en http://localhost:8000/admin):

```bat
docker compose exec web python manage.py createsuperuser
```

### 4 — Instalar dependencias Flutter

```bat
cd ..
flutter pub get
```

### 5 — Correr la app Flutter

| Destino | Comando |
|---|---|
| Android Emulator (AVD) | `flutter run` |
| iOS Simulator (Mac) | `flutter run --dart-define=API_URL=http://localhost:8000/api/v1` |
| Dispositivo físico | `flutter run --dart-define=API_URL=http://TU_IP_LOCAL:8000/api/v1` |

> Tu IP local: ejecutar `ipconfig` en Windows → buscar la IPv4 de tu red WiFi.

---

## Flujo de desarrollo diario

```bat
# Terminal 1 — backend
cd backend && docker compose up

# Terminal 2 — frontend
flutter run
```

---

## Notificaciones push (Firebase) — opcional

Sin configurarlas la app funciona completamente (login, booking, matching, pagos).

Para habilitarlas:
1. Crear proyecto en https://console.firebase.google.com
2. Descargar `google-services.json` → reemplazar `android/app/google-services.json`
3. Descargar `GoogleService-Info.plist` → colocar en `ios/Runner/`
4. Descargar service account JSON del proyecto Firebase
5. Agregar en `backend/.env`: `FIREBASE_CREDENTIALS=/app/firebase-service-account.json`

---

## Pago con Flow Chile (sandbox)

1. Registrarse en https://sandbox.flow.cl
2. Obtener `FLOW_API_KEY` y `FLOW_SECRET_KEY` del panel sandbox
3. Configurarlos en `backend/.env`
4. Tarjeta de prueba: `4051 8856 0044 6623` / exp `12/25` / CVV `123`

---

## API

- Base URL local: `http://localhost:8000/api/v1/`
- Admin panel: `http://localhost:8000/admin/`
- Autenticación: JWT Bearer token

Endpoints principales:

```
POST   /auth/login/
POST   /auth/register/
POST   /auth/token/refresh/
GET    /events/
GET    /events/:id/
POST   /bookings/
POST   /payments/init/
GET    /payments/status/?token=<flow_token>
GET    /matching/my-group/
POST   /reviews/
```
