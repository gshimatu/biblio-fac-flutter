import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'views/home.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/student/home_student_view.dart';
import 'views/admin/home_admin_view.dart';
import 'views/student/profile_details_view.dart';
import 'views/admin/profile_admin_details_view.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/loan_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
      ],
      child: MaterialApp(
        title: 'Biblio Fac',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF272662)),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginView(),
          '/register': (context) => const RegisterView(),
          '/student': (context) => const HomeStudentView(),
          '/admin': (context) => const HomeAdminView(),
          '/profile': (context) => const ProfileDetailsView(),
          '/adminProfile': (context) => const ProfileAdminDetailsView(), 
        },
      ),
    );
  }
}