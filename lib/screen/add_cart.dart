import 'dart:convert';
import 'dart:math' as math;
import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/widgets/header_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  final _cvvFocus = FocusNode();

  late AnimationController _cardFlipController;
  late Animation<double> _cardFlipAnimation;

  bool _isCardFlipped = false;
  bool _isLoading = false;
  bool _userIdLoaded = false;
  bool _cardSaved = false; // Controla qué vista mostrar
  String _cardType = '';
  String? _userId;
  
  Map<String, dynamic>? _savedCardData;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
    _obtenerUserId();
  }

  void _setupAnimations() {
    _cardFlipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardFlipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardFlipController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupListeners() {
    _cardNumberController.addListener(() {
      setState(() {
        _cardType = _getCardType(_cardNumberController.text);
      });
    });

    _cvvFocus.addListener(() {
      if (_cvvFocus.hasFocus && !_isCardFlipped) {
        _flipCard();
      } else if (!_cvvFocus.hasFocus && _isCardFlipped) {
        _flipCard();
      }
    });
  }

  Future<void> _obtenerUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null || userId.isEmpty) {
        _mostrarError('Error: Usuario no identificado. Por favor, inicia sesión nuevamente.');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      
      setState(() {
        _userId = userId;
        _userIdLoaded = true;
      });
      
      await _cargarTarjetaExistente();
      
    } catch (e) {
      _mostrarError('Error obteniendo datos del usuario: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _cargarTarjetaExistente() async {
    try {
      final idTarjetaExistente = await _verificarTarjetaExistente();
      if (idTarjetaExistente != null && idTarjetaExistente.isNotEmpty) {
        final tarjetaDoc = await FirebaseFirestore.instance
            .collection('tarjetas')
            .doc(idTarjetaExistente)
            .get();
            
        if (tarjetaDoc.exists) {
          setState(() {
            _savedCardData = tarjetaDoc.data();
            _cardSaved = true; // Mostrar vista de tarjeta guardada
          });
        }
      }
    } catch (e) {
      print('Error cargando tarjeta existente: $e');
    }
  }

  void _flipCard() {
    setState(() {
      _isCardFlipped = !_isCardFlipped;
    });
    if (_isCardFlipped) {
      _cardFlipController.forward();
    } else {
      _cardFlipController.reverse();
    }
  }

  String _getCardType(String number) {
    if (number.startsWith('4')) return 'visa';
    if (number.startsWith('5')) return 'mastercard';
    if (number.startsWith('3')) return 'amex';
    return 'unknown';
  }

  String _encriptarDato(String dato) {
    return sha256.convert(utf8.encode(dato)).toString();
  }

  Future<String?> _verificarTarjetaExistente() async {
    if (_userId == null || _userId!.isEmpty) {
      throw Exception('ID de usuario no válido');
    }

    try {
      final usuarios = FirebaseFirestore.instance.collection('usuarios');
      final usuarioDoc = await usuarios.doc(_userId).get();
      
      if (usuarioDoc.exists) {
        final userData = usuarioDoc.data();
        return userData?['id_tarjeta'];
      }
      return null;
    } catch (e) {
      throw Exception('Error verificando tarjeta existente: $e');
    }
  }

  String _generarIdTarjeta() {
    if (_userId == null || _userId!.isEmpty) {
      throw Exception('No se puede generar ID de tarjeta sin userId válido');
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(9999).toString().padLeft(4, '0');
    return 'card_${_userId}_${timestamp}_$random';
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_userIdLoaded || _userId == null || _userId!.isEmpty) {
      _mostrarError('Error: Usuario no identificado. Reinicia la aplicación.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final numeroTarjeta = _cardNumberController.text.replaceAll(' ', '');
      final nombreTitular = _cardHolderController.text.trim();
      final fechaVencimiento = _expiryController.text.trim();
      final cvv = _cvvController.text.trim();

      final idTarjetaExistente = await _verificarTarjetaExistente();
      
      final tarjetas = FirebaseFirestore.instance.collection('tarjetas');
      final usuarios = FirebaseFirestore.instance.collection('usuarios');
      
      String idTarjeta;
      Map<String, dynamic> tarjetaData;

      if (idTarjetaExistente != null && idTarjetaExistente.isNotEmpty) {
        // Actualizar tarjeta existente
        idTarjeta = idTarjetaExistente;
        
        tarjetaData = {
          'id_tarjeta': idTarjeta,
          'id_usuario': _userId,
          'numeroTarjeta': _encriptarDato(numeroTarjeta),
          'nombreTitular': nombreTitular,
          'fechaVencimiento': fechaVencimiento,
          'cvv': _encriptarDato(cvv),
          'tipoTarjeta': _cardType,
          'ultimosCuatroDigitos': numeroTarjeta.substring(numeroTarjeta.length - 4),
          'fechaActualizacion': FieldValue.serverTimestamp(),
          'activa': true,
        };

        await tarjetas.doc(idTarjeta).update(tarjetaData);
        _mostrarExito('Tarjeta actualizada exitosamente');
        
      } else {
        // Crear nueva tarjeta
        idTarjeta = _generarIdTarjeta();
        
        tarjetaData = {
          'id_tarjeta': idTarjeta,
          'id_usuario': _userId,
          'numeroTarjeta': _encriptarDato(numeroTarjeta),
          'nombreTitular': nombreTitular,
          'fechaVencimiento': fechaVencimiento,
          'cvv': _encriptarDato(cvv),
          'tipoTarjeta': _cardType,
          'ultimosCuatroDigitos': numeroTarjeta.substring(numeroTarjeta.length - 4),
          'fechaCreacion': FieldValue.serverTimestamp(),
          'activa': true,
        };

        await tarjetas.doc(idTarjeta).set(tarjetaData);
        
        await usuarios.doc(_userId).update({
          'id_tarjeta': idTarjeta,
        });
        
        _mostrarExito('Tarjeta guardada exitosamente');
      }

      // Cambiar a vista de tarjeta guardada
      setState(() {
        _savedCardData = {
          ...tarjetaData,
          'fechaCreacion': DateTime.now(),
        };
        _cardSaved = true; // ← AQUÍ cambia la vista
      });

      _limpiarFormulario();

    } catch (e) {
      _mostrarError('Error guardando tarjeta: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _limpiarFormulario() {
    _cardNumberController.clear();
    _cardHolderController.clear();
    _expiryController.clear();
    _cvvController.clear();
    setState(() {
      _cardType = '';
      if (_isCardFlipped) {
        _flipCard();
      }
    });
  }

  void _editarTarjeta() {
    if (_savedCardData != null) {
      _cardHolderController.text = _savedCardData!['nombreTitular'] ?? '';
      _expiryController.text = _savedCardData!['fechaVencimiento'] ?? '';
      
      setState(() {
        _cardType = _savedCardData!['tipoTarjeta'] ?? '';
        _cardSaved = false; // ← AQUÍ cambia la vista
      });
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _cardFlipController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_userIdLoaded) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: const HeaderPage(showBackButton: true),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const HeaderPage(showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          // ↓ AQUÍ está la magia - UN archivo, DOS vistas ↓
          child: _cardSaved ? _buildSavedCardView() : _buildFormView(),
        ),
      ),
    );
  }

  // VISTA 1: Tarjeta guardada
  Widget _buildSavedCardView() {
    return Column(
      children: [
        _buildHeader(saved: true),
        const SizedBox(height: 32),
        _buildSavedCreditCard(),
        const SizedBox(height: 32),
        _buildCardInfo(),
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }

  // VISTA 2: Formulario
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildCreditCard(),
          const SizedBox(height: 32),
          _buildFormCard(),
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader({bool saved = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: saved ? Colors.green : AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            saved ? Icons.check_circle : Icons.credit_card,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          saved ? 'Tarjeta Guardada' : 'Agregar Tarjeta',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          saved 
            ? 'Tu método de pago está configurado correctamente'
            : 'Agrega tu método de pago de forma segura',
          style: TextStyle(
            color: AppColors.primaryMedium,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCreditCard() {
    if (_savedCardData == null) return const SizedBox();

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CAFETERÍA USM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                _buildSavedCardTypeIcon(),
              ],
            ),
            const Spacer(),
            Text(
              '**** **** **** ${_savedCardData!['ultimosCuatroDigitos']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TITULAR',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (_savedCardData!['nombreTitular'] ?? '').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VENCE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _savedCardData!['fechaVencimiento'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCardTypeIcon() {
    final tipo = _savedCardData?['tipoTarjeta'] ?? '';
    switch (tipo) {
      case 'visa':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'VISA',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'mastercard':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'MC',
            style: TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return const Icon(
          Icons.credit_card,
          color: Colors.white,
          size: 20,
        );
    }
  }

  Widget _buildCardInfo() {
    if (_savedCardData == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Información de la Tarjeta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Titular', _savedCardData!['nombreTitular'] ?? ''),
            _buildInfoRow('Tipo', _getTipoTarjetaTexto(_savedCardData!['tipoTarjeta'] ?? '')),
            _buildInfoRow('Últimos 4 dígitos', '**** ${_savedCardData!['ultimosCuatroDigitos']}'),
            _buildInfoRow('Vencimiento', _savedCardData!['fechaVencimiento'] ?? ''),
            _buildInfoRow('Estado', 'Activa', isStatus: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.primaryMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getTipoTarjetaTexto(String tipo) {
    switch (tipo) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'American Express';
      default:
        return 'Desconocido';
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _editarTarjeta,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'Editar Tarjeta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCard() {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _cardFlipAnimation,
        builder: (context, child) {
          final isShowingFront = _cardFlipAnimation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_cardFlipAnimation.value * math.pi),
            child: isShowingFront ? _buildCardFront() : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CAFETERÍA USM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                _buildCardTypeIcon(),
              ],
            ),
            const Spacer(),
            Text(
              _formatCardNumber(_cardNumberController.text),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TITULAR',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cardHolderController.text.isEmpty
                          ? 'NOMBRE APELLIDO'
                          : _cardHolderController.text.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VENCE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _expiryController.text.isEmpty
                          ? 'MM/AA'
                          : _expiryController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 32,
              color: Colors.black,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _cvvController.text.isEmpty ? 'CVV' : _cvvController.text,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeIcon() {
    switch (_cardType) {
      case 'visa':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'VISA',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'mastercard':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'MC',
            style: TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return const Icon(
          Icons.credit_card,
          color: Colors.white,
          size: 20,
        );
    }
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos de la Tarjeta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _cardNumberController,
              label: 'Número de tarjeta',
              hint: '1234 5678 9012 3456',
              icon: Icons.credit_card,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el número de tarjeta';
                }
                if (value.replaceAll(' ', '').length < 16) {
                  return 'Número de tarjeta inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cardHolderController,
              label: 'Nombre del titular',
              hint: 'Juan Pérez',
              icon: Icons.person,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el nombre del titular';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    label: 'Fecha de vencimiento',
                    hint: 'MM/AA',
                    icon: Icons.calendar_today,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa la fecha';
                      }
                      if (value.length < 5) {
                        return 'Fecha inválida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    focusNode: _cvvFocus,
                    label: 'CVV',
                    hint: '123',
                    icon: Icons.lock,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CVV requerido';
                      }
                      if (value.length < 3) {
                        return 'CVV inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      validator: validator,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
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
        labelStyle: TextStyle(color: AppColors.primaryMedium),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Guardar Tarjeta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _formatCardNumber(String number) {
    String digits = number.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digits[i];
    }
    return formatted.padRight(19, '•');
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
