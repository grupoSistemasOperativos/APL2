<#
    .SYNOPSIS
        Mover archivos de una carpeta a otra.
    .DESCRIPTION
        Este script mueve archivos de un directorio a otro pasados por parametro
    .EXAMPLE
        ./ej4.ps1 
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [String]$descargas,
    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path -Path $_})]
    [String]$directorioDestino
)

$fw = New-Object System.IO.FileSystemWatcher;
$descargas
$fw.Path = "." #(Resolve-Path $descargas).Path;
$fw.EnableRaisingEvents = $true;

$moverArchivo = {
    #moverArchivo -archivo (Get-Item $evento.SourceArgs.FullPath -Force);
    $archivo = Get-Item $evento.SourceArgs.FullPath -Force
    $extension = ($archivo.Extension | Select-String -Pattern '(?<=\.)(.+)' -All).Matches.value
    $path = Join-Path -Path $directorioDestino ""

    Write-Host prueba $archivo.Basename $archivo.Extension prueba
    if(($archivo.Basename -ne "") -and ($archivo.Extension -ne ""))
    {
        New-Item -Path $path -Name $extension.ToUpper() -ItemType "directory" -Force
        $path = $path+$extension.ToUpper()
    }
    $existeArchivo = $path + "/" +$archivo.Name
    $existeArchivo
    if(Test-Path -LiteralPath $existeArchivo)
    {
        $archivo.FullName
        $nombreNuevo = $archivo.Basename + "_" + (Get-Random) + $archivo.Extension;
        $archivo = Rename-Item -Path $archivo.FullName -NewName $nombreNuevo -PassThru
    }
    Move-Item -Path $archivo.FullName -Destination $path
}

Register-ObjectEvent -InputObject $fw -EventName Created -SourceIdentifier archivoCreado -Action $moverArchivo

function moverArchivo()
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.IO.FileInfo]
        $archivo
    )
    #$archivo = Get-Item $evento.SourceArgs.FullPath -Force
    $extension = ($archivo.Extension | Select-String -Pattern '(?<=\.)(.+)' -All).Matches.value
    $path = Join-Path -Path $directorioDestino ""

    Write-Host prueba $archivo.Basename $archivo.Extension prueba
    if(($archivo.Basename -ne "") -and ($archivo.Extension -ne ""))
    {
        New-Item -Path $path -Name $extension.ToUpper() -ItemType "directory" -Force
        $path = $path+$extension.ToUpper()
    }
    $existeArchivo = $path + "/" +$archivo.Name
    $existeArchivo
    if(Test-Path -LiteralPath $existeArchivo)
    {
        $archivo.FullName
        $nombreNuevo = $archivo.Basename + "_" + (Get-Random) + $archivo.Extension;
        $archivo = Rename-Item -Path $archivo.FullName -NewName $nombreNuevo -PassThru
    }
    Move-Item -Path $archivo.FullName -Destination $path
}