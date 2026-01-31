import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page Object for Login screen
/// Provides methods to interact with login UI elements
class LoginPage {
  final WidgetTester tester;

  LoginPage(this.tester);

  /// Find email input field
  Finder get emailField => find.byKey(const Key('email_field'));

  /// Find password input field
  Finder get passwordField => find.byKey(const Key('password_field'));

  /// Find login button
  Finder get loginButton => find.byKey(const Key('login_button'));

  /// Find error message
  Finder get errorMessage => find.byKey(const Key('login_error'));

  /// Perform login with email and password
  Future<void> login(String email, String password) async {
    // Enter email
    await tester.enterText(emailField, email);
    await tester.pumpAndSettle();

    // Enter password
    await tester.enterText(passwordField, password);
    await tester.pumpAndSettle();

    // Tap login button
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  /// Check if error message is visible
  bool isErrorVisible() {
    return tester.any(errorMessage);
  }

  /// Get error message text
  String? getErrorText() {
    if (!isErrorVisible()) return null;
    final widget = tester.widget<Text>(errorMessage);
    return widget.data;
  }

  /// Check if login button is enabled
  bool isLoginButtonEnabled() {
    final button = tester.widget<ElevatedButton>(loginButton);
    return button.onPressed != null;
  }
}
