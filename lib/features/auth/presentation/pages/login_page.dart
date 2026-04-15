import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';

/// Pantalla de Login
///
/// Permite al usuario autenticarse con email y contraseña.
/// Usa BLoC para manejar el estado de autenticación.
///
/// Características:
/// - Validación de formulario
/// - Mostrar/ocultar contraseña
/// - Loading state
/// - Manejo de errores
/// - Diseño basado en las capturas proporcionadas
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Key para el formulario (permite validar)
  final _formKey = GlobalKey<FormState>();

  /// Controllers para los campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Controla si la contraseña es visible
  bool _obscurePassword = true;

  @override
  void dispose() {
    // IMPORTANTE: Siempre limpiar los controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Maneja el evento de login
  void _handleLogin() {
    // Validar el formulario
    if (_formKey.currentState!.validate()) {
      // Enviar evento al BLoC
      context.read<AuthBloc>().add(
        LoginButtonPressed(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BlocConsumer: Escucha estados Y ejecuta acciones
      body: BlocConsumer<AuthBloc, AuthState>(
        // LISTENER: Ejecuta acciones (no reconstruye UI)
        listener: (context, state) {
          // Si hay error, mostrar SnackBar
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },

        // BUILDER: Construye la UI según el estado
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),

                      // ════════════════════════════════════
                      // LOGO
                      // ════════════════════════════════════
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 60,
                            color: AppColors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ════════════════════════════════════
                      // TÍTULO
                      // ════════════════════════════════════
                      Text(
                        'Bienvenido',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Inicia sesión para continuar',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // ════════════════════════════════════
                      // CAMPO DE EMAIL
                      // ════════════════════════════════════
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'ejemplo@correo.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          if (!value.contains('@')) {
                            return 'Ingresa un email válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // ════════════════════════════════════
                      // CAMPO DE CONTRASEÑA
                      // ════════════════════════════════════
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // ════════════════════════════════════
                      // ¿OLVIDASTE TU CONTRASEÑA?
                      // ════════════════════════════════════
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implementar recuperación de contraseña
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función en desarrollo'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ════════════════════════════════════
                      // BOTÓN DE LOGIN
                      // ════════════════════════════════════
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state is AuthLoading ? null : _handleLogin,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : const Text('Iniciar Sesión'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ════════════════════════════════════
                      // INFORMACIÓN DE USUARIOS DE PRUEBA
                      // ════════════════════════════════════
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Usuarios de prueba',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTestUserInfo(
                              'Admin',
                              'admin@restaurant.com',
                              '123456',
                            ),
                            const SizedBox(height: 8),
                            _buildTestUserInfo(
                              'Usuario',
                              'user@test.com',
                              '123456',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget helper para mostrar info de usuarios de prueba
  Widget _buildTestUserInfo(String role, String email, String password) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text('Email: $email', style: Theme.of(context).textTheme.bodySmall),
        Text(
          'Contraseña: $password',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
