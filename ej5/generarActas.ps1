#    ENCABEZADO
# NOMBRE DEL SCRIPT : generarActas.sh
# APL : 2
# EJERCICIO N° : 5
# INTEGRANTES : Axel Kenneth Hellberg 42296528,Tomas Victorio Serravento 42038102,Carolina Luana Huergo 42562990,Axel Joel Cascasi 42200104,Agustin Ratto 42673142
# ENTREGA : Primera Entrega    
# FECHA : 
#
#

<#
    .SYNOPSIS
        Generacion actas.
    
    .DESCRIPTION
        Genera un archivo JSON a partir de archivos CSV. Dicho JSON va a contener, para cada alumno, su nota y codigo de materia
    
    .PARAMETER Notas
        Indica directorio de donde se procesarán los CSV
    
    .PARAMETER Salida
        Indica directorio (con nombre de archivo incluido) donde se generará el JSON

    .EXAMPLE
        ./generarActas.ps1 -Notas ../descargas/carpetaPrueba/ -Salida ../descargas/carpetaPrueba/destino/prueba.json
#>

param(
    [Parameter(Mandatory=$true, ParameterSetName="json")]
    [String]
    [ValidateScript({Test-Path $_})]
    $Notas,
    [Parameter(Mandatory=$true, ParameterSetName="json")]
    [System.IO.FileInfo]
    [ValidateScript({(Test-Path $_.DirectoryName) -and ($_.Extension -eq ".json")})]
    $Salida
)

function obtenerNotas {
    param (
        [Parameter()]
        [String]
        $directorioNotas,
        [Parameter()]
        [String]
        $directorioSalida
    )
    
    process {

        $alumnos = New-Object System.Collections.ArrayList 
        foreach($archivoCsv in (Get-ChildItem $directorioNotas | Where-Object Length -gt 0) ){
            $codMateria = ($archivoCsv.BaseName -split "_")[0]

            $contenido = [String[]](Get-Content $archivoCsv)
            
            $cantCampos = ($contenido[0] -split ",").Length
            $headers = New-Object System.Collections.ArrayList;

            for ($i = 0; $i -lt $cantCampos; $i++) {
                $headers.add($i.ToString()) | Out-Null
            }

            Import-Csv $archivoCsv -Header $headers | ForEach-Object { 
                $registro = [System.Collections.ArrayList]::New()

                $_.PSObject.Properties | ForEach-Object {
                    $registro.add($_.value) | Out-Null
                }

                $dni = $registro[0]
                $registro.RemoveAt(0)
                $alumnoRepetido = 0
                $materiaRepetida = 0
                foreach ($alumno in $alumnos) {
                    if ($alumno.dni -eq $dni) {
                        foreach ($nota in $alumno.notas){
                            if ($nota.materia -eq $codMateria) {
                                $materiaRepetida = 1
                            }
                        }
                        if ($materiaRepetida -eq 0) {
                            $alumno.agregarNota($codMateria,$registro) | Out-Null
                        }
                        $alumnoRepetido = 1

                    }
                }
                if ($alumnoRepetido -eq 0) {
                     $alumnos.add([Alumno]::New($dni,$codMateria,$registro)) | Out-Null
                }
                
            }
        }
        if($alumnos.Count -gt 0)
        {
            ConvertTo-Json -Depth 3 $alumnos | Set-Content $Salida
            return $true;
        }
        else {
            return $false
        }
        
  
    }
    
    
}


###################################### CLASES ######################################

class Alumno{  
  #[ValidatePattern('^[0-9]')][ValidateLength(8,8)][string]$dni
  [long]$dni
  [System.Collections.ArrayList]$notas 
  
  Alumno ([string]$dni,[string]$materia,[System.Collections.ArrayList]$nota){
        $this.dni = $dni
        $this.notas = New-Object System.Collections.ArrayList
        $this.agregarNota($materia,$nota)
  }

  [void] agregarNota ([string]$materia,[System.Collections.ArrayList]$nota) {
        $this.notas.add([Notas]::New($materia,$nota))
    }

}

class Notas{
    [string]$materia 
    [int]$nota

    Notas([string]$materia,[System.Collections.ArrayList]$notas){
        $this.materia = $materia
        $this.nota = $this.obtenerNota($notas)
    }

    [int] obtenerNota ([System.Collections.ArrayList]$arrayNotas) {
        $total = 0;
        foreach ($nota in $arrayNotas) {
            if($nota -eq "b"){
                $total += 1
            }else {
                if($nota -eq "r"){
                $total += 0.5        
                }   
            }

        }

        return ($total ? $total*10 / (($arrayNotas.Count)): 1)
    }
}

#################################### FIN CLASES ####################################


#$hs = @{ 
#    actas = @{ 
#        $Alumno = New-Object -TypeName Alumno
#    }
#}

$res = obtenerNotas -directorioNotas $Notas;

if($res)
{
    $nombreArchivo = $Salida.Name
    Write-Host `"$nombreArchivo`" "generado con exito" -ForegroundColor Green    
}
else {
    Write-Host "Archivo(s) CSV vacio(s)" -ForegroundColor Red
}
