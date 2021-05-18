<#
    .SYNOPSIS
        Mover archivos de una carpeta a otra.
    .DESCRIPTION
        Este script mueve archivos de un directorio a otro pasados por parametro
    .EXAMPLE
        ./ej4.ps1 
#>

################### COMIENZO VALIDACIONES #####################

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, ParameterSetName="moverArchivos")]
    [ValidateScript({Test-Path $_})]
    [String]$Descargas,
    [Parameter(Mandatory = $false, ParameterSetName="moverArchivos")]
    [ValidateScript({Test-Path -Path $_})]
    [String]$Destino= (xdg-user-dir DOWNLOAD),
    [Parameter(Mandatory= $true, ParameterSetName="iniciarApagar")]
    [Switch]$Detener
)

###################### FIN VALIDACIONES #######################

########################## FUNCIONES ##########################
function global:moverArchivo()
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.IO.FileInfo]
        $archivo
    )
    
    $archivosExistentes = (Get-ChildItem $Destino -Recurse -File).FullName
    foreach ($archivoBuscado in $archivosExistentes) {
        if($archivoBuscado -eq $archivo.FullName)
        {
            return
        }
    }

    $extension = ($archivo.Extension | Select-String -Pattern '(?<=\.)(.+)' -All).Matches.value
    $path = Join-Path -Path $Destino ""

    if(($archivo.Basename -ne "") -and ($archivo.Extension -ne ""))
    {
        New-Item -Path $path -Name $extension.ToUpper() -ItemType "directory" -Force | out-null
        $path = $path+$extension.ToUpper()
    }
    $existeArchivo = $path + "/" +$archivo.Name
    
    if(Test-Path -LiteralPath $existeArchivo)
    {
        $nombreNuevo = $archivo.Basename + "_" + (Get-Random) + $archivo.Extension;
        $archivo = Rename-Item -Path $archivo.FullName -NewName $nombreNuevo -PassThru
    }
    Move-Item -Path $archivo.FullName -Destination $path | out-null
}

function moverArchivosExistentes()
{
    $archivos = (Get-ChildItem $descargas -File -Recurse -Force)

    foreach ($archivo in $archivos) {
        moverArchivo -archivo $archivo
    }
}

function manejarErrores()
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $mensaje
    )

    Write-Host "Error`n"$mensaje -ForegroundColor Red

}

function registrarEvento()
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.IO.FileSystemWatcher]
        $watcher,
        [Parameter()]
        $accion
    )

    try {
        Register-ObjectEvent -InputObject $fw -EventName Created -SourceIdentifier archivoCreado -Action $accion -ErrorAction Stop | out-null
    }
    catch {
        manejarErrores -mensaje "El evento para mover archivo ya fue inicializado"
        exit 1
    }

}

function detenerEjecucion()
{
    if($Detener.IsPresent)
    {
        try {
            Unregister-Event -SourceIdentifier archivoCreado -ErrorAction Stop  
        }
        catch {
            manejarErrores -mensaje "Aun no se ha inicializado el evento para mover archivos"
            exit 1
        }

        Write-Host "Evento eliminado" -ForegroundColor Green
        exit 0
    }
}
###############################################################

####################### COMIENZO MAIN #########################

detenerEjecucion

$global:descargas = $descargas
$global:Destino = $Destino

moverArchivosExistentes

$fw = New-Object System.IO.FileSystemWatcher;
$fw.Path = (Resolve-Path $descargas).Path;
$fw.EnableRaisingEvents = $true;
$fw.IncludeSubdirectories = $true;

$moverArchivo = {
    moverArchivo -archivo (Get-Item $Event.SourceArgs.FullPath -Force)
}
registrarEvento  -accion $moverArchivo

Write-Host "`nMonitoreando directorio"(Resolve-Path($descargas)).Path"`n"

#################### FIN MAIN #################################