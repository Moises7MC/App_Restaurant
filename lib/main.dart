import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/dependency_injection.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/meals/presentation/bloc/cart_bloc.dart';
import 'features/meals/presentation/bloc/cart_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Iniciando Restaurant App...\n');
  final di = DependencyInjection();
  await di.init();

  runApp(MyApp(di: di));
}

class MyApp extends StatelessWidget {
  final DependencyInjection di;

  const MyApp({super.key, required this.di});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.createAuthBloc()..add(CheckAuthStatus()),
        ),
        BlocProvider(create: (context) => CartBloc()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            debugPrint('✅ Usuario autenticado: ${state.user.name}');
            AppRouter.router.go(AppRouter.meals);
            context.read<CartBloc>().add(const ClearCart());
          } else if (state is AuthUnauthenticated) {
            debugPrint('⚠️  Usuario no autenticado');
            AppRouter.router.go(AppRouter.login);
            context.read<CartBloc>().add(const ClearCart());
          } else if (state is AuthError) {
            debugPrint('❌ Error de autenticación: ${state.message}');
          }
        },
        child: MaterialApp.router(
          title: 'Restaurant App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
