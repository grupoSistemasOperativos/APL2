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


$directorioPapelera = $HOME+'\Papelera';
$directorioPapelera1 = $HOME+'\salida.txt';
$destino=$HOME+'\Papelera.zip';
$listar=$HOME+'\Papelera';


Write-Host "Directorio de la papelera: $directorioPapelera"


#Creamos la papelera en caso de que no exista
if(Test-Path -Path $destino ){
    Write-Host "  existe"
   
}else{
     Write-Host " no existe --> creo la carpeta"
     New-Item -Path $directorioPapelera -ItemType directory #Creo la papelera
     [io.compression.zipfile]::CreateFromDirectory($directorioPapelera, $destino)# la comprimo
     Remove-Item -Path $directorioPapelera #remuevo la carpeta
   # Compress-Archive -Path $directorioPapelera -CompressionLevel Optimal -DestinationPath $destino
}
#Chequear esto porque lo que sucede es que tengo que tener un archivo para usarlo de "ziper" y poder generar la papelera.zip , ya que si creo la carpeta papelera e intento zipearla no funciona


if (Test-Path -Path $args[0]){
    
    #Mandar el archivo a la papelera
    $pathAbsoluto = (Get-ChildItem $args[0] | Select-Object FullName).FullName
    $pathAbsoluto -match "(?<=\\).[^\\]*$";
    $nombreArchivo = $Matches[0];
    $pathAbsoluto -match ".*(?=\\)";
    $ruta = $Matches[0];
    Write-Host $nombreArchivo + " - " + $ruta
    
    #[io.compression.zipfile]::CreateFromDirectory('C:\Users\acasc\OneDrive\Escritorio\APL2\Ejercicio6\hola\pepe',$destino,0,$true)
    Compress-Archive -Path $pathAbsoluto -Update -DestinationPath $destino

    #Remove-Item -Path $pathAbsoluto 
    
    #Eliminamos el archivo de su ubicacion original


  
}

if ( $args[0] -eq '-l'){
    #listar los archivos de la papelera
    Expand-Archive -Path $destino -DestinationPath $directorioPapelera

    Get-ChildItem -Path $listar -Recurse  -File | Format-Table FullName


    Remove-Item -Path $directorioPapelera -Recurse
     #Eliminamos el archivo de su ubicacion original
  #[IO.Compression.ZipFile]::OpenRead($listar) | Get-Member;

  }

