@echo off
color 0A
rem ====================================================================
rem SCRIPT DE RESPALDO DE EMERGENCIA (CMD) - ANTIGRAVITY IDE
rem ====================================================================
rem Desarrollado por: William Hoyos (Whoar27)
rem Sitio web: https://williamhoyos.com
rem GitHub: https://github.com/Whoar27
rem ====================================================================
rem Disenado para Entornos de Recuperacion (WinRE) o Modo Seguro
rem ====================================================================

chcp 65001 > nul
cls
echo ==========================================================
echo    RESPALDO DE EMERGENCIA (CMD) - ANTIGRAVITY IDE
echo    Desarrollado por: William Hoyos (Whoar27)
echo    Sitio web: williamhoyos.com
echo ==========================================================
echo.

rem 1. DEFINICION DE RUTAS DE ORIGEN
set "OrigenRoaming=%APPDATA%\Antigravity IDE\User"
if "%APPDATA%"=="" (
    set "OrigenRoaming=%USERPROFILE%\AppData\Roaming\Antigravity IDE\User"
)
set "OrigenGemini=%USERPROFILE%\.gemini"

rem Verificar que al menos una ruta exista
if not exist "%OrigenRoaming%" (
    if not exist "%OrigenGemini%" (
        echo [ERROR] No se encontraron datos de Antigravity en el perfil actual.
        echo Asegurate de estar ejecutando el script con el usuario correcto.
        echo.
        pause
        exit /b
    )
)

rem 2. SUGERIR RUTA DE DESTINO
set "DestinoBase=%USERPROFILE%\AntigravityBackup"
echo Ruta de respaldo sugerida (presiona Enter para confirmar):
echo - %DestinoBase%
echo.
set /p "RutaManual=O introduce una ruta personalizada (ej. E:\Backup_USB): "

if not "%RutaManual%"=="" (
    set "DestinoBase=%RutaManual%"
)

rem Limpiar comillas
set "DestinoBase=%DestinoBase:"=%"

rem Generar marca de tiempo robusta compatible con cualquier idioma de Windows
set "fecha=%date%"
set "fecha=%fecha:/=-%"
set "fecha=%fecha:\=-%"
set "fecha=%fecha: =_%"
set "fecha=%fecha:.=-%"

set "hora=%time%"
set "hora=%hora::=-%"
set "hora=%hora:.=-%"
set "hora=%hora: =0%"

set "NombreZip=Backup_Emergency_Antigravity_%fecha%_%hora%.zip"
set "ArchivoZipFinal=%DestinoBase%\%NombreZip%"
set "RutaTemporal=%TEMP%\AntigravityBackupTemp"

rem 3. PREPARAR ENTORNO TEMPORAL
echo.
echo [1/4] Creando directorios temporales de copia...
if exist "%RutaTemporal%" rd /s /q "%RutaTemporal%"
mkdir "%RutaTemporal%\User" 2>nul
mkdir "%RutaTemporal%\.gemini" 2>nul

rem 4. EJECUTAR COPIAS CON ROBOCOPY
echo.
echo [2/4] Respaldando archivos de configuracion y chats...

echo - Copiando datos de configuracion del editor (User)...
robocopy "%OrigenRoaming%\globalStorage" "%RutaTemporal%\User\globalStorage" /E /R:1 /W:1 /NFL /NDL >nul
robocopy "%OrigenRoaming%\workspaceStorage" "%RutaTemporal%\User\workspaceStorage" /E /R:1 /W:1 /NFL /NDL >nul
robocopy "%OrigenRoaming%\History" "%RutaTemporal%\User\History" /E /R:1 /W:1 /NFL /NDL >nul
robocopy "%OrigenRoaming%\snippets" "%RutaTemporal%\User\snippets" /E /R:1 /W:1 /NFL /NDL >nul

copy /y "%OrigenRoaming%\settings.json" "%RutaTemporal%\User\" >nul 2>&1
copy /y "%OrigenRoaming%\storage.json" "%RutaTemporal%\User\" >nul 2>&1
copy /y "%OrigenRoaming%\keybindings.json" "%RutaTemporal%\User\" >nul 2>&1

echo - Copiando cerebro del agente y chats (.gemini)...
robocopy "%OrigenGemini%" "%RutaTemporal%\.gemini" /E /R:1 /W:1 /NFL /NDL >nul

rem 5. COMPRESION ZIP
echo.
echo [3/4] Comprimiendo respaldo en formato ZIP...
if not exist "%DestinoBase%" mkdir "%DestinoBase%"

rem Especificamos directamente las carpetas internas para evitar agregar los directorios "." y ".."
tar -caf "%ArchivoZipFinal%" -C "%RutaTemporal%" User .gemini

if errorlevel 1 (
    echo [ERROR] No se pudo comprimir. Se guardaran los archivos descomprimidos.
    set "BackupFolder=%DestinoBase%\Backup_Emergency_Antigravity_%fecha%_%hora%"
    mkdir "%BackupFolder%" 2>nul
    robocopy "%RutaTemporal%" "%BackupFolder%" /E /R:1 /W:1 /NFL /NDL >nul
) else (
    echo - Archivo de respaldo ZIP creado con exito.
)

rem 6. LIMPIEZA
echo.
echo [4/4] Limpiando archivos temporales...
rd /s /q "%RutaTemporal%"

rem 7. FINALIZACION
echo.
echo ==========================================================
echo    RESPALDO DE EMERGENCIA COMPLETADO CON EXITO! (100%%)
echo ==========================================================
echo  Ruta de salida:  %ArchivoZipFinal%
echo ==========================================================
echo NOTA: Puedes mover este ZIP a un disco USB o nube.
echo Para restaurar, usa el script de PowerShell en tu sistema activo.
echo.
pause
color

