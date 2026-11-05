package com.example.iconolab.conexion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionBD {
    // Configuración de tu base de datos local en XAMPP
    private static final String URL = "jdbc:mysql://localhost:3306/bitacoras_datos?useSSL=false&serverTimezone=America/Mexico_City";
    private static final String USUARIO = "root";
    private static final String CONTRASENA = "";

    public static Connection conectar() {
        Connection conexion = null;
        try {
            // Cargar el driver de MySQL
            Class.forName("com.mysql.cj.jdbc.Driver");
            // Establecer la conexión
            conexion = DriverManager.getConnection(URL, USUARIO, CONTRASENA);
            System.out.println("¡Conexión exitosa a la base de datos desde Java!");
        } catch (ClassNotFoundException e) {
            System.out.println("Error: No se encontró el Driver de MySQL -> " + e.getMessage());
        } catch (SQLException e) {
            System.out.println("Error de conexión a la Base de Datos -> " + e.getMessage());
        }
        return conexion;
    }
}