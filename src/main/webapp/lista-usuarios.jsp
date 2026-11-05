<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.example.iconolab.conexion.ConexionBD" %>
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

    String resultado = request.getParameter("resultado");
    if ("eliminado".equals(resultado)) {
        mensaje = "Usuario eliminado correctamente del sistema.";
        tipoAlerta = "exito";
    } else if ("masivo".equals(resultado)) {
        String totalStr = request.getParameter("total");
        int total = totalStr != null ? Integer.parseInt(totalStr) : 0;
        mensaje = "Se han eliminado " + total + " usuario(s) seleccionados correctamente.";
        tipoAlerta = "exito";
    }

    List<Map<String, String>> docentes = new ArrayList<>();
    List<Map<String, String>> tecnicos = new ArrayList<>();
    List<Map<String, String>> estudiantes = new ArrayList<>();

    try (Connection conn = ConexionBD.conectar();
         Statement st = conn.createStatement();
         ResultSet rs = st.executeQuery("SELECT u.*, " +
                 "(SELECT cuatrimestre FROM bitacoras_estudiantes WHERE matricula = u.matricula LIMIT 1) as cuatrimestre, " +
                 "(SELECT carrera FROM bitacoras_estudiantes WHERE matricula = u.matricula LIMIT 1) as carrera " +
                 "FROM usuarios u WHERE u.es_encargado != 1 ORDER BY u.matricula DESC")) {

        while (rs.next()) {
            Map<String, String> row = new HashMap<>();
            row.put("nombre", rs.getString("nombre"));
            row.put("apellido_paterno", rs.getString("apellido_paterno"));
            row.put("apellido_materno", rs.getString("apellido_materno"));
            row.put("matricula", rs.getString("matricula"));
            row.put("rol", rs.getString("rol"));
            row.put("turno", rs.getString("turno"));
            row.put("grupo", rs.getString("grupo"));
            row.put("cuatrimestre", rs.getString("cuatrimestre"));
            row.put("carrera", rs.getString("carrera"));

            String rol = rs.getString("rol");
            if ("docente".equals(rol)) {
                docentes.add(row);
            } else if ("tecnico".equals(rol)) {
                tecnicos.add(row);
            } else if ("estudiante".equals(rol)) {
                estudiantes.add(row);
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
    <title>Directorio General de Usuarios - Administrador</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        .container-admin { max-width: 1300px; margin: 30px auto; padding: 20px; font-family: Arial, sans-serif; }
        .grid-3-columnas-usuarios { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-top: 20px; }
        .seccion-rol { background: #fafdfb; border: 1px solid #ccc; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
        .seccion-rol h3 { margin-top: 0; color: #005442; border-bottom: 2px solid #005442; padding-bottom: 8px; font-size: 16px; display: flex; justify-content: space-between; align-items: center; }
        .contador-badge { background: #005442; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px; }
        .usuario-card { background: #ffffff; border: 1px solid #e0e0e0; border-radius: 6px; padding: 12px; margin-bottom: 12px; font-size: 13px; box-shadow: 0 1px 3px rgba(0,0,0,0.02); }
        .usuario-card p { margin: 4px 0; color: #333; }
        .card-header-checkbox { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #eee; padding-bottom: 6px; margin-bottom: 8px; font-weight: bold; }
        .card-actions { display: flex; gap: 8px; margin-top: 8px; padding-top: 8px; border-top: 1px solid #eee; }
        .btn-accion-mini { background-color: #005442; color: white; padding: 4px 10px; border-radius: 4px; text-decoration: none; font-weight: bold; font-size: 11px; border: none; cursor: pointer; display: inline-block; }
        .btn-accion-mini:hover { background-color: #0b2f27; }
        .btn-eliminar-masivo { background-color: #c92a2a; color: white; padding: 8px 15px; border-radius: 6px; font-weight: bold; font-size: 13px; border: none; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; }
        .btn-eliminar-masivo:hover { background-color: #a02020; }
        .btn-cancelar { background-color: #6c757d; color: white; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-weight: bold; display: inline-block; }
        .btn-cancelar:hover { background-color: #5a6268; }
        .alerta-exito { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; padding: 12px; border-radius: 6px; margin-bottom: 15px; }
        .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; padding: 12px; border-radius: 6px; margin-bottom: 15px; }
        .seleccionar-todos-label { font-size: 12px; cursor: pointer; color: #555; display: flex; align-items: center; gap: 5px; }
        .buscador-container { margin-bottom: 20px; background: #ffffff; padding: 15px; border-radius: 8px; border: 1px solid #ccc; display: flex; gap: 10px; align-items: center; }
        .buscador-container input { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; font-size: 14px; }
        @media (max-width: 950px) { .grid-3-columnas-usuarios { grid-template-columns: 1fr; } }
    </style>
</head>
<body>

<div class="container-admin">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h2 style="margin: 0; color: #005442;">Directorio General de Usuarios Registrados</h2>
        <a href="panel-administrador.jsp" class="btn-cancelar">Volver al Panel</a>
    </div>

    <% if (!mensaje.isEmpty()) { %>
        <div class="<%= tipoAlerta.equals("exito") ? "alerta-exito" : "alerta-error" %>">
            <%= mensaje %>
        </div>
    <% } %>

    <div class="buscador-container">
        <label for="buscador-usuarios" style="font-weight: bold; color: #005442; white-space: nowrap;">🔍 Buscar usuario:</label>
        <input type="text" id="buscador-usuarios" placeholder="Escribe nombre, apellido o matrícula..." onkeyup="filtrarUsuarios()">
    </div>

    <form method="POST" action="ListaUsuariosServlet" id="form-masivo" onsubmit="return confirm('¿Estás seguro de eliminar a todos los usuarios seleccionados?');">
        <input type="hidden" name="accion" value="eliminar_masivo">

        <div style="margin-bottom: 15px; display: flex; justify-content: flex-end;">
            <button type="submit" class="btn-eliminar-masivo">🗑️ Eliminar Seleccionados</button>
        </div>

        <div class="grid-3-columnas-usuarios">

            <!-- COLUMNA 1: DOCENTES -->
            <div class="seccion-rol">
                <h3>
                    <span>👨‍🏫 Docentes</span>
                    <span class="contador-badge"><%= docentes.size() %></span>
                </h3>
                <% if (!docentes.isEmpty()) { %>
                    <div style="margin: 10px 0;">
                        <label class="seleccionar-todos-label">
                            <input type="checkbox" onclick="toggleColumn(this, 'docente')"> Seleccionar todos los docentes
                        </label>
                    </div>
                    <% for (Map<String, String> d : docentes) {
                        String nombreCompleto = (d.get("nombre") != null ? d.get("nombre") : "") + " " +
                                                (d.get("apellido_paterno") != null ? d.get("apellido_paterno") : "") + " " +
                                                (d.get("apellido_materno") != null ? d.get("apellido_materno") : "");
                    %>
                        <div class="usuario-card" data-busqueda="<%= nombreCompleto.toLowerCase() + " " + d.get("matricula").toLowerCase() %>">
                            <div class="card-header-checkbox">
                                <span style="font-size: 11px; color: #666;">Seleccionar</span>
                                <input type="checkbox" name="matriculas_seleccionadas[]" value="<%= d.get("matricula") %>" class="checkbox-docente">
                            </div>
                            <p><strong>Nombre:</strong> <%= nombreCompleto %></p>
                            <p><strong>Matrícula:</strong> <%= d.get("matricula") %></p>
                            <p><strong>Turno:</strong> <%= d.get("turno") != null ? d.get("turno") : "N/A" %></p>

                            <div class="card-actions">
                                <a href="editar-usuario.jsp?matricula=<%= java.net.URLEncoder.encode(d.get("matricula"), "UTF-8") %>" class="btn-accion-mini">Editar</a>
                            </div>
                        </div>
                    <% } %>
                <% } else { %>
                    <p style="color: #777; font-size: 13px; text-align: center; padding: 20px 0;">No hay docentes registrados.</p>
                <% } %>
            </div>

            <!-- COLUMNA 2: TÉCNICOS -->
            <div class="seccion-rol">
                <h3>
                    <span>🛠️ Personal Técnico</span>
                    <span class="contador-badge"><%= tecnicos.size() %></span>
                </h3>
                <% if (!tecnicos.isEmpty()) { %>
                    <div style="margin: 10px 0;">
                        <label class="seleccionar-todos-label">
                            <input type="checkbox" onclick="toggleColumn(this, 'tecnico')"> Seleccionar todos los técnicos
                        </label>
                    </div>
                    <% for (Map<String, String> t : tecnicos) {
                        String nombreCompleto = (t.get("nombre") != null ? t.get("nombre") : "") + " " +
                                                (t.get("apellido_paterno") != null ? t.get("apellido_paterno") : "") + " " +
                                                (t.get("apellido_materno") != null ? t.get("apellido_materno") : "");
                    %>
                        <div class="usuario-card" data-busqueda="<%= nombreCompleto.toLowerCase() + " " + t.get("matricula").toLowerCase() %>">
                            <div class="card-header-checkbox">
                                <span style="font-size: 11px; color: #666;">Seleccionar</span>
                                <input type="checkbox" name="matriculas_seleccionadas[]" value="<%= t.get("matricula") %>" class="checkbox-tecnico">
                            </div>
                            <p><strong>Nombre:</strong> <%= nombreCompleto %></p>
                            <p><strong>Matrícula:</strong> <%= t.get("matricula") %></p>
                            <p><strong>Turno:</strong> <%= t.get("turno") != null ? t.get("turno") : "N/A" %></p>

                            <div class="card-actions">
                                <a href="editar-usuario.jsp?matricula=<%= java.net.URLEncoder.encode(t.get("matricula"), "UTF-8") %>" class="btn-accion-mini">Editar</a>
                            </div>
                        </div>
                    <% } %>
                <% } else { %>
                    <p style="color: #777; font-size: 13px; text-align: center; padding: 20px 0;">No hay personal técnico registrado.</p>
                <% } %>
            </div>

            <!-- COLUMNA 3: ESTUDIANTES -->
            <div class="seccion-rol">
                <h3>
                    <span>🎓 Estudiantes</span>
                    <span class="contador-badge"><%= estudiantes.size() %></span>
                </h3>
                <% if (!estudiantes.isEmpty()) { %>
                    <div style="margin: 10px 0;">
                        <label class="seleccionar-todos-label">
                            <input type="checkbox" onclick="toggleColumn(this, 'estudiante')"> Seleccionar todos los estudiantes
                        </label>
                    </div>
                    <% for (Map<String, String> e : estudiantes) {
                        String nombreCompleto = (e.get("nombre") != null ? e.get("nombre") : "") + " " +
                                                (e.get("apellido_paterno") != null ? e.get("apellido_paterno") : "") + " " +
                                                (e.get("apellido_materno") != null ? e.get("apellido_materno") : "");
                    %>
                        <div class="usuario-card" data-busqueda="<%= nombreCompleto.toLowerCase() + " " + e.get("matricula").toLowerCase() + " " + (e.get("carrera") != null ? e.get("carrera").toLowerCase() : "") %>">
                            <div class="card-header-checkbox">
                                <span style="font-size: 11px; color: #666;">Seleccionar</span>
                                <input type="checkbox" name="matriculas_seleccionadas[]" value="<%= e.get("matricula") %>" class="checkbox-estudiante">
                            </div>
                            <p><strong>Nombre:</strong> <%= nombreCompleto %></p>
                            <p><strong>Matrícula:</strong> <%= e.get("matricula") %></p>
                            <p><strong>Cuatrimestre:</strong> <%= e.get("cuatrimestre") != null && !e.get("cuatrimestre").isEmpty() ? e.get("cuatrimestre") : "N/A" %></p>
                            <p><strong>Grupo:</strong> <%= e.get("grupo") != null ? e.get("grupo") : "N/A" %> | <strong>Turno:</strong> <%= e.get("turno") != null ? e.get("turno") : "N/A" %></p>
                            <p><strong>Carrera:</strong> <%= e.get("carrera") != null && !e.get("carrera").isEmpty() ? e.get("carrera") : "N/A" %></p>

                            <div class="card-actions">
                                <a href="editar-usuario.jsp?matricula=<%= java.net.URLEncoder.encode(e.get("matricula"), "UTF-8") %>" class="btn-accion-mini">Editar</a>
                            </div>
                        </div>
                    <% } %>
                <% } else { %>
                    <p style="color: #777; font-size: 13px; text-align: center; padding: 20px 0;">No hay estudiantes registrados.</p>
                <% } %>
            </div>

        </div>
    </form>
</div>

<script>
function toggleColumn(source, tipo) {
    var checkboxes = document.querySelectorAll('.checkbox-' + tipo);
    for (var i = 0; i < checkboxes.length; i++) {
        checkboxes[i].checked = source.checked;
    }
}

function filtrarUsuarios() {
    const filtro = document.getElementById('buscador-usuarios').value.toLowerCase().trim();
    const tarjetas = document.querySelectorAll('.usuario-card');

    tarjetas.forEach(tarjeta => {
        const datos = tarjeta.getAttribute('data-busqueda');
        if (datos.includes(filtro)) {
            tarjeta.style.display = 'block';
        } else {
            tarjeta.style.display = 'none';
        }
    });
}
</script>

</body>
</html>