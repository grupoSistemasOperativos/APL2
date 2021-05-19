[CmdletBinding()]
Param (
[Parameter(Position = 1, Mandatory = $false)]
[ValidateScript( { Test-Path -PathType Container $_ } )]
[String] $directorio,
[int] $resultadosAMostrar = 0
)
$LIST = Get-ChildItem -Path $directorio -Directory
$ITEMS = ForEach ($ITEM in $LIST) {
$COUNT = (Get-ChildItem -Path $ITEM).Length
$props = @{
name = $ITEM
count = $COUNT
}
New-Object psobject -Property $props
}

$CANDIDATES = $ITEMS | Sort-Object -Property count -Descending | Select-Object -First $resultadosAMostrar | Select-Object -Property name

Write-Output "Se listan las primeras $resultadosAMostrar carpetas mas pesadas" # COMPLETAR
$CANDIDATES | Format-Table -HideTableHeaders


# Respuestas a las preguntas

# 1) El objetivo del script es mostrar los primeros N directorios (dentro del que fue pasado por parametro) 
# de mayor peso. Recibe por parametro un directorio y un numero indicando la cantidad de resultados a mostrar.

# 2) Primero se almacena en $LIST aquellos archivos y directorios contenidos en el directorio pasado por parametro.
# Luego se obtiene la cantidad de bytes que ocupa cada uno de ellos. Se los ordena de forma descendente y se toma 
# los primeros N mayores (N siendo el parametro entero). Finalmente se muestran por pantalla dichos directorios seleccionados.

# 3) Hecho en el codigo.

# 4) Le agregaria al parametro entero que valide un rango >= 0, ya que no tiene sentido buscar una cantidad negativa.
# Un error está dado por dicho parametro, haciendo que el script falle al querer obtener los primeros elementos al ser ordenados.

# 5) El [CmdLetBinding()] se utiliza para acceder a las funcionalidades de los cmdLets (en todo el script o dentro de 
# funciones declaradas en el mismo script). Entre ellas, tenemos el bloque Param, Begin, Process, End, por ejemplo.

# 7) Si se ejecuta el script sin parametros, se toma como ruta aquella desde donde se ejecutó
# el script y, por defecto(el parametro entero), mostraria los primeros 0 directorios, por lo que no muestra nada.