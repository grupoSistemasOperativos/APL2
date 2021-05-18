function mostrarAyuda()
{
    param (
        [string[]]$1
    )

    if (($1 -eq "-h") || ($1 -eq "-help") || ($1 -eq "-?")) {
        Write-Host "Uso: Ejercicio 3.ps1 -Directorio [DIR] -DirectorioSalida [DIR] -Umbral [KB]"
        Write-Host ""
        Write-Host "Argumentos obligatorios (se pueden enviar en cualquier orden):"
        Write-Host ""
        Write-Host "      -Directorio         [DIR]       indica directorio donde buscar repetidos"
        Write-Host "      -DirectorioSalida   [DIR]       indica directorio donde se va a escribir archivo de texto indicando repetidos (debe ser distinto a -Directorio)"
        Write-Host "      -Umbral             [KB]        indica tamaño en kilobytes a partir del cual se los empieza a evaluar"
        Write-Host "Estados Exit:"
        Write-Host "-1 (error) si los directorios indicados fueron el mismo"
        Write-Host "0 si no hubo archivos repetidos"
        Write-Host "1 si hubo archivos repetidos"
        exit 0      
    }
}

function asignarParametros($argumentos)
{
    if (
         $argumentos.Count -lt 6 ) {
        Write-Host "Cantidad incorrecta de parametros"
        exit 1;
    }

    $i=0;
    while ( $i -lt 5 ) {
        $variable=$argumentos[$i]
        $i++;
        $valor=$argumentos[$i]
        switch ($variable) {
        -Directorio {
            $global:directorio="$valor"
            #echo $variable - $valor
        }
        -DirectorioSalida {
            $global:directorioSalida="$valor"
            #echo $variable - $valor
        }
        -Umbral {
            $global:umbral=$valor
            #echo $variable - $valor
        }
        default {
            Write-Host "Error, el nombre del parámetro no coincide con los requeridos. $variable $valor"
            exit 1
        }
        }
        $i++;
    }
}

function esUnNumero ($valor) {
    return $valor -match "^[\d\.]+$"
}

function validarParametros($1, $2, $3)
{
    if (-not (Test-Path -Path "$1" -PathType Container)) {
        Write-Host "El directorio entrada $1 no existe"
        exit 1
    }
    
    if (-not (Test-Path -Path "$2" -PathType Container)) {
        Write-Host "El directorio $2 no existe"
        exit 1
    }

    if (-not (esUnNumero($3))) {
        Write-Host "El umbral no es un numero"
        exit 1
    }

    if ( $3 -lt 0 ) {
        Write-Host "Especifique cantidad de KB mayor que 0"
        exit 1
    }

    if ( "$1" -eq "$2"  ) {
        Write-Host "Los directorios ingresados deben ser distintos"
        exit -1
    }
}

# function formatoLineaArchivoRepetido($archivo)
# {
#     $pathAbsoluto = (Get-ChildItem $archivo | Select-Object FullName).FullName
#     $pathAbsoluto -match "(?<=\\).[^\\]*$";
#     $nombreArchivo = $Matches[0];
#     $pathAbsoluto -match ".*(?=\\)";
#     $ruta = $Matches[0];
#     $regexMatch = [Regex]::Match("12345", "\d+")
#     if ($regexMatch.Success -eq $true) {
#         $regexMatch.Value
#     } else {

#     }
#     return $nombreArchivo + "`t"+ $ruta;
# }

$global:directorio | Out-Null;
$global:directorioSalida | Out-Null;
$global:umbral | Out-Null;
mostrarAyuda $args[0]
asignarParametros $args
validarParametros "$directorio" "$directorioSalida" "$umbral"

#definicion variables
$array
$hayRepetidos=0

$array = @(Get-ChildItem -Path $directorio -Recurse -Name -File);
$arrayArchivos = [System.Collections.ArrayList]::new();
for ($i=0; $i -lt $array.Count ; $i++) {
    $archivo = $directorio + "\" + $array[$i];
    $tamaño = (Get-ChildItem $archivo | % {[int]($_.length / 1kb)});
    if($tamaño -ge $umbral) {
        $arrayArchivos.Add($directorio + "\" + $array[$i]) | Out-Null;
    }
}

#Write-Host $arrayArchivos;

$archivosIgualesMap = @{};
$cantidad = $arrayArchivos.Count;
for ($i=0; $i -lt ($cantidad-1) ; $i++) {
    $arrayInterno = [System.Collections.ArrayList]::new();
    for ($j=($i+1); $j -lt $cantidad ; $j++) {
        $sonIguales = (Get-FileHash $arrayArchivos[$i]).Hash -eq (Get-FileHash $arrayArchivos[$j]).Hash;
        if($sonIguales -eq "True") {
            #Write-Host $arrayArchivos[$i] es igual a $arrayArchivos[$j]
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
    $pathAbsoluto -match "(?<=\\).[^\\]*$" | Out-Null;
    $nombreArchivo = $Matches[0];
    $pathAbsoluto -match ".*(?=\\)" | Out-Null;
    $ruta = $Matches[0];
    $contenidoArchivo += $nombreArchivo + "`t"+ $ruta;

    foreach ($repetidos in $archivosIgualesMap[$llave]) {
        $pathAbsoluto = (Get-ChildItem $repetidos | Select-Object FullName).FullName
        $pathAbsoluto -match "(?<=\\).[^\\]*$" | Out-Null;
        $nombreArchivo = $Matches[0];
        $pathAbsoluto -match ".*(?=\\)" | Out-Null;
        $ruta = $Matches[0];
        $contenidoArchivo += "`n"+$nombreArchivo + "`t"+ $ruta;
    }
}

$dia = Get-Date -Format 'yyyyMMddHHmm'
$nombreArchivo= "Resultado_[" + $dia + "].log"
New-Item -Path $directorioSalida -Force -Name $nombreArchivo -ItemType "file" -Value $contenidoArchivo | Out-Null;

Write-Host "Se ha creado el archivo " $nombreArchivo " en la ruta " $directorioSalida " con exito!"

exit($hayRepetidos);
