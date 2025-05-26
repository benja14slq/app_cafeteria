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

class _RegistroScreenState extends State<RegistroScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
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
        'tipo': 'Estudiante',
      });

      _showSuccess('Usuario registrado exitosamente');

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarSelectorCarrera() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.7,
            initialChildSize: 0.5,
            builder: (_, controller) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Selecciona tu carrera',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: _carreras.length,
                      itemBuilder: (context, index) {
                        final carrera = _carreras[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: _carreraSeleccionada == carrera
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: ListTile(
                            title: Text(
                              carrera,
                              style: TextStyle(
                                color: _carreraSeleccionada == carrera
                                    ? AppColors.primary
                                    : Colors.black87,
                                fontWeight: _carreraSeleccionada == carrera
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: _carreraSeleccionada == carrera
                                ? Icon(Icons.check, color: AppColors.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _carreraSeleccionada = carrera;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryDark,
                            AppColors.primary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildWelcomeCard(),
                          const SizedBox(height: 24),
                          _buildFormCard(),
                          const SizedBox(height: 24),
                          _buildRegisterButton(),
                          const SizedBox(height: 16),
                          _buildLoginLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_add_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              '¡Únete a nosotros!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu cuenta para acceder a todos los servicios de la cafetería',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _nombreController,
                    'Nombre',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _apellidosController,
                    'Apellidos',
                    icon: Icons.person_outline,
                  ),
                ),
              ],
            ),
            _buildDropdownCarrera(),
            _buildTextField(
              _correoController,
              'Correo electrónico',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validarCorreo,
            ),
            _buildTextField(
              _contrasenaController,
              'Contraseña',
              icon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              validator: _validarContrasena,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
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
              icon: Icons.lock_outline,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
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
          prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
          labelStyle: TextStyle(color: AppColors.primaryDark),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _carreraSeleccionada ?? 'Selecciona tu carrera',
                  style: TextStyle(
                    color: _carreraSeleccionada == null
                        ? Colors.grey.shade600
                        : AppColors.primaryDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registrarUsuario,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Crear Cuenta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Inicia Sesión',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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