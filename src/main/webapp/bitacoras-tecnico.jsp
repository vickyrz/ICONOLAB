<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.example.iconolab.conexion.ConexionBD" %>
<%
    if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("tecnico")) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Estructura para almacenar los docentes y sus reportes asociados
    Map<String, Map<String, Object>> docentesMap = new LinkedHashMap<>();

    try (Connection conn = ConexionBD.conectar();
         Statement st = conn.createStatement();
         ResultSet rs = st.executeQuery("SELECT d.nombre, d.apellido_paterno, d.apellido_materno, d.matricula, b.id_bitacora, b.fecha, b.laboratorio, b.calificacion_servicio, b.observaciones_docente FROM usuarios d LEFT JOIN bitacoras_docentes b ON d.matricula = b.matricula_docente WHERE d.rol = 'docente'")) {

        while (rs.next()) {
            String matricula = rs.getString("matricula");
            if (!docentesMap.containsKey(matricula)) {
                Map<String, Object> docData = new HashMap<>();
                docData.put("nombre_completo", rs.getString("nombre") + " " + rs.getString("apellido_paterno") + " " + rs.getString("apellido_materno"));
                docData.put("matricula", matricula);

                Map<String, Object> reporte = new HashMap<>();
                reporte.put("id_bitacora", rs.getInt("id_bitacora") != 0 ? rs.getInt("id_bitacora") : 0);
                reporte.put("fecha", rs.getString("fecha") != null ? rs.getString("fecha") : "No registrada");
                reporte.put("laboratorio", rs.getString("laboratorio") != null ? rs.getString("laboratorio") : "N/A");
                reporte.put("calificacion_servicio", rs.getString("calificacion_servicio") != null ? rs.getString("calificacion_servicio") : "No especificada");
                reporte.put("observaciones_docente", rs.getString("observaciones_docente") != null ? rs.getString("observaciones_docente") : "Sin observaciones");

                docData.put("reporte", reporte);
                docentesMap.put(matricula, docData);
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    List<Map<String, Object>> docentesArray = new ArrayList<>(docentesMap.values());

    String nombreTecnico = session.getAttribute("nombre") + " " + session.getAttribute("apellido_paterno") + " " + session.getAttribute("apellido_materno");
    String matriculaTecnico = (String) session.getAttribute("matricula");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Control de Laboratorio - Personal Técnico</title>
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
        .row-inline { display: flex; gap: 10px; align-items: flex-end; }
        .btn-aceptar { background-color: #005442; color: white; border: none; padding: 10px 15px; border-radius: 6px; cursor: pointer; font-weight: bold; height: 42px; }
        .btn-aceptar:hover { background-color: #0b2f27; }
        .btn-siguiente, .btn-regresar, .btn-guardar { background-color: #005442; color: white; border: none; padding: 12px 25px; border-radius: 6px; cursor: pointer; font-weight: bold; font-size: 15px; }
        .btn-siguiente:hover, .btn-guardar:hover { background-color: #0b2f27; }
        .btn-regresar { background-color: #6c757d; }
        .btn-regresar:hover { background-color: #5a6268; }
        .paso-seccion { display: none; }
        .paso-seccion.activo { display: block; }
        .reporte-caja { background: #f8f9fa; border: 1px dashed #ced4da; padding: 15px; border-radius: 6px; margin-top: 10px; }
    </style>
</head>
<body>

<div class="container">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h2 id="titulo-vista" style="margin: 0; color: #005442;">Control de Laboratorio (Personal Técnico)</h2>
        <a href="login.jsp" style="color: #c92a2a; font-weight: bold; text-decoration: none; border: 1px solid #c92a2a; padding: 6px 12px; border-radius: 4px; font-size: 14px;">Salir sin guardar</a>
    </div>

    <form action="TecnicoServlet" method="POST" onsubmit="return validarFormularioFinal();">

        <div id="paso-1" class="paso-seccion activo">

            <div class="seccion-bloque">
                <h3>Datos de Control del Técnico</h3>

                <div class="grid-2-columnas">
                    <div class="form-group">
                        <label>Nombre del Técnico:</label>
                        <input type="text" value="<%= nombreTecnico %>" readonly style="background-color: #e9ecef;">
                    </div>
                    <div class="form-group">
                        <label>Matrícula:</label>
                        <input type="text" value="<%= matriculaTecnico %>" readonly style="background-color: #e9ecef;">
                    </div>
                </div>

                <div class="grid-3-columnas" style="margin-top: 15px;">
                    <div class="form-group">
                        <label>Fecha:</label>
                        <input type="date" name="fecha_tecnico" value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>" required>
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
                        <label>Turno:</label>
                        <select name="turno" required>
                            <option value="">Selecciona turno...</option>
                            <option value="Matutino">Matutino</option>
                            <option value="Vespertino">Vespertino</option>
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
            </div>

            <div class="seccion-bloque">
                <h3>Docente</h3>
                <div class="grid-2-columnas" style="align-items: flex-end;">
                    <div class="form-group" style="margin-bottom: 0;">
                        <label>Escribe el nombre completo del docente:</label>
                        <input type="text" id="nombre_docente" name="nombre_docente" placeholder="Escribe el nombre del docente" required oninput="limpiarDocente();">
                    </div>
                    <div class="row-inline">
                        <button type="button" class="btn-aceptar" onclick="buscarMatriculaDocente()">Aceptar</button>
                        <div class="form-group" style="flex: 1; margin-bottom: 0;">
                            <label>Matrícula del Docente:</label>
                            <input type="text" id="matricula_docente" name="matricula_docente" placeholder="Se autocompleta" readonly required style="background-color: #e9ecef;">
                        </div>
                    </div>
                </div>
            </div>

            <div class="seccion-bloque">
                <h3>Reporte del Docente</h3>
                <input type="hidden" name="id_bitacora_referencia" id="id_bitacora_referencia" value="0">

                <div class="reporte-caja">
                    <div class="grid-2-columnas">
                        <div class="form-group">
                            <label>Fecha del reporte:</label>
                            <input type="text" id="rep_fecha" value="--" readonly style="background-color: #e9ecef;">
                        </div>
                        <div class="form-group">
                            <label>Laboratorio reportado:</label>
                            <input type="text" id="rep_laboratorio" value="--" readonly style="background-color: #e9ecef;">
                        </div>
                    </div>
                    <div class="form-group" style="margin-top: 15px;">
                        <label>Calificación del servicio:</label>
                        <input type="text" id="rep_calificacion" value="No especificado" readonly style="background-color: #e9ecef;">
                    </div>
                    <div class="form-group" style="margin-top: 15px;">
                        <label>Observaciones del docente:</label>
                        <input type="text" id="rep_observaciones" value="Sin observaciones" readonly style="background-color: #e9ecef;">
                    </div>
                </div>
            </div>

            <div style="text-align: right; margin-top: 20px;">
                <button type="button" class="btn-siguiente" onclick="irAlPaso2()">Siguiente ➔</button>
            </div>
        </div>

        <div id="paso-2" class="paso-seccion">

            <div id="referencia-banner" style="background: #e2f0d9; padding: 10px 15px; border-radius: 6px; margin-bottom: 20px; font-weight: bold; color: #274e13; border: 1px solid #b7d7a8;">
                Reporte de Referencia: Cargando...
            </div>

            <div class="seccion-bloque">
                <h3>Diagnóstico y Solución del Técnico</h3>

                <div class="form-group">
                    <label>Estado de la Falla:</label>
                    <div style="display: flex; gap: 20px; margin-top: 5px;">
                        <label><input type="radio" name="estado_falla" value="Resuelto" checked> Resuelto</label>
                        <label><input type="radio" name="estado_falla" value="En Proceso / Pendiente"> En Proceso / Pendiente</label>
                        <label><input type="radio" name="estado_falla" value="Reemplazo necesario"> Reemplazo necesario</label>
                    </div>
                </div>

                <div class="form-group" style="margin-top: 15px;">
                    <label>Tipo de Trabajo Realizado:</label>
                    <div style="display: flex; gap: 20px; margin-top: 5px;">
                        <label><input type="radio" name="tipo_trabajo" value="Software / Configuración" checked> Software / Configuración</label>
                        <label><input type="radio" name="tipo_trabajo" value="Hardware / Componente"> Hardware / Componente</label>
                        <label><input type="radio" name="tipo_trabajo" value="Red / Cableado"> Red / Cableado</label>
                    </div>
                </div>

                <div class="form-group" style="margin-top: 15px;">
                    <label>Descripción de la solución / Trabajo realizado:</label>
                    <textarea name="descripcion_solucion" rows="3" placeholder="Ej. Se realizó cambio de conector RJ45 dañado en el equipo #12 y se reconfiguró la IP estática." required style="width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px;"></textarea>
                </div>

                <div class="form-group" style="margin-top: 15px;">
                    <label>Materiales / Refacciones empleadas:</label>
                    <input type="text" name="materiales" placeholder="Ej. 1 Patch cord Cat 6 de 2 metros." style="width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px;">
                </div>

                <div class="grid-2-columnas" style="margin-top: 15px;">
                    <div class="form-group">
                        <label>Estado final del laboratorio / equipo:</label>
                        <select name="estado_final" required style="width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px;">
                            <option value="Operativo al 100%">Operativo al 100%</option>
                            <option value="Equipo deshabilitado temporalmente">Equipo deshabilitado temporalmente</option>
                        </select>
                    </div>
                </div>

                <div class="form-group" style="margin-top: 15px;">
                    <label>Observaciones adicionales del técnico:</label>
                    <textarea name="observaciones_tecnico" rows="2" placeholder="Sin más novedades por el momento." style="width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 6px;"></textarea>
                </div>
            </div>

            <div style="display: flex; justify-content: space-between; margin-top: 20px;">
                <button type="button" class="btn-regresar" onclick="irAlPaso1()">⬅ Regresar</button>
                <button type="submit" class="btn-guardar">Guardar Bitácora Técnica</button>
            </div>
        </div>

    </form>
</div>

<script>
const docentesData = [
    <% for(int i = 0; i < docentesArray.size(); i++) {
        Map<String, Object> doc = docentesArray.get(i);
        Map<String, Object> rep = (Map<String, Object>) doc.get("reporte");
    %>
    {
        "nombre_completo": "<%= doc.get("nombre_completo") %>",
        "matricula": "<%= doc.get("matricula") %>",
        "reporte": {
            "id_bitacora": <%= rep.get("id_bitacora") %>,
            "fecha": "<%= rep.get("fecha") %>",
            "laboratorio": "<%= rep.get("laboratorio") %>",
            "calificacion_servicio": "<%= rep.get("calificacion_servicio") %>",
            "observaciones_docente": "<%= rep.get("observaciones_docente") %>"
        }
    }<%= (i < docentesArray.size() - 1) ? "," : "" %>
    <% } %>
];

function buscarMatriculaDocente() {
    const inputNombre = document.getElementById('nombre_docente').value.trim().toLowerCase();
    const inputMatricula = document.getElementById('matricula_docente');

    if(inputNombre === "") {
        alert("Por favor, escribe el nombre del docente primero.");
        return;
    }

    const encontrado = docentesData.find(doc => doc.nombre_completo.toLowerCase().includes(inputNombre));

    if(encontrado) {
        inputMatricula.value = encontrado.matricula;

        const rep = encontrado.reporte;
        document.getElementById('id_bitacora_referencia').value = rep.id_bitacora;
        document.getElementById('rep_fecha').value = rep.fecha;
        document.getElementById('rep_laboratorio').value = rep.laboratorio;
        document.getElementById('rep_calificacion').value = rep.calificacion_servicio;
        document.getElementById('rep_observaciones').value = rep.observaciones_docente;

        document.getElementById('referencia-banner').innerText = "Reporte de Referencia: Docente " + encontrado.nombre_completo + " | Lab: " + rep.laboratorio + " | Fecha: " + rep.fecha;

        alert("¡Matrícula y reporte del docente cargados con éxito!");
    } else {
        inputMatricula.value = "2672000001";
        alert("Docente no encontrado en la lista, se asignó clave provisional de respaldo.");
    }
}

function limpiarDocente() {
    document.getElementById('matricula_docente').value = '';
    document.getElementById('id_bitacora_referencia').value = '0';
}

function irAlPaso2() {
    const folio = document.getElementById('matricula_docente').value.trim();
    if(folio === "") {
        alert("¡Atención! Debe hacer clic en el botón 'Aceptar' para confirmar la matrícula del docente antes de continuar.");
        document.getElementById('nombre_docente').focus();
        return;
    }

    document.getElementById('paso-1').classList.remove('activo');
    document.getElementById('paso-2').classList.add('activo');
    document.getElementById('titulo-vista').innerText = "Control de Laboratorio (Atención Técnica)";
    window.scrollTo(0, 0);
}

function irAlPaso1() {
    document.getElementById('paso-2').classList.remove('activo');
    document.getElementById('paso-1').classList.add('activo');
    document.getElementById('titulo-vista').innerText = "Control de Laboratorio (Personal Técnico)";
    window.scrollTo(0, 0);
}

function validarFormularioFinal() {
    const folio = document.getElementById('matricula_docente').value.trim();
    if(folio === "") {
        alert("Error: Falta confirmar la matrícula del docente.");
        irAlPaso1();
        return false;
    }
    return true;
}
</script>

</body>
</html>