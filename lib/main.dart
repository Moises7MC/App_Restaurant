import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/di/dependency_injection.dart';
import 'core/routes/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/meals/presentation/bloc/cart_bloc.dart';
import 'features/meals/presentation/bloc/cash_flow_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔧 Inicializando DependencyInjection...');

  final di = DependencyInjection();
  await di.init();

  print('✅ DependencyInjection inicializado correctamente');

  runApp(MyApp(di: di));
}

class MyApp extends StatelessWidget {
  final DependencyInjection di;

  const MyApp({super.key, required this.di});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.createAuthBloc()),
        BlocProvider(create: (context) => CartBloc()),
        BlocProvider(create: (context) => CashFlowBloc()),
      ],
      child: MaterialApp.router(
        title: 'App Restaurant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.background,
        ),
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              print('📍 AuthState changed: $state');

              if (state is AuthAuthenticated) {
                // ✅ NUEVO: decidir destino según el rol
                if (state.user.isCantador) {
                  print('✅ Cantador autenticado, navegando a /cantador');
                  AppRouter.router.go('/cantador');
                } else {
                  print('✅ Mozo autenticado, navegando a /meals');
                  AppRouter.router.go('/meals');
                }
              } else if (state is AuthUnauthenticated) {
                print('❌ Usuario desautenticado, navegando a /login');
                AppRouter.router.go('/login');
              }
            },
            child: child,
          );
        },
      ),
    );
  }
}
