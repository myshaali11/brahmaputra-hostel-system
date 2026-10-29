import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'student_dashboard_screen.dart';
import 'staff_dashboard_screen.dart';
import 'manager_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'student1');
  final _passwordController = TextEditingController(text: 'password');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _quickFill(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  void _routeByRole(String role) {
    if (!mounted) return;
    if (role == 'STUDENT') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
      );
    } else if (role == 'MANAGER') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
      );
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both username and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.login(username, password);
      _routeByRole(user.role);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGoogleOAuthDialog() {
    final emailController = TextEditingController(text: 'ch23b001@smail.iitm.ac.in');
    final nameController = TextEditingController(text: 'Varun Mishra');
    bool isGoogleLoading = false;
    String? googleError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IITM Google Sign-In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('@smail.iitm.ac.in domain', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user, color: Color(0xFF1E3A8A), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'IITM Smail classification automatically detects roll numbers as Students, and admin/staff keywords as Managers and Staff.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (googleError != null) ...[
                  Text(googleError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 8),
                ],

                // Quick selector for testing
                const Text('Quick Select Smail Account:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('ch23b001 (Student)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          emailController.text = 'ch23b001@smail.iitm.ac.in';
                          nameController.text = 'Varun Mishra';
                          googleError = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('cs26e001 (Student)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          emailController.text = 'cs26e001@smail.iitm.ac.in';
                          nameController.text = 'Akhilesh K R';
                          googleError = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('admin (Manager)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          emailController.text = 'admin@smail.iitm.ac.in';
                          nameController.text = 'Admin Manager';
                          googleError = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('staff1 (Staff)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          emailController.text = 'staff1@smail.iitm.ac.in';
                          nameController.text = 'Maintenance Staff 1';
                          googleError = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'IITM Smail Email',
                    hintText: 'rollno@smail.iitm.ac.in',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isGoogleLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: isGoogleLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login, size: 16),
              label: const Text('Continue with Google'),
              onPressed: isGoogleLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      final name = nameController.text.trim();

                      if (!email.endsWith('@smail.iitm.ac.in') && !email.endsWith('@iitm.ac.in')) {
                        setDialogState(() => googleError = 'Must be an @smail.iitm.ac.in email address');
                        return;
                      }

                      setDialogState(() {
                        isGoogleLoading = true;
                        googleError = null;
                      });

                      try {
                        final user = await ApiService.googleLogin(email: email, name: name);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _routeByRole(user.role);
                      } catch (e) {
                        setDialogState(() {
                          isGoogleLoading = false;
                          googleError = e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Logo & Institution
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.apartment_rounded, size: 48, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Brahmaputra Hostel',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Indian Institute of Technology Madras',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),

                    // Error Notification Box
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Standard Username Field
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username or Roll Number',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 22),

                    // Standard Sign In Button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 18),

                    // Divider: OR
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Google OAuth on IITM Smail Button
                    OutlinedButton(
                      onPressed: _isLoading ? null : _showGoogleOAuthDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(shape: BoxShape.circle),
                            child: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Sign in with IITM Smail Google',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Quick-login chips for testing and verification
                    Text(
                      'Quick Sign-In Accounts:',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.school, size: 16),
                          label: const Text('student1'),
                          onPressed: () => _quickFill('student1', 'password'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.badge, size: 16),
                          label: const Text('ch23b001 (Student)'),
                          onPressed: () => _quickFill('ch23b001', 'password'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.handyman, size: 16),
                          label: const Text('staff1'),
                          onPressed: () => _quickFill('staff1', 'password'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.admin_panel_settings, size: 16),
                          label: const Text('admin (Manager)'),
                          onPressed: () => _quickFill('admin', 'password'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
