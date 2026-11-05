<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")
            || session.getAttribute("es_encargado") == null || Integer.parseInt(session.getAttribute("es_encargado").toString()) != 1) {
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
    <title>Gestión de Usuarios - Administrador</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: 30px auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
        .seccion-bloque { border: 1px solid #ccc; border-radius: 8px; padding: 25px; margin-bottom: 25px; background-color: #fafdfb; }
        .seccion-bloque h3 { margin: 0 0 20px 0; color: #005442; border-bottom: 2px solid #005442; padding-bottom: 5px; font-size: 16px; }
        .grid-2-columnas { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .grid-3-columnas { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; }
        .form-group { margin-bottom: 15px; display: flex; flex-direction: column; }
        .form-group label { font-weight: bold; margin-bottom: 5px; font-size: 14px; }
        .form-group input, .form-group select { padding: 10px; border: 1px solid #ccc; border-radius: 4px; font-size: 14px; }
        .btn-accion { background-color: #005442; color: white; border: none; padding: 12px 25px; border-radius: 6px; cursor: pointer; font-weight: bold; font-size: 15px; }
        .btn-accion:hover { background-color: #0b2f27; }
        .btn-cancelar { background-color: #6c757d; color: white; padding: 12px 25px; border-radius: 6px; text-decoration: none; font-weight: bold; display: inline-block; text-align: center; }
        .btn-cancelar:hover { background-color: #5a6268; }
        .alerta-exito { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; padding: 12px; border-radius: 6px; margin-bottom: 15px; }
        .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; padding: 12px; border-radius: 6px; margin-bottom: 15px; }
        .oculto { display: none !important; }
    </style>
</head>
<body>

<div class="container">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px;">
        <h2 style="margin: 0; color: #005442;">Panel de Administración - Gestión Global de Usuarios</h2>
        <a href="panel-administrador.jsp" class="btn-cancelar">Volver al Panel</a>
    </div>

    <% if (!mensaje.isEmpty()) { %>
        <div class="<%= tipoAlerta.equals("exito") ? "alerta-exito" : "alerta-error" %>">
            <%= mensaje %>
        </div>
    <% } %>

    <form action="UsuarioAdminServlet" method="POST">
        <div class="seccion-bloque">
            <h3>Alta de Nuevo Usuario (Docente, Técnico o Estudiante)</h3>

            <div class="form-group">
                <label>Selecciona el Rol del Usuario a Registrar:</label>
                <div style="display: flex; gap: 20px; padding: 12px; background: #ffffff; border: 1px solid #ccc; border-radius: 6px;">
                    <label><input type="radio" name="rol" value="docente" checked required onchange="toggleCamposEstudiante()"> Docente</label>
                    <label><input type="radio" name="rol" value="tecnico" required onchange="toggleCamposEstudiante()"> Personal Técnico</label>
                    <label><input type="radio" name="rol" value="estudiante" required onchange="toggleCamposEstudiante()"> Estudiante</label>
                </div>
            </div>

            <div class="grid-2-columnas">
                <div class="form-group">
                    <label>Apellido Paterno:</label>
                    <input type="text" name="apellido_paterno" required placeholder="Ej. Pérez" oninput="validarSoloLetras(this)">
                </div>
                <div class="form-group">
                    <label>Apellido Materno:</label>
                    <input type="text" name="apellido_materno" required placeholder="Ej. Gómez" oninput="validarSoloLetras(this)">
                </div>
            </div>

            <div class="form-group">
                <label>Nombre(s):</label>
                <input type="text" name="nombre" required placeholder="Ej. Laura Elena" oninput="validarSoloLetras(this)">
            </div>

            <div class="grid-3-columnas">
                <div class="form-group">
                    <label>Matrícula/Contraseña (10 dígitos):</label>
                    <input type="text" name="matricula" required placeholder="Ej. 2672000000" maxlength="10" oninput="validarSoloNumeros(this)">
                </div>

                <div class="form-group">
                    <label>Turno:</label>
                    <select name="turno" required>
                        <option value="">Selecciona turno...</option>
                        <option value="Matutino">Matutino</option>
                        <option value="Vespertino">Vespertino</option>
                    </select>
                </div>

                <div class="form-group campo-estudiante">
                    <label>Cuatrimestre:</label>
                    <select name="cuatrimestre" id="cuatrimestre">
                        <option value="">Selecciona cuatrimestre...</option>
                        <%
                        String[] nombresCuatris = {"1ro", "2do", "3ro", "4to", "5to", "6to", "7mo", "8vo", "9no"};
                        for (String cuatVal : nombresCuatris) {
                        %>
                            <option value="<%= cuatVal %>"><%= cuatVal %></option>
                        <% } %>
                    </select>
                </div>
            </div>

            <div class="grid-2-columnas campo-estudiante" style="margin-top: 10px;">
                <div class="form-group">
                    <label>Grupo:</label>
                    <select name="grupo" id="grupo">
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
                    <select name="carrera" id="carrera">
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
            <a href="panel-administrador.jsp" class="btn-cancelar">Cancelar</a>
            <button type="submit" class="btn-accion">Registrar en el Sistema</button>
        </div>
    </form>
</div>

<script>
function toggleCamposEstudiante() {
    const rolSeleccionado = document.querySelector('input[name="rol"]:checked').value;
    const elementosEstudiante = document.querySelectorAll('.campo-estudiante');
    const inputCuatrimestre = document.getElementById('cuatrimestre');
    const inputGrupo = document.getElementById('grupo');
    const inputCarrera = document.getElementById('carrera');

    if (rolSeleccionado === 'estudiante') {
        elementosEstudiante.forEach(el => el.classList.remove('oculto'));
        inputCuatrimestre.setAttribute('required', 'required');
        inputGrupo.setAttribute('required', 'required');
        inputCarrera.setAttribute('required', 'required');
    } else {
        elementosEstudiante.forEach(el => el.classList.add('oculto'));
        inputCuatrimestre.removeAttribute('required');
        inputGrupo.removeAttribute('required');
        inputCarrera.removeAttribute('required');
        inputCuatrimestre.value = '';
        inputGrupo.value = '';
        inputCarrera.value = '';
    }
}

document.addEventListener("DOMContentLoaded", function() {
    toggleCamposEstudiante();
});

function validarSoloLetras(input) {
    input.value = input.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, '');
}

function validarSoloNumeros(input) {
    input.value = input.value.replace(/[^0-9]/g, '').slice(0, 10);
}
</script>

</body>
</html>