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

$fw.Path = $descargas;
$fw.EnableRaisingEvents = $true;

Register-ObjectEvent -InputObject $fw -EventName Created -SourceIdentifier archivoCreado -Action $moverArchivo

$i = 0
try {
    while($true)
    {
        $archivosExistentes = Get-ChildItem $descargas -File -Recurse
        $archivosExistentes
        if($archivosExistentes -eq "")
        {
            $evento = Wait-Event -SourceIdentifier "archivoCreado"
            $evento | Remove-Event
            $archivo = Get-Item $evento.SourceArgs.FullPath -Force
        }
        else {
            $archivo = $archivosExistentes[0]
            $i++
        }
        
        #Write-Host 'archivo creado' $evento
        #$evento | Format-List
        $extension = ($archivo.Extension | Select-String -Pattern '(?<=\.)(.+)' -All).Matches.value
        
        #$extension
        #$archivo.FullName
        #$extension = "./" + $extension
        
        $path = Join-Path -Path $directorioDestino ""
        #$rutaExtension
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
}
catch {
    Write-Host "se produjo error"
}
finally{
    Unregister-Event -SourceIdentifier archivoCreado
}