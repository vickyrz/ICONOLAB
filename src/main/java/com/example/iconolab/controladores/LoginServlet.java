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

@WebServlet(name = "LoginServlet", value = "/LoginServlet")
public class LoginServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Recibimos los parámetros del formulario exactamente igual que en PHP
        String rol = request.getParameter("usuario");
        String matricula = request.getParameter("matricula");

        String error = "";

        if (matricula == null || matricula.trim().isEmpty() || rol == null || rol.trim().isEmpty()) {
            error = "Por favor, completa todos los campos.";
            response.sendRedirect("login.jsp?error=" + java.net.URLEncoder.encode(error, "UTF-8"));
            return;
        }

        matricula = matricula.trim();

        // Validación estricta para estudiante o técnico (exactamente 10 dígitos)
        if (!rol.equals("docente") && !matricula.matches("^[0-9]{10}$")) {
            error = "La contraseña debe contener exactamente 10 números.";
            response.sendRedirect("login.jsp?error=" + java.net.URLEncoder.encode(error, "UTF-8"));
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = ConexionBD.conectar();

            // Consulta preparada buscando por matrícula y rol
            String sql = "SELECT * FROM usuarios WHERE matricula = ? AND rol = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, matricula);
            pstmt.setString(2, rol);

            rs = pstmt.executeQuery();

            if (rs.next()) {
                // Guardamos los datos del usuario en la sesión de Java (equivalente a $_SESSION de PHP)
                HttpSession session = request.getSession();
                session.setAttribute("matricula", rs.getString("matricula"));
                session.setAttribute("nombre", rs.getString("nombre"));
                session.setAttribute("apellido_paterno", rs.getString("apellido_paterno"));
                session.setAttribute("apellido_materno", rs.getString("apellido_materno"));
                session.setAttribute("grupo", rs.getString("grupo") != null ? rs.getString("grupo") : "");
                session.setAttribute("rol", rs.getString("rol"));
                session.setAttribute("es_encargado", rs.getInt("es_encargado"));

                int esEncargado = rs.getInt("es_encargado");
                String dbRol = rs.getString("rol");

                // Redirección estricta según privilegios y roles
                if (esEncargado == 1) {
                    response.sendRedirect("panel-administrador.jsp");
                } else if (dbRol.equals("estudiante")) {
                    response.sendRedirect("bitacoras-estudiantes.jsp");
                } else if (dbRol.equals("docente")) {
                    response.sendRedirect("bitacoras-docentes.jsp");
                } else if (dbRol.equals("tecnico")) {
                    response.sendRedirect("bitacoras-tecnico.jsp");
                } else {
                    response.sendRedirect("login.jsp");
                }
            } else {
                error = "Credenciales incorrectas o el usuario no coincide.";
                response.sendRedirect("login.jsp?error=" + java.net.URLEncoder.encode(error, "UTF-8"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
            error = "Error de conexión con la base de datos.";
            response.sendRedirect("login.jsp?error=" + java.net.URLEncoder.encode(error, "UTF-8"));
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException ignored) {}
            try { if (pstmt != null) pstmt.close(); } catch (SQLException ignored) {}
            try { if (conn != null) conn.close(); } catch (SQLException ignored) {}
        }
    }
}