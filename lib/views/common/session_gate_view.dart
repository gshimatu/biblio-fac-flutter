import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../admin/home_admin_view.dart';
import '../home.dart';
import '../student/home_student_view.dart';

class SessionGateView extends StatefulWidget {
  const SessionGateView({super.key});

  @override
  State<SessionGateView> createState() => _SessionGateViewState();
}

class _SessionGateViewState extends State<SessionGateView> {
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _bootstrapFuture = Future.microtask(() {
      return authProvider.restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final authProvider = Provider.of<AuthProvider>(context);
        if (!authProvider.isInitialized || authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authProvider.currentUser;
        if (user == null) return const HomePage();
        return user.role == UserRole.admin
            ? const HomeAdminView()
            : const HomeStudentView();
      },
    );
  }
}
