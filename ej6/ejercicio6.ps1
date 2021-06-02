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
    [ValidateScript({Test-Path -Path $_ -PathType Leaf })]
    [string]
    $archivoAEliminar="",

    [Parameter(Mandatory=$false,ParameterSetName="param1")]
    [Switch]
    $l,
    
    [Parameter(Mandatory=$false,ParameterSetName="param2")]
    [String]
    #[ValidateScript({Test-Path -Path $_})]
    $r=$null,
    
    [Parameter(Mandatory=$false,ParameterSetName="param3")]
    [Switch]
    $e
)


$papelera = [Papelera]::New();

if($archivoAEliminar -ne "")
{
    $archivoAEliminar = Get-ChildItem $archivoAEliminar
    $papelera.eliminar($archivoAEliminar)
}
if($l -eq $true)
{
    $papelera.listarArchivos();
}
if($r -ne "")
{
    $papelera.recuperar($r);
}
if($e -eq $true)
{
    $papelera.vaciar();
}


############################ CLASES ############################

class Papelera {
    static [String]$ruta = ($HOME);
    static [String[]]$headers = "nombreArchivo","rutaOriginal","nombreOriginal","extension";
    Papelera ()
    {
        if( ! (Test-Path ([Papelera]::ruta+"/Papelera.zip") -PathType leaf))
        {
            $baseDatos = New-Item -Path ([Papelera]::ruta) -Name "papelera.papelera" -ItemType "file" -Force

            $header="nombreArchivo,rutaOriginal,nombreOriginal,extension"

            Out-File -FilePath $baseDatos.FullName

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

        $archivo = $this.generarNombre($random,$archivo)
        #Write-Host 123 $archivo.FullName $baseDatos.FullName
        Compress-Archive -Path $archivo.FullName, $baseDatos.FullName -DestinationPath ([Papelera]::ruta+"/Papelera.zip") -Update
        
        $this.borrarTemporal();
        Remove-Item -Path $archivo.FullName
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

    [System.IO.FileInfo] generarNombre([Int32]$random,[System.IO.FileInfo]$archivo)
    {
        #Write-Host $archivo
        $archivo = (Rename-Item -Path $archivo.FullName -NewName $random -PassThru)
        #Write-Host $archivo
        return $archivo
    }

    [void] listarArchivos()
    {
        $baseDatos = $this.obtenerBaseDatos();
        
        $datosCsv = Import-Csv -Header ([Papelera]::headers) -Path $baseDatos.FullName;
        try {
            $cantidad = ($datosCsv | Measure-Object).Count

            if($cantidad -eq 0)
            {
                throw "Papelera vacia";
            }
            Write-Host "~~~~~~" `t`t`t "~~~~" -ForegroundColor Green
            Write-Host "Nombre" `t`t`t "Ruta"
            Write-Host "~~~~~~" `t`t`t "~~~~" -ForegroundColor Green
    
            $datosCsv | ForEach-Object {
                Write-Host $_.nombreOriginal `t`t $_.rutaOriginal
            }
        }
        catch {
            Write-Host "Papelera vacia" -ForegroundColor Red
        }
        finally
        {
            $this.borrarTemporal()
        }

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

    [void] recuperar([String] $archivo)
    {
        $baseDatos = $this.obtenerBaseDatos();

        #Write-Host $archivo

        $datosCsv = Import-Csv -Header ([Papelera]::headers) -Path $baseDatos.FullName | Where-Object nombreOriginal -Like $archivo

        $cantidad = ($datosCsv | Measure-Object).Count

        if($cantidad -eq 0)
        {
            Write-Host "Archivo no encontrado en papelera" -ForegroundColor Red
            $this.borrarTemporal();
            exit 1;
        }

        if($cantidad -gt 1 )
        {
            $i = 1;
            foreach ($registro in $datosCsv) {
                Write-Host $i "-" $registro.nombreOriginal `t $registro.rutaOriginal
                $i++
            }
            $opcion = Read-Host "Seleccione una opcion"
            $archivoARecuperar = $datosCsv[$opcion-1]
        }
        else {
            $archivoARecuperar = $datosCsv
        }

        #Write-Host $archivoARecuperar
        $rutaOriginal = ($archivoARecuperar.rutaOriginal + "/" + $archivoARecuperar.nombreOriginal)

        if((Test-Path $rutaOriginal) -eq $true)
        {
            $opcion = Read-Host "Atencion! `n
                                El archivo que quiere restablecer ya existe en el directorio original `n
                                ¿ Desea sobreescribirlo ? Escriba S o N: "
            if($opcion -eq "N")
            {
                exit 0;
            }
        }

        $datosCsv = Import-Csv -Header ([Papelera]::headers) -Path $baseDatos.FullName | Where-Object nombreArchivo -ne $archivoARecuperar.nombreArchivo

        Remove-Item -Path $baseDatos.FullName

        $datosCsv | Export-Csv -Path $baseDatos.FullName

        $rutaArchivo = "Papelera/" + ($archivoARecuperar.nombreArchivo);
        Move-Item -Path $rutaArchivo -Destination ($archivoARecuperar.rutaOriginal + "/" + $archivoARecuperar.nombreOriginal) -Force;

        Compress-Archive -Path "Papelera/*" -DestinationPath ([Papelera]::ruta+"/Papelera.zip") -Force

        $this.borrarTemporal();

    }
    
    [boolean] buscarArchivo([String] $archivo,$datosCsv)
    {
        foreach ($registro in $datosCsv) {
            if($registro.nombreOriginal -eq $archivo)
            {
                return $true;
            }
        }
        return $false;
    } 
}