<#
    .SYNOPSIS
        Muestra archivos repetidos filtrando por un umbral.
    
    .DESCRIPTION
        Creará un archivo resultado con todos los archivos iguales.

    .PARAMETER Directorio
        Indica directorio a verificar archivos repetidos.
    
    .PARAMETER DirectorioSalida
        Indica directorio donde se guardara el archivo resultados.

    .PARAMETER Umbral
        Indica tamaño en KB a partir del cual se los empieza a evaluar.

    .EXAMPLE
        ./mueveArchivo.ps1 -Directorio Entrada -DirectorioSalida Salida -Umbral 3
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({(Test-Path $_ -PathType Container) -and ($directorioSalida -ne $_)})]
    [String]$directorio,
    [Parameter(Mandatory = $true)]
    [ValidateScript({(Test-Path $_ -PathType Container) -and ($directorio -ne $_)})]
    [String]$directorioSalida,
    [Parameter(Mandatory = $true)]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$umbral
)

#definicion variables
$array
$hayRepetidos=0

$array = @(Get-ChildItem -Path $directorio -Recurse -Name -File);
$arrayArchivos = [System.Collections.ArrayList]::new();
for ($i=0; $i -lt $array.Count ; $i++) {
    $archivo = $directorio + "/" + $array[$i];
    $tamaño = (Get-ChildItem $archivo | ForEach-Object {[int]($_.length / 1kb)});
    if($tamaño -ge $umbral) {
        $arrayArchivos.Add($directorio + "/" + $array[$i]) | Out-Null;
    }
}

$archivosIgualesMap = @{};
$cantidad = $arrayArchivos.Count;
for ($i=0; $i -lt ($cantidad-1) ; $i++) {
    $arrayInterno = [System.Collections.ArrayList]::new();
    for ($j=($i+1); $j -lt $cantidad ; $j++) {
        $sonIguales = (Get-FileHash $arrayArchivos[$i]).Hash -eq (Get-FileHash $arrayArchivos[$j]).Hash;
        if($sonIguales -eq "True") {
            $hayRepetidos = 1;
            $arrayInterno.Add($arrayArchivos[$j]) | Out-Null;
            $archivosIgualesMap[$arrayArchivos[$i]] = $arrayInterno;
            $arrayArchivos.Remove($arrayArchivos[$j]);
            $cantidad--;
            $j--;
        }
    }
}

$contenidoArchivo = "";
$comienza=1;

foreach ($llave in $archivosIgualesMap.Keys) {
    if($comienza -ne 1) {
        $contenidoArchivo += "`n`n";
    }
    $comienza=0;
    $pathAbsoluto = (Get-ChildItem $llave | Select-Object FullName).FullName
    $pathAbsoluto -match "(?<=\/).[^\/]*$" | Out-Null;
    $nombreArchivo = $Matches[0];
    $pathAbsoluto -match ".*(?=\/)" | Out-Null;
    $ruta = $Matches[0];
    $contenidoArchivo += $nombreArchivo + "`t"+ $ruta;

    foreach ($repetidos in $archivosIgualesMap[$llave]) {
        $pathAbsoluto = (Get-ChildItem $repetidos | Select-Object FullName).FullName
        $pathAbsoluto -match "(?<=\/).[^\/]*$" | Out-Null;
        $nombreArchivo = $Matches[0];
        $pathAbsoluto -match ".*(?=\/)" | Out-Null;
        $ruta = $Matches[0];
        $contenidoArchivo += "`n"+$nombreArchivo + "`t"+ $ruta;
    }
}

$dia = Get-Date -Format 'yyyyMMddHHmm'
$nombreArchivo= "Resultado_[" + $dia + "].log"
New-Item -Path $directorioSalida -Force -Name $nombreArchivo -ItemType "file" -Value $contenidoArchivo | Out-Null;

Write-Host "Se ha creado el archivo " $nombreArchivo " en la ruta " $directorioSalida " con exito!"

exit($hayRepetidos);
