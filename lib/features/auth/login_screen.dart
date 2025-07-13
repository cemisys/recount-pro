import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_button.dart';
import '../../services/auth_service.dart';
import '../../core/services/validation_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    // Listener para actualizar las credenciales en tiempo real
    _cedulaController.addListener(() {
      if (_isRegistering && mounted) {
        setState(() {
          // Trigger rebuild para mostrar credenciales actualizadas
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cedulaController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Sanitizar inputs
      final email = ValidationService.sanitizeText(_emailController.text);
      final password = _passwordController.text; // No sanitizar contraseña

      final success = await authService.signInWithEmailAndPassword(email, password);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de autenticación: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _handleLogin,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Sanitizar inputs
      final cedula = ValidationService.sanitizeText(_cedulaController.text);
      final nombre = ValidationService.sanitizeText(_nombreController.text);

      // Crear email usando la cédula
      final email = '$cedula@recount.com';
      // Crear contraseña usando la cédula + 123
      final password = '${cedula}123';

      final success = await authService.createUserWithEmailAndPassword(
        email,
        password,
        nombre
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (success && mounted) {
        // Mostrar diálogo con credenciales generadas
        await _showCredentialsDialog(context, email, password, nombre);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de registro: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _handleRegister,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showCredentialsDialog(BuildContext context, String email, String password, String nombre) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Usuario debe hacer clic en OK
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '¡Registro Exitoso!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido $nombre!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Tus credenciales de acceso son:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),

                // Email
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Contraseña
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outlined, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contraseña:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              password,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nota importante
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_outlined, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '¡IMPORTANTE! Guarda estas credenciales en un lugar seguro. Las necesitarás para iniciar sesión en el futuro.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            GradientButton(
              text: 'Entendido',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'CD-3M',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Título
                        const Text(
                          'ReCount Pro',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegistering
                              ? 'Registro por Primera Vez'
                              : 'Verificador - Segundo Conteo',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Información adicional para registro
                        if (_isRegistering) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[50]!, Colors.indigo[50]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[300]!, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Credenciales que se generarán:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Email generado
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.email_outlined, color: Colors.grey[600], size: 18),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Email:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _cedulaController.text.isNotEmpty
                                                ? '${_cedulaController.text}@recount.com'
                                                : '{cédula}@recount.com',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Contraseña generada
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_outlined, color: Colors.grey[600], size: 18),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Contraseña:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _cedulaController.text.isNotEmpty
                                                ? '${_cedulaController.text}123'
                                                : '{cédula}123',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Nota importante
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '¡Guarda estas credenciales! Las necesitarás para iniciar sesión.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.amber[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 16),

                        // Campos dinámicos según el modo
                        if (_isRegistering) ...[
                          // Campo de cédula
                          TextFormField(
                            controller: _cedulaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Número de Cédula',
                              prefixIcon: Icon(Icons.badge_outlined),
                              helperText: 'Ingresa tu número de cédula',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La cédula es requerida';
                              }
                              if (value.trim().length < 6) {
                                return 'La cédula debe tener al menos 6 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo de nombre
                          TextFormField(
                            controller: _nombreController,
                            keyboardType: TextInputType.name,
                            decoration: const InputDecoration(
                              labelText: 'Nombre Completo',
                              prefixIcon: Icon(Icons.person_outlined),
                              helperText: 'Ingresa tu nombre completo',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es requerido';
                              }
                              if (value.trim().length < 3) {
                                return 'El nombre debe tener al menos 3 caracteres';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          // Campo de email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final result = ValidationService.validateEmail(value);
                              return result.isValid ? null : result.errorMessage;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo de contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  }
                                },
                              ),
                            ),
                            validator: (value) {
                              final result = ValidationService.validatePassword(value);
                              return result.isValid ? null : result.errorMessage;
                            },
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Botón principal con degradado
                        GradientButton.fullWidth(
                          text: _isRegistering ? 'Registrarse' : 'Iniciar Sesión',
                          onPressed: _isLoading
                              ? null
                              : (_isRegistering ? _handleRegister : _handleLogin),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Botón para alternar entre login y registro
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            if (mounted) {
                              setState(() {
                                _isRegistering = !_isRegistering;
                                // Limpiar campos al cambiar de modo
                                _emailController.clear();
                                _passwordController.clear();
                                _cedulaController.clear();
                                _nombreController.clear();
                              });
                            }
                          },
                          child: Text(
                            _isRegistering
                                ? '¿Ya tienes cuenta? Iniciar Sesión'
                                : '¿Primera vez? Registrarse',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Pie de página
                        Text(
                          'ReCount Pro by 3M Technology®',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}