import 'dart:convert';
import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/screen/home.dart';
import 'package:app_cafeteria/screen/registro_screen.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verificarSesionExistente();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Verificar si ya hay una sesión activa
  Future<void> _verificarSesionExistente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sesionActiva = prefs.getBool('loggedIn') ?? false;
      
      if (sesionActiva && mounted) {
        // Si hay sesión activa, ir directamente al home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage())
        );
      }
    } catch (e) {
      print('Error verificando sesión: $e');
    }
  }

  Future<void> _iniciarSesion() async {
    final correo = _emailController.text.trim();
    final contrasena = _passwordController.text.trim();

    if (correo.isEmpty || contrasena.isEmpty) {
      _mostrarError('Todos los campos son obligatorios');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usuarios = FirebaseFirestore.instance.collection('usuarios');
      final consulta = await usuarios.where('correo', isEqualTo: correo).get();

      if (consulta.docs.isEmpty) {
        if (mounted) _mostrarError('Usuario no encontrado');
        return;
      }

      final usuario = consulta.docs.first.data();
      final contrasenaHash = sha256.convert(utf8.encode(contrasena)).toString();

      if (usuario['contraseña'] != contrasenaHash) {
        if (mounted) _mostrarError('Contraseña incorrecta');
        return;
      }

      // Guardar datos de sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('correo', correo);
      await prefs.setBool('loggedIn', true);
      
      // También puedes guardar otros datos del usuario si los necesitas
      await prefs.setString('nombre', usuario['nombre'] ?? '');
      await prefs.setString('userId', consulta.docs.first.id);

      // Inicio de sesión exitoso
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage())
        );
      }
    } catch (e) {
      if (mounted) _mostrarError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
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
                      enabled: !_isLoading,
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
                      enabled: !_isLoading,
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
                          onPressed: _isLoading ? null : () {
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
                      onPressed: _isLoading ? null : _iniciarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: AppColors.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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
                        onPressed: _isLoading ? null : () {
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

