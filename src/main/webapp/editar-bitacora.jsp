<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, com.example.iconolab.conexion.ConexionBD" %>
<%
    if (session == null || session.getAttribute("rol") == null || !"docente".equals(session.getAttribute("rol"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String idStr = request.getParameter("id");
    int idBitacora = 0;
    try {
        if (idStr != null) {
            idBitacora = Integer.parseInt(idStr);
        }
    } catch (NumberFormatException ignored) {}

    if (idBitacora <= 0) {
        response.sendRedirect("panel-administrador.jsp");
        return;
    }

    Map<String, Object> doc = new HashMap<>();
    doc.put("laboratorio", "");
    doc.put("fecha", new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()));
    doc.put("nombre_docente", "");
    doc.put("matricula_docente", "");
    doc.put("calificacion_servicio", "Regular");
    doc.put("observaciones_docente", "");
    doc.put("total_alumnos", 0);

    Map<String, Object> primerEstudiante = null;
    List<Map<String, Object>> listaEstudiantes = new ArrayList<>();
    Map<String, Object> tec = new HashMap<>();
    tec.put("hora_entrada", "");
    tec.put("hora_salida", "");
    tec.put("uso_internet", "No");
    tec.put("observaciones_tecnico", "");
    tec.put("nombre_tecnico", "");
    tec.put("firma_tecnico", "");

    try (Connection conn = ConexionBD.conectar()) {
        // Consultar datos del docente
        try (PreparedStatement pst = conn.prepareStatement("SELECT * FROM bitacoras_docentes WHERE id_bitacora = ?")) {
            pst.setInt(1, idBitacora);
            try (ResultSet rs = pst.executeQuery()) {
                if (rs.next()) {
                    ResultSetMetaData meta = rs.getMetaData();
                    for (int i = 1; i <= meta.getColumnCount(); i++) {
                        doc.put(meta.getColumnName(i), rs.getObject(i));
                    }
                }
            }
        }

        // Consultar datos de la práctica desde el primer estudiante
        try (PreparedStatement pst = conn.prepareStatement("SELECT e.*, u.nombre, u.apellido_paterno, u.apellido_materno FROM bitacoras_estudiantes e LEFT JOIN usuarios u ON e.matricula = u.matricula WHERE e.id_bitacora = ? LIMIT 1")) {
            pst.setInt(1, idBitacora);
            try (ResultSet rs = pst.executeQuery()) {
                if (rs.next()) {
                    primerEstudiante = new HashMap<>();
                    ResultSetMetaData meta = rs.getMetaData();
                    for (int i = 1; i <= meta.getColumnCount(); i++) {
                        primerEstudiante.put(meta.getColumnName(i), rs.getObject(i));
                    }
                }
            }
        }

        // Consultar todos los estudiantes para la tabla de alumnos
        try (PreparedStatement pst = conn.prepareStatement("SELECT e.*, u.nombre, u.apellido_paterno, u.apellido_materno FROM bitacoras_estudiantes e LEFT JOIN usuarios u ON e.matricula = u.matricula WHERE e.id_bitacora = ?")) {
            pst.setInt(1, idBitacora);
            try (ResultSet rs = pst.executeQuery()) {
                ResultSetMetaData meta = rs.getMetaData();
                while (rs.next()) {
                    Map<String, Object> est = new HashMap<>();
                    for (int i = 1; i <= meta.getColumnCount(); i++) {
                        est.put(meta.getColumnName(i), rs.getObject(i));
                    }
                    listaEstudiantes.add(est);
                }
            }
        }

        // Consultar datos del técnico
        try (PreparedStatement pst = conn.prepareStatement("SELECT * FROM bitacoras_tecnicos WHERE id_bitacora = ?")) {
            pst.setInt(1, idBitacora);
            try (ResultSet rs = pst.executeQuery()) {
                if (rs.next()) {
                    ResultSetMetaData meta = rs.getMetaData();
                    for (int i = 1; i <= meta.getColumnCount(); i++) {
                        tec.put(meta.getColumnName(i), rs.getObject(i));
                    }
                }
            }
        }

    } catch (Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Formato Único de Bitácora</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        body { background-color: #f4f6f5; font-family: Arial, sans-serif; }
        .documento-unificado { max-width: 950px; margin: 30px auto; background: #fff; padding: 30px; border: 1px solid #ccc; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        .form-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 13px; }
        .form-table th, .form-table td { border: 1px solid #333; padding: 6px 8px; vertical-align: middle; }
        .form-table th { background-color: #d9d9d9; color: #000; text-align: center; font-weight: bold; }
        input[type="text"], input[type="date"], input[type="time"], input[type="number"], select, textarea {
            width: 100%; border: none; background: transparent; font-size: 13px; outline: none; padding: 3px; box-sizing: border-box;
        }
        input:focus, textarea:focus { background: #eef5f2; border-radius: 3px; }
        .seccion-titulo-barra { background-color: #333; color: #fff; text-align: center; font-weight: bold; padding: 6px; font-size: 14px; text-transform: uppercase; margin-top: 15px; margin-bottom: 0; }
        .top-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
        .btn-regresar { background: #c92a2a; color: white; padding: 8px 15px; border-radius: 5px; text-decoration: none; font-weight: bold; }
        .btn-regresar:hover { background: #a51d1d; }
        .btn-guardar { background: #005442; color: white; padding: 12px 20px; border: none; border-radius: 5px; font-weight: bold; cursor: pointer; width: 100%; font-size: 16px; margin-top: 20px; }
        .btn-guardar:hover { background: #0b2f27; }
    </style>
    <script>
        function confirmarCancelar(event) {
            event.preventDefault();
            if (confirm("¿Seguro que quiere salir sin guardar? Se perderán los cambios no guardados.")) {
                window.location.href = "panel-administrador.jsp";
            }
        }
    </script>
</head>
<body>

<div class="documento-unificado">
    <div class="top-actions">
        <h2 style="color: #005442; margin: 0;">Edición de Bitácora Integral</h2>
        <a href="panel-administrador.jsp" class="btn-regresar" onclick="confirmarCancelar(event)">Cancelar / Volver</a>
    </div>

    <form action="EditarBitacoraServlet?id=<%= idBitacora %>" method="POST">

        <!-- DATOS GENERALES Y CLASE -->
        <table class="form-table">
            <tr>
                <td style="width: 15%;"><strong>Laboratorio:</strong></td>
                <td style="width: 50%;"><input type="text" name="laboratorio" value="<%= doc.getOrDefault("laboratorio", "") %>"></td>
                <td style="width: 15%;"><strong>Fecha:</strong></td>
                <td style="width: 20%;"><input type="date" name="fecha" value="<%= doc.getOrDefault("fecha", "") %>" required></td>
            </tr>
        </table>

        <table class="form-table">
            <tr>
                <td style="width: 15%;"><strong>Docente:</strong></td>
                <td style="width: 60%;"><input type="text" name="nombre_docente" value="<%= doc.getOrDefault("nombre_docente", "") %>" required></td>
                <td style="width: 10%;"><strong>Matrícula:</strong></td>
                <td style="width: 15%;"><input type="text" name="folio_docente" value="<%= doc.getOrDefault("matricula_docente", "") %>" required></td>
            </tr>
            <tr>
                <td><strong>Carrera:</strong></td>
                <td><input type="text" name="carrera" value="<%= primerEstudiante != null ? primerEstudiante.getOrDefault("carrera", "") : "" %>"></td>
                <td><strong>Grupo:</strong></td>
                <td><input type="text" name="grupo" value="<%= primerEstudiante != null ? primerEstudiante.getOrDefault("grupo", "") : "" %>"></td>
            </tr>
            <tr>
                <td><strong>Turno:</strong></td>
                <td><input type="text" name="turno" value="<%= primerEstudiante != null ? primerEstudiante.getOrDefault("turno", "") : "" %>"></td>
                <td><strong>Materia:</strong></td>
                <td><input type="text" name="materia" value="<%= primerEstudiante != null ? primerEstudiante.getOrDefault("materia", "") : "" %>"></td>
            </tr>
            <tr>
                <td><strong>Práctica no.:</strong></td>
                <td><input type="text" name="practica_no" value="<%= primerEstudiante != null ? primerEstudiante.getOrDefault("practica_no", "") : "" %>"></td>
                <td colspan="2"><strong>Nombre:</strong> <input type="text" name="nombre_practica" style="width: 75%; display:inline-block;" value="<%= primerEstudiante != null ? primerEstudiante.getOrDefault("nombre_practica", "") : "" %>"></td>
            </tr>
        </table>

        <!-- ESTUDIANTES -->
        <table class="form-table" style="margin-top: 10px;">
            <thead>
                <tr>
                    <th style="width: 8%;">No. PC</th>
                    <th style="width: 32%;">Nombre del Alumno</th>
                    <th style="width: 20%;">Firma</th>
                    <th style="width: 30%;">Fallas / Observaciones</th>
                    <th style="width: 10%;">No. Reporte</th>
                </tr>
            </thead>
            <tbody>
                <%
                if (!listaEstudiantes.isEmpty()) {
                    for(Map<String, Object> est : listaEstudiantes) {
                        String nombre = est.get("nombre") != null ? est.get("nombre").toString() : "";
                        String apP = est.get("apellido_paterno") != null ? est.get("apellido_paterno").toString() : "";
                        String apM = est.get("apellido_materno") != null ? est.get("apellido_materno").toString() : "";
                        String nombreCompleto = (nombre + " " + apP + " " + apM).trim();
                        if(nombreCompleto.isEmpty()) nombreCompleto = "Matrícula: " + est.get("matricula");
                        String idDetalle = est.get("id_detalle").toString();
                %>
                <tr>
                    <td style="text-align: center;"><input type="text" name="alumnos[<%= idDetalle %>][num_pc]" value="<%= est.getOrDefault("num_pc", "") %>" style="text-align: center;"></td>
                    <td><%= nombreCompleto %></td>
                    <td style="font-family:'Comic Sans MS', cursive; font-weight:bold; color:#005442;"><%= nombreCompleto %></td>
                    <td><input type="text" name="alumnos[<%= idDetalle %>][fallas_observaciones]" value="<%= est.getOrDefault("fallas_observaciones", "") %>"></td>
                    <td style="text-align: center;"><input type="text" name="alumnos[<%= idDetalle %>][num_reporte]" value="<%= est.getOrDefault("num_reporte", "") %>" style="text-align: center;"></td>
                </tr>
                <%
                    }
                } else {
                %>
                <tr><td colspan='5' style='text-align:center; color:#777;'>No hay estudiantes registrados para esta bitácora.</td></tr>
                <% } %>
            </tbody>
        </table>

        <!-- SECCIÓN DOCENTE -->
        <div class="seccion-titulo-barra">Para ser llenado por el Docente</div>
        <table class="form-table" style="border-top: none;">
            <tr>
                <td style="width: 35%;"><strong>¿Cómo calificas el servicio recibido?</strong></td>
                <td>
                    <% String cs = doc.getOrDefault("calificacion_servicio", "Regular").toString(); %>
                    Malo [<input type="radio" name="calificacion_servicio" value="Malo" <%= "Malo".equals(cs) ? "checked" : "" %>>]
                    Regular [<input type="radio" name="calificacion_servicio" value="Regular" <%= "Regular".equals(cs) ? "checked" : "" %>>]
                    Bueno [<input type="radio" name="calificacion_servicio" value="Bueno" <%= "Bueno".equals(cs) ? "checked" : "" %>>]
                    Excelente [<input type="radio" name="calificacion_servicio" value="Excelente" <%= "Excelente".equals(cs) ? "checked" : "" %>>]
                </td>
            </tr>
            <tr>
                <td colspan="2">
                    <strong>Observaciones del docente:</strong><br>
                    <textarea name="observaciones_docente" rows="3"><%= doc.getOrDefault("observaciones_docente", "") %></textarea>
                </td>
            </tr>
            <tr>
                <td><strong>Total de Alumnos atendidos:</strong> <input type="number" name="total_alumnos" value="<%= doc.getOrDefault("total_alumnos", 0) %>" style="width: 60px; display:inline-block; border: 1px solid #ccc; text-align:center;"></td>
                <td><strong>Firma del docente:</strong> <input type="text" value="<%= doc.getOrDefault("nombre_docente", "") %>" readonly style="font-family:'Comic Sans MS', cursive; font-weight:bold; color:#005442;"></td>
            </tr>
        </table>

        <!-- SECCIÓN PERSONAL ADMINISTRATIVO / TÉCNICO -->
        <div class="seccion-titulo-barra">Solo para Personal Administrativo / Técnico</div>
        <table class="form-table" style="border-top: none;">
            <tr>
                <td style="width: 33%;"><strong>Hora de entrada:</strong><br><input type="time" name="hora_entrada" value="<%= tec.getOrDefault("hora_entrada", "") %>"></td>
                <td style="width: 33%;"><strong>Hora de salida:</strong><br><input type="time" name="hora_salida" value="<%= tec.getOrDefault("hora_salida", "") %>"></td>
                <td><strong>¿Uso Internet?</strong><br>
                    <% String ui = tec.getOrDefault("uso_internet", "No").toString(); %>
                    Sí [<input type="radio" name="uso_internet" value="Si" <%= "Si".equals(ui) ? "checked" : "" %>>]
                    No [<input type="radio" name="uso_internet" value="No" <%= "No".equals(ui) ? "checked" : "" %>>]
                </td>
            </tr>
            <tr>
                <td colspan="3">
                    <strong>Observaciones del técnico:</strong><br>
                    <textarea name="observaciones_tecnico" rows="2"><%= tec.getOrDefault("observaciones_tecnico", "") %></textarea>
                </td>
            </tr>
            <tr>
                <td colspan="2"><strong>Responsable del Laboratorio:</strong><br><input type="text" name="nombre_tecnico" value="<%= tec.getOrDefault("nombre_tecnico", "") %>"></td>
                <td><strong>Firma:</strong><br><input type="text" name="firma_tecnico" value="<%= tec.getOrDefault("firma_tecnico", "").toString().isEmpty() ? tec.getOrDefault("nombre_tecnico", "") : tec.getOrDefault("firma_tecnico", "") %>" style="font-family:'Comic Sans MS', cursive; font-weight:bold; color:#005442;"></td>
            </tr>
        </table>

        <button type="submit" class="btn-guardar">Guardar Todos los Cambios de la Bitácora</button>
    </form>
</div>

</body>
</html>