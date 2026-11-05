<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.example.iconolab.conexion.ConexionBD" %>
<%
    if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")) {
        response.sendRedirect("login.jsp");
        return;
    }
    Object esEncargadoObj = session.getAttribute("es_encargado");
    if (esEncargadoObj == null || Integer.parseInt(esEncargadoObj.toString()) != 1) {
        response.sendRedirect("bitacoras-docentes.jsp");
        return;
    }

    if (session.getAttribute("csrf_panel") == null) {
        session.setAttribute("csrf_panel", java.util.UUID.randomUUID().toString());
    }

    String mensaje = "";
    String tipoMensaje = "error";

    String resultado = request.getParameter("resultado");
    if ("eliminado".equals(resultado)) {
        mensaje = "La bitácora y sus registros relacionados se eliminaron correctamente.";
        tipoMensaje = "exito";
    }

    String errorParam = request.getParameter("error");
    if (errorParam != null) {
        mensaje = "Ocurrió un error al procesar la solicitud en el panel.";
    }

    List<Map<String, Object>> bitacorasList = new ArrayList<>();
    try (Connection conn = ConexionBD.conectar();
         Statement st = conn.createStatement();
         ResultSet rs = st.executeQuery("SELECT d.*, " +
                 "(SELECT COUNT(*) FROM bitacoras_estudiantes e WHERE e.id_bitacora = d.id_bitacora) AS total_alumnos_reg, " +
                 "(SELECT COUNT(*) FROM bitacoras_tecnicos p WHERE p.id_bitacora = d.id_bitacora) AS total_tecnico_reg, " +
                 "(SELECT p.nombre_tecnico FROM bitacoras_tecnicos p WHERE p.id_bitacora = d.id_bitacora LIMIT 1) AS nombre_tecnico_reg, " +
                 "(SELECT e.grupo FROM bitacoras_estudiantes e WHERE e.id_bitacora = d.id_bitacora LIMIT 1) AS grupo_reg, " +
                 "(SELECT e.turno FROM bitacoras_estudiantes e WHERE e.id_bitacora = d.id_bitacora LIMIT 1) AS turno_reg, " +
                 "(SELECT e.materia FROM bitacoras_estudiantes e WHERE e.id_bitacora = d.id_bitacora LIMIT 1) AS materia_reg " +
                 "FROM bitacoras_docentes d ORDER BY d.id_bitacora DESC")) {

        while (rs.next()) {
            Map<String, Object> fila = new HashMap<>();
            fila.put("id_bitacora", rs.getInt("id_bitacora"));
            fila.put("nombre_docente", rs.getString("nombre_docente"));
            fila.put("matricula_docente", rs.getString("matricula_docente"));
            fila.put("fecha", rs.getString("fecha"));
            fila.put("total_alumnos_reg", rs.getInt("total_alumnos_reg"));
            fila.put("total_tecnico_reg", rs.getInt("total_tecnico_reg"));
            fila.put("nombre_tecnico_reg", rs.getString("nombre_tecnico_reg"));
            fila.put("grupo_reg", rs.getString("grupo_reg"));
            fila.put("materia_reg", rs.getString("materia_reg"));
            bitacorasList.add(fila);
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
    <title>Panel de Administración General</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; }
        .panel-container { max-width: 900px; margin: 30px auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
        .admin-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; gap: 12px; }
        .admin-title { color: #0b4f3b; margin: 0; }
        .acciones-header { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
        .cards-container { display: flex; flex-direction: column; gap: 15px; margin-top: 20px; }
        .bitacora-card { background: #fff; border: 1px solid #ccc; border-radius: 8px; padding: 15px 20px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 2px 4px rgba(0,0,0,0.05); gap: 15px; }
        .bitacora-info { min-width: 0; overflow-wrap: anywhere; }
        .bitacora-info h4 { margin: 0 0 5px 0; color: #0b4f3b; font-size: 18px; }
        .bitacora-info p { margin: 3px 0; color: #555; font-size: 14px; }
        .bitacora-actions { display: flex; gap: 8px; flex-wrap: wrap; }
        .badge-vacio { background: #e74c3c; color: white; padding: 2px 6px; border-radius: 4px; font-size: 11px; margin-left: 5px; }
        .badge-completo { background: #27ae60; color: white; padding: 2px 6px; border-radius: 4px; font-size: 11px; margin-left: 5px; }
        .badge-tecnico { background: #2980b9; color: white; padding: 2px 6px; border-radius: 4px; font-size: 11px; margin-left: 5px; }
        .btn-accion, .btn-cerrar, .btn-buscar, .btn-respaldo, .btn-gestion-usuarios, .btn-ver-usuarios {
            background: #0b4f3b; color: white; padding: 8px 14px; border-radius: 5px; text-decoration: none; font-weight: bold; font-size: 14px; border: none; cursor: pointer; display: inline-flex; align-items: center; justify-content: center;
        }
        .btn-accion:hover, .btn-cerrar:hover, .btn-buscar:hover, .btn-respaldo:hover, .btn-gestion-usuarios:hover, .btn-ver-usuarios:hover { background: #083c2d; }
        .btn-respaldo { background: #005442; }
        .btn-gestion-usuarios { background: #17a2b8; }
        .btn-ver-usuarios { background: #6c757d; }
        .form-eliminar { display: inline-flex; margin: 0; }
        .buscador-wrapper { display: flex; gap: 10px; margin-bottom: 20px; }
        #buscador { padding: 12px; flex: 1; min-width: 0; border: 2px solid #0b4f3b; border-radius: 8px; font-size: 16px; outline: none; }
        .seccion-titulo { color: #0b4f3b; margin-top: 20px; border-bottom: 2px solid #0b4f3b; padding-bottom: 5px; font-size: 20px; }
        .mensaje-panel { padding: 12px 15px; margin: 15px 0; border-radius: 6px; }
        .mensaje-panel.error { background: #fdecea; color: #922b21; border: 1px solid #e6b0aa; }
        .mensaje-panel.exito { background: #eafaf1; color: #196f3d; border: 1px solid #a9dfbf; }
    </style>
</head>
<body>

<div class="panel-container">

    <div class="admin-header">
        <h2 class="admin-title">Panel General de Control - Bitácoras</h2>

        <div class="acciones-header">
            <a href="registro-usuarios-admin.jsp" class="btn-gestion-usuarios" title="Registrar Usuarios">👥 Registrar Usuario</a>
            <a href="lista-usuarios.jsp" class="btn-ver-usuarios" title="Ver directorio general">📋 Ver Usuarios</a>
            <a href="AdminServlet?accion=respaldo" class="btn-respaldo" title="Descargar Respaldo SQL">📥 Respaldo DB</a>
            <a href="login.jsp" class="btn-cerrar">Cerrar Sesión</a>
        </div>
    </div>

    <% if (!mensaje.isEmpty()) { %>
        <div class="mensaje-panel <%= tipoMensaje %>" role="status"><%= mensaje %></div>
    <% } %>

    <div class="buscador-wrapper">
        <input type="text" id="buscador" oninput="filtrarTarjetas()" placeholder="Buscar por número, docente, matrícula, grupo o fecha..." aria-label="Buscar bitácoras">
        <button type="button" class="btn-buscar" onclick="filtrarTarjetas()">🔍 Buscar</button>
    </div>

    <h3 class="seccion-titulo">Bitácoras de Docentes</h3>

    <div class="cards-container" id="contenedorTarjetas">
        <%
            int contador = 1;
            if (!bitacorasList.isEmpty()) {
                for (Map<String, Object> f : bitacorasList) {
                    int totalAlumnos = (int) f.get("total_alumnos_reg");
                    int totalTecnico = (int) f.get("total_tecnico_reg");
                    boolean tieneAlumnos = totalAlumnos > 0;
                    boolean tieneTecnico = totalTecnico > 0;
                    String nombreTecnico = tieneTecnico ? (String) f.get("nombre_tecnico_reg") : "Ninguno";
                    String grupoTxt = f.get("grupo_reg") != null ? (String) f.get("grupo_reg") : "Sin grupo";
                    String materiaTxt = f.get("materia_reg") != null ? (String) f.get("materia_reg") : "N/A";

                    String textoBusqueda = ("Bitácora " + contador + " " + f.get("nombre_docente") + " " + f.get("matricula_docente") + " " + f.get("fecha") + " " + grupoTxt + " " + materiaTxt + " " + nombreTecnico).toLowerCase();
        %>
            <div class="bitacora-card" data-search="<%= textoBusqueda %>">
                <div class="bitacora-info">
                    <h4>
                        Bitácora <%= contador %> - Docente: <%= f.get("nombre_docente") %>
                        <% if (tieneAlumnos) { %>
                            <span class="badge-completo">Con alumnos (<%= totalAlumnos %>)</span>
                        <% } else { %>
                            <span class="badge-vacio">Vacía / Sin alumnos</span>
                        <% } %>

                        <% if (tieneTecnico) { %>
                            <span class="badge-tecnico">Técnico: <%= nombreTecnico %></span>
                        <% } else { %>
                            <span class="badge-vacio" style="background:#e67e22;">Sin técnico</span>
                        <% } %>
                    </h4>
                    <p>
                        <strong>Fecha:</strong> <%= f.get("fecha") %> |
                        <strong>Matrícula:</strong> <%= f.get("matricula_docente") %> |
                        <strong>Grupo:</strong> <%= grupoTxt %> |
                        <strong>Materia:</strong> <%= materiaTxt %>
                    </p>
                </div>

                <div class="bitacora-actions">
                    <a href="ver-bitacora.jsp?id=<%= f.get("id_bitacora") %>" class="btn-accion" title="Ver Formato">Ver</a>
                    <a href="editar-bitacora.jsp?id=<%= f.get("id_bitacora") %>" class="btn-accion" title="Editar Formato">Editar</a>

                    <form method="POST" action="AdminServlet" class="form-eliminar" onsubmit="return confirm('¿Estás seguro de eliminar esta bitácora completa y todos sus registros asociados? Esta acción no se puede deshacer.');">
                        <input type="hidden" name="accion" value="eliminar_bitacora">
                        <input type="hidden" name="eliminar_id" value="<%= f.get("id_bitacora") %>">
                        <input type="hidden" name="csrf_token" value="<%= session.getAttribute("csrf_panel") %>">
                        <button type="submit" class="btn-accion" title="Eliminar">Eliminar</button>
                    </form>
                </div>
            </div>
        <%
                    contador++;
                }
            } else {
        %>
            <p style="text-align:center; color:#666;">No hay bitácoras registradas actualmente en la base de datos.</p>
        <% } %>
    </div>
</div>

<script>
function filtrarTarjetas() {
    const input = document.getElementById("buscador").value.toLowerCase();
    const tarjetas = document.getElementsByClassName("bitacora-card");
    for (const tarjeta of tarjetas) {
        const data = tarjeta.getAttribute("data-search") || "";
        tarjeta.style.display = data.includes(input) ? "flex" : "none";
    }
}
</script>

</body>
</html>