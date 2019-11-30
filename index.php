<?php
 $release = array();
 $Conectar = false;
 $mensaje = "";
if(isset($_POST['submit'])){
    if($_POST['submit'] == 'Conectar'){
        $host = $_POST['host'];
        $port = $_POST['port'];
        $user = $_POST['userss'];
        $pass = $_POST['passss'];
        $database = $_POST['database'];
       
        $Conectar = true;
        $dbconn = @pg_connect("host=$host port=$port dbname=$database user=$user password=$pass");
        if(!$dbconn)
    {
        $mensaje = "Error de Conexion!";
    }else{
        $result = pg_query($dbconn, "select release,fecha from huella group by release,fecha order by fecha ASC;");
        $release = pg_fetch_all($result);
    }
        
    }elseif($_POST['submit'] == 'GenerarReleaseActual'){
        $host = $_POST['host'];
        $port = $_POST['port'];
        $user = $_POST['userss'];
        $pass = $_POST['passss'];
        $database = $_POST['database'];
        $newrelease = $_POST['newrelease'];
        $fecha = date('Y-m-d')." ".date('h:i:s');
       
        $Conectar = true;
        $dbconn = pg_connect("host=$host port=$port dbname=$database user=$user password=$pass");
        $result = pg_query($dbconn, "select fc_generarrelease('$newrelease','$fecha');");
        $result = pg_query($dbconn, "select release,fecha from huella group by release,fecha order by fecha ASC;");
        $release = pg_fetch_all($result);

    }elseif($_POST['submit'] == 'Comparar'){
        $host = $_POST['host'];
        $port = $_POST['port'];
        $user = $_POST['userss'];
        $pass = $_POST['passss'];
        $database = $_POST['database'];
        $releasecomparar = $_POST['releasecomparar'];
       
        $Conectar = true;
        $dbconn = pg_connect("host=$host port=$port dbname=$database user=$user password=$pass");
        $result = pg_query($dbconn, "select release,fecha from huella group by release,fecha order by fecha ASC;");
        $release = pg_fetch_all($result);

        $result02 = pg_query($dbconn, "delete from huella_tmp;");
        $result02 = pg_query($dbconn, "select fc_validarrelease('$releasecomparar');");
        $Comparacion = pg_fetch_all($result02);

        $result02 = pg_query($dbconn, "select release,fecha,tipo,objecto,codigo,codigo2 from huella_tmp;");
        $Comparacion = pg_fetch_all($result02);
    }
}
 
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Huella Base de Datos</title>
    <script>
        function Selecionar(obj) {
            document.getElementById("releasecomparar").value = obj.value;
        }
    </script>
</head>

<body>
    <div style="margin-left: 15px;">
    <div><h1>Huella Base de Datos</h1></div>
        <div>
            <br>
            <span>
                <h2 style="background-color: red"><?php  echo $mensaje; ?></h2>
            </span>
            <form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
                <label><b>Servidor:</b></label> <input type="text" id="host" name="host" value="localhost" required>
                <label><b>Puerto:</b></label> <input type="text" id="port" name="port" value="5432" required>
                <label><b>Usuario:</b></label> <input type="text" id="userss" name="userss" value="postgres" required>
                <label><b>Clave:</b></label> <input type="password" id="passss" name="passss" value="root" required>
                <label><b>Base de Datos:</b></label> <input type="text" id="database" name="database" value="bank"
                    required>
                <button type="submit" name="submit" value="Conectar">Conectar</button>
            </form>
        </div>
        <div>

            <br>
            <br>
            <div>
                <table border="1">
                    <caption><b>Release Existentes</b></caption>
                    <tr>
                        <th>Release</th>
                        <th>Fecha / Hora</th>
                        <th>Comparar Actual</th>
                    </tr>
                    <?php if(@count($release) > 0){?>
                    <?php  foreach($release as $value){ ?>
                    <tr>
                        <td><b><?php  echo $value['release']; ?></b></td>
                        <td><?php  echo $value['fecha']; ?></td>
                        <td><input type="radio" name="radiocomparar" onclick="Selecionar(this);"
                                value="<?php  echo $value['release']; ?>"></td>
                    </tr>
                    <?php } ?>
                    <?php }?>
                </table>
                <?php if($Conectar){?>
                <br>
                <form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
                    <input type="hidden" id="host" name="host" value="<?php  echo $host; ?>">
                    <input type="hidden" id="port" name="port" value="<?php  echo $port; ?>">
                    <input type="hidden" id="userss" name="userss" value="<?php  echo $user; ?>">
                    <input type="hidden" id="passss" name="passss" value="<?php  echo $pass; ?>">
                    <input type="hidden" id="database" name="database" value="<?php  echo $database; ?>">
                    <input type="hidden" id="database" name="database" value="<?php  echo $database; ?>">
                    <input type="hidden" id="releasecomparar" name="releasecomparar" required>
                    <button type="submit" name="submit" value="Comparar">Comparar</button>
                </form>
                <br><br>

                <form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
                    <input type="hidden" id="host" name="host" value="<?php  echo $host; ?>">
                    <input type="hidden" id="port" name="port" value="<?php  echo $port; ?>">
                    <input type="hidden" id="userss" name="userss" value="<?php  echo $user; ?>">
                    <input type="hidden" id="passss" name="passss" value="<?php  echo $pass; ?>">
                    <input type="hidden" id="database" name="database" value="<?php  echo $database; ?>">
                    <input type="hidden" id="database" name="database" value="<?php  echo $database; ?>">
                    <label><b>Nombre Nuevo Release:</b></label> <input type="text" id="newrelease" name="newrelease"
                        required>
                    <button type="submit" name="submit" value="GenerarReleaseActual">Generar Release Actual</button>
                </form>
                <?php }?>
            </div>


            <br>
            <br>
            <div>
                <table border="1">
                    <caption><b>Comparacion Release</b></caption>
                    <tr>
                        <th>Release</th>
                        <th>Fecha</th>
                        <th>Objecto</th>
                        <th>Código</th>
                        <th>Estado</th>
                    </tr>
                    <?php if(@count($Comparacion) > 0){?>
                    <?php  foreach($Comparacion as $value02){ 
            $backgroundcolor = '';
            if($value02['codigo'] != $value02['codigo2'])
            $backgroundcolor = 'red';
            
            ?>
                    <tr style="background-color: <?php echo $backgroundcolor;  ?>">
                        <td><?php  echo $value02['release']; ?></td>
                        <td><?php  echo $value02['fecha']; ?></td>
                        <td><?php  echo $value02['objecto']; ?></td>
                        <td><?php  echo $value02['codigo']; ?></td>
                        <td><?php  if($value02['codigo'] == $value02['codigo2']){echo "<span style='background-color: green;'>******* OK *******</span>";} else{echo "<span style='background-color: red;'>** MODIFICADO **</span>";}  ?>
                        </td>
                    </tr>
                    <?php } ?>
                    <?php }?>

            </div>
        </div>
    </div>
</body>

</html>