# ====================================================================
# SCRIPT DE RESPALDO AUTOMATICO - ANTIGRAVITY IDE (EDICION PREMIUM)
# ====================================================================
# Desarrollado por: William Hoyos (Whoar27)
# Sitio web: https://williamhoyos.com
# GitHub: https://github.com/Whoar27
# ====================================================================
# Este script realiza un respaldo seguro, empaquetado y comprimido
# de toda la configuracion, historial de chats y bases de datos
# de tu agente Antigravity IDE.
# ====================================================================

# Habilitar codificacion UTF-8 para evitar problemas de caracteres en la consola
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. CONFIGURACION DINAMICA DE RUTAS
# Intentamos buscar OneDrive de forma predeterminada, si no, usamos el perfil del usuario.
$DestinoBaseDefault = ""
if ($env:OneDrive) {
    $DestinoBaseDefault = Join-Path $env:OneDrive "Backups\AntigravityBackup"
} else {
    $DestinoBaseDefault = Join-Path $env:USERPROFILE "AntigravityBackup"
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     SISTEMA DE RESPALDO AUTOMATICO - ANTIGRAVITY IDE     " -ForegroundColor Cyan -BackgroundColor DarkBlue
Write-Host "     Desarrollado por: William Hoyos (Whoar27)            " -ForegroundColor Yellow -BackgroundColor DarkBlue
Write-Host "     Sitio web: williamhoyos.com                          " -ForegroundColor Yellow -BackgroundColor DarkBlue
Write-Host "==========================================================" -ForegroundColor Cyan

# Confirmar o personalizar ruta de destino
Write-Host "`nRuta de respaldo sugerida (presiona Enter para confirmar):" -ForegroundColor Gray
Write-Host "-> $DestinoBaseDefault" -ForegroundColor White
$DestinoBase = Read-Host "O introduce una ruta personalizada"
if ([string]::IsNullOrWhiteSpace($DestinoBase)) {
    $DestinoBase = $DestinoBaseDefault
}

# Crear nombre de carpeta unico con la fecha y hora
$FechaObj = Get-Date
$Fecha = $FechaObj.ToString("yyyy-MM-dd_HH-mm-ss")
$NombreCarpeta = "Backup_Antigravity_$Fecha"
$RutaTemporal = Join-Path $env:TEMP $NombreCarpeta
$ArchivoZipFinal = Join-Path $DestinoBase "$NombreCarpeta.zip"

# Rutas de origen oficiales
$OrigenRoaming = "$env:APPDATA\Antigravity IDE\User"
$OrigenGemini  = "$env:USERPROFILE\.gemini"

# Validar que existan datos que respaldar
if (!(Test-Path $OrigenRoaming) -and !(Test-Path $OrigenGemini)) {
    Write-Host "`n[ERROR] No se detecto ninguna instalacion activa de Antigravity en las rutas por defecto." -ForegroundColor Red
    Write-Host "Asegurate de haber instalado y abierto Antigravity al menos una vez." -ForegroundColor Yellow
    Exit
}

# ====================================================================
# 2. CONTROL Y CIERRE SEGURO DE PROCESOS
# ====================================================================
Write-Host "`n[1/5] Verificando procesos activos..." -ForegroundColor Yellow

$Procesos = @("Antigravity", "Antigravity IDE", "gemini-agent", "code")
$ProcesosActivos = @()

foreach ($Proc in $Procesos) {
    if (Get-Process $Proc -ErrorAction SilentlyContinue) {
        $ProcesosActivos += $Proc
    }
}

if ($ProcesosActivos.Count -gt 0) {
    Write-Host "`n[ADVERTENCIA] Se han detectado procesos de Antigravity abiertos: $($ProcesosActivos -join ', ')" -ForegroundColor Yellow
    Write-Host "Para evitar la corrupcion de base de datos o archivos bloqueados, es altamente recomendado cerrarlos." -ForegroundColor Yellow
    
    $Confirmacion = Read-Host "Deseas cerrar estos procesos automaticamente ahora mismo? (S/N)"
    if ($Confirmacion -eq "S" -or $Confirmacion -eq "s" -or [string]::IsNullOrWhiteSpace($Confirmacion)) {
        Write-Host "Cerrando procesos..." -ForegroundColor Cyan
        foreach ($Proc in $ProcesosActivos) {
            Stop-Process -Name $Proc -Force -ErrorAction SilentlyContinue
            Write-Host "-> Proceso [$Proc] cerrado con exito." -ForegroundColor Gray
        }
        Start-Sleep -Seconds 2 # Esperar a que se liberen los archivos
    } else {
        Write-Host "`n[ERROR] No se puede realizar un respaldo seguro mientras los procesos de Antigravity esten activos." -ForegroundColor Red
        Write-Host "Por favor, guarda tu trabajo, cierra la aplicacion de forma manual y vuelve a ejecutar este script." -ForegroundColor Yellow
        Exit
    }
} else {
    Write-Host "-> Todo despejado. No hay procesos activos bloqueando archivos." -ForegroundColor Green
}

# ====================================================================
# 3. EJECUCION DEL COPIADO A DIRECTORIO TEMPORAL
# ====================================================================
Write-Host "`n[2/5] Preparando entorno de copia..." -ForegroundColor Yellow

# Crear directorio temporal limpio
if (Test-Path $RutaTemporal) { Remove-Item -Path $RutaTemporal -Recurse -Force }
$DestinoUser = New-Item -ItemType Directory -Force -Path (Join-Path $RutaTemporal "User")
$DestinoGemini = New-Item -ItemType Directory -Force -Path (Join-Path $RutaTemporal ".gemini")

# --- Copia de Roaming (Configuraciones de Usuario) ---
Write-Host "-> Respaldando configuraciones del editor (Roaming)..." -ForegroundColor Cyan
$CarpetasUser = @("globalStorage", "workspaceStorage", "History", "snippets")
$ArchivosUser = @("keybindings.json", "settings.json", "storage.json")

$ErroresCopia = 0

foreach ($Carpeta in $CarpetasUser) {
    $Origen = Join-Path $OrigenRoaming $Carpeta
    if (Test-Path $Origen) {
        $DestinoCarpeta = Join-Path $DestinoUser.FullName $Carpeta
        Copy-Item -Path $Origen -Destination $DestinoCarpeta -Recurse -Force -ErrorAction SilentlyContinue
        if (!(Test-Path $DestinoCarpeta)) { $ErroresCopia++ }
    }
}

foreach ($Archivo in $ArchivosUser) {
    $Origen = Join-Path $OrigenRoaming $Archivo
    if (Test-Path $Origen) {
        Copy-Item -Path $Origen -Destination $DestinoUser.FullName -Force -ErrorAction SilentlyContinue
        $DestinoArch = Join-Path $DestinoUser.FullName $Archivo
        if (!(Test-Path $DestinoArch)) { $ErroresCopia++ }
    }
}

# --- Copia de .gemini (Cerebro, Historial de Chats y Config de Proyectos) ---
Write-Host "-> Respaldando base de datos del agente y conversaciones (.gemini)..." -ForegroundColor Cyan
if (Test-Path $OrigenGemini) {
    # Copia limpia y robusta usando iteracion para evitar problemas con comodines en carpetas ocultas
    Get-ChildItem -Path $OrigenGemini | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $DestinoGemini.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ====================================================================
# 4. GENERACION DE METADATOS DE SEGURIDAD (INTEGRIDAD DE DATOS)
# ====================================================================
Write-Host "`n[3/5] Generando metadatos de integridad..." -ForegroundColor Yellow

$Metadata = @{
    Fecha          = $FechaObj.ToString("dd/MM/yyyy HH:mm:ss")
    Usuario        = $env:USERNAME
    Computadora    = $env:COMPUTERNAME
    VersionScript  = "1.2.0"
    ArchivosUser   = (Get-ChildItem -Path $DestinoUser.FullName -Recurse -File | Measure-Object).Count
    ArchivosGemini = (Get-ChildItem -Path $DestinoGemini.FullName -Recurse -File | Measure-Object).Count
}

$MetaPath = Join-Path $RutaTemporal "backup_info.json"
$Metadata | ConvertTo-Json | Out-File -FilePath $MetaPath -Encoding utf8

# ====================================================================
# 5. COMPRESION ZIP (Optimizacion extrema de tamaño y transferencia)
# ====================================================================
Write-Host "`n[4/5] Comprimiendo respaldo en un solo archivo ZIP..." -ForegroundColor Yellow

# Asegurar que la carpeta base de destino exista
if (!(Test-Path $DestinoBase)) {
    New-Item -ItemType Directory -Force -Path $DestinoBase | Out-Null
}

try {
    # Comprimir usando compresion nativa de PowerShell
    Compress-Archive -Path "$RutaTemporal\*" -DestinationPath $ArchivoZipFinal -Force -ErrorAction Stop
    Write-Host "-> Archivo ZIP creado de forma exitosa." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Fallo la creacion del archivo ZIP: $_" -ForegroundColor Red
    Write-Host "Se mantendran los archivos sin comprimir en el destino." -ForegroundColor Yellow
    
    # Copia de seguridad alternativa si falla el ZIP (e.g. ruta de red o permisos)
    $RutaAlternativa = Join-Path $DestinoBase $NombreCarpeta
    Copy-Item -Path $RutaTemporal -Destination $RutaAlternativa -Recurse -Force
    $ArchivoZipFinal = $RutaAlternativa
}

# Limpiar directorio temporal
if (Test-Path $RutaTemporal) {
    Remove-Item -Path $RutaTemporal -Recurse -Force
}

# ====================================================================
# 6. FINALIZACION Y RESUMEN
# ====================================================================
$TamanoBytes = (Get-Item $ArchivoZipFinal).Length
$TamanoMB = [Math]::Round($TamanoBytes / 1MB, 2)

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "        RESPALDO COMPLETADO CON EXITO! (100%)            " -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  Ruta de salida:  $ArchivoZipFinal" -ForegroundColor White
Write-Host "  Tamaño total:   $TamanoMB MB" -ForegroundColor White
Write-Host "  Archivos User:  $($Metadata.ArchivosUser)" -ForegroundColor White
Write-Host "  Archivos IA:    $($Metadata.ArchivosGemini)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green

if ($ErroresCopia -gt 0) {
    Write-Host "[!] ADVERTENCIA: $ErroresCopia archivos de Roaming no se pudieron copiar (posiblemente bloqueados)." -ForegroundColor DarkYellow
    Write-Host "Se recomienda cerrar el IDE por completo y repetir para un respaldo absoluto." -ForegroundColor DarkYellow
}
Write-Host "`nGuarda este archivo ZIP en tu OneDrive, Google Drive o USB." -ForegroundColor Gray
Write-Host "Para restaurar, utiliza el script 'restaurar_antigravity.ps1'." -ForegroundColor Gray