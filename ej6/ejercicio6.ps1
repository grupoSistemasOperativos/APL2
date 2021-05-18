Add-Type -Assembly System.IO.Compression.FileSystem
function mostrarAyuda()
{

    param(
        [string[]]$1
    )

    if ( ($1 -eq"-h") || ($1 -eq "-help")  || ($1 -eq "-?") ){

            Write-Host "Uso: $0"
            Write-Host ""
            Write-Host "Argumentos:"
            Write-Host ""
            Write-Host "      -[FILE]"$'\t'"elimina el archivo llevandolo a la papelera de reciclaje."
            Write-Host "      -l"$'\t'"lista los archivos contenidos en la papelera de reciclaje."
            Write-Host "      -r [FILE]"$'\t'"recupera el archivo."
            Write-Host "      -e"$'\t'"vacia la papelera de reciclaje."
            exit 0

    }
}



function verificarParametros($1, $2)
{
    

    if ($1 -ne '-l' -and $1 -ne '-r' -and $1 -ne '-e' -and  -not(Test-Path -Path $1) ) {
        # chequear porque no funciona simepre con rutas absolutas ???

        Write-Host "\"$1\" no es una opcion valida o es un archivo inexistente"
        exit 1
    }

    
     if ((Test-Path -Path $1) -and "$2" -ne "" ){

        Write-Host "Error, si busca eliminar un archivo, debe enviar como parametro solo [FILE]"
        exit 1
    }

    if  ("$1" -eq '-l' -and "$2" -ne "" ){

        Write-Host "Error, el parametro "-l" debe ser enviado solo"
        exit 1
    }

    if  ("$1" -eq '-r' -and "$2" -eq "" ){

        Write-Host "Error, el parametro "-r" debe estar acompañado de un nombre de archivo"
            exit 1
    }

    if  ("$1" -eq '-e' -and "$2" -ne "") {

        Write-Host "Error, el parametro "-e" debe ser enviado solo"
        exit 1
    }
}

if ( $args.Count -gt 2 ){

    Write-Host "Error, como maximo se pueden pasar 2 parametros."
    Write-Host "Indique -h para obtener mas informacion sobre los parametros"
    exit 1
}


mostrarAyuda $args[0]
verificarParametros $args[0] $args[1]


$directorioPapelera = $HOME+'/Papelera';
#$directorioPapelera1 = $HOME+'/salida.txt';
$destino=$HOME+'\Papelera.zip';
$listar=$HOME+'\Papelera';


Write-Host "Directorio de la papelera: $directorioPapelera"

if (Test-Path -Path $args[0]){
    
    #Mandar el archivo a la papelera
    $pathAbsoluto = (Get-ChildItem $args[0] | Select-Object FullName).FullName
    $pathAbsoluto -match "(?<=/).[^/]*$";
    $pathAbsoluto -match ".*(?=/)";

    zip -m $HOME/Papelera.zip $pathAbsoluto *> /dev/null
}

if ( $args[0] -eq '-l'){
    #listar los archivos de la papelera
    Expand-Archive -Path $destino -DestinationPath $directorioPapelera *> /dev/null

    $archivos = Get-ChildItem -Path $listar -Recurse  -File

    Write-Host "~~~~~~" `t`t "~~~~" -ForegroundColor Green
    Write-Host "Nombre" `t`t "Ruta"
    Write-Host "~~~~~~" `t`t "~~~~" -ForegroundColor Green

    foreach ($item in $archivos) {
        Write-Host $item.Name `t ($item.Directory |Select-String -Pattern '(?<=Papelera\/).+' -All).Matches.value
    }

    Remove-Item -Path $directorioPapelera -Recurse
}
if($args[0] -eq "-e")
{
    zip -d $HOME/Papelera.zip "*" *> /dev/null
}

if($args[0] -eq "-r")
{
    $archivoBuscado = $args[1]
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

    unzip -p $HOME/Papelera.zip $directorioReal > /$directorioReal #*> /dev/null
    zip -d $HOME/Papelera.zip $directorioReal #*> /dev/null

    Remove-Item -Path $directorioPapelera -Recurse
}
