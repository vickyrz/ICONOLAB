<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.example.iconolab.conexion.ConexionBD" %>
<%
    // Validar sesión de estudiante
    if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("estudiante")) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Obtener lista de docentes para el autocompletado de forma dinámica
    List<Map<String, String>> docentesList = new ArrayList<>();
    try (Connection conn = ConexionBD.conectar();
         Statement st = conn.createStatement();
         ResultSet rs = st.executeQuery("SELECT nombre, apellido_paterno, apellido_materno, matricula FROM usuarios WHERE rol = 'docente'")) {

        while (rs.next()) {
            String nombreCompleto = (rs.getString("nombre") + " " + rs.getString("apellido_paterno") + " " + rs.getString("apellido_materno")).trim();
            Map<String, String> doc = new HashMap<>();
            doc.put("nombre_completo", nombreCompleto);
            doc.put("matricula", rs.getString("matricula"));
            docentesList.add(doc);
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    String errorMensaje = request.getParameter("error");
    if (errorMensaje == null) errorMensaje = "";

    String nombreAlumno = session.getAttribute("nombre") + " " + session.getAttribute("apellido_paterno") + " " + session.getAttribute("apellido_materno");
    String matriculaAlumno = (String) session.getAttribute("matricula");
    String grupoAlumno = session.getAttribute("grupo") != null ? (String) session.getAttribute("grupo") : "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bitácora de Laboratorios - Estudiantes</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
        .seccion-bloque { border: 1px solid #dcdde1; border-radius: 8px; padding: 20px; margin-bottom: 25px; background-color: #fafdfb; }
        .seccion-bloque h3 { margin: 0 0 20px 0; color: #005442; border-bottom: 2px solid #005442; padding-bottom: 5px; font-size: 16px; }
        .grid-2-columnas { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .grid-3-columnas { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; }
        .grid-dinamico-practica { display: grid; grid-template-columns: 1fr 3fr; gap: 15px; }
        .row-inline { display: flex; gap: 10px; align-items: flex-end; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; font-size: 14px; }
        .form-group input, .form-group select, .form-group textarea { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px; box-sizing: border-box; font-size: 14px; }
        .btn-aceptar { background-color: #005442; color: white; border: none; padding: 10px 15px; border-radius: 6px; cursor: pointer; font-weight: bold; height: 42px; }
        .btn-aceptar:hover { background-color: #0b2f27; }
        .btn-block { width: 100%; background-color: #005442; color: white; border: none; padding: 12px; border-radius: 6px; font-size: 16px; font-weight: bold; cursor: pointer; }
        .btn-block:hover { background-color: #0b2f27; }
        .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; padding: 12px; border-radius: 6px; margin-bottom: 20px; }
    </style>
</head>
<body>

<div class="container">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h2 style="margin: 0; color: #005442;">Bitácoras de Laboratorios</h2>
        <a href="login.jsp" style="color: #c92a2a; font-weight: bold; text-decoration: none; border: 1px solid #c92a2a; padding: 6px 12px; border-radius: 4px;">Salir sin guardar</a>
    </div>

    <% if (!errorMensaje.isEmpty()) { %>
        <div class="alerta-error"><%= errorMensaje %></div>
    <% } %>

    <form action="EstudianteServlet" method="POST" onsubmit="return validarFormulario();">
        <div class="seccion-bloque">
            <h3>Datos del Estudiante <span style="color: red;">*</span></h3>

            <div class="grid-2-columnas">
                <div class="form-group">
                    <label>Nombre del Alumno:</label>
                    <input type="text" value="<%= nombreAlumno %>" readonly style="background-color: #e9ecef;">
                </div>
                <div class="form-group">
                    <label>Matrícula:</label>
                    <input type="text" name="matricula" value="<%= matriculaAlumno %>" readonly style="background-color: #e9ecef;">
                </div>
            </div>

            <div class="grid-2-columnas" style="margin-top: 15px;">
                <div class="form-group">
                    <label>Carrera:</label>
                    <select name="carrera" required>
                        <option value="">Selecciona tu carrera...</option>
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
                <div class="form-group">
                    <label>Grupo:</label>
                    <input type="text" name="grupo" value="<%= grupoAlumno %>" readonly style="background-color: #e9ecef;">
                </div>
            </div>

            <div class="grid-2-columnas" style="margin-top: 15px;">
                <div class="form-group">
                    <label>Materia:</label>
                    <input type="text" name="materia" placeholder="Ingresa la materia" required oninput="validarTextoCoherente(this)">
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
        </div>

        <div class="seccion-bloque">
            <h3>Datos de la Práctica <span style="color: red;">*</span></h3>

            <div class="grid-2-columnas" style="align-items: flex-end;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label>Nombre del docente:</label>
                    <input type="text" id="nombre_docente" name="nombre_docente" placeholder="Escribe el nombre del docente" required oninput="validarSoloLetras(this); document.getElementById('folio_docente').value = '';">
                </div>
                <div class="row-inline">
                    <button type="button" class="btn-aceptar" onclick="buscarFolioDocente()">Aceptar</button>
                    <div class="form-group" style="flex: 1; margin-bottom: 0;">
                        <label>Matrícula Docente:</label>
                        <input type="text" id="folio_docente" name="folio_docente" placeholder="Se autocompleta" readonly required style="background-color: #e9ecef;">
                    </div>
                </div>
            </div>

            <div class="grid-3-columnas" style="margin-top: 15px;">
                <div class="form-group">
                    <label>Fecha:</label>
                    <input type="date" name="fecha" value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>" required>
                </div>
                <div class="form-group">
                    <label>Hora de entrada:</label>
                    <input type="time" name="hora_entrada" value="<%= new java.text.SimpleDateFormat("HH:mm").format(new java.util.Date()) %>" required>
                </div>
                <div class="form-group">
                    <label>Hora de salida:</label>
                    <input type="time" name="hora_salida" required>
                </div>
            </div>

            <div class="grid-2-columnas" style="margin-top: 15px;">
                <div class="form-group">
                    <label>No. PC:</label>
                    <select name="num_pc" required>
                        <option value="">Selecciona No. PC...</option>
                        <% for (int i = 1; i <= 12; i++) { %>
                            <option value="<%= i %>"><%= i %></option>
                        <% } %>
                    </select>
                </div>
                <div class="form-group">
                    <label>Laboratorio:</label>
                    <select name="laboratorio" required>
                        <option value="">Selecciona tu laboratorio...</option>
                        <option value="LTI1">LTI1</option>
                        <option value="LTI2">LTI2</option>
                        <option value="Academia de Hardware y Redes 1">Academia de Hardware y Redes 1</option>
                        <option value="Academia de Hardware y Redes 2">Academia de Hardware y Redes 2</option>
                        <option value="LP1">LP1</option>
                        <option value="LP2">LP2</option>
                    </select>
                </div>
            </div>

            <div class="grid-dinamico-practica" style="margin-top: 15px;">
                <div class="form-group">
                    <label>Práctica no.:</label>
                    <input type="text" name="practica_no" placeholder="Ej. 1" required oninput="validarSoloNumeros(this);">
                </div>
                <div class="form-group">
                    <label>Nombre de la práctica:</label>
                    <input type="text" name="nombre_practica" placeholder="Nombre de la práctica" required oninput="validarTextoCoherente(this)">
                </div>
            </div>
        </div>

        <div class="seccion-bloque">
            <h3>Reporte de Incidencias (Opcional)</h3>
            <div class="form-group">
                <label>Fallas/Observaciones:</label>
                <textarea name="fallas_observaciones" rows="3" placeholder="Ninguna..."></textarea>
            </div>
            <div class="form-group" style="margin-top: 15px;">
                <label>No. Reporte (Si aplica):</label>
                <input type="text" name="num_reporte" placeholder="Ej. REP-89">
            </div>
        </div>

        <button type="submit" class="btn-block">Guardar Registro en Bitácora</button>
    </form>
</div>

<script>
// Convertir la lista de docentes de Java a un arreglo JSON en JavaScript
const docentesData = [
    <% for(int i = 0; i < docentesList.size(); i++) {
        Map<String, String> doc = docentesList.get(i);
    %>
        { "nombre_completo": "<%= doc.get("nombre_completo").toLowerCase() %>", "matricula": "<%= doc.get("matricula") %>" }<%= (i < docentesList.size() - 1) ? "," : "" %>
    <% } %>
];

function buscarFolioDocente() {
    const inputNombre = document.getElementById('nombre_docente').value.trim().toLowerCase();
    const inputFolio = document.getElementById('folio_docente');

    if (inputNombre === '') {
        alert('Por favor, escribe el nombre del docente primero.');
        return;
    }

    const encontrado = docentesData.find(
        doc => doc.nombre_completo === inputNombre
    );

    if (encontrado) {
        inputFolio.value = encontrado.matricula;
        alert('¡Matrícula de docente encontrada con éxito!');
    } else {
        inputFolio.value = '';
        alert('Docente no encontrado. Verifica el nombre.');
    }
}

function validarFormulario() {
    const folio = document.getElementById('folio_docente').value.trim();
    if (folio === '') {
        alert("Debes confirmar una matrícula válida usando el botón 'Aceptar'.");
        document.getElementById('nombre_docente').focus();
        return false;
    }

    const nombrePractica = document.querySelector('input[name="nombre_practica"]').value.trim();
    const materia = document.querySelector('input[name="materia"]').value.trim();

    if (nombrePractica.length < 3) {
        alert("El nombre de la práctica debe tener al menos 3 caracteres.");
        return false;
    }
    if (materia.length < 3) {
        alert("El nombre de la materia debe tener al menos 3 caracteres.");
        return false;
    }

    return true;
}

function validarTextoCoherente(input) {
    input.value = input.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s]/g, '');
}

function validarSoloLetras(input) {
    input.value = input.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, '');
}

function validarSoloNumeros(input) {
    input.value = input.value.replace(/[^0-9]/g, '');
}
</script>

</body>
</html>