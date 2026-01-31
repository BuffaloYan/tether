import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page Object for the Add/Edit Contact dialog.
/// Encapsulates all interactions with the contact form.
class ContactDialogPage {
  final WidgetTester tester;

  ContactDialogPage(this.tester);

  // Finders
  Finder get dialog => find.byType(AlertDialog);
  Finder get nameField => find.byKey(const Key('contact_name_field'));
  Finder get phoneField => find.byKey(const Key('contact_phone_field'));
  Finder get emailField => find.byKey(const Key('contact_email_field'));
  Finder get priorityField => find.byKey(const Key('contact_priority_field'));
  Finder get saveButton => find.text('Save');
  Finder get cancelButton => find.text('Cancel');

  Finder get dialogTitle => find.descendant(
    of: dialog,
    matching: find.byType(Text),
  ).first;

  Finder validationError(String message) => find.text(message);

  // Actions
  Future<void> enterName(String name) async {
    await tester.enterText(nameField, name);
    await tester.pumpAndSettle();
  }

  Future<void> enterPhone(String phone) async {
    await tester.enterText(phoneField, phone);
    await tester.pumpAndSettle();
  }

  Future<void> enterEmail(String email) async {
    await tester.enterText(emailField, email);
    await tester.pumpAndSettle();
  }

  Future<void> selectPriority(int priority) async {
    await tester.tap(priorityField);
    await tester.pumpAndSettle();

    final menuItem = find.text(priority.toString()).last;
    await tester.tap(menuItem);
    await tester.pumpAndSettle();
  }

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

  Future<void> tapSave() async {
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapCancel() async {
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
  }

  Future<void> submitForm() async {
    await tapSave();
  }

  // Verifications
  Future<void> verifyDialogOpen() async {
    expect(dialog, findsOneWidget);
  }

  Future<void> verifyDialogClosed() async {
    expect(dialog, findsNothing);
  }

  Future<void> verifyTitle(String title) async {
    expect(find.text(title), findsOneWidget);
  }

  Future<void> verifyValidationError(String message) async {
    expect(validationError(message), findsOneWidget);
  }

  Future<void> verifyNoValidationErrors() async {
    // Common validation error messages
    expect(find.text('Please enter a name'), findsNothing);
    expect(find.text('Please enter a phone number'), findsNothing);
    expect(find.text('Please enter a valid phone number'), findsNothing);
    expect(find.text('Please enter a valid email'), findsNothing);
  }
}
