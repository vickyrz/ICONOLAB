<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.example.iconolab.conexion.ConexionBD" %>
<%
    if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")
            || session.getAttribute("es_encargado") == null || Integer.parseInt(session.getAttribute("es_encargado").toString()) != 1) {
        response.sendRedirect("login.jsp");
        return;
    }

    String matriculaParam = request.getParameter("matricula");
    if (matriculaParam == null || matriculaParam.trim().isEmpty()) {
        response.sendRedirect("lista-usuarios.jsp");
        return;
    }
    matriculaParam = matriculaParam.trim();

    String mensaje = request.getParameter("mensaje");
    if (mensaje == null) mensaje = "";
    String tipoAlerta = request.getParameter("tipo");
    if (tipoAlerta == null) tipoAlerta = "";

    Map<String, String> usuario = null;

    try (Connection conn = ConexionBD.conectar();
         PreparedStatement pstmt = conn.prepareStatement(
             "SELECT u.*, " +
             "(SELECT cuatrimestre FROM bitacoras_estudiantes WHERE matricula = u.matricula LIMIT 1) as cuatrimestre, " +
             "(SELECT carrera FROM bitacoras_estudiantes WHERE matricula = u.matricula LIMIT 1) as carrera " +
             "FROM usuarios u WHERE u.matricula = ?")) {

        pstmt.setString(1, matriculaParam);
        try (ResultSet rs = pstmt.executeQuery()) {
            if (rs.next()) {
                usuario = new HashMap<>();
                usuario.put("nombre", rs.getString("nombre"));
                usuario.put("apellido_paterno", rs.getString("apellido_paterno"));
                usuario.put("apellido_materno", rs.getString("apellido_materno"));
                usuario.put("matricula", rs.getString("matricula"));
                usuario.put("rol", rs.getString("rol"));
                usuario.put("turno", rs.getString("turno"));
                usuario.put("grupo", rs.getString("grupo"));
                usuario.put("cuatrimestre", rs.getString("cuatrimestre"));
                usuario.put("carrera", rs.getString("carrera"));
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    if (usuario == null) {
        response.sendRedirect("lista-usuarios.jsp");
        return;
    }

    String rolUsuario = usuario.get("rol");
    boolean esEstudiante = "estudiante".equals(rolUsuario);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Editar Usuario - Administrador</title>
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
    </style>
</head>
<body>

<div class="container">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px;">
        <h2 style="margin: 0; color: #005442;">Editar Información de Usuario</h2>
        <a href="lista-usuarios.jsp" class="btn-cancelar">Volver al Directorio</a>
    </div>

    <% if (!mensaje.isEmpty()) { %>
        <div class="<%= tipoAlerta.equals("exito") ? "alerta-exito" : "alerta-error" %>">
            <%= mensaje %>
        </div>
    <% } %>

    <form action="EditarUsuarioServlet" method="POST">
        <input type="hidden" name="matricula" value="<%= usuario.get("matricula") %>">

        <div class="seccion-bloque">
            <h3>Modificar Datos (Rol: <%= rolUsuario.toUpperCase() %> | Matrícula: <%= usuario.get("matricula") %>)</h3>

            <div class="grid-2-columnas">
                <div class="form-group">
                    <label>Apellido Paterno:</label>
                    <input type="text" name="apellido_paterno" required value="<%= usuario.get("apellido_paterno") != null ? usuario.get("apellido_paterno") : "" %>" oninput="validarSoloLetras(this)">
                </div>
                <div class="form-group">
                    <label>Apellido Materno:</label>
                    <input type="text" name="apellido_materno" required value="<%= usuario.get("apellido_materno") != null ? usuario.get("apellido_materno") : "" %>" oninput="validarSoloLetras(this)">
                </div>
            </div>

            <div class="form-group">
                <label>Nombre(s):</label>
                <input type="text" name="nombre" required value="<%= usuario.get("nombre") != null ? usuario.get("nombre") : "" %>" oninput="validarSoloLetras(this)">
            </div>

            <div class="<%= esEstudiante ? "grid-3-columnas" : "grid-2-columnas" %>">
                <div class="form-group">
                    <label>Turno:</label>
                    <select name="turno" required>
                        <option value="Matutino" <%= "Matutino".equals(usuario.get("turno")) ? "selected" : "" %>>Matutino</option>
                        <option value="Vespertino" <%= "Vespertino".equals(usuario.get("turno")) ? "selected" : "" %>>Vespertino</option>
                    </select>
                </div>

                <% if (esEstudiante) { %>
                <div class="form-group">
                    <label>Grupo:</label>
                    <select name="grupo" required>
                        <option value="">Selecciona grupo...</option>
                        <%
                        for (int i = 1; i <= 9; i++) {
                            for (int j = 1; j <= 4; j++) {
                                int numGrupo = (i * 100) + j;
                                String numGrupoStr = String.valueOf(numGrupo);
                                boolean isSelected = numGrupoStr.equals(usuario.get("grupo"));
                        %>
                                <option value="<%= numGrupo %>" <%= isSelected ? "selected" : "" %>><%= numGrupo %></option>
                        <%
                            }
                        }
                        %>
                    </select>
                </div>

                <div class="form-group">
                    <label>Cuatrimestre:</label>
                    <select name="cuatrimestre" required>
                        <option value="">Selecciona cuatrimestre...</option>
                        <%
                        String[] nombresCuatris = {"1ro", "2do", "3ro", "4to", "5to", "6to", "7mo", "8vo", "9no"};
                        for (String cuatVal : nombresCuatris) {
                            boolean isSelected = cuatVal.equals(usuario.get("cuatrimestre"));
                        %>
                            <option value="<%= cuatVal %>" <%= isSelected ? "selected" : "" %>><%= cuatVal %></option>
                        <% } %>
                    </select>
                </div>
                <% } %>
            </div>

            <% if (esEstudiante) { %>
            <div class="form-group" style="margin-top: 10px;">
                <label>Carrera / Área:</label>
                <select name="carrera" required>
                    <option value="">Selecciona carrera o área...</option>
                    <%
                    String[] carreras = {
                        "Licenciatura en Administración",
                        "Licenciatura en Enfermería",
                        "Licenciatura en Terapia Física",
                        "Ingeniería en Alimentos",
                        "Ingeniería en Biotecnología",
                        "Ingeniería Industrial",
                        "Ingeniería en Logística",
                        "Ingeniería Mecánica Automotriz",
                        "Ingeniería Mecatrónica",
                        "Ingeniería en Nanotecnología",
                        "Ingeniería en Tecnologías de la Información e Innovación Digital",
                        "Maestría en Alta Dirección de las Organizaciones",
                        "Maestría en Ciencias en Micro y Nanotecnologías",
                        "Maestría en Formación de Formadores de Docentes de Ciencias Naturales",
                        "Maestría en Ingeniería para la Optimización de Procesos de Manufactura",
                        "Maestría en Ingeniería Mecatrónica",
                        "Maestría en Tecnologías de la Información y Comunicaciones",
                        "Doctorado en Ciencia de Materiales"
                    };
                    for (String car : carreras) {
                        boolean isSelected = car.equals(usuario.get("carrera"));
                    %>
                        <option value="<%= car %>" <%= isSelected ? "selected" : "" %>><%= car %></option>
                    <% } %>
                </select>
            </div>
            <% } %>
        </div>

        <div style="display: flex; justify-content: center; gap: 20px; margin-top: 20px;">
            <a href="lista-usuarios.jsp" class="btn-cancelar">Cancelar</a>
            <button type="submit" class="btn-accion">Guardar Cambios</button>
        </div>
    </form>
</div>

<script>
function validarSoloLetras(input) {
    input.value = input.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, '');
}
</script>

</body>
</html>