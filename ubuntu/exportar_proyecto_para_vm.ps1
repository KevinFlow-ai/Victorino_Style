# =====================================================
#  VictorinoStyle — Exportar proyecto para Ubuntu VM
#  Ejecuta este script en Windows (PowerShell)
# =====================================================

$proyecto   = "C:\Users\barqu\AndroidStudioProjects\VictorinoStyleDefinitodelTodo\frontend_victorino"
$destino    = "C:\Users\barqu\AndroidStudioProjects\VictorinoStyleDefinitodelTodo"
$zipSalida  = "$destino\victorino_flutter_para_linux.zip"

Write-Host "=====================================================`n  Exportando proyecto Flutter para Ubuntu VM...`n=====================================================" -ForegroundColor Cyan

# Carpetas y archivos que NO se necesitan en la VM (reducen el ZIP)
$excluir = @(
    "$proyecto\build",
    "$proyecto\.dart_tool",
    "$proyecto\.flutter-plugins",
    "$proyecto\.flutter-plugins-dependencies",
    "$proyecto\windows",
    "$proyecto\web",
    "$proyecto\ios",
    "$proyecto\macos",
    "$proyecto\instalador_windows"
)

Write-Host "`n[1/2] Creando ZIP sin carpetas innecesarias..." -ForegroundColor Yellow

# Recoger todos los archivos excepto los excluidos
$archivos = Get-ChildItem -Path $proyecto -Recurse -File | Where-Object {
    $ruta = $_.FullName
    $excluir | ForEach-Object { if ($ruta.StartsWith($_)) { return $true } }
    $false
}

# Invertir lógica: incluir los que NO estén en la lista de excluidos
$archivosIncluir = Get-ChildItem -Path $proyecto -Recurse -File | Where-Object {
    $ruta = $_.FullName
    $estaExcluido = $false
    foreach ($ex in $excluir) {
        if ($ruta.StartsWith($ex)) {
            $estaExcluido = $true
            break
        }
    }
    -not $estaExcluido
}

# Crear ZIP
if (Test-Path $zipSalida) { Remove-Item $zipSalida -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipSalida, 'Create')

foreach ($file in $archivosIncluir) {
    $rutaRelativa = $file.FullName.Substring($proyecto.Length + 1)
    $entrada = "frontend_victorino\$rutaRelativa"
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entrada) | Out-Null
}

$zip.Dispose()

$tamano = [math]::Round((Get-Item $zipSalida).Length / 1MB, 1)
Write-Host "[2/2] ZIP creado correctamente." -ForegroundColor Green
Write-Host "`n  Archivo: $zipSalida"
Write-Host "  Tamaño:  $tamano MB"
Write-Host "`n=====================================================`n  SIGUIENTE PASO:`n=====================================================" -ForegroundColor Cyan
Write-Host "  1. Copia '$zipSalida' a tu VM Ubuntu"
Write-Host "     (usa carpeta compartida, USB virtual, o arrastrar y soltar)"
Write-Host "  2. En Ubuntu, descomprime y ejecuta:"
Write-Host "     unzip victorino_flutter_para_linux.zip"
Write-Host "     cd frontend_victorino"
Write-Host "     chmod +x construir_deb_ubuntu.sh"
Write-Host "     ./construir_deb_ubuntu.sh"
Write-Host "`n  El script construir_deb_ubuntu.sh esta dentro del ZIP`n"

Pause

