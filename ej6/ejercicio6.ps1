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


$papelera = [Papelera]::New();
#$papelera.eliminar($archivoAEliminar)
$papelera.listarArchivos();
#$papelera.vaciar();

class Papelera {
    static [String]$ruta = ($HOME);
    
    Papelera ()
    {
        if( ! (Test-Path ([Papelera]::ruta+"/Papelera.zip") -PathType leaf))
        {
            $baseDatos = New-Item -Path ([Papelera]::ruta) -Name "papelera.papelera" -ItemType "file" -Force

            $headers="nombreArchivo,rutaOriginal,nombreOriginal,extension"

            $headers | Out-File -FilePath $baseDatos.FullName

            Compress-Archive -Path $baseDatos.FullName -DestinationPath ([Papelera]::ruta+"/Papelera.zip")
            Remove-Item -Path $baseDatos.FullName
        }
    }

    [void] eliminar([System.IO.FileInfo] $archivo)
    {
        $baseDatos = $this.obtenerBaseDatos()

        $random = (Get-Random);
        $rutaOriginal = $archivo.Directory;
        $nombreOriginal = $archivo.Name;
        $extension = $archivo.Extension;

        $random.toString() + "," + $rutaOriginal + "," + $nombreOriginal + "," + $extension | Add-Content -Path $baseDatos.FullName

        #$reg = [Registro]::New($random,$archivo.Directory,$archivo.Name,$archivo.Extension)

        $archivo = $this.generarNombre($random,$archivo)
        #Write-Host $reg
        Compress-Archive -Path $archivo.FullName, $baseDatos.FullName -DestinationPath ([Papelera]::ruta+"/Papelera.zip") -Update
        #Remove-Item -Path $archivo.FullName
    }

    [System.IO.FileInfo] obtenerBaseDatos()
    {
        Expand-Archive -Path ([Papelera]::ruta+"/Papelera.zip") -PassThru
        
        foreach ($item in (Get-ChildItem -Path "./Papelera") ) {
            if($item.Name -eq "papelera.papelera")
            {
                return $item
            }
        }
        return $null;
    }

    [String] generarNombre([Int32]$random,[System.IO.FileInfo]$archivo)
    {
        $archivo = Rename-Item -Path $archivo.FullName -NewName $random -PassThru

        return $archivo
    }

    [void] listarArchivos()
    {
        $baseDatos = $this.obtenerBaseDatos();

        Write-Host "~~~~~~" `t`t`t "~~~~" -ForegroundColor Green
        Write-Host "Nombre" `t`t`t "Ruta"
        Write-Host "~~~~~~" `t`t`t "~~~~" -ForegroundColor Green

        Import-Csv -Path $baseDatos.FullName | ForEach-Object {
            Write-Host $_.nombreOriginal `t`t $_.rutaOriginal
        }

        $this.borrarTemporal()
    }

    [void] vaciar()
    {
        Remove-Item -Path ([Papelera]::ruta+"/Papelera.zip")
        $this = [Papelera]::New();
    }

    [void] borrarTemporal()
    {
        Remove-Item -Path "Papelera/" -recurse 
    }

    [void] recuperar([String] archivo)
    {

    }
}

class Registro{
    [String] $nombreNuevo;
    [String] $rutaOriginal;
    [String] $nombreOriginal;
    [String] $extension;

    Registro([String]$nombreNuevo,[String]$ruta,[String]$nombre,[String]$ext)
    {
        $this.nombreNuevo = $nombreNuevo;
        $this.rutaOriginal = $ruta;
        $this.nombreOriginal = $nombre;
        $this.extension = $ext;
    }

    [String] toString()
    {
        return $this.$this.rutaOriginal + "," + $this.nombreOriginal
    }
}