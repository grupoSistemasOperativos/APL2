<#
    .SYNOPSIS
        Papelera de reciclaje
    
    .DESCRIPTION
        Permite eliminar archivos, recuperarlos, listarlos y vaciarla.
        Se puede pasar solo un parametro a la vez.
    
    .PARAMETER [FILE]
        Idica ruta de archivo a eliminar.
    .PARAMETER l
        Lista los archivos dentro de la papelera
    .PARAMETER r
        Indica el nombre del archivo a recuperar de la papelera.
        Vuelve a su ubicacion original
    .PARAMETER e
        Permite detener el evento
        No se puede pasar con los otros parametros

    .EXAMPLE
        ./mueveArchivo.ps1 -Descargas ../descargas/carpetaPrueba/ -DirectorioDestino ../descargas/carpetaPrueba/destino/
    .EXAMPLE
        ./mueveArchivo.ps1 -Descargas ../descargas/carpetaPrueba/
    .EXAMPLE
        ./mueveArchivo.ps1 -Detener 
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$false,
    ValueFromPipeline=$true,Position=0,ParameterSetName="param0")]
    [ValidateScript({Test-Path -Path $_})]
    [System.IO.FileInfo]
    $archivoAEliminar=$null,

    [Parameter(Mandatory=$false,ParameterSetName="param1")]
    [Switch]
    $l,
    
    [Parameter(Mandatory=$false,ParameterSetName="param2")]
    [System.IO.FileInfo]
    #[ValidateScript({Test-Path -Path $_})]
    $r=$null,
    
    [Parameter(Mandatory=$false,ParameterSetName="param3")]
    [Switch]
    $e
)

Add-Type -Assembly System.IO.Compression.FileSystem

$directorioPapelera = $HOME+'/Papelera';
$destino=$HOME+'\Papelera.zip';
$listar=$HOME+'\Papelera';


Write-Host "Directorio de la papelera: $directorioPapelera"

if ($archivoAEliminar -ne $null)
{    
    #Mandar el archivo a la papelera
    $pathAbsoluto = (Get-ChildItem $archivoAEliminar | Select-Object FullName).FullName
    $pathAbsoluto -match "(?<=/).[^/]*$" | Out-Null
    $pathAbsoluto -match ".*(?=/)" | Out-Null

    zip -m $HOME/Papelera.zip $pathAbsoluto *> /dev/null

    Write-Host $archivoAEliminar.Name "eliminado" -ForegroundColor Magenta
}

if ($l -eq $true){
    #listar los archivos de la papelera
    Expand-Archive -Path $destino -DestinationPath $directorioPapelera *> /dev/null

    $archivos = Get-ChildItem -Path $listar -Recurse  -File

    if($archivos.Count -eq 0)
    {
        Write-Host "Papelera vacia" -ForegroundColor Green
    }
    else {
        Write-Host "~~~~~~" `t`t "~~~~" -ForegroundColor Green
        Write-Host "Nombre" `t`t "Ruta"
        Write-Host "~~~~~~" `t`t "~~~~" -ForegroundColor Green
    
        foreach ($item in $archivos) {
            Write-Host $item.Name `t ($item.Directory |Select-String -Pattern '(?<=Papelera\/).+' -All).Matches.value
        }
    }

    Remove-Item -Path $directorioPapelera -Recurse
}
if($e -eq $true)
{
    zip -d $HOME/Papelera.zip "*" *> /dev/null
}

if($r -ne $null)
{
    $archivoBuscado = $r
    Expand-Archive -Path $destino -DestinationPath $directorioPapelera *> /dev/null
    $archivos = Get-ChildItem -Path $listar -Recurse  -File 

    [System.Collections.ArrayList] $archivoASacar = [System.Collections.ArrayList]::new();

    foreach ($archivo in $archivos) {
        if($archivo.Name -eq $archivoBuscado)
        {
            $archivoASacar.Add($archivo) | Out-Null
        }
    }

    if($archivoASacar.Count -eq 0)
    {
        Write-Host `n`"$archivoBuscado`" "no existe en la papelera"`n -ForegroundColor Red
        exit 1 
    }

    if($archivoASacar.Count -gt 1)
    {
        $i = 1
        foreach ($archivo in $archivoASacar) {
            Write-Host $i "-" $archivo.Name `t ($archivo.Directory |Select-String -Pattern '(?<=Papelera\/).+' -All).Matches.value 
            $i++
        }
        $opcion = Read-Host "Seleccione una opcion"
        $archivo = $archivoASacar[$opcion-1]
    }
    else {
        $archivo = $archivoASacar[0]
    }

    $directorioReal = ($archivo.FullName |Select-String -Pattern '(?<=Papelera\/).+' -All).Matches.value

    unzip -p $HOME/Papelera.zip $directorioReal > /$directorioReal *> /dev/null
    zip -d $HOME/Papelera.zip $directorioReal *> /dev/null

    Write-Host $archivo.Name "restaurado a su ubicacion original" -ForegroundColor Green

    Remove-Item -Path $directorioPapelera -Recurse
}
