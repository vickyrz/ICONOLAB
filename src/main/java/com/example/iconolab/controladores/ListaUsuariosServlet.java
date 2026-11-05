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
import java.net.URLEncoder;

@WebServlet(name = "ListaUsuariosServlet", value = "/ListaUsuariosServlet")
public class ListaUsuariosServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")
                || session.getAttribute("es_encargado") == null || Integer.parseInt(session.getAttribute("es_encargado").toString()) != 1) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String accion = request.getParameter("accion");
        String adminMatricula = (String) session.getAttribute("matricula");

        Connection conexion = null;
        try {
            conexion = ConexionBD.conectar();

            if ("eliminar_usuario".equals(accion)) {
                String matriculaEliminar = request.getParameter("matricula") != null ? request.getParameter("matricula").trim() : "";

                if (matriculaEliminar.equals(adminMatricula)) {
                    response.sendRedirect("lista-usuarios.jsp?mensaje=" + URLEncoder.encode("No puedes eliminar tu propia cuenta de administrador.", "UTF-8") + "&tipo=error");
                    return;
                }

                try (PreparedStatement stmt = conexion.prepareStatement("DELETE FROM usuarios WHERE matricula = ?")) {
                    stmt.setString(1, matriculaEliminar);
                    if (stmt.executeUpdate() > 0) {
                        try (PreparedStatement stmt2 = conexion.prepareStatement("DELETE FROM bitacoras_estudiantes WHERE matricula = ?")) {
                            stmt2.setString(1, matriculaEliminar);
                            stmt2.executeUpdate();
                        }
                        response.sendRedirect("lista-usuarios.jsp?resultado=eliminado");
                        return;
                    }
                }
                response.sendRedirect("lista-usuarios.jsp?mensaje=" + URLEncoder.encode("Error al eliminar el usuario.", "UTF-8") + "&tipo=error");

            } else if ("eliminar_masivo".equals(accion)) {
                String[] matriculasABorrar = request.getParameterValues("matriculas_seleccionadas");

                if (matriculasABorrar != null && matriculasABorrar.length > 0) {
                    int eliminadosCount = 0;
                    for (String mat : matriculasABorrar) {
                        mat = mat != null ? mat.trim() : "";
                        if (mat.isEmpty() || mat.equals(adminMatricula)) continue;

                        try (PreparedStatement stmt = conexion.prepareStatement("DELETE FROM usuarios WHERE matricula = ?")) {
                            stmt.setString(1, mat);
                            if (stmt.executeUpdate() > 0) {
                                try (PreparedStatement stmt2 = conexion.prepareStatement("DELETE FROM bitacoras_estudiantes WHERE matricula = ?")) {
                                    stmt2.setString(1, mat);
                                    stmt2.executeUpdate();
                                }
                                eliminadosCount++;
                            }
                        }
                    }
                    response.sendRedirect("lista-usuarios.jsp?resultado=masivo&total=" + eliminadosCount);
                } else {
                    response.sendRedirect("lista-usuarios.jsp?mensaje=" + URLEncoder.encode("No seleccionaste ningún usuario para eliminar.", "UTF-8") + "&tipo=error");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("lista-usuarios.jsp?mensaje=" + URLEncoder.encode("Error de base de datos: " + e.getMessage(), "UTF-8") + "&tipo=error");
        } finally {
            if (conexion != null) {
                try { conexion.close(); } catch (SQLException ignored) {}
            }
        }
    }
}