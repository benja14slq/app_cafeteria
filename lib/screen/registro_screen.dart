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
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String? _carreraSeleccionada;
  List<String> _carreras = [];

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('carrera').get();
    setState(() {
      _carreras = snapshot.docs.map((doc) => doc['carrera'].toString()).toList();
    });
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text.trim();
    final confirmar = _confirmarContrasenaController.text.trim();

    if (contrasena != confirmar) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    if (_carreraSeleccionada == null) {
      _showError('Seleccione una carrera');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuarios = FirebaseFirestore.instance.collection('usuarios');
      final existente = await usuarios.where('correo', isEqualTo: correo).get();

      if (existente.docs.isNotEmpty) {
        _showError('El correo ya está registrado');
        setState(() => _isLoading = false);
        return;
      }

      final hashedPassword = sha256.convert(utf8.encode(contrasena)).toString();

      await usuarios.add({
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'carrera': _carreraSeleccionada,
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
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryMedium,
      ),
    );
  }

  void _mostrarSelectorCarrera() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.7,
          builder: (_, controller) {
            return ListView.builder(
              controller: controller,
              itemCount: _carreras.length,
              itemBuilder: (context, index) {
                final carrera = _carreras[index];
                return ListTile(
                  title: Text(carrera),
                  onTap: () {
                    setState(() {
                      _carreraSeleccionada = carrera;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.backgroundLight,
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
                _buildDropdownCarrera(),
                _buildTextField(
                  _correoController,
                  'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                  validator: _validarCorreo,
                ),
                _buildTextField(
                  _contrasenaController,
                  'Contraseña',
                  obscureText: !_isPasswordVisible,
                  validator: _validarContrasena,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.secondary,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
                _buildTextField(
                  _confirmarContrasenaController,
                  'Confirmar Contraseña',
                  obscureText: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
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
    Widget? suffixIcon,
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
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildDropdownCarrera() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _mostrarSelectorCarrera(),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Carrera',
            labelStyle: const TextStyle(color: AppColors.primaryDark),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            _carreraSeleccionada ?? 'Seleccione una carrera',
            style: TextStyle(
              color: _carreraSeleccionada == null
                  ? Colors.grey
                  : AppColors.primaryDark,
            ),
          ),
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
    final contrasenaRegExp =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$');
    if (value == null || !contrasenaRegExp.hasMatch(value)) {
      return 'Contraseña debe tener 8+ caracteres, mayúscula, minúscula y número';
    }
    return null;
  }
}