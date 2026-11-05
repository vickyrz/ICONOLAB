package com.example.iconolab.controladores;

import com.example.iconolab.conexion.ConexionBD;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.*;

@WebServlet(name = "EstudianteServlet", value = "/EstudianteServlet")
public class EstudianteServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("estudiante")) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String errorMensaje = "";

        // Recibir datos del formulario
        String folioDocente = request.getParameter("folio_docente") != null ? request.getParameter("folio_docente").trim() : "";
        String laboratorio = request.getParameter("laboratorio") != null ? request.getParameter("laboratorio").trim() : "";
        String fecha = request.getParameter("fecha") != null ? request.getParameter("fecha").trim() : "";
        String grupo = request.getParameter("grupo") != null ? request.getParameter("grupo").trim() : "";
        String turno = request.getParameter("turno") != null ? request.getParameter("turno").trim() : "";
        String materia = request.getParameter("materia") != null ? request.getParameter("materia").trim() : "";
        String horaEntrada = request.getParameter("hora_entrada") != null ? request.getParameter("hora_entrada").trim() : "";
        String horaSalida = request.getParameter("hora_salida") != null ? request.getParameter("hora_salida").trim() : "";

        if (horaEntrada.length() == 5) horaEntrada += ":00";
        if (horaSalida.length() == 5) horaSalida += ":00";

        String numPc = request.getParameter("num_pc") != null ? request.getParameter("num_pc").trim() : "";
        String carrera = request.getParameter("carrera") != null ? request.getParameter("carrera").trim() : "";
        String practicaNo = request.getParameter("practica_no") != null ? request.getParameter("practica_no").trim() : "";
        String nombrePractica = request.getParameter("nombre_practica") != null ? request.getParameter("nombre_practica").trim() : "";
        String fallasObservaciones = request.getParameter("fallas_observaciones") != null ? request.getParameter("fallas_observaciones").trim() : "";
        String numReporte = request.getParameter("num_reporte") != null ? request.getParameter("num_reporte").trim() : "";

        if (fallasObservaciones.isEmpty()) fallasObservaciones = "Ninguna";
        if (numReporte.isEmpty()) numReporte = "N/A";
        String asistencia = "Asistió";
        String matriculaEstudiante = (String) session.getAttribute("matricula");

        if (folioDocente.isEmpty()) {
            errorMensaje = "Error: selecciona un docente válido.";
        }

        Connection conexion = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        boolean bloqueoObtenido = false;
        boolean transaccionIniciada = false;
        String claveBloqueo = "";

        try {
            conexion = ConexionBD.conectar();
            conexion.setAutoCommit(false);

            // Verificar que el docente exista y obtener su nombre completo
            String sqlDocente = "SELECT nombre, apellido_paterno, apellido_materno FROM usuarios WHERE matricula = ? AND rol = 'docente' LIMIT 1";
            stmt = conexion.prepareStatement(sqlDocente);
            stmt.setString(1, folioDocente);
            rs = stmt.executeQuery();

            String nombreDocente = "";
            if (rs.next()) {
                nombreDocente = (rs.getString("nombre") + " " + rs.getString("apellido_paterno") + " " + rs.getString("apellido_materno")).trim();
            } else {
                errorMensaje = "Error: el docente seleccionado no existe.";
            }
            rs.close();
            stmt.close();

            if (!errorMensaje.isEmpty()) {
                redirigirConError(request, response, errorMensaje);
                return;
            }

            // Validaciones de obligatorios
            if (laboratorio.isEmpty() || fecha.isEmpty() || grupo.isEmpty() || turno.isEmpty() || materia.isEmpty() ||
                    horaEntrada.isEmpty() || horaSalida.isEmpty() || numPc.isEmpty() || carrera.isEmpty() ||
                    practicaNo.isEmpty() || nombrePractica.isEmpty()) {
                redirigirConError(request, response, "Error: completa todos los campos obligatorios.");
                return;
            }

            // Generar clave de bloqueo similar a SHA-256 de PHP
            String datosConcatenados = folioDocente + fecha + laboratorio + grupo + turno + materia;
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(datosConcatenados.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hashBytes) {
                hexString.append(String.format("%02x", b));
            }
            claveBloqueo = "bitacora_" + hexString.substring(0, Math.min(48, hexString.length()));

            // Obtener GET_LOCK de MySQL
            stmt = conexion.prepareStatement("SELECT GET_LOCK(?, 15)");
            stmt.setString(1, claveBloqueo);
            rs = stmt.executeQuery();
            int resultadoBloqueo = 0;
            if (rs.next()) resultadoBloqueo = rs.getInt(1);
            rs.close();
            stmt.close();

            if (resultadoBloqueo != 1) {
                throw new Exception("No se pudo bloquear la clase. Intenta nuevamente.");
            }
            bloqueoObtenido = true;
            transaccionIniciada = true;

            // Buscar bitácora docente existente con FOR UPDATE
            String sqlBusquedaDocente = "SELECT id_bitacora FROM bitacoras_docentes WHERE matricula_docente = ? AND fecha = ? AND laboratorio = ? AND grupo = ? AND turno = ? AND materia = ? ORDER BY id_bitacora DESC LIMIT 1 FOR UPDATE";
            stmt = conexion.prepareStatement(sqlBusquedaDocente);
            stmt.setString(1, folioDocente);
            stmt.setString(2, fecha);
            stmt.setString(3, laboratorio);
            stmt.setString(4, grupo);
            stmt.setString(5, turno);
            stmt.setString(6, materia);
            rs = stmt.executeQuery();

            int idBitacora = -1;
            if (rs.next()) {
                idBitacora = rs.getInt("id_bitacora");
            }
            rs.close();
            stmt.close();

            // Si no existe, la creamos automáticamente
            if (idBitacora == -1) {
                String sqlInsertaDocente = "INSERT INTO bitacoras_docentes (matricula_docente, nombre_docente, fecha, laboratorio, materia, grupo, total_alumnos, hora_entrada, hora_salida, calificacion_servicio, turno, observaciones_docente) VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, 'Regular', ?, 'Generado automáticamente por registro de alumno')";
                stmt = conexion.prepareStatement(sqlInsertaDocente, Statement.RETURN_GENERATED_KEYS);
                stmt.setString(1, folioDocente);
                stmt.setString(2, nombreDocente);
                stmt.setString(3, fecha);
                stmt.setString(4, laboratorio);
                stmt.setString(5, materia);
                stmt.setString(6, grupo);
                stmt.setString(7, horaEntrada);
                stmt.setString(8, horaSalida);
                stmt.setString(9, turno);
                stmt.executeUpdate();

                rs = stmt.getGeneratedKeys();
                if (rs.next()) idBitacora = rs.getInt(1);
                rs.close();
                stmt.close();
            }

            // Insertar el registro del estudiante en bitacoras_estudiantes
            String sqlInsertaEstudiante = "INSERT INTO bitacoras_estudiantes (id_bitacora, num_pc, matricula, carrera, grupo, turno, materia, asistencia, fallas_observaciones, num_reporte, practica_no, nombre_practica, hora_entrada, hora_salida) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            stmt = conexion.prepareStatement(sqlInsertaEstudiante);
            stmt.setInt(1, idBitacora);
            stmt.setString(2, numPc);
            stmt.setString(3, matriculaEstudiante);
            stmt.setString(4, carrera);
            stmt.setString(5, grupo);
            stmt.setString(6, turno);
            stmt.setString(7, materia);
            stmt.setString(8, asistencia);
            stmt.setString(9, fallasObservaciones);
            stmt.setString(10, numReporte);
            stmt.setString(11, practicaNo);
            stmt.setString(12, nombrePractica);
            stmt.setString(13, horaEntrada);
            stmt.setString(14, horaSalida);
            stmt.executeUpdate();
            stmt.close();

            // Actualizar el total de alumnos en la bitácora del docente
            String sqlUpdateTotal = "UPDATE bitacoras_docentes SET total_alumnos = (SELECT COUNT(*) FROM bitacoras_estudiantes WHERE id_bitacora = ?) WHERE id_bitacora = ?";
            stmt = conexion.prepareStatement(sqlUpdateTotal);
            stmt.setInt(1, idBitacora);
            stmt.setInt(2, idBitacora);
            stmt.executeUpdate();
            stmt.close();

            conexion.commit();
            transaccionIniciada = false;

            // Liberar bloqueo
            stmt = conexion.prepareStatement("SELECT RELEASE_LOCK(?)");
            stmt.setString(1, claveBloqueo);
            stmt.execute();
            stmt.close();
            bloqueoObtenido = false;

            // Destruir sesión y regresar al login tras guardar con éxito
            session.invalidate();
            response.sendRedirect("login.jsp");

        } catch (Exception e) {
            if (transaccionIniciada && conexion != null) {
                try { conexion.rollback(); } catch (SQLException ignored) {}
            }
            if (bloqueoObtenido && conexion != null) {
                try {
                    PreparedStatement releaseStmt = conexion.prepareStatement("SELECT RELEASE_LOCK(?)");
                    releaseStmt.setString(1, claveBloqueo);
                    releaseStmt.execute();
                    releaseStmt.close();
                } catch (SQLException ignored) {}
            }
            e.printStackTrace();
            redirigirConError(request, response, "No se pudo guardar el registro. Ocurrió un error en la base de datos.");
        } finally {
            if (conexion != null) {
                try { conexion.close(); } catch (SQLException ignored) {}
            }
        }
    }

    private void redirigirConError(HttpServletRequest request, HttpServletResponse response, String mensaje) throws IOException {
        response.sendRedirect("bitacoras-estudiantes.jsp?error=" + java.net.URLEncoder.encode(mensaje, "UTF-8"));
    }
}