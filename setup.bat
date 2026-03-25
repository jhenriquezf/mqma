@echo off
setlocal EnableDelayedExpansion
title MQMA — Setup

echo.
echo ============================================================
echo   MQMA Setup
echo ============================================================
echo.

:: ── 1. Verificar Docker ────────────────────────────────────────
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker no encontrado.
    echo         Instala Docker Desktop: https://www.docker.com/products/docker-desktop
    pause & exit /b 1
)
echo [OK] Docker encontrado.

:: ── 2. Verificar Flutter ───────────────────────────────────────
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter no encontrado en el PATH.
    echo         Instala Flutter: https://docs.flutter.dev/get-started/install
    pause & exit /b 1
)
echo [OK] Flutter encontrado.

:: ── 3. Copiar .env si no existe ────────────────────────────────
if not exist "backend\.env" (
    copy "backend\.env.example" "backend\.env" >nul
    echo [OK] backend\.env creado desde .env.example
    echo.
    echo  IMPORTANTE: Edita backend\.env antes de continuar.
    echo  Necesitas completar al menos:
    echo    - SECRET_KEY
    echo    - FLOW_API_KEY y FLOW_SECRET_KEY  (desde sandbox.flow.cl)
    echo.
    echo  Presiona cualquier tecla cuando hayas guardado el .env ...
    pause >nul
) else (
    echo [OK] backend\.env ya existe.
)

:: ── 4. flutter pub get ─────────────────────────────────────────
echo.
echo [..] Instalando dependencias Flutter...
flutter pub get
if errorlevel 1 (
    echo [ERROR] flutter pub get fallo.
    pause & exit /b 1
)
echo [OK] Dependencias Flutter instaladas.

:: ── 5. Build y levantar Docker ─────────────────────────────────
echo.
echo [..] Construyendo imagenes Docker (puede tardar unos minutos la primera vez)...
cd backend
docker compose build
if errorlevel 1 (
    echo [ERROR] docker compose build fallo.
    cd ..
    pause & exit /b 1
)
echo [OK] Imagenes construidas.

:: ── 6. Aplicar migraciones ─────────────────────────────────────
echo.
echo [..] Aplicando migraciones de base de datos...
docker compose run --rm web python manage.py migrate
if errorlevel 1 (
    echo [ERROR] Las migraciones fallaron.
    cd ..
    pause & exit /b 1
)
echo [OK] Migraciones aplicadas.

:: ── 7. Datos de prueba (opcional) ──────────────────────────────
echo.
set /p SEED="[?] Cargar datos de prueba (eventos, usuarios)? (s/n): "
if /i "!SEED!"=="s" (
    docker compose run --rm web python manage.py seed_data
    echo [OK] Datos de prueba cargados.
)

:: ── 8. Crear superusuario (opcional) ───────────────────────────
echo.
set /p SUPER="[?] Crear superusuario para el admin? (s/n): "
if /i "!SUPER!"=="s" (
    docker compose run --rm web python manage.py createsuperuser
)

cd ..

:: ── Resumen ────────────────────────────────────────────────────
echo.
echo ============================================================
echo   Setup completado.
echo ============================================================
echo.
echo  Para trabajar a diario:
echo.
echo    Terminal 1 — Backend:
echo      cd backend
echo      docker compose up
echo.
echo    Terminal 2 — Flutter (emulador Android):
echo      flutter run
echo.
echo    Flutter en dispositivo fisico:
echo      flutter run --dart-define=API_URL=http://TU_IP_LOCAL:8000/api/v1
echo      (ejecuta ipconfig para ver tu IP local)
echo.
echo    Admin Django: http://localhost:8000/admin
echo    API:          http://localhost:8000/api/v1/
echo.
pause
