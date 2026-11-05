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
import java.sql.SQLException;

@WebServlet(name = "DocenteServlet", value = "/DocenteServlet")
public class DocenteServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String nombreDocente = session.getAttribute("nombre") + " " + session.getAttribute("apellido_paterno") + " " + session.getAttribute("apellido_materno");
        String matriculaDocente = (String) session.getAttribute("matricula");

        String fecha = request.getParameter("fecha");
        String horaEntrada = request.getParameter("hora_entrada");
        String horaSalida = request.getParameter("hora_salida");
        String grupo = request.getParameter("grupo");
        String materia = request.getParameter("materia");
        String laboratorio = request.getParameter("laboratorio");
        String turno = request.getParameter("turno");

        // Bloque de observaciones
        String calificacionServicio = request.getParameter("calificacion_servicio");
        String falloComponente = request.getParameter("fallo_componente");
        String funcionInternet = request.getParameter("funcion_internet");
        String detalleFallo = request.getParameter("detalle_fallo");
        if (detalleFallo == null) detalleFallo = "";
        String observacionesAdicionales = request.getParameter("observaciones_adicionales");

        Connection conexion = null;
        PreparedStatement pstmt = null;

        try {
            conexion = ConexionBD.conectar();

            String sql = "INSERT INTO bitacoras_docentes (" +
                    "laboratorio, fecha, hora_entrada, hora_salida, nombre_docente, matricula_docente, " +
                    "grupo, materia, turno, calificacion_servicio, fallos_componente, " +
                    "funcion_internet, detalle_fallo, observaciones_docente, total_alumnos" +
                    ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)";

            pstmt = conexion.prepareStatement(sql);
            pstmt.setString(1, laboratorio);
            pstmt.setString(2, fecha);
            pstmt.setString(3, horaEntrada);
            pstmt.setString(4, horaSalida);
            pstmt.setString(5, nombreDocente);
            pstmt.setString(6, matriculaDocente);
            pstmt.setString(7, grupo);
            pstmt.setString(8, materia);
            pstmt.setString(9, turno);
            pstmt.setString(10, calificacionServicio);
            pstmt.setString(11, falloComponente);
            pstmt.setString(12, funcionInternet);
            pstmt.setString(13, detalleFallo);
            pstmt.setString(14, observacionesAdicionales);

            int filasAfectadas = pstmt.executeUpdate();

            if (filasAfectadas > 0) {
                // Destruir sesión y regresar al login al igual que en PHP
                session.invalidate();
                response.sendRedirect("login.jsp");
            } else {
                response.getWriter().println("Error al guardar el registro en la base de datos.");
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.getWriter().println("Error de SQL: " + e.getMessage());
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (SQLException ignored) {}
            try { if (conexion != null) conexion.close(); } catch (SQLException ignored) {}
        }
    }
}