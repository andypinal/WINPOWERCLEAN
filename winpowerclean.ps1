


# =========================================================
# WINDOWS POWERCLEAN CODE - WWW.GRUPOPRODE.MX
# =========================================================

# Version: 1.0
# Fecha: 2025-12-31
# Dev: andypinal

$TotalEliminados = 0
$TotalFallidos   = 0

function Get-FreeSpaceGB {
    return [math]::Round((Get-PSDrive C).Free / 1GB, 2)
}

$EspacioInicial = Get-FreeSpaceGB

function Ejecutar-Limpieza {
    param (
        [string]$Titulo,
        [array]$Archivos,
        [scriptblock]$Accion
    )

    Write-Host ">> $Titulo"

    $Eliminados = 0
    $Fallidos   = 0
    $Total      = $Archivos.Count
    $i = 0

    foreach ($item in $Archivos) {
        $i++
        $porcentaje = [int](($i / $Total) * 100)

        Write-Progress -Activity $Titulo -Status "$porcentaje% completado" -PercentComplete $porcentaje

        try {
            & $Accion $item
            $Eliminados++
        }
        catch {
            $Fallidos++
        }
    }

    Write-Progress -Activity $Titulo -Completed

    Write-Host "   Archivos eliminados      : $Eliminados"
    Write-Host "   Archivos no eliminados   : $Fallidos`n"

    $script:TotalEliminados += $Eliminados
    $script:TotalFallidos   += $Fallidos
}

# =========================================================
# 1. Archivos temporales del sistema
# =========================================================
$TempSistema = @()
$TempSistema += Get-ChildItem "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue
$TempSistema += Get-ChildItem "$env:TEMP" -Recurse -Force -ErrorAction SilentlyContinue

Ejecutar-Limpieza `
    "Limpieza de archivos temporales del sistema" `
    $TempSistema `
    { Remove-Item $_.FullName -Force -Recurse -ErrorAction Stop }

# =========================================================
# 2. Papelera
# =========================================================
Write-Host ">> Vaciando papelera de reciclaje"
try {
    $Antes = (Get-ChildItem 'C:\$Recycle.Bin' -Recurse -Force -ErrorAction SilentlyContinue).Count
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Progress -Activity "Vaciando papelera de reciclaje" -PercentComplete 100 -Completed
    Write-Host "   Archivos eliminados      : $Antes"
    Write-Host "   Archivos no eliminados   : 0`n"
    $TotalEliminados += $Antes
}
catch {
    Write-Host "   Archivos eliminados      : 0"
    Write-Host "   Archivos no eliminados   : 1`n"
    $TotalFallidos++
}

# =========================================================
# 3. Logs y archivos de error
# =========================================================
$Logs = @()
$Logs += Get-ChildItem "C:\Windows\Logs\CBS\*.log" -Force -ErrorAction SilentlyContinue
$Logs += Get-ChildItem "C:\Windows\Logs\DISM\*.log" -Force -ErrorAction SilentlyContinue

Ejecutar-Limpieza `
    "Limpieza de logs y archivos de error" `
    $Logs `
    { Remove-Item $_.FullName -Force -ErrorAction Stop }

# =========================================================
# 4. Cache de miniaturas
# =========================================================
$Thumbs = Get-ChildItem "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" `
    -Force -ErrorAction SilentlyContinue

Ejecutar-Limpieza `
    "Limpieza de cache de miniaturas" `
    $Thumbs `
    { Remove-Item $_.FullName -Force -ErrorAction Stop }

# =========================================================
# 5. Basura de Windows Update
# =========================================================
Write-Host ">> Limpieza de Windows Update"
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service bits -Force -ErrorAction SilentlyContinue

$WU = Get-ChildItem "C:\Windows\SoftwareDistribution\Download" -Recurse -Force -ErrorAction SilentlyContinue

Ejecutar-Limpieza `
    "Basura de Windows Update" `
    $WU `
    { Remove-Item $_.FullName -Force -Recurse -ErrorAction Stop }

Start-Service wuauserv
Start-Service bits

# =========================================================
# 6. Prefetch
# =========================================================
$Prefetch = Get-ChildItem "C:\Windows\Prefetch" -Force -ErrorAction SilentlyContinue

Ejecutar-Limpieza `
    "Limpieza de Prefetch" `
    $Prefetch `
    { Remove-Item $_.FullName -Force -ErrorAction Stop }

# =========================================================
# 7. Cache del sistema
# =========================================================
Write-Host ">> Limpieza de cache del sistema"
ipconfig /flushdns | Out-Null
Write-Progress -Activity "Limpieza de cache del sistema" -PercentComplete 100 -Completed
Write-Host "   Archivos eliminados      : 0"
Write-Host "   Archivos no eliminados   : 0`n"

# =========================================================
# 8. Limpieza profunda WinSxS
# =========================================================
Write-Host ">> Limpieza profunda de WinSxS (DISM)"
Start-Process -FilePath "dism.exe" `
    -ArgumentList "/online /Cleanup-Image /StartComponentCleanup /ResetBase" `
    -Wait -NoNewWindow
Write-Progress -Activity "Limpieza profunda WinSxS" -PercentComplete 100 -Completed
Write-Host "   Componentes obsoletos limpiados`n"

# =========================================================
# RESULTADOS FINALES
# =========================================================
$EspacioFinal = Get-FreeSpaceGB
$EspacioLiberado = [math]::Round(($EspacioFinal - $EspacioInicial), 2)

Write-Host " "
Write-Host " "
Write-Host "=================================================="
Write-Host " WINDOWS POWERCLEAN - LIMPIEZA TOTAL FINALIZADA"
Write-Host "=================================================="
Write-Host "Espacio inicial            : $EspacioInicial GB"
Write-Host "Espacio liberado           : $EspacioLiberado GB" -ForegroundColor Yellow
Write-Host "Espacio final disponible   : $EspacioFinal GB" -ForegroundColor Green
Write-Host "Archivos eliminados totales: $TotalEliminados"
Write-Host "Archivos no eliminados     : $TotalFallidos"
Write-Host "=================================================="
Write-Host " "
Write-Host " "
Write-Host "=================================================="
Write-Host " DESARROLLADO POR ANDY PINAL - WWW.GRUPOPRODE.MX" -ForegroundColor Cyan
Write-Host "=================================================="
Write-Host " "










