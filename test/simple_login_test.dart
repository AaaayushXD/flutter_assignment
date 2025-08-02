import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Simple Login Page Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<MockAuthProvider>.value(
          value: mockAuthProvider,
          child: const SimpleLoginPage(),
        ),
      );
    }

    testWidgets('should display login form elements', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should show validation errors for empty fields', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Try to sign in without entering any data
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should accept valid email and password', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter valid credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Assert - No validation errors should appear
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
    });

    testWidgets('should show loading state when signing in', (
      WidgetTester tester,
    ) async {
      // Arrange
      mockAuthProvider.setLoading(true);
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when auth fails', (
      WidgetTester tester,
    ) async {
      // Arrange
      mockAuthProvider.setError('Invalid credentials');
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should have proper form structure', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}

// Simple Login Page for testing
class SimpleLoginPage extends StatefulWidget {
  const SimpleLoginPage({super.key});

  @override
  State<SimpleLoginPage> createState() => _SimpleLoginPageState();
}

class _SimpleLoginPageState extends State<SimpleLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<MockAuthProvider>(
        context,
        listen: false,
      );
      authProvider.signIn(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<MockAuthProvider>(
                    builder: (context, authProvider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _signIn,
                          child: authProvider.isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Sign In'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<MockAuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.error != null) {
                        return Text(
                          authProvider.error!,
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Mock Auth Provider for testing
class MockAuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void signIn(String email, String password) {
    setLoading(true);
    setError(null);

    // Simulate immediate response
    if (email == 'test@example.com' && password == 'password123') {
      setLoading(false);
      // Success
    } else {
      setLoading(false);
      setError('Invalid credentials');
    }
  }
}
