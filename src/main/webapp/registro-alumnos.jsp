<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if (session == null || session.getAttribute("rol") == null || !"docente".equals(session.getAttribute("rol"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String mensaje = request.getParameter("mensaje");
    if (mensaje == null) mensaje = "";
    String tipoAlerta = request.getParameter("tipo");
    if (tipoAlerta == null) tipoAlerta = "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registro de Alumnado Nuevo - ICONOLAB</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        .seccion-bloque { border: 1px solid #ccc; border-radius: 8px; padding: 25px; margin-bottom: 25px; background-color: #fafdfb; }
        .seccion-bloque h3 { margin: 0 0 20px 0; color: #005442; border-bottom: 2px solid #005442; padding-bottom: 5px; font-size: 16px; }
        .grid-2-columnas { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .grid-3-columnas { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; }
        .form-group { margin-bottom: 15px; display: flex; flex-direction: column; }
        .form-group label { font-weight: bold; margin-bottom: 5px; font-size: 14px; }
        .form-group input, .form-group select { padding: 10px; border: 1px solid #ccc; border-radius: 4px; font-size: 14px; }
        .input-matricula-wrapper { display: flex; align-items: center; border: 1px solid #ccc; border-radius: 4px; background: #e9ecef; }
        .input-matricula-wrapper span { padding: 10px; font-weight: bold; color: #495057; border-right: 1px solid #ccc; }
        .input-matricula-wrapper input { border: none; background: transparent; width: 100%; padding: 10px; }
        .btn-accion { background-color: #005442; color: white; border: none; padding: 12px 25px; border-radius: 6px; cursor: pointer; font-weight: bold; font-size: 15px; }
        .btn-accion:hover { background-color: #0b2f27; }
        .btn-cancelar { background-color: #6c757d; color: white; padding: 12px 25px; border-radius: 6px; text-decoration: none; font-weight: bold; display: inline-block; text-align: center; }
        .btn-cancelar:hover { background-color: #5a6268; }
        .alerta-exito { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; padding: 12px; border-radius: 6px; margin-bottom: 15px; }
        .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; padding: 12px; border-radius: 6px; margin-bottom: 15px; }
    </style>
</head>
<body class="bitacora-body">

<div class="container" style="max-width: 900px; margin: 30px auto; padding: 20px;">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px;">
        <h2 style="margin: 0; color: #005442;">Registro de Alumnado Nuevo</h2>
        <a href="bitacoras-docentes.jsp" class="btn-cancelar">Volver</a>
    </div>

    <% if (!mensaje.isEmpty()) { %>
        <div class="<%= tipoAlerta.equals("exito") ? "alerta-exito" : "alerta-error" %>">
            <%= mensaje %>
        </div>
    <% } %>

    <form action="RegistroAlumnosServlet" method="POST">
        <div class="seccion-bloque">
            <h3>Formulario de Alta de Estudiante</h3>

            <div class="grid-2-columnas">
                <div class="form-group">
                    <label>Apellido Paterno:</label>
                    <input type="text" name="apellido_paterno" required placeholder="Ej. Pérez" oninput="validarSoloLetras(this)">
                </div>
                <div class="form-group">
                    <label>Apellido Materno:</label>
                    <input type="text" name="apellido_materno" required placeholder="Ej. Hernández" oninput="validarSoloLetras(this)">
                </div>
            </div>

            <div class="form-group">
                <label>Nombre(s):</label>
                <input type="text" name="nombre" required placeholder="Ej. Carlos Alberto" oninput="validarSoloLetras(this)">
            </div>

            <div class="grid-3-columnas">
                <div class="form-group">
                    <label>Matrícula:</label>
                    <div class="input-matricula-wrapper">
                        <span>1224</span>
                        <input type="text" name="matricula" required placeholder="0000" maxlength="6" oninput="validarSoloNumeros(this)">
                    </div>
                </div>

                <div class="form-group">
                    <label>Cuatrimestre:</label>
                    <select name="cuatrimestre" required>
                        <option value="">Selecciona cuatrimestre...</option>
                        <option value="1° Cuatrimestre">1° Cuatrimestre</option>
                        <option value="2° Cuatrimestre">2° Cuatrimestre</option>
                        <option value="3° Cuatrimestre">3° Cuatrimestre</option>
                        <option value="4° Cuatrimestre">4° Cuatrimestre</option>
                        <option value="5° Cuatrimestre">5° Cuatrimestre</option>
                        <option value="6° Cuatrimestre">6° Cuatrimestre</option>
                        <option value="7° Cuatrimestre">7° Cuatrimestre</option>
                        <option value="8° Cuatrimestre">8° Cuatrimestre</option>
                        <option value="9° Cuatrimestre">9° Cuatrimestre</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>Turno:</label>
                    <select name="turno" required>
                        <option value="">Selecciona turno...</option>
                        <option value="Matutino">Matutino</option>
                        <option value="Vespertino">Vespertino</option>
                    </select>
                </div>
            </div>

            <div class="grid-2-columnas" style="margin-top: 10px;">
                <div class="form-group">
                    <label>Grupo:</label>
                    <select name="grupo" required>
                        <option value="">Selecciona grupo...</option>
                        <%
                        for (int i = 1; i <= 9; i++) {
                            for (int j = 1; j <= 4; j++) {
                                int numGrupo = (i * 100) + j;
                        %>
                                <option value="<%= numGrupo %>"><%= numGrupo %></option>
                        <%
                            }
                        }
                        %>
                    </select>
                </div>

                <div class="form-group">
                    <label>Carrera / Área:</label>
                    <select name="carrera" required>
                        <option value="">Selecciona carrera o área...</option>
                        <option value="Licenciatura en Administración">Licenciatura en Administración</option>
                        <option value="Licenciatura en Enfermería">Licenciatura en Enfermería</option>
                        <option value="Licenciatura en Terapia Física">Licenciatura en Terapia Física</option>
                        <option value="Ingeniería en Alimentos">Ingeniería en Alimentos</option>
                        <option value="Ingeniería en Biotecnología">Ingeniería en Biotecnología</option>
                        <option value="Ingeniería Industrial">Ingeniería Industrial</option>
                        <option value="Ingeniería en Logística">Ingeniería en Logística</option>
                        <option value="Ingeniería Mecánica Automotriz">Ingeniería Mecánica Automotriz</option>
                        <option value="Ingeniería Mecatrónica">Ingeniería Mecatrónica</option>
                        <option value="Ingeniería en Nanotecnología">Ingeniería en Nanotecnología</option>
                        <option value="Ingeniería en Tecnologías de la Información e Innovación Digital">Ingeniería en Tecnologías de la Información e Innovación Digital</option>
                        <option value="Maestría en Alta Dirección de las Organizaciones">Maestría en Alta Dirección de las Organizaciones</option>
                        <option value="Maestría en Ciencias en Micro y Nanotecnologías">Maestría en Ciencias en Micro y Nanotecnologías</option>
                        <option value="Maestría en Formación de Formadores de Docentes de Ciencias Naturales">Maestría en Formación de Formadores de Docentes de Ciencias Naturales</option>
                        <option value="Maestría en Ingeniería para la Optimización de Procesos de Manufactura">Maestría en Ingeniería para la Optimización de Procesos de Manufactura</option>
                        <option value="Maestría en Ingeniería Mecatrónica">Maestría en Ingeniería Mecatrónica</option>
                        <option value="Maestría en Tecnologías de la Información y Comunicaciones">Maestría en Tecnologías de la Información y Comunicaciones</option>
                        <option value="Doctorado en Ciencia de Materiales">Doctorado en Ciencia de Materiales</option>
                    </select>
                </div>
            </div>
        </div>

        <div style="display: flex; justify-content: center; gap: 20px; margin-top: 20px;">
            <a href="bitacoras-docentes.jsp" class="btn-cancelar">Cancelar</a>
            <button type="submit" class="btn-accion">Registrar usuario</button>
        </div>
    </form>
</div>

<script>
function validarSoloLetras(input) {
    input.value = input.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, '');
}

function validarSoloNumeros(input) {
    input.value = input.value.replace(/[^0-9]/g, '');
}
</script>

</body>
</html>