<#
    .SYNOPSIS
        Para un archivo de texto, corrige los errores y muestra la cantidad de inconsistencias entre los signos.
    .DESCRIPTION
        Creará un archivo resultado con todas las correciones realizadas, y un archivo .log con la contabilidad de las
        correcciones y las inconsistencias.
    .EXAMPLE
        ./Corrector.ps1 -In prueba/hola.txt
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType leaf})]
    [String]
    $in
)

$pathAbsoluto = (Get-ChildItem $in | Select-Object FullName).FullName;
$pathAbsoluto -match ".*(?=/)" | Out-Null;
$ruta = $Matches[0];
$pathAbsoluto -match "(?<=/).[^/]*$"| Out-Null;
$nombreArchivo = $Matches[0];
$nombreArchivo -match ".*(?=\.)"| Out-Null;
$nombreArchivoSinExtension = $Matches[0];
$nombreArchivo -match "\.([^.]*?)(?=\?|#|$)"| Out-Null;
$extension = $Matches[0];

if($Matches[0] -eq $nombreArchivo){
    $extension=""
}

$dia = Get-Date -Format 'yyyyMMddHHmm';
$nombreArchivoResultado= $ruta + '\' + $nombreArchivoSinExtension + "_" + $dia;
$pathLog= $nombreArchivoResultado + ".log"
$nombreArchivoResultado= $nombreArchivoResultado + $extension

$text = get-content $pathAbsoluto 

if($text.Length -eq 0)
{
    Write-Host archivo vacio -ForegroundColor Red
    exit 1
}

get-content $pathAbsoluto | ForEach-Object{$_ -replace "[ ]{2,}"," " ` -replace " \.", "." ` -replace " \,", "," ` -replace " \;", ";" ` -replace " \.", "." ` -replace "\.(?=[0-9a-z])", ". " ` -replace "\,(?=[0-9a-z])", ", " ` -replace "\;(?=[0-9a-z])", "; "} | Set-Content $nombreArchivoResultado
                                         
$contarInconsistencias = [regex]::Matches($text, "[ ]{2,}").Count + [regex]::Matches($text, " [.;,]").Count + [regex]::Matches($text, "[.;,][^ ]").Count 


$parentesis = [regex]::Matches($text, "\(").Count - [regex]::Matches($text, "\)").Count
$parentesis = [Math]::Abs($parentesis)

$preguntas = [regex]::Matches($text, "\?").Count - [regex]::Matches($text, "\¿").Count
$preguntas = [Math]::Abs($preguntas)


$admiracion = [regex]::Matches($text, "\!").Count - [regex]::Matches($text, "\¡").Count
$admiracion = [Math]::Abs($admiracion)


# $parentesis = contarInconsistencias("\(", "\)")
# $preguntas = contarInconsistencias("\?", "\¿")
# $admiracion = contarInconsistencias("\!", "\¡")

$texto = "La cantidad de correciones realizadas fueron: $contarInconsistencias.`n"
$texto += "La cantidad de parentesis dispares es: $parentesis.`n"
$texto += "La cantidad de signos de pregunta dispares es: $preguntas.`n"
$texto += "La cantidad de signos de exclamacion dispares es: $admiracion."

New-Item -Path $pathLog -ItemType "file" -Value $texto -Force| Out-Null;

Write-Host "Correccion efectuada con exito" -ForegroundColor Green