<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.example.iconolab.conexion.ConexionBD" %>
<%
    if (session == null || session.getAttribute("rol") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String rolSesion = (String) session.getAttribute("rol");
    if (!"docente".equals(rolSesion) && !"administrador".equals(rolSesion)) {
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
    Map<String, Object> primerEstudiante = null;
    List<Map<String, Object>> listaEstudiantes = new ArrayList<>();
    Map<String, Object> tec = new HashMap<>();
    int totalAlumnosReales = 0;

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

        // Consultar total real de alumnos
        try (PreparedStatement pst = conn.prepareStatement("SELECT COUNT(*) as total FROM bitacoras_estudiantes WHERE id_bitacora = ?")) {
            pst.setInt(1, idBitacora);
            try (ResultSet rs = pst.executeQuery()) {
                if (rs.next()) {
                    totalAlumnosReales = rs.getInt("total");
                }
            }
        }

        // Consultar datos del primer estudiante
        try (PreparedStatement pst = conn.prepareStatement("SELECT * FROM bitacoras_estudiantes WHERE id_bitacora = ? LIMIT 1")) {
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

        // Consultar todos los estudiantes vinculados
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
    <title>Consulta de Bitácora</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        body { background-color: #f4f6f5; font-family: Arial, sans-serif; }
        .documento-unificado { max-width: 950px; margin: 30px auto; background: #fff; padding: 30px; border: 1px solid #ccc; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        .form-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 13px; }
        .form-table th, .form-table td { border: 1px solid #333; padding: 8px 10px; vertical-align: middle; }
        .form-table th { background-color: #d9d9d9; color: #000; text-align: center; font-weight: bold; }
        .seccion-titulo-barra { background-color: #333; color: #fff; text-align: center; font-weight: bold; padding: 6px; font-size: 14px; text-transform: uppercase; margin-top: 15px; margin-bottom: 0; }
        .top-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .acciones-derecha { display: flex; gap: 10px; }
        .btn-regresar { background: #555; color: white; padding: 8px 15px; border-radius: 5px; text-decoration: none; font-weight: bold; font-size: 14px; }
        .btn-regresar:hover { background: #333; }
        .btn-imprimir { background: #005442; color: white; padding: 8px 15px; border: none; border-radius: 5px; font-weight: bold; cursor: pointer; font-size: 14px; }
        .btn-imprimir:hover { background: #0b2f27; }
        .texto-firma { font-family: 'Comic Sans MS', cursive, sans-serif; font-weight: bold; color: #005442; }
        @media print {
            body { background-color: #fff; }
            .documento-unificado { border: none; box-shadow: none; margin: 0; padding: 0; max-width: 100%; }
            .top-actions { display: none; }
        }
    </style>
</head>
<body>

<div class="documento-unificado">
    <div class="top-actions">
        <h2 style="color: #005442; margin: 0;">Consulta de Bitácora</h2>
        <div class="acciones-derecha">
            <button onclick="window.print();" class="btn-imprimir">🖨️ Imprimir / Guardar PDF</button>
            <a href="panel-administrador.jsp" class="btn-regresar">Regresar al Panel</a>
        </div>
    </div>

    <!-- DATOS GENERALES -->
    <table class="form-table">
        <tr>
            <td style="width: 15%;"><strong>Laboratorio:</strong></td>
            <td style="width: 50%;"><%= doc.getOrDefault("laboratorio", "N/A") %></td>
            <td style="width: 15%;"><strong>Fecha:</strong></td>
            <td style="width: 20%;"><%= doc.getOrDefault("fecha", "N/A") %></td>
        </tr>
    </table>

    <!-- DATOS DE LA CLASE Y PRÁCTICA -->
    <table class="form-table">
        <tr>
            <td style="width: 15%;"><strong>Docente:</strong></td>
            <td style="width: 60%;"><%= doc.getOrDefault("nombre_docente", "N/A") %></td>
            <td style="width: 10%;"><strong>Matrícula:</strong></td>
            <td style="width: 15%;"><%= doc.getOrDefault("matricula_docente", "N/A") %></td>
        </tr>
        <tr>
            <td><strong>Carrera:</strong></td>
            <td><%= primerEstudiante != null ? primerEstudiante.getOrDefault("carrera", "N/A") : "N/A" %></td>
            <td><strong>Grupo:</strong></td>
            <td><%= primerEstudiante != null ? primerEstudiante.getOrDefault("grupo", "N/A") : "N/A" %></td>
        </tr>
        <tr>
            <td><strong>Turno:</strong></td>
            <td><%= primerEstudiante != null ? primerEstudiante.getOrDefault("turno", "N/A") : "N/A" %></td>
            <td><strong>Materia:</strong></td>
            <td><%= primerEstudiante != null ? primerEstudiante.getOrDefault("materia", "N/A") : "N/A" %></td>
        </tr>
        <tr>
            <td><strong>Práctica no.:</strong></td>
            <td><%= primerEstudiante != null ? primerEstudiante.getOrDefault("practica_no", "N/A") : "N/A" %></td>
            <td colspan="2"><strong>Nombre:</strong> <%= primerEstudiante != null ? primerEstudiante.getOrDefault("nombre_practica", "N/A") : "N/A" %></td>
        </tr>
    </table>

    <!-- TABLA DE ESTUDIANTES -->
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
            %>
            <tr>
                <td style="text-align: center;"><%= est.getOrDefault("num_pc", "") %></td>
                <td><%= nombreCompleto %></td>
                <td class="texto-firma"><%= nombreCompleto %></td>
                <td><%= est.getOrDefault("fallas_observaciones", "") %></td>
                <td style="text-align: center;"><%= est.getOrDefault("num_reporte", "") %></td>
            </tr>
            <%
                }
            } else {
            %>
            <tr><td colspan='5' style='text-align:center; color:#777;'>No hay estudiantes registrados para esta bitácora.</td></tr>
            <% } %>
        </tbody>
    </table>

    <!-- SECCIÓN LLENADA POR EL DOCENTE -->
    <div class="seccion-titulo-barra">Para ser llenado por el Docente</div>
    <table class="form-table" style="border-top: none;">
        <tr>
            <td style="width: 35%;"><strong>¿Cómo calificas el servicio recibido?</strong></td>
            <td>
                <% String cs = doc.getOrDefault("calificacion_servicio", "Regular").toString(); %>
                Malo [<%= "Malo".equals(cs) ? "X" : "&nbsp;" %>]
                Regular [<%= "Regular".equals(cs) ? "X" : "&nbsp;" %>]
                Bueno [<%= "Bueno".equals(cs) ? "X" : "&nbsp;" %>]
                Excelente [<%= "Excelente".equals(cs) ? "X" : "&nbsp;" %>]
            </td>
        </tr>
        <tr>
            <td><strong>¿Uso Internet?</strong></td>
            <td>
                <% String ui = doc.getOrDefault("uso_internet", "No").toString(); %>
                Sí [<%= "Si".equals(ui) ? "X" : "&nbsp;" %>]
                No [<%= "No".equals(ui) ? "X" : "&nbsp;" %>]
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <strong>Observaciones del docente:</strong><br>
                <div style="padding: 5px 0; min-height: 40px;"><%= doc.getOrDefault("observaciones_docente", "Ninguna") %></div>
            </td>
        </tr>
        <tr>
            <td><strong>Total de Alumnos en clase:</strong> <%= totalAlumnosReales %></td>
            <td><strong>Firma del docente:</strong> <span class="texto-firma"><%= doc.getOrDefault("nombre_docente", "") %></span></td>
        </tr>
    </table>

    <!-- SECCIÓN PERSONAL TÉCNICO / ADMINISTRATIVO -->
    <div class="seccion-titulo-barra">Solo para Personal Administrativo / Técnico</div>
    <table class="form-table" style="border-top: none;">
        <tr>
            <td style="width: 50%;"><strong>Hora de entrada:</strong><br><%= tec.getOrDefault("hora_entrada", "--:--") %></td>
            <td style="width: 50%;"><strong>Hora de salida:</strong><br><%= tec.getOrDefault("hora_salida", "--:--") %></td>
        </tr>
        <tr>
            <td colspan="2">
                <strong>Observaciones del técnico:</strong><br>
                <div style="padding: 5px 0; min-height: 30px;"><%= tec.getOrDefault("observaciones_tecnico", "Ninguna") %></div>
            </td>
        </tr>
        <tr>
            <td><strong>Responsable del Laboratorio:</strong><br><%= tec.getOrDefault("nombre_tecnico", "Pendiente") %></td>
            <td><strong>Firma:</strong><br><span class="texto-firma"><%= tec.getOrDefault("nombre_tecnico", "") %></span></td>
        </tr>
    </table>

</div>

</body>
</html>