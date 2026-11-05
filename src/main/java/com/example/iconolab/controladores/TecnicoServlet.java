package com.example.iconolab.controladores;

import com.example.iconolab.conexion.ConexionBD;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

@WebServlet(name = "TecnicoServlet", value = "/TecnicoServlet")
public class TecnicoServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("tecnico")) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String matriculaDocenteDef = request.getParameter("matricula_docente");
        if (matriculaDocenteDef == null || matriculaDocenteDef.trim().isEmpty()) {
            response.getWriter().println("<script>alert('Error: Debe verificar y confirmar la matrícula del docente haciendo clic en Aceptar antes de guardar.'); window.history.back();</script>");
            return;
        }
        matriculaDocenteDef = matriculaDocenteDef.trim();

        String nombreTecnico = session.getAttribute("nombre") + " " + session.getAttribute("apellido_paterno") + " " + session.getAttribute("apellido_materno");
        String folioTecnico = (String) session.getAttribute("matricula");

        String fechaTecnico = request.getParameter("fecha_tecnico");
        String horaEntrada = request.getParameter("hora_entrada");
        String horaSalida = request.getParameter("hora_salida");
        String turno = request.getParameter("turno");
        String laboratorio = request.getParameter("laboratorio");
        String nombreDocente = request.getParameter("nombre_docente");

        String idBitacoraRefStr = request.getParameter("id_bitacora_referencia");
        int idBitacoraPost = 0;
        try {
            if (idBitacoraRefStr != null) {
                idBitacoraPost = Integer.parseInt(idBitacoraRefStr);
            }
        } catch (NumberFormatException ignored) {}

        String estadoFalla = request.getParameter("estado_falla") != null ? request.getParameter("estado_falla") : "Resuelto";
        String tipoTrabajo = request.getParameter("tipo_trabajo") != null ? request.getParameter("tipo_trabajo") : "Software / Configuración";
        String descripcionSolucion = request.getParameter("descripcion_solucion") != null ? request.getParameter("descripcion_solucion") : "";
        String materiales = request.getParameter("materiales") != null ? request.getParameter("materiales") : "";
        String estadoFinal = request.getParameter("estado_final") != null ? request.getParameter("estado_final") : "Operativo al 100%";
        String observacionesTecnico = request.getParameter("observaciones_tecnico") != null ? request.getParameter("observaciones_tecnico") : "";

        Connection conexion = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conexion = ConexionBD.conectar();

            // Si no hay bitácora de referencia, creamos una de manera automática
            if (idBitacoraPost == 0) {
                String sqlCrear = "INSERT INTO bitacoras_docentes (laboratorio, fecha, nombre_docente, matricula_docente, calificacion_servicio, observaciones_docente, total_alumnos) VALUES (?, ?, ?, ?, 'Regular', 'Generado automáticamente por registro técnico', 0)";
                pstmt = conexion.prepareStatement(sqlCrear, Statement.RETURN_GENERATED_KEYS);
                pstmt.setString(1, laboratorio);
                pstmt.setString(2, fechaTecnico);
                pstmt.setString(3, nombreDocente);
                pstmt.setString(4, matriculaDocenteDef);
                pstmt.executeUpdate();

                rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    idBitacoraPost = rs.getInt(1);
                }
                rs.close();
                pstmt.close();
            }

            // Insertar en bitacoras_tecnicos
            String sql = "INSERT INTO bitacoras_tecnicos (id_bitacora, fecha, hora_entrada, hora_salida, turno, laboratorio, nombre_tecnico, matricula_tecnico, estado_falla, tipo_trabajo, descripcion_solucion, materiales, estado_final, observaciones_tecnico, uso_internet) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Si')";

            pstmt = conexion.prepareStatement(sql);
            pstmt.setInt(1, idBitacoraPost);
            pstmt.setString(2, fechaTecnico);
            pstmt.setString(3, horaEntrada);
            pstmt.setString(4, horaSalida);
            pstmt.setString(5, turno);
            pstmt.setString(6, laboratorio);
            pstmt.setString(7, nombreTecnico);
            pstmt.setString(8, folioTecnico);
            pstmt.setString(9, estadoFalla);
            pstmt.setString(10, tipoTrabajo);
            pstmt.setString(11, descripcionSolucion);
            pstmt.setString(12, materiales);
            pstmt.setString(13, estadoFinal);
            pstmt.setString(14, observacionesTecnico);

            int filas = pstmt.executeUpdate();

            if (filas > 0) {
                session.invalidate();
                response.sendRedirect("login.jsp");
            } else {
                response.getWriter().println("Error al guardar el registro técnico.");
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Error de base de datos: " + e.getMessage());
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException ignored) {}
            try { if (pstmt != null) pstmt.close(); } catch (SQLException ignored) {}
            try { if (conexion != null) conexion.close(); } catch (SQLException ignored) {}
        }
    }
}