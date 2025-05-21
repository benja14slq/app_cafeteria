import 'dart:convert';
import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/screen/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _carreraController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text.trim();
    final confirmar = _confirmarContrasenaController.text.trim();

    if (contrasena != confirmar) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuarios = FirebaseFirestore.instance.collection('usuarios');

      final existente = await usuarios.where('correo', isEqualTo: correo).get();
      if (existente.docs.isNotEmpty) {
        _showError('El correo ya esta registrado');
        setState(() => _isLoading = false);
        return;
      }

      final hashedPassword = sha256.convert(utf8.encode(contrasena)).toString();

      await usuarios.add({
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'carrera': _carreraController.text.trim(),
        'correo': correo,
        'contraseña': hashedPassword,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado exitosamente')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Registro de Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_nombreController, 'Nombre'),
                _buildTextField(_apellidosController, 'Apellidos'),
                _buildTextField(_carreraController, 'Carrera'),
                _buildTextField(
                  _correoController,
                  'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                  validator: _validarCorreo,
                ),
                _buildTextField(
                  _contrasenaController,
                  'Contraseña',
                  obscureText: true,
                  validator: _validarContrasena,
                ),
                _buildTextField(
                  _confirmarContrasenaController,
                  'Confirmar Contraseña',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(color: AppColors.backgroundLight),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator:
            validator ?? (value) => value!.isEmpty ? 'Campo requerido' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.primaryDark),
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  String? _validarCorreo(String? value) {
    final correoRegExp = RegExp(r'^[\w\.-]+@(usm\.cl|sansano\.usm\.cl)$');
    if (value == null || !correoRegExp.hasMatch(value)) {
      return 'Correo debe ser @usm.cl o @sansano.usm.cl';
    }
    return null;
  }

  String? _validarContrasena(String? value) {
    final contrasenaRegExp = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$',
    );
    if (value == null || !contrasenaRegExp.hasMatch(value)) {
      return 'Contraseña debe tener 8+ caracteres, mayúscula, minúscula y número';
    }
    return null;
  }
}
