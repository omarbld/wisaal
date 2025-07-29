import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'auth_screen.dart';
import 'donor/donor_home.dart';
import 'association/association_home.dart';
import 'volunteer/volunteer_home.dart';
import 'manager/manager_home.dart';
import 'core/theme.dart';
import 'core/config/app_config.dart';
import 'core/exceptions/error_handler.dart';
import 'register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration
  await AppConfig.initialize();

  // Initialize Supabase
  await SupabaseConfig.init();

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorHandler.logError(
      ErrorHandler.handleError(details.exception),
      stackTrace: details.stack,
    );
  };

  runApp(const WisaalApp());
}

class WisaalApp extends StatefulWidget {
  const WisaalApp({super.key});

  @override
  State<WisaalApp> createState() => _WisaalAppState();

  static _WisaalAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_WisaalAppState>()!;
}

class _WisaalAppState extends State<WisaalApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'وصال',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/register': (context) => const NewRegisterScreen(),
        '/donor': (context) => const DonorHome(),
        '/association': (context) => const AssociationHome(),
        '/volunteer': (context) => const VolunteerHome(),
        '/manager': (context) => const ManagerHomeScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    final session = Supabase.instance.client.auth.currentSession;
    if (!mounted) return;

    if (session != null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final userRole = (await Supabase.instance.client
              .from('users')
              .select('role')
              .eq('id', user.id)
              .single())['role'];

          switch (userRole) {
            case 'manager':
              Navigator.of(context).pushReplacementNamed('/manager');
              break;
            case 'donor':
              Navigator.of(context).pushReplacementNamed('/donor');
              break;
            case 'association':
              Navigator.of(context).pushReplacementNamed('/association');
              break;
            case 'volunteer':
              Navigator.of(context).pushReplacementNamed('/volunteer');
              break;
            default:
              Navigator.of(context).pushReplacementNamed('/auth');
          }
        } catch (e) {
          // Handle error, e.g., user not in 'users' table yet
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 120),
            const SizedBox(height: 24),
            Text(
              'وصال',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'نصل الخير، ونحفظ النعمة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
