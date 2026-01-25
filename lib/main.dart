import 'package:brainwavers/providers/admin_provider.dart';
import 'package:brainwavers/providers/franchise_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brainwavers/providers/academic_data_provider.dart';
import 'package:brainwavers/providers/dashboard_provider.dart';
import 'package:brainwavers/providers/results_provider.dart';
import 'package:brainwavers/providers/student_provider.dart';
import 'package:brainwavers/providers/marks_provider.dart';
import 'package:brainwavers/screens/auth/login_screen.dart';
import 'package:brainwavers/screens/dashboard/dashboard_screen.dart';
import 'package:brainwavers/services/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/navigation/route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  try {
    await SupabaseService.initialize();
    print('Supabase initialized successfully');
  } catch (e) {
    print('Failed to initialize Supabase: $e');
  }
  //SupabaseService.createSuperAdmin();
  runApp(StudentManagementApp(isLoggedIn: isLoggedIn,));
}

class StudentManagementApp extends StatelessWidget {
  final bool isLoggedIn;
  const StudentManagementApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StudentProvider()),
        ChangeNotifierProvider(create: (context) => FranchiseProvider()),
        ChangeNotifierProvider(create: (context) => AdminProvider()),
        ChangeNotifierProvider(create: (context) => AcademicDataProvider()),
        ChangeNotifierProvider(create: (context) => MarksProvider()),
        ChangeNotifierProvider(create: (context) => DashboardProvider()),
        ChangeNotifierProvider(create: (context) => ResultsProvider()),
      ],

      child: MaterialApp(
        navigatorObservers: [routeObserver],
        title: 'Brainwavers',
        theme: _buildTheme(),
        debugShowCheckedModeBanner: false,
        home: isLoggedIn
            ? const DashboardScreen()
            : const LoginScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      fontFamily: 'Lexend',
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

// Temporary placeholder screen until we build LoginScreen
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management System'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'App Setup Complete!',
              style: AppTextStyles.headlineLarge(context),
            ),
            const SizedBox(height: 20),
            Text(
              'Ready to build Login Screen',
              style: AppTextStyles.bodyMedium(context),
            ),
          ],
        ),
      ),
    );
  }
}