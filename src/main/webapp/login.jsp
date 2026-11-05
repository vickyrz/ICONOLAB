<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>¡Bienvenid@! - Login</title>
    <style>
        body {
            background-color: #f4f6f9;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
        }
        .login-card-pro {
            background: white;
            padding: 40px 35px;
            border-radius: 12px;
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.08);
            width: 100%;
            max-width: 420px;
            box-sizing: border-box;
        }
        .login-card-pro h1 {
            color: #005442;
            font-size: 28px;
            margin: 0 0 8px 0;
            text-align: center;
        }
        .login-card-pro p {
            color: #666;
            font-size: 14px;
            margin: 0 0 25px 0;
            text-align: center;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: bold;
            font-size: 14px;
        }
        .form-group input, .form-group select {
            width: 100%;
            padding: 12px;
            border: 1px solid #ccc;
            border-radius: 6px;
            box-sizing: border-box;
            font-size: 14px;
        }
        .btn-submit-pro {
            width: 100%;
            background-color: #005442;
            color: white;
            border: none;
            padding: 12px;
            border-radius: 6px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.2s;
        }
        .btn-submit-pro:hover {
            background-color: #0b2f27;
        }
        .error-msg {
            color: #c92a2a;
            background-color: #ffe3e3;
            border: 1px solid #ffc9c9;
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 13px;
            text-align: center;
        }
    </style>
</head>
<body>

<div class="login-card-pro">
    <h1>¡Bienvenid@!</h1>
    <p>Introduce tu contraseña para acceder</p>

    <%
        // Recogemos los errores enviados desde el Servlet de forma dinámica
        String errorMsg = request.getParameter("error");
        if (errorMsg != null && !errorMsg.isEmpty()) {
    %>
            <div class="error-msg"><%= errorMsg %></div>
    <%
        }
    %>

    <form action="LoginServlet" method="POST" onsubmit="return validarFormulario()">
        <div class="form-group">
            <label for="usuario">Usuario:</label>
            <select id="usuario" name="usuario" required onchange="actualizarRestricciones()">
                <option value="">Selecciona tu usuario</option>
                <option value="estudiante">Estudiante</option>
                <option value="docente">Docente</option>
                <option value="tecnico">Técnico</option>
            </select>
        </div>

        <div class="form-group">
            <label for="matricula">Contraseña:</label>
            <input type="password" id="matricula" name="matricula" placeholder="Selecciona un usuario primero" required autocomplete="off">
        </div>

        <button type="submit" class="btn-submit-pro">Ingresar</button>
    </form>
</div>

<script>
    function actualizarRestricciones() {
        const usuario = document.getElementById('usuario').value;
        const inputMatricula = document.getElementById('matricula');

        inputMatricula.oninput = null;
        inputMatricula.removeAttribute('maxlength');
        inputMatricula.value = "";

        if (usuario === 'estudiante' || usuario === 'tecnico') {
            inputMatricula.placeholder = "Ingresa tu contraseña de 10 dígitos";
            inputMatricula.maxLength = 10;
            inputMatricula.oninput = function() {
                this.value = this.value.replace(/[^0-9]/g, '');
            };
        } else if (usuario === 'docente') {
            inputMatricula.placeholder = "Ingresa tu contraseña";
        } else {
            inputMatricula.placeholder = "Selecciona un usuario primero";
        }
    }

    function validarFormulario() {
        const usuario = document.getElementById('usuario').value;
        const inputMatricula = document.getElementById('matricula').value.trim();

        if (usuario === 'estudiante' || usuario === 'tecnico') {
            if (inputMatricula.length !== 10) {
                alert("La contraseña debe tener exactamente 10 dígitos.");
                return false;
            }
        } else if (usuario === 'docente') {
            if (inputMatricula === "") {
                alert("Por favor, introduce tu contraseña.");
                return false;
            }
        }
        return true;
    }
</script>

</body>
</html>