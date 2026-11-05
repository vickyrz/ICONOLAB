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

@WebServlet(name = "RegistroAlumnosServlet", value = "/RegistroAlumnosServlet")
public class RegistroAlumnosServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null || !"docente".equals(session.getAttribute("rol"))) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String apellidoPaterno = request.getParameter("apellido_paterno") != null ? request.getParameter("apellido_paterno").trim() : "";
        String apellidoMaterno = request.getParameter("apellido_materno") != null ? request.getParameter("apellido_materno").trim() : "";
        String nombre = request.getParameter("nombre") != null ? request.getParameter("nombre").trim() : "";
        String extensionMatricula = request.getParameter("matricula") != null ? request.getParameter("matricula").trim() : "";
        String matriculaCompleta = "1224" + extensionMatricula;

        String cuatrimestre = request.getParameter("cuatrimestre") != null ? request.getParameter("cuatrimestre").trim() : "";
        String turno = request.getParameter("turno") != null ? request.getParameter("turno").trim() : "";
        String grupo = request.getParameter("grupo") != null ? request.getParameter("grupo").trim() : "";
        String carrera = request.getParameter("carrera") != null ? request.getParameter("carrera").trim() : "";

        String mensaje = "";
        String tipoAlerta = "error";

        // Validaciones del servidor
        if (nombre.isEmpty() || apellidoPaterno.isEmpty() || apellidoMaterno.isEmpty() ||
                extensionMatricula.isEmpty() || cuatrimestre.isEmpty() || turno.isEmpty() || grupo.isEmpty() || carrera.isEmpty()) {
            mensaje = "Todos los campos son estrictamente obligatorios.";
        } else if (!nombre.matches("^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$") ||
                !apellidoPaterno.matches("^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$") ||
                !apellidoMaterno.matches("^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$")) {
            mensaje = "Los campos de nombre y apellidos únicamente deben contener letras y espacios.";
        } else if (!extensionMatricula.matches("^[0-9]+$")) {
            mensaje = "La matrícula debe contener exclusivamente números.";
        } else {
            Connection conexion = null;
            try {
                conexion = ConexionBD.conectar();

                // Verificar si la matrícula completa ya existe
                try (PreparedStatement check = conexion.prepareStatement("SELECT matricula FROM usuarios WHERE matricula = ?")) {
                    check.setString(1, matriculaCompleta);
                    try (ResultSet res = check.executeQuery()) {
                        if (res.next()) {
                            mensaje = "La matrícula " + matriculaCompleta + " ya se encuentra registrada.";
                            response.sendRedirect("registro-alumnos.jsp?mensaje=" + URLEncoder.encode(mensaje, "UTF-8") + "&tipo=" + tipoAlerta);
                            return;
                        }
                    }
                }

                // Insertar estudiante en usuarios
                String sqlUser = "INSERT INTO usuarios (nombre, apellido_paterno, apellido_materno, matricula, rol, turno, grupo) VALUES (?, ?, ?, ?, 'estudiante', ?, ?)";
                try (PreparedStatement stmt = conexion.prepareStatement(sqlUser)) {
                    stmt.setString(1, nombre);
                    stmt.setString(2, apellidoPaterno);
                    stmt.setString(3, apellidoMaterno);
                    stmt.setString(4, matriculaCompleta);
                    stmt.setString(5, turno);
                    stmt.setString(6, grupo);

                    if (stmt.executeUpdate() > 0) {
                        // Registrar también en bitacoras_estudiantes
                        String sqlEst = "INSERT INTO bitacoras_estudiantes (matricula, carrera, grupo, turno, cuatrimestre) VALUES (?, ?, ?, ?, ?)";
                        try (PreparedStatement stmtEst = conexion.prepareStatement(sqlEst)) {
                            stmtEst.setString(1, matriculaCompleta);
                            stmtEst.setString(2, carrera);
                            stmtEst.setString(3, grupo);
                            stmtEst.setString(4, turno);
                            stmtEst.setString(5, cuatrimestre);
                            stmtEst.executeUpdate();
                        }

                        mensaje = "¡Alumno " + nombre + " " + apellidoPaterno + " registrado con éxito! Matrícula: " + matriculaCompleta;
                        tipoAlerta = "exito";
                    } else {
                        mensaje = "Error al registrar el alumno en el sistema.";
                    }
                }

            } catch (SQLException e) {
                e.printStackTrace();
                mensaje = "Error de SQL: " + e.getMessage();
            } finally {
                if (conexion != null) {
                    try { conexion.close(); } catch (SQLException ignored) {}
                }
            }
        }

        response.sendRedirect("registro-alumnos.jsp?mensaje=" + URLEncoder.encode(mensaje, "UTF-8") + "&tipo=" + tipoAlerta);
    }
}