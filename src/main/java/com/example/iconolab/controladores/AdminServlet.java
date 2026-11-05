package com.example.iconolab.controladores;

import com.example.iconolab.conexion.ConexionBD;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.Date;

@WebServlet(name = "AdminServlet", value = "/AdminServlet")
public class AdminServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (!validarPermisosAdmin(session)) {
            response.sendRedirect("login.jsp");
            return;
        }

        String accion = request.getParameter("accion");
        if ("respaldo".equals(accion)) {
            generarRespaldoSQL(response);
        } else {
            response.sendRedirect("panel-administrador.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (!validarPermisosAdmin(session)) {
            response.sendRedirect("login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String accion = request.getParameter("accion");

        if ("eliminar_bitacora".equals(accion)) {
            String tokenRecibido = request.getParameter("csrf_token");
            String tokenSesion = (String) session.getAttribute("csrf_panel");

            if (tokenRecibido == null || tokenSesion == null || !tokenRecibido.equals(tokenSesion)) {
                response.sendRedirect("panel-administrador.jsp?error=token");
                return;
            }

            String idStr = request.getParameter("eliminar_id");
            int idBitacora = 0;
            try {
                idBitacora = Integer.parseInt(idStr);
            } catch (NumberFormatException ignored) {}

            if (idBitacora < 1) {
                response.sendRedirect("panel-administrador.jsp?error=invalid_id");
                return;
            }

            Connection conn = null;
            try {
                conn = ConexionBD.conectar();
                conn.setAutoCommit(false);

                // Verificar si existe la bitácora
                PreparedStatement stmt = conn.prepareStatement("SELECT id_bitacora FROM bitacoras_docentes WHERE id_bitacora = ? FOR UPDATE");
                stmt.setInt(1, idBitacora);
                ResultSet rs = stmt.executeQuery();
                boolean existe = rs.next();
                rs.close();
                stmt.close();

                if (!existe) {
                    conn.rollback();
                    response.sendRedirect("panel-administrador.jsp?error=not_found");
                    return;
                }

                // Eliminar registros dependientes
                stmt = conn.prepareStatement("DELETE FROM bitacoras_estudiantes WHERE id_bitacora = ?");
                stmt.setInt(1, idBitacora);
                stmt.executeUpdate();
                stmt.close();

                stmt = conn.prepareStatement("DELETE FROM bitacoras_tecnicos WHERE id_bitacora = ?");
                stmt.setInt(1, idBitacora);
                stmt.executeUpdate();
                stmt.close();

                // Eliminar registro principal
                stmt = conn.prepareStatement("DELETE FROM bitacoras_docentes WHERE id_bitacora = ?");
                stmt.setInt(1, idBitacora);
                stmt.executeUpdate();
                stmt.close();

                conn.commit();
                response.sendRedirect("panel-administrador.jsp?resultado=eliminado");

            } catch (Exception e) {
                if (conn != null) {
                    try { conn.rollback(); } catch (SQLException ignored) {}
                }
                e.printStackTrace();
                response.sendRedirect("panel-administrador.jsp?error=db");
            } finally {
                if (conn != null) {
                    try { conn.close(); } catch (SQLException ignored) {}
                }
            }
        }
    }

    private boolean validarPermisosAdmin(HttpSession session) {
        if (session == null || session.getAttribute("rol") == null || !session.getAttribute("rol").equals("docente")) {
            return false;
        }
        Object esEncargado = session.getAttribute("es_encargado");
        return esEncargado != null && Integer.parseInt(esEncargado.toString()) == 1;
    }

    private void generarRespaldoSQL(HttpServletResponse response) throws IOException {
        response.setContentType("application/sql; charset=utf-8");
        String fechaStr = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss").format(new Date());
        response.setHeader("Content-Disposition", "attachment; filename=\"respaldo_bitacoras_datos_" + fechaStr + ".sql\"");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");

        try (Connection conn = ConexionBD.conectar();
             Statement st = conn.createStatement();
             OutputStream out = response.getOutputStream()) {

            StringBuilder sql = new StringBuilder();
            sql.append("-- Respaldo de la base de datos: bitacoras_datos\n");
            sql.append("-- Fecha: ").append(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())).append("\n");
            sql.append("SET NAMES utf8mb4;\n");
            sql.append("SET FOREIGN_KEY_CHECKS=0;\n\n");

            ResultSet rsTables = st.executeQuery("SHOW TABLES");
            while (rsTables.next()) {
                String tabla = rsTables.getString(1);
                String tablaSql = "`" + tabla.replace("`", "``") + "`";

                try (Statement stTable = conn.createStatement();
                     ResultSet rsCreate = stTable.executeQuery("SHOW CREATE TABLE " + tablaSql)) {
                    if (rsCreate.next()) {
                        sql.append("-- Estructura de ").append(tabla).append("\n");
                        sql.append("DROP TABLE IF EXISTS ").append(tablaSql).append(";\n");
                        sql.append(rsCreate.getString(2)).append(";\n\n");
                    }
                }

                try (Statement stData = conn.createStatement();
                     ResultSet rsData = stData.executeQuery("SELECT * FROM " + tablaSql)) {
                    ResultSetMetaData meta = rsData.getMetaData();
                    int columnCount = meta.getColumnCount();

                    while (rsData.next()) {
                        sql.append("INSERT INTO ").append(tablaSql).append(" VALUES (");
                        for (int i = 1; i <= columnCount; i++) {
                            Object val = rsData.getObject(i);
                            if (val == null) {
                                sql.append("NULL");
                            } else {
                                sql.append("'").append(val.toString().replace("'", "''")).append("'");
                            }
                            if (i < columnCount) {
                                sql.append(", ");
                            }
                        }
                        sql.append(");\n");
                    }
                }
                sql.append("\n");
            }
            sql.append("SET FOREIGN_KEY_CHECKS=1;\n");
            out.write(sql.toString().getBytes(StandardCharsets.UTF_8));
            out.flush();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}