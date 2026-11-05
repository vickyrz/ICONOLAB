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
import java.net.URLEncoder;

@WebServlet(name = "EditarUsuarioServlet", value = "/EditarUsuarioServlet")
public class EditarUsuarioServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")
                || session.getAttribute("es_encargado") == null || Integer.parseInt(session.getAttribute("es_encargado").toString()) != 1) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String matriculaParam = request.getParameter("matricula") != null ? request.getParameter("matricula").trim() : "";
        String nombre = request.getParameter("nombre") != null ? request.getParameter("nombre").trim() : "";
        String apellidoPaterno = request.getParameter("apellido_paterno") != null ? request.getParameter("apellido_paterno").trim() : "";
        String apellidoMaterno = request.getParameter("apellido_materno") != null ? request.getParameter("apellido_materno").trim() : "";
        String turno = request.getParameter("turno") != null ? request.getParameter("turno").trim() : "";
        String grupo = request.getParameter("grupo") != null ? request.getParameter("grupo").trim() : null;
        String cuatrimestre = request.getParameter("cuatrimestre") != null ? request.getParameter("cuatrimestre").trim() : "";
        String carrera = request.getParameter("carrera") != null ? request.getParameter("carrera").trim() : "";

        if (matriculaParam.isEmpty() || nombre.isEmpty() || apellidoPaterno.isEmpty() || turno.isEmpty()) {
            response.sendRedirect("editar-usuario.jsp?matricula=" + URLEncoder.encode(matriculaParam, "UTF-8") + "&mensaje=" + URLEncoder.encode("Los campos principales son obligatorios.", "UTF-8") + "&tipo=error");
            return;
        }

        Connection conexion = null;
        try {
            conexion = ConexionBD.conectar();

            // Consultar el rol del usuario para saber si es estudiante
            String rolUsuario = "";
            try (PreparedStatement stmtRol = conexion.prepareStatement("SELECT rol FROM usuarios WHERE matricula = ?")) {
                stmtRol.setString(1, matriculaParam);
                try (ResultSet rsRol = stmtRol.executeQuery()) {
                    if (rsRol.next()) {
                        rolUsuario = rsRol.getString("rol");
                    }
                }
            }

            // Actualizar datos base en la tabla usuarios
            String sqlUpdate = "UPDATE usuarios SET nombre = ?, apellido_paterno = ?, apellido_materno = ?, turno = ?, grupo = ? WHERE matricula = ?";
            try (PreparedStatement stmt = conexion.prepareStatement(sqlUpdate)) {
                stmt.setString(1, nombre);
                stmt.setString(2, apellidoPaterno);
                stmt.setString(3, apellidoMaterno);
                stmt.setString(4, turno);
                stmt.setString(5, "estudiante".equals(rolUsuario) ? grupo : null);
                stmt.setString(6, matriculaParam);
                stmt.executeUpdate();
            }

            // Si es estudiante, actualizar también en bitacoras_estudiantes
            if ("estudiante".equals(rolUsuario)) {
                String sqlEst = "UPDATE bitacoras_estudiantes SET cuatrimestre = ?, carrera = ?, grupo = ?, turno = ? WHERE matricula = ?";
                try (PreparedStatement stmtEst = conexion.prepareStatement(sqlEst)) {
                    stmtEst.setString(1, cuatrimestre);
                    stmtEst.setString(2, carrera);
                    stmtEst.setString(3, grupo);
                    stmtEst.setString(4, turno);
                    stmtEst.setString(5, matriculaParam);
                    stmtEst.executeUpdate();
                }
            }

            response.sendRedirect("editar-usuario.jsp?matricula=" + URLEncoder.encode(matriculaParam, "UTF-8") + "&mensaje=" + URLEncoder.encode("¡Información actualizada correctamente!", "UTF-8") + "&tipo=exito");

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("editar-usuario.jsp?matricula=" + URLEncoder.encode(matriculaParam, "UTF-8") + "&mensaje=" + URLEncoder.encode("Error al actualizar el usuario: " + e.getMessage(), "UTF-8") + "&tipo=error");
        } finally {
            if (conexion != null) {
                try { conexion.close(); } catch (SQLException ignored) {}
            }
        }
    }
}