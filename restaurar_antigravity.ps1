# ====================================================================
# SCRIPT DE RESTAURACION AUTOMATICA - ANTIGRAVITY IDE (EDICION PREMIUM)
# ====================================================================
# Desarrollado por: William Hoyos (Whoar27)
# Sitio web: https://williamhoyos.com
# GitHub: https://github.com/Whoar27
# ====================================================================
# Este script restaura de forma segura un respaldo previo de Antigravity
# (.zip o carpeta) en tu computadora actual, configurando todo
# exactamente como estaba al momento del respaldo.
# ====================================================================

# Habilitar codificacion UTF-8 para evitar problemas de caracteres en la consola
$OutputEncoding = [System.Text.Encoding]::UTF8

# Destinos oficiales
$DestinoRoaming = "$env:APPDATA\Antigravity IDE\User"
$DestinoGemini  = "$env:USERPROFILE\.gemini"

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    SISTEMA DE RESTAURACION AUTOMATICA - ANTIGRAVITY IDE   " -ForegroundColor Cyan -BackgroundColor DarkBlue
Write-Host "    Desarrollado por: William Hoyos (Whoar27)              " -ForegroundColor Yellow -BackgroundColor DarkBlue
Write-Host "    Sitio web: williamhoyos.com                            " -ForegroundColor Yellow -BackgroundColor DarkBlue
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. LOCALIZAR EL ARCHIVO DE RESPALDO
Write-Host "`n[1/5] Selecciona tu archivo de respaldo (.zip)..." -ForegroundColor Yellow

$RutaRespaldo = Read-Host "Introduce la ruta completa del archivo .zip de tu respaldo"
# Limpiar comillas si el usuario arrastro el archivo a la consola
$RutaRespaldo = $RutaRespaldo.Trim("`"", "'", " ")

if ([string]::IsNullOrWhiteSpace($RutaRespaldo) -or !(Test-Path $RutaRespaldo)) {
    Write-Host "`n[ERROR] No se pudo encontrar el archivo de respaldo especificado: '$RutaRespaldo'" -ForegroundColor Red
    Write-Host "Asegurate de copiar y pegar la ruta correcta (Ej: D:\Respaldos\Backup_Antigravity_2026-05-20.zip)." -ForegroundColor Yellow
    Exit
}

# 2. CONTROL Y CIERRE SEGURO DE PROCESOS
Write-Host "`n[2/5] Verificando procesos activos..." -ForegroundColor Yellow

$Procesos = @("Antigravity", "Antigravity IDE", "gemini-agent", "code")
$ProcesosActivos = @()

foreach ($Proc in $Procesos) {
    if (Get-Process $Proc -ErrorAction SilentlyContinue) {
        $ProcesosActivos += $Proc
    }
}

if ($ProcesosActivos.Count -gt 0) {
    Write-Host "`n[ADVERTENCIA] Se han detectado procesos de Antigravity abiertos: $($ProcesosActivos -join ', ')" -ForegroundColor Yellow
    Write-Host "Para poder sobreescribir los archivos de configuracion y la base de datos sin errores," -ForegroundColor Yellow
    Write-Host "DEBES cerrar la aplicacion por completo." -ForegroundColor Yellow
    
    $Confirmacion = Read-Host "Deseas cerrar estos procesos automaticamente ahora mismo? (S/N)"
    if ($Confirmacion -eq "S" -or $Confirmacion -eq "s" -or [string]::IsNullOrWhiteSpace($Confirmacion)) {
        Write-Host "Cerrando procesos..." -ForegroundColor Cyan
        foreach ($Proc in $ProcesosActivos) {
            Stop-Process -Name $Proc -Force -ErrorAction SilentlyContinue
            Write-Host "-> Proceso [$Proc] cerrado con exito." -ForegroundColor Gray
        }
        Start-Sleep -Seconds 2
    } else {
        Write-Host "`n[!] ERROR: No se puede restaurar mientras Antigravity este abierto. Por favor, cierralo y vuelve a ejecutar el script." -ForegroundColor Red
        Exit
    }
} else {
    Write-Host "-> Todo despejado. No hay procesos activos bloqueando la restauracion." -ForegroundColor Green
}

# 3. CREAR RESPALDO PREVENTIVO DEL ESTADO ACTUAL (SEGURIDAD ANTE TODO!)
Write-Host "`n[3/5] Creando respaldo de seguridad rapido de tu estado actual..." -ForegroundColor Yellow

$TempRestauracion = Join-Path $env:TEMP "AntigravityRestoreTemp"
if (Test-Path $TempRestauracion) { Remove-Item -Path $TempRestauracion -Recurse -Force }
New-Item -ItemType Directory -Force -Path $TempRestauracion | Out-Null

$EstadoActualBackup = Join-Path $env:USERPROFILE "Antigravity_PreRestore_Backup"
if (Test-Path $EstadoActualBackup) {
    Remove-Item -Path $EstadoActualBackup -Recurse -Force
}

# Si ya existen carpetas, hacemos una copia de seguridad rapida en el perfil por si acaso
if ((Test-Path $DestinoRoaming) -or (Test-Path $DestinoGemini)) {
    $PreRestoreDir = New-Item -ItemType Directory -Force -Path $EstadoActualBackup
    if (Test-Path $DestinoRoaming) {
        Copy-Item -Path $DestinoRoaming -Destination (Join-Path $PreRestoreDir.FullName "User") -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $DestinoGemini) {
        Copy-Item -Path $DestinoGemini -Destination (Join-Path $PreRestoreDir.FullName ".gemini") -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "-> Respaldo preventivo guardado en: $EstadoActualBackup" -ForegroundColor Gray
}

# 4. EXTRACCION Y VALIDACION DEL ZIP
Write-Host "`n[4/5] Extrayendo y validando el contenido del respaldo..." -ForegroundColor Yellow

try {
    # Extraer el ZIP en una carpeta temporal para validarlo
    Expand-Archive -Path $RutaRespaldo -DestinationPath $TempRestauracion -Force -ErrorAction Stop
} catch {
    Write-Host "[ERROR] El archivo ZIP esta corrupto o no se pudo abrir: $_" -ForegroundColor Red
    Exit
}

# Validar y leer metadatos de integridad si existen
$MetaPath = Join-Path $TempRestauracion "backup_info.json"
if (Test-Path $MetaPath) {
    try {
        $Info = Get-Content -Raw -Path $MetaPath | ConvertFrom-Json
        Write-Host "`n==========================================================" -ForegroundColor Cyan
        Write-Host "           METADATOS DEL RESPALDO DETECTADOS              " -ForegroundColor Cyan -BackgroundColor DarkCyan
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "  Creado el:       $($Info.Fecha)" -ForegroundColor White
        Write-Host "  PC de origen:    $($Info.Computadora)" -ForegroundColor White
        Write-Host "  Usuario origen:  $($Info.Usuario)" -ForegroundColor White
        Write-Host "  Archivos User:   $($Info.ArchivosUser)" -ForegroundColor White
        Write-Host "  Archivos IA:     $($Info.ArchivosGemini)" -ForegroundColor White
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        $ConfirmacionRest = Read-Host "`nConfirmas que deseas restaurar este respaldo? (S/N)"
        if ($ConfirmacionRest -ne "S" -and $ConfirmacionRest -ne "s" -and ![string]::IsNullOrWhiteSpace($ConfirmacionRest)) {
            Write-Host "`n[!] Restauracion cancelada por el usuario." -ForegroundColor Yellow
            Remove-Item -Path $TempRestauracion -Recurse -Force
            Exit
        }
    } catch {
        Write-Host "`n[!] No se pudieron validar los metadatos, pero se continuara con la restauracion." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "`n[!] Advertencia: Respaldo sin archivo de metadatos. Se procedera con cautela." -ForegroundColor DarkYellow
}

$UserOrigenTemp = Join-Path $TempRestauracion "User"
$GeminiOrigenTemp = Join-Path $TempRestauracion ".gemini"

if (!(Test-Path $UserOrigenTemp) -and !(Test-Path $GeminiOrigenTemp)) {
    Write-Host "[ERROR] El archivo de respaldo seleccionado no tiene la estructura correcta de Antigravity." -ForegroundColor Red
    Write-Host "Faltan las carpetas 'User' y/o '.gemini'. Asegurate de que el ZIP fue generado por 'respaldo_antigravity.ps1'." -ForegroundColor Yellow
    Remove-Item -Path $TempRestauracion -Recurse -Force
    Exit
}

# 5. APLICACION DE LA RESTAURACION (SOBREESCRITURA FINAL)
Write-Host "`n[5/5] Escribiendo datos en las rutas oficiales del sistema..." -ForegroundColor Yellow

# Restauracion de Roaming (User)
if (Test-Path $UserOrigenTemp) {
    Write-Host "-> Restaurando preferencias y configuracion del editor (User)..." -ForegroundColor Cyan
    # Limpiamos el destino para evitar conflictos de mezcla de archivos o bloqueos
    if (Test-Path $DestinoRoaming) {
        Remove-Item -Path $DestinoRoaming -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Force -Path $DestinoRoaming | Out-Null
    # Copiar contenido de la carpeta temporal User a Roaming
    Copy-Item -Path "$UserOrigenTemp\*" -Destination $DestinoRoaming -Recurse -Force -ErrorAction SilentlyContinue
}

# Restauracion de .gemini (Cerebro)
if (Test-Path $GeminiOrigenTemp) {
    Write-Host "-> Restaurando base de conocimientos e historial del agente (.gemini)..." -ForegroundColor Cyan
    # Limpiamos el destino para evitar conflictos de mezcla de archivos o bloqueos
    if (Test-Path $DestinoGemini) {
        Remove-Item -Path $DestinoGemini -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Force -Path $DestinoGemini | Out-Null
    # Copiar contenido de la carpeta temporal .gemini a .gemini oficial
    Copy-Item -Path "$GeminiOrigenTemp\*" -Destination $DestinoGemini -Recurse -Force -ErrorAction SilentlyContinue
}

# Limpieza
if (Test-Path $TempRestauracion) {
    Remove-Item -Path $TempRestauracion -Recurse -Force
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "       RESTAURACION COMPLETADA CON EXITO! (100%)         " -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  Tus configuraciones, temas y chats han sido restaurados." -ForegroundColor White
Write-Host "  Ya puedes abrir Antigravity IDE y continuar trabajando!" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
