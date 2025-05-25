import 'dart:convert';
import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/screen/home.dart';
import 'package:app_cafeteria/screen/registro_screen.dart';
import 'package:app_cafeteria/screen_tienda/login_admin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Controladores de Texto para capturar correo y contraseña
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estado para mostrar u ocultar contraseña
  bool _isPasswordVisible = false;

  // Estado para recordar al usuario 
  final bool _rememberMe = false;

  @override
  void dispose() {
    // Liberar los controladores cuando no se necesiten más
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para iniciar sesión cuando se presiona el boton
  Future<void> _iniciarSesion() async {
    // Obtener los valores y la contraseña ingresada
    final correo = _emailController.text.trim();
    final contrasena = _passwordController.text.trim();

    // Verificar que ambos campos no están vacios
    if (correo.isEmpty || contrasena.isEmpty) {
      _mostrarError('Todos los campos son obligatorios');
      return;
    }

    try {
      // Llamar a colección 'Usuarios' en Firestore
      final usuarios = FirebaseFirestore.instance.collection('usuarios');
      // Buscar en 'Usuarios' el campo 'correo' sea igual al que se ingreso
      final consulta = await usuarios.where('correo', isEqualTo: correo).get();

      // Si no se encuentra ningun usuario, mostrar error
      if (consulta.docs.isEmpty) {
        _mostrarError('Usuario no encontrado');
        return;
      }

      // Se obtiene datos del usuario encontrado
      final usuario = consulta.docs.first.data();
      // Hashear contraseña ingresada, mayor seguridad
      final contrasenaHash = sha256.convert(utf8.encode(contrasena)).toString();

    // Comparar la contraseña ingresada con la almacenada en la base de datos.
      if (usuario['contraseña'] != contrasenaHash) {
        _mostrarError('Contraseña incorrecta');
        return;
      }

    // Guardar el correo para mantener la sesión iniciada
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('correo', correo);

    // Obtener el tipo de usuario para redireccionar si es estudiante
      final tipo = usuario['tipo'];

    // Redirigir al HomePage si es de tipo Estudiante
      if (tipo == 'Estudiante') {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        _mostrarError('Solo ingresan estudiantes');
      }
    } catch (e) {
      // Capturar errores inesperados y mostrarlos
      _mostrarError('Error: $e');
    }
  }

  // Función auxiliar para mostrar mensajes de error en un SnackBar
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo o imagen
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Título
                  Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Campo de correo electrónico
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryLight.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Correo electrónico',
                        prefixIcon: Icon(
                          Icons.email,
                          color: AppColors.secondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo de contraseña
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryLight.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        prefixIcon: Icon(
                          Icons.lock,
                          color: AppColors.secondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.secondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botón de inicio de sesión
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _iniciarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: AppColors.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'INICIAR SESIÓN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Texto para registrarse
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes una cuenta?',
                        style: TextStyle(
                          color: AppColors.primaryMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistroScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Regístrate',
                          style: TextStyle(
                            color: AppColors.accent1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Eres Administrador?',
                        style: TextStyle(
                          color: AppColors.primaryMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginAdmin(),
                            ),
                          );
                        },
                        child: Text(
                          'Ingresa Aquí',
                          style: TextStyle(
                            color: AppColors.accent1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
