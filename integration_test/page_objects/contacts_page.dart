import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page Object for the Contacts list screen.
/// Encapsulates all interactions with the contacts list UI.
class ContactsPage {
  final WidgetTester tester;

  ContactsPage(this.tester);

  // Finders
  Finder get _contactsTab => find.text('Contacts');
  Finder get _addButton => find.byType(FloatingActionButton);
  Finder get _emptyStateMessage => find.text('No emergency contacts yet');
  Finder get _contactsList => find.byType(ListView);

  // Form fields
  Finder get _nameField => find.byKey(const Key('contact_name_field'));
  Finder get _phoneField => find.byKey(const Key('contact_phone_field'));
  Finder get _emailField => find.byKey(const Key('contact_email_field'));
  Finder get _priorityDropdown => find.byKey(const Key('contact_priority_dropdown'));

  // Buttons
  Finder get _saveButton => find.text('Save');
  Finder get _cancelButton => find.text('Cancel');
  Finder get _editButton => find.byIcon(Icons.edit);
  Finder get _deleteButton => find.byIcon(Icons.delete);

  // Dialog
  Finder get _confirmDeleteButton => find.text('Delete');
  Finder get _cancelDeleteButton => find.text('Cancel');

  // Contact tile finders
  Finder _contactTile(String name) => find.ancestor(
    of: find.text(name),
    matching: find.byType(ListTile),
  );

  Finder _priorityBadge(String name) => find.descendant(
    of: _contactTile(name),
    matching: find.byType(Chip),
  );

  // Navigation
  Future<void> navigateToContacts() async {
    await tester.tap(_contactsTab);
    await tester.pumpAndSettle();
  }

  // Actions - Add Contact
  Future<void> tapAddContactButton() async {
    await tester.tap(_addButton);
    await tester.pumpAndSettle();
  }

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

  Future<void> selectPriority(String priority) async {
    await tester.tap(_priorityDropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text(priority).last);
    await tester.pumpAndSettle();
  }

  Future<void> clearName() async {
    await tester.enterText(_nameField, '');
    await tester.pumpAndSettle();
  }

  Future<void> clearEmail() async {
    await tester.enterText(_emailField, '');
    await tester.pumpAndSettle();
  }

  // Actions - Save/Cancel
  Future<void> tapSaveButton() async {
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelButton() async {
    await tester.tap(_cancelButton);
    await tester.pumpAndSettle();
  }

  // Actions - Contact Interaction
  Future<void> tapContact(String name) async {
    await tester.tap(_contactTile(name));
    await tester.pumpAndSettle();
  }

  Future<void> tapEditButton() async {
    await tester.tap(_editButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteButton() async {
    await tester.tap(_deleteButton);
    await tester.pumpAndSettle();
  }

  // Actions - Delete Confirmation
  Future<void> confirmDelete() async {
    await tester.tap(_confirmDeleteButton);
    await tester.pumpAndSettle();
  }

  Future<void> cancelDelete() async {
    await tester.tap(_cancelDeleteButton);
    await tester.pumpAndSettle();
  }

  // Verifications - Visibility
  bool isEmptyStateVisible() {
    return tester.any(_emptyStateMessage);
  }

  bool isContactVisible(String name) {
    return tester.any(_contactTile(name));
  }

  bool isFormVisible() {
    return tester.any(_nameField) && tester.any(_phoneField);
  }

  bool isAddContactButtonEnabled() {
    final button = tester.widget<FloatingActionButton>(_addButton);
    return button.onPressed != null;
  }

  // Verifications - Contact Details
  String getContactPriority(String name) {
    final chipFinder = _priorityBadge(name);
    if (!tester.any(chipFinder)) {
      return '';
    }

    final chip = tester.widget<Chip>(chipFinder);
    final label = chip.label as Text;
    return label.data ?? '';
  }

  String getContactEmail() {
    // Assuming email is displayed in a text field or text widget in detail view
    final emailFinder = find.byKey(const Key('contact_detail_email'));
    if (tester.any(emailFinder)) {
      return tester.widget<Text>(emailFinder).data ?? '';
    }
    return '';
  }

  // Verifications - Contact Order
  List<String> getContactsInOrder() {
    final tiles = tester.widgetList<ListTile>(
      find.descendant(
        of: _contactsList,
        matching: find.byType(ListTile),
      ),
    );

    return tiles.map((tile) {
      if (tile.title is Text) {
        final text = tile.title as Text;
        return text.data ?? '';
      }
      return '';
    }).where((name) => name.isNotEmpty).toList();
  }

  // Verifications - Errors
  bool hasValidationError(String message) {
    return tester.any(find.text(message));
  }

  bool hasError(String message) {
    return tester.any(find.text(message));
  }
}
