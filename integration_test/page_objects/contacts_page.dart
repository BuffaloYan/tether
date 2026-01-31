import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page Object for the Contacts list screen.
/// Encapsulates all interactions with the contacts list UI.
class ContactsPage {
  final WidgetTester tester;

  ContactsPage(this.tester);

  // Finders
  Finder get addButton => find.byType(FloatingActionButton);
  Finder get contactsList => find.byType(ListView);
  Finder get emptyState => find.text('No contacts yet');

  Finder contactTile(String name) => find.ancestor(
    of: find.text(name),
    matching: find.byType(ListTile),
  );

  Finder contactPhone(String phone) => find.text(phone);
  Finder contactEmail(String email) => find.text(email);

  Finder deleteButton(String contactName) => find.descendant(
    of: contactTile(contactName),
    matching: find.byIcon(Icons.delete),
  );

  Finder editButton(String contactName) => find.descendant(
    of: contactTile(contactName),
    matching: find.byIcon(Icons.edit),
  );

  // Navigation
  Future<void> tapAddButton() async {
    await tester.tap(addButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapEditButton(String contactName) async {
    await tester.tap(editButton(contactName));
    await tester.pumpAndSettle();
  }

  // Actions
  Future<void> deleteContact(String contactName) async {
    await tester.tap(deleteButton(contactName));
    await tester.pumpAndSettle();
  }

  Future<void> tapContact(String contactName) async {
    await tester.tap(contactTile(contactName));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToContact(String contactName) async {
    await tester.scrollUntilVisible(
      contactTile(contactName),
      100,
      scrollable: find.descendant(
        of: contactsList,
        matching: find.byType(Scrollable),
      ),
    );
  }

  // Verifications
  Future<void> verifyContactExists(String name) async {
    expect(contactTile(name), findsOneWidget);
  }

  Future<void> verifyContactNotExists(String name) async {
    expect(contactTile(name), findsNothing);
  }

  Future<void> verifyContactDetails({
    required String name,
    String? phone,
    String? email,
  }) async {
    await verifyContactExists(name);
    if (phone != null) {
      expect(contactPhone(phone), findsOneWidget);
    }
    if (email != null) {
      expect(contactEmail(email), findsOneWidget);
    }
  }

  Future<void> verifyEmptyState() async {
    expect(emptyState, findsOneWidget);
  }

  Future<void> verifyContactCount(int count) async {
    if (count == 0) {
      await verifyEmptyState();
    } else {
      expect(
        find.descendant(
          of: contactsList,
          matching: find.byType(ListTile),
        ),
        findsNWidgets(count),
      );
    }
  }

  Future<void> verifyContactOrder(List<String> names) async {
    final tiles = tester.widgetList<ListTile>(
      find.descendant(
        of: contactsList,
        matching: find.byType(ListTile),
      ),
    );

    final actualNames = tiles.map((tile) {
      final text = tile.title as Text;
      return text.data!;
    }).toList();

    expect(actualNames, equals(names));
  }
}
