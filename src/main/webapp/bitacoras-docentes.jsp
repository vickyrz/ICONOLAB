<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // Validar que el usuario haya iniciado sesión y sea docente
    if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String nombreDocente = session.getAttribute("nombre") + " " + session.getAttribute("apellido_paterno") + " " + session.getAttribute("apellido_materno");
    String matriculaDocente = (String) session.getAttribute("matricula");
    Object esEncargadoObj = session.getAttribute("es_encargado");
    boolean esEncargado = (esEncargadoObj != null && Integer.parseInt(esEncargadoObj.toString()) == 1);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bitácora Docente</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
        .seccion-bloque { border: 1px solid #dcdde1; border-radius: 8px; padding: 20px; margin-bottom: 25px; background-color: #fafdfb; }
        .seccion-bloque h3 { margin: 0 0 20px 0; color: #005442; border-bottom: 2px solid #005442; padding-bottom: 5px; font-size: 16px; }
        .grid-2-columnas { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .grid-3-columnas { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; font-size: 14px; }
        .form-group input, .form-group select, .form-group textarea { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px; box-sizing: border-box; font-size: 14px; }
        .btn-admin-nav { background-color: #005442; color: white; padding: 6px 12px; border-radius: 4px; text-decoration: none; font-weight: bold; font-size: 14px; margin-right: 5px; display: inline-block; }
        .btn-admin-nav:hover { background-color: #0b2f27; }
        .btn-registro-nav { background-color: #17a2b8; color: white; padding: 6px 12px; border-radius: 4px; text-decoration: none; font-weight: bold; font-size: 14px; margin-right: 5px; display: inline-block; }
        .btn-registro-nav:hover { background-color: #117a8b; }
        .btn-block { width: 100%; background-color: #005442; color: white; border: none; padding: 12px; border-radius: 6px; font-size: 16px; font-weight: bold; cursor: pointer; }
        .btn-block:hover { background-color: #0b2f27; }
    </style>
</head>
<body>

<div class="container">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h2 style="margin: 0; color: #005442;">Bitácora Docente</h2>
        <div>
            <% if (esEncargado) { %>
                <a href="panel-administrador.jsp" class="btn-admin-nav">Panel de Administración</a>
            <% } %>

            <a href="registro-alumnos.jsp" class="btn-registro-nav">Registrar Alumno</a>
            <a href="login.jsp" style="color: #c92a2a; font-weight: bold; text-decoration: none; border: 1px solid #c92a2a; padding: 6px 12px; border-radius: 4px; font-size: 14px;">Salir sin guardar</a>
        </div>
    </div>

    <form action="DocenteServlet" method="POST">

        <!-- DATOS DEL DOCENTE -->
        <div class="seccion-bloque">
            <h3>Datos del Docente:</h3>

            <div class="grid-2-columnas">
                <div class="form-group">
                    <label>Nombre del Docente:</label>
                    <input type="text" value="<%= nombreDocente %>" readonly style="background-color: #e9ecef;">
                </div>
                <div class="form-group">
                    <label>Matrícula:</label>
                    <input type="text" value="<%= matriculaDocente %>" readonly style="background-color: #e9ecef;">
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

            <div class="grid-3-columnas" style="margin-top: 15px;">
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
                    <label>Materia impartiendo:</label>
                    <input type="text" name="materia" placeholder="Ej. Gestión de Desarrollo de Software" required>
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

            <div class="form-group" style="margin-top: 15px; width: 50%;">
                <label>Turno:</label>
                <select name="turno" required>
                    <option value="">Selecciona turno...</option>
                    <option value="Matutino">Matutino</option>
                    <option value="Vespertino">Vespertino</option>
                </select>
            </div>
        </div>

        <!-- OBSERVACIONES -->
        <div class="seccion-bloque">
            <h3>Observaciones</h3>

            <div class="grid-2-columnas">
                <div class="form-group">
                    <label>¿Cómo calificas el estado de la instalación?</label>
                    <select name="calificacion_servicio" required>
                        <option value="">Selecciona una opción...</option>
                        <option value="Excelente">Excelente</option>
                        <option value="Bueno">Bueno</option>
                        <option value="Regular">Regular</option>
                        <option value="Malo">Malo</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>¿Fallo en algún componente del laboratorio?</label>
                    <select name="fallo_componente" required>
                        <option value="">Selecciona una opción...</option>
                        <option value="Si">Sí</option>
                        <option value="No">No</option>
                    </select>
                </div>
            </div>

            <div class="grid-2-columnas" style="margin-top: 15px;">
                <div class="form-group">
                    <label>Función del internet:</label>
                    <select name="funcion_internet" required>
                        <option value="">Selecciona una opción...</option>
                        <option value="Óptima">Óptima</option>
                        <option value="Intermitente">Intermitente</option>
                        <option value="Sin conexión">Sin conexión</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Si es así, ¿Cuál?</label>
                    <input type="text" name="detalle_fallo" placeholder="Escribe detalles del fallo si aplica">
                </div>
            </div>

            <div class="form-group" style="margin-top: 15px;">
                <label>Observaciones adicionales:</label>
                <textarea name="observaciones_adicionales" rows="3" placeholder="Escribe observaciones adicionales..."></textarea>
            </div>
        </div>

        <button type="submit" class="btn-block">Guardar Registro en Bitácora</button>
    </form>
</div>

</body>
</html>