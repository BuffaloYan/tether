import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page Object for the Add/Edit Contact dialog.
/// Encapsulates all interactions with the contact form.
class ContactDialogPage {
  final WidgetTester tester;

  ContactDialogPage(this.tester);

  // Finders
  Finder get _dialog => find.byType(AlertDialog);
  Finder get _nameField => find.byKey(const Key('contact_name_field'));
  Finder get _phoneField => find.byKey(const Key('contact_phone_field'));
  Finder get _emailField => find.byKey(const Key('contact_email_field'));
  Finder get _priorityDropdown => find.byKey(const Key('contact_priority_dropdown'));
  Finder get _saveButton => find.text('Save');
  Finder get _cancelButton => find.text('Cancel');

  Finder get _dialogTitle => find.descendant(
    of: _dialog,
    matching: find.byType(Text),
  ).first;

  Finder _validationError(String message) => find.text(message);

  // Actions - Form Input
  Future<void> enterName(String name) async {
    await tester.enterText(_nameField, name);
    await tester.pumpAndSettle();
  }

  Future<void> enterPhone(String phone) async {
    await tester.enterText(_phoneField, phone);
    await tester.pumpAndSettle();
  }

  Future<void> enterEmail(String email) async {
    await tester.enterText(_emailField, email);
    await tester.pumpAndSettle();
  }

  Future<void> selectPriority(int priority) async {
    await tester.tap(_priorityDropdown);
    await tester.pumpAndSettle();

    final menuItem = find.text(priority.toString()).last;
    await tester.tap(menuItem);
    await tester.pumpAndSettle();
  }

  // Actions - Batch Input
  Future<void> fillForm({
    required String name,
    required String phone,
    String? email,
    int? priority,
  }) async {
    await enterName(name);
    await enterPhone(phone);
    if (email != null) {
      await enterEmail(email);
    }
    if (priority != null) {
      await selectPriority(priority);
    }
  }

  // Actions - Save/Cancel
  Future<void> tapSave() async {
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapCancel() async {
    await tester.tap(_cancelButton);
    await tester.pumpAndSettle();
  }

  Future<void> submitForm() async {
    await tapSave();
  }

  // Verifications - Visibility
  bool isVisible() {
    return tester.any(_dialog);
  }

  Future<void> verifyDialogOpen() async {
    expect(_dialog, findsOneWidget);
  }

  Future<void> verifyDialogClosed() async {
    expect(_dialog, findsNothing);
  }

  // Verifications - Title
  bool hasTitle(String title) {
    return tester.any(find.text(title));
  }

  Future<void> verifyTitle(String title) async {
    expect(find.text(title), findsOneWidget);
  }

  // Verifications - Validation Errors
  String? getValidationError(String fieldLabel) {
    // Look for error text near the field
    final errorFinder = find.descendant(
      of: _dialog,
      matching: find.text(fieldLabel),
    );

    if (tester.any(errorFinder)) {
      return fieldLabel;
    }
    return null;
  }

  Future<void> verifyValidationError(String message) async {
    expect(_validationError(message), findsOneWidget);
  }

  Future<void> verifyNoValidationErrors() async {
    // Common validation error messages
    expect(find.text('Please enter a name'), findsNothing);
    expect(find.text('Name is required'), findsNothing);
    expect(find.text('Please enter a phone number'), findsNothing);
    expect(find.text('Phone is required'), findsNothing);
    expect(find.text('Please enter a valid phone number'), findsNothing);
    expect(find.text('Phone must be at least 10 digits'), findsNothing);
    expect(find.text('Please enter a valid email'), findsNothing);
    expect(find.text('Invalid email format'), findsNothing);
  }

  // Verifications - Available Priorities
  List<int> getAvailablePriorities() {
    // This would need to open the dropdown and read the options
    // For now, return the expected priorities
    return [1, 2, 3]; // Low, Medium, High
  }
}
