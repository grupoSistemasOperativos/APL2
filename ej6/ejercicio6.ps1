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
$global:nombreScript = $MyInvocation.MyCommand.Name

$papelera = [Papelera]::New();

if($archivoAEliminar -ne "")
{
    try {
        $archivoABorrar = Get-ChildItem -Path $archivoAEliminar

        $papelera.eliminar($archivoABorrar)
    }
    catch {
        Write-Host "Error! No puede eliminar el script de papelera!" -ForegroundColor Red
        exit 1
    }

    Write-Host $archivoABorrar.Name "eliminado con exito!" -ForegroundColor Green
}
if($l -eq $true)
{
    $papelera.listarArchivos();
}
if($r -ne "")
{
    $archivoRecuperado = $papelera.recuperar($r);

    Write-Host $archivoRecuperado.Name "recuperado con exito en" $archivoRecuperado.Directory -ForegroundColor Green
}
if($e -eq $true)
{
    $papelera.vaciar();
    Write-Host "Papelera vaciada" -ForegroundColor Green
}

exit 0;

############################ CLASES ############################

class Papelera {
    static [String]$ruta = ($HOME)+"/Papelera.zip";
    static [String[]]$headers = "nombreArchivo","rutaOriginal","nombreOriginal";
    [String]$nombrePapelera;
    
    Papelera ()
    {
        $this.nombrePapelera = $this.obtenerNombreBaseDatos();
        if( ! (Test-Path ([Papelera]::ruta) -PathType leaf))
        {
            #Write-Host $this.nombrePapelera
            $baseDatos = New-Item -Name ($this.nombrePapelera) -ItemType "file" -Force

            Out-File -FilePath $baseDatos.FullName

            Compress-Archive -Path $baseDatos.FullName -DestinationPath ([Papelera]::ruta)
            Remove-Item -Path $baseDatos.FullName
        }
    }

    [String] obtenerNombreBaseDatos()
    {
        $stringAsStream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write("papelera.papelera")
        $writer.Flush()
        $stringAsStream.Position = 0

        return (Get-FileHash -InputStream $stringAsStream | Select-Object Hash).GetHashCode()
    }

    [void] eliminar([System.IO.FileInfo] $archivo)
    {
        if($archivo.FullName -eq ($PSScriptRoot+"/"+$global:nombreScript))
        {
            throw "Imposible eliminar"
        }

        $baseDatos = $this.obtenerBaseDatos()

        $random = (Get-Random);
        $rutaOriginal = $archivo.Directory;
        $nombreOriginal = $archivo.Name;
        #$extension = $archivo.Extension;

        $random.toString() + "," + $rutaOriginal + "," + $nombreOriginal | Add-Content -Path $baseDatos.FullName

        $archivo = $this.generarNombre($random,$archivo)
        #Write-Host 123 $archivo.FullName $baseDatos.FullName
        Compress-Archive -Path $archivo.FullName, $baseDatos.FullName -DestinationPath ([Papelera]::ruta) -Update
        
        $this.borrarTemporal();
        Remove-Item -Path $archivo.FullName
    }

    [System.IO.FileInfo] obtenerBaseDatos()
    {
        Expand-Archive -Path ([Papelera]::ruta) -PassThru
        $rutaArchivo = "./Papelera/"+($this.nombrePapelera)
        #Write-Host $this.nombrePapelera
        return (Get-ChildItem -Path $rutaArchivo);
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
        Remove-Item -Path ([Papelera]::ruta)
        $this = [Papelera]::New();
    }

    [void] borrarTemporal()
    {
        Remove-Item -Path "Papelera/" -recurse 
    }

    [System.IO.FileInfo] recuperar([String] $archivo)
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
                $this.borrarTemporal();
                exit 0;
            }
        }

        $datosCsv = Import-Csv -Header ([Papelera]::headers) -Path $baseDatos.FullName | Where-Object nombreArchivo -ne $archivoARecuperar.nombreArchivo

        $cantidad = ($datosCsv | Measure-Object).Count

        if($cantidad -gt 0)
        {
            $datosCsv | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip ($cantidad -gt 0 ? 1 : 0) | Set-Content -Path $baseDatos.FullName
        }
        else {
            Out-File -FilePath $baseDatos.FullName
        }

        $rutaArchivo = "Papelera/" + ($archivoARecuperar.nombreArchivo);
        $archivoRecuperado = Move-Item -Path $rutaArchivo -Destination ($archivoARecuperar.rutaOriginal + "/" + $archivoARecuperar.nombreOriginal) -Force -PassThru;

        Compress-Archive -Path "Papelera/*" -DestinationPath ([Papelera]::ruta) -Force

        $this.borrarTemporal();

        return $archivoRecuperado;
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