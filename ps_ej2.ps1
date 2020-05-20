<#

.SYNOPSIS
    El siguente  script procesa el archivo especificado en el path y  muestra 
        1-Promedio de tiempo de las llamadas realizadas por día.
        2-Promedio de tiempo y cantidad por usuario por día.
        3-Los 3 usuarios con más llamadas en la semana.
        4-Cuántas llamadas no superan la media de tiempo por día y el usuario que tiene más
        5-llamadas por debajo de la media en la semana.
    
.DESCRIPTION
    Para ejecutar se debera poner como parametro (-path) el archivo 
    el cual se que procesar el cual debera tener el siguente
    formato :
        Fecha y Hora: Formato YYYY-MM-DD HH:mm:ss
        Usuario que realiza la llamada.
        Separador: “ _ “ (espacio, guión bajo, espacio)


.EXAMPLE
    ./ps_ej2.ps1 -path log/file.txt

.NOTES
    Los autores son
         
#>

Param(
    #[Parameter(Mandatory=$True,  Position=1)] [string]$path
    
    [parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [IO.FileInfo]$Path 
     )

     
 try {
    $P = Import-Csv -Path $Path -Delimiter "_" -Header 'tiempo', 'usuario' | Select-Object usuario,@{Name="tiempo";Expression={Get-Date $_.tiempo}}
 }
 catch {
     Write-OutPut "El archivo que quiere ingresar es invalido "
     Exit 1
 }  Get-Help 
   



$usuarios = $P | Select-Object -Unique -Property usuario 

$dias = $P | Select-Object -Unique -Property @{Name="dia";Expression={($_.tiempo).DayOfWeek.toString()}}


function tiempoxllamada {
    param (
        
    )
    begin{
        $llamadasanteriores = @{}
    }
    process{
            if ($llamadasanteriores.($_.usuario)){
                 $fin =  $_.tiempo
                $inicio = $llamadasanteriores.($_.usuario)
                $tiempoLlamadas = $fin - $inicio
                 Write-Output $tiempoLlamadas
                $llamadasanteriores.Remove($_.usuario)
        }
        else{
                $llamadasanteriores.($_.usuario) = $_.tiempo;
        }
    
}

}

function tiempodellamadas {
    param (
        
    )
    begin{
        $llamadasanteriores = @{}
    }
    process{
        
            if ($llamadasanteriores.($_.usuario)){
            $fin =  $_.tiempo
            $inicio = $llamadasanteriores.($_.usuario)
            $tiempoLlamadas+= $fin - $inicio
            $llamadasanteriores.Remove($_.usuario)
        }
        else{
            $llamadasanteriores.($_.usuario) = $_.tiempo;
        }
    
}
    end{
        Write-Output  $tiempoLlamadas
    }
}
function cantidaddellamadas {
    param (
    
    )
    begin{
        
        $cantidadLlamadas = 0
        $llamadasanteriores = @{}
        
    }
    process{
             if ($llamadasanteriores.($_.usuario)){
            $cantidadLlamadas++
            $llamadasanteriores.Remove($_.usuario)
         }
            else{
            $llamadasanteriores.($_.usuario) = $_.tiempo;
         }
}
    end{
        Write-Output  $cantidadLlamadas
    }
}

Write-OutPut "Promedio total x Dia"

$PromedioTotalxDia =foreach($dia in $dias.dia){
    $llamadasxDia = $p | Where-Object { ($_.tiempo).DayOfWeek.toString() -eq $dia}
    $cant= $llamadasxDia | cantidaddellamadas
    $tiempo= $llamadasxDia | tiempodellamadas
    Write-OutPut  ($tiempo / $cant) | Select-Object @{Name="Dia";Expression={$dia}},@{Name="promedio";Expression={$_}}
} 

$PromedioTotalxDia | Format-List

Write-OutPut ""
Write-OutPut ""
Write-OutPut "Promedio x usuario x Dia"

$prom = foreach($dia in $dias.dia){
    $llamadasxDia = $p | Where-Object { ($_.tiempo).DayOfWeek.toString() -eq $dia}
    foreach( $usr in $usuarios.usuario){
        $llamadaxUsuario = $llamadasxDia | Where-Object { $usr -eq $_.usuario} 
        $cant= $llamadaxUsuario | cantidaddellamadas
        $tiempo= $llamadaxUsuario | tiempodellamadas
        
        if($cant){
                $LlamadasxDiaxUsuario = [pscustomobject]@{
                Usuario = $usr
                Dia = $dia     
                Cantidad = $cant
                Promedio = ($tiempo / $cant)
                }
        }  
        else{
                $LlamadasxDiaxUsuario = [pscustomobject]@{
                Usuario = $usr
                Dia = $dia    
                Cantidad = $cant
                Promedio = 0
         }
        }
            Write-OutPut $LlamadasxDiaxUsuario 
            
        } 
}

$prom | Format-List


Write-OutPut "Mayores de la semana"

$cantusr = foreach($usr in $usuarios.usuario){
    $llamadasxDia = $p | Where-Object { $usr -eq $_.usuario} 
    $cant= $llamadasxDia | cantidaddellamadas
    $tiempo= $llamadasxDia | tiempodellamadas
    Write-OutPut  $cant | Select-Object @{Name="Usuario";Expression={$usr}},@{Name="Cantidad";Expression={$_}}
} 

$cantusr | Sort-Object -Property Cantidad -Descending | Select-Object -First 3 | Format-List


$Llamadas30omenosxDia =foreach($dia in $dias.dia){
    $llamadasxDia = $p | Where-Object { ($_.tiempo).DayOfWeek.toString() -eq $dia}
    $counter = $llamadasxDia | tiempoxllamada |  Where-Object { ($_).Minutes -lt 30 } | Measure-Object
    Write-OutPut  $counter | Select-Object @{Name="Dia";Expression={$dia}},@{Name="Cantidad";Expression={($_).Count}}
} 


$Llamadas30omenosxDia | Format-List



$Llamadas30omenosxUsuario= foreach($usr in $usuarios.usuario){
    $llamadasxDia = $p | Where-Object { $usr -eq $_.usuario}
    $counter = $llamadasxDia | tiempoxllamada |  Where-Object { ($_).Minutes -lt 30 } | Measure-Object
    Write-OutPut  $counter | Select-Object @{Name="Usuario";Expression={$usr}},@{Name="Cantidad";Expression={($_).Count}}
} 

$Llamadas30omenosxUsuario | Sort-Object -Property Cantidad -Descending | Select-Object -First 1 | Format-List