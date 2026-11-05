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

@WebServlet(name = "EditarBitacoraServlet", value = "/EditarBitacoraServlet")
public class EditarBitacoraServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null || !"docente".equals(session.getAttribute("rol"))) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String idStr = request.getParameter("id");
        int idBitacora = 0;
        try {
            if (idStr != null) {
                idBitacora = Integer.parseInt(idStr);
            }
        } catch (NumberFormatException ignored) {}

        if (idBitacora <= 0) {
            response.sendRedirect("panel-administrador.jsp");
            return;
        }

        String nombreDocente = request.getParameter("nombre_docente");
        String folioDocente = request.getParameter("folio_docente");
        String laboratorio = request.getParameter("laboratorio");
        String fecha = request.getParameter("fecha");
        String calificacionServicio = request.getParameter("calificacion_servicio");
        if (calificacionServicio == null) calificacionServicio = "Regular";
        String observacionesDocente = request.getParameter("observaciones_docente");

        int totalAlumnos = 0;
        try {
            totalAlumnos = Integer.parseInt(request.getParameter("total_alumnos"));
        } catch (NumberFormatException ignored) {}

        String carrera = request.getParameter("carrera");
        String grupo = request.getParameter("grupo");
        String turno = request.getParameter("turno");
        String materia = request.getParameter("materia");
        String practicaNo = request.getParameter("practica_no");
        String nombrePractica = request.getParameter("nombre_practica");

        String horaEntrada = request.getParameter("hora_entrada");
        String horaSalida = request.getParameter("hora_salida");
        String usoInternet = request.getParameter("uso_internet");
        if (usoInternet == null) usoInternet = "No";
        String obsTecnico = request.getParameter("observaciones_tecnico");
        String nombreTecnico = request.getParameter("nombre_tecnico");
        String firmaTecnico = request.getParameter("firma_tecnico");

        try (Connection conn = ConexionBD.conectar()) {
            // 1. Actualizar datos de bitacoras_docentes
            String sqlDoc = "UPDATE bitacoras_docentes SET nombre_docente = ?, matricula_docente = ?, laboratorio = ?, fecha = ?, calificacion_servicio = ?, observaciones_docente = ?, total_alumnos = ? WHERE id_bitacora = ?";
            try (PreparedStatement pst = conn.prepareStatement(sqlDoc)) {
                pst.setString(1, nombreDocente);
                pst.setString(2, folioDocente);
                pst.setString(3, laboratorio);
                pst.setString(4, fecha);
                pst.setString(5, calificacionServicio);
                pst.setString(6, observacionesDocente);
                pst.setInt(7, totalAlumnos);
                pst.setInt(8, idBitacora);
                pst.executeUpdate();
            }

            // 2. Actualizar datos generales de la práctica en bitacoras_estudiantes
            String sqlEstGen = "UPDATE bitacoras_estudiantes SET carrera = ?, grupo = ?, turno = ?, materia = ?, practica_no = ?, nombre_practica = ? WHERE id_bitacora = ?";
            try (PreparedStatement pst = conn.prepareStatement(sqlEstGen)) {
                pst.setString(1, carrera);
                pst.setString(2, grupo);
                pst.setString(3, turno);
                pst.setString(4, materia);
                pst.setString(5, practicaNo);
                pst.setString(6, nombrePractica);
                pst.setInt(7, idBitacora);
                pst.executeUpdate();
            }

            // 3. Actualizar detalles de estudiantes individuales iterando sobre los parámetros enviados del formulario
            for (Object keyObj : request.getParameterMap().keySet()) {
                String paramName = (String) keyObj;
                if (paramName.startsWith("alumnos[")) {
                    // Extraer id_detalle usando expresiones regulares o parsing simple
                    try {
                        int start = paramName.indexOf("[") + 1;
                        int end = paramName.indexOf("]");
                        int idDetalle = Integer.parseInt(paramName.substring(start, end));

                        if (paramName.endsWith("[num_pc]")) {
                            String numPc = request.getParameter(paramName);
                            String fallasObs = request.getParameter("alumnos[" + idDetalle + "][fallas_observaciones]");
                            String numRep = request.getParameter("alumnos[" + idDetalle + "][num_reporte]");

                            String sqlDetalle = "UPDATE bitacoras_estudiantes SET num_pc = ?, fallas_observaciones = ?, num_reporte = ? WHERE id_detalle = ? AND id_bitacora = ?";
                            try (PreparedStatement pst = conn.prepareStatement(sqlDetalle)) {
                                pst.setString(1, numPc);
                                pst.setString(2, fallasObs);
                                pst.setString(3, numRep);
                                pst.setInt(4, idDetalle);
                                pst.setInt(5, idBitacora);
                                pst.executeUpdate();
                            }
                        }
                    } catch (Exception ignored) {}
                }
            }

            // 4. Actualizar o insertar datos en bitacoras_tecnicos
            boolean existeTec = false;
            try (PreparedStatement pst = conn.prepareStatement("SELECT id_tecnico FROM bitacoras_tecnicos WHERE id_bitacora = ?")) {
                pst.setInt(1, idBitacora);
                try (ResultSet rs = pst.executeQuery()) {
                    if (rs.next()) {
                        existeTec = true;
                    }
                }
            }

            if (existeTec) {
                String sqlTecUp = "UPDATE bitacoras_tecnicos SET hora_entrada = ?, hora_salida = ?, uso_internet = ?, observaciones_tecnico = ?, nombre_tecnico = ?, firma_tecnico = ? WHERE id_bitacora = ?";
                try (PreparedStatement pst = conn.prepareStatement(sqlTecUp)) {
                    pst.setString(1, horaEntrada);
                    pst.setString(2, horaSalida);
                    pst.setString(3, usoInternet);
                    pst.setString(4, obsTecnico);
                    pst.setString(5, nombreTecnico);
                    pst.setString(6, firmaTecnico);
                    pst.setInt(7, idBitacora);
                    pst.executeUpdate();
                }
            } else {
                String sqlTecIns = "INSERT INTO bitacoras_tecnicos (id_bitacora, hora_entrada, hora_salida, uso_internet, observaciones_tecnico, nombre_tecnico, firma_tecnico) VALUES (?, ?, ?, ?, ?, ?, ?)";
                try (PreparedStatement pst = conn.prepareStatement(sqlTecIns)) {
                    pst.setInt(1, idBitacora);
                    pst.setString(2, horaEntrada);
                    pst.setString(3, horaSalida);
                    pst.setString(4, usoInternet);
                    pst.setString(5, obsTecnico);
                    pst.setString(6, nombreTecnico);
                    pst.setString(7, firmaTecnico);
                    pst.executeUpdate();
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        response.sendRedirect("panel-administrador.jsp");
    }
}