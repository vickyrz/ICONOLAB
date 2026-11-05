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
import java.nio.charset.StandardCharsets;

@WebServlet(name = "UsuarioAdminServlet", value = "/UsuarioAdminServlet")
public class UsuarioAdminServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")
                || session.getAttribute("es_encargado") == null || Integer.parseInt(session.getAttribute("es_encargado").toString()) != 1) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String rol = request.getParameter("rol") != null ? request.getParameter("rol").trim() : "";
        String nombre = request.getParameter("nombre") != null ? request.getParameter("nombre").trim() : "";
        String apellidoPaterno = request.getParameter("apellido_paterno") != null ? request.getParameter("apellido_paterno").trim() : "";
        String apellidoMaterno = request.getParameter("apellido_materno") != null ? request.getParameter("apellido_materno").trim() : "";
        String matricula = request.getParameter("matricula") != null ? request.getParameter("matricula").trim() : "";
        String turno = request.getParameter("turno") != null ? request.getParameter("turno").trim() : "";

        String cuatrimestre = rol.equals("estudiante") ? request.getParameter("cuatrimestre") : null;
        String grupo = rol.equals("estudiante") ? request.getParameter("grupo") : null;
        String carrera = rol.equals("estudiante") ? request.getParameter("carrera") : null;

        String mensaje = "";
        String tipoAlerta = "error";

        // Validaciones del lado del servidor
        if (rol.isEmpty() || nombre.isEmpty() || apellidoPaterno.isEmpty() || apellidoMaterno.isEmpty() ||
                matricula.isEmpty() || turno.isEmpty() ||
                (rol.equals("estudiante") && (cuatrimestre == null || cuatrimestre.isEmpty() || grupo == null || grupo.isEmpty() || carrera == null || carrera.isEmpty()))) {
            mensaje = "Todos los campos correspondientes al rol son obligatorios.";
        } else if (!nombre.matches("^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$") ||
                !apellidoPaterno.matches("^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$") ||
                !apellidoMaterno.matches("^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$")) {
            mensaje = "Los campos de nombre y apellidos únicamente deben contener letras y espacios.";
        } else if (!matricula.matches("^[0-9]{10}$")) {
            mensaje = "El campo de Matrícula/Contraseña debe contener exclusivamente 10 dígitos numéricos.";
        } else {
            Connection conexion = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;

            try {
                conexion = ConexionBD.conectar();

                // Verificar si la matrícula ya existe
                PreparedStatement check = conexion.prepareStatement("SELECT matricula FROM usuarios WHERE matricula = ?");
                check.setString(1, matricula);
                rs = check.executeQuery();

                if (rs.next()) {
                    mensaje = "La matrícula o clave " + matricula + " ya se encuentra registrada en el sistema.";
                    rs.close();
                    check.close();
                } else {
                    rs.close();
                    check.close();

                    // Insertar en la tabla unificada usuarios
                    String sql = "INSERT INTO usuarios (nombre, apellido_paterno, apellido_materno, matricula, rol, turno, grupo, carrera, cuatrimestre) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                    pstmt = conexion.prepareStatement(sql);
                    pstmt.setString(1, nombre);
                    pstmt.setString(2, apellidoPaterno);
                    pstmt.setString(3, apellidoMaterno);
                    pstmt.setString(4, matricula);
                    pstmt.setString(5, rol);
                    pstmt.setString(6, turno);
                    pstmt.setString(7, grupo);
                    pstmt.setString(8, carrera);
                    pstmt.setString(9, cuatrimestre);

                    int filas = pstmt.executeUpdate();
                    pstmt.close();

                    if (filas > 0) {
                        // Si es estudiante, registrar adicionalmente en bitacoras_estudiantes
                        if (rol.equals("estudiante")) {
                            String sqlEst = "INSERT INTO bitacoras_estudiantes (matricula, carrera, grupo, turno, cuatrimestre) VALUES (?, ?, ?, ?, ?)";
                            PreparedStatement pstmtEst = conexion.prepareStatement(sqlEst);
                            pstmtEst.setString(1, matricula);
                            pstmtEst.setString(2, carrera);
                            pstmtEst.setString(3, grupo);
                            pstmtEst.setString(4, turno);
                            pstmtEst.setString(5, cuatrimestre);
                            pstmtEst.executeUpdate();
                            pstmtEst.close();
                        }

                        mensaje = "¡Usuario con rol de [" + rol.toUpperCase() + "] registrado exitosamente!";
                        tipoAlerta = "exito";
                    } else {
                        mensaje = "Error al registrar el usuario en la base de datos.";
                    }
                }

            } catch (SQLException e) {
                e.printStackTrace();
                mensaje = "Error de SQL: " + e.getMessage();
            } finally {
                try { if (conexion != null) conexion.close(); } catch (SQLException ignored) {}
            }
        }

        response.sendRedirect("registro-usuarios-admin.jsp?mensaje=" + URLEncoder.encode(mensaje, "UTF-8") + "&tipo=" + tipoAlerta);
    }
}