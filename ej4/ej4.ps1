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

$fw.Path = ".";
$fw.EnableRaisingEvents = $true;

Register-ObjectEvent -InputObject $fw -EventName Created -SourceIdentifier archivoCreado

try {
    while($true)
    {
        $evento = Wait-Event -SourceIdentifier "archivoCreado"
        $evento | Remove-Event
        
        Write-Host 'archivo creado' $evento
        #$evento | Format-List
        $archivo = Get-Item $evento.SourceArgs.FullPath -Force
        $extension = ($archivo.Extension | Select-String -Pattern '(?<=\.)(.+)' -All).Matches.value
        
        #$extension
        #$archivo.FullName
        #$extension = "./" + $extension
        
        $path = Join-Path -Path $directorioDestino ""
        #$rutaExtension
        Write-Host prueba $archivo.Basename $archivo.Extensio prueba
        if(($archivo.Basename -ne "") -and ($archivo.Extension -ne ""))
        {
            New-Item -Path $path -Name $extension.ToUpper() -ItemType "directory"
            $path = $path+$extension.ToUpper()
        }
        $path
        Move-Item -Path $archivo.FullName -Destination $path
    }
}
catch {
    Write-Host "se produjo error"
}
finally{
    Unregister-Event -SourceIdentifier archivoCreado
}