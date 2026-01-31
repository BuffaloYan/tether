import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tether_app/main.dart' as app;

import 'helpers/emulator_helper.dart';
import 'helpers/firebase_helper.dart';
import 'page_objects/contacts_page.dart';
import 'page_objects/login_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late EmulatorHelper emulatorHelper;
  late FirebaseHelper firebaseHelper;
  late ContactsPage contactsPage;
  late LoginPage loginPage;

  setUpAll(() async {
    emulatorHelper = EmulatorHelper();
    await emulatorHelper.startEmulators();
  });

  tearDownAll(() async {
    await emulatorHelper.stopEmulators();
  });

  setUp(() async {
    firebaseHelper = FirebaseHelper();
    await firebaseHelper.clearAllData();
    await firebaseHelper.createTestUser(
      email: 'test@example.com',
      password: 'testPassword123',
    );
  });

  tearDown(() async {
    await firebaseHelper.clearAllData();
  });

  group('Contacts E2E - Happy Path', () {
    testWidgets('should add first contact successfully', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Initialize page objects
      loginPage = LoginPage(tester);
      contactsPage = ContactsPage(tester);

      // Login
      await loginPage.login('test@example.com', 'testPassword123');
      await tester.pumpAndSettle();

      // Navigate to contacts
      await contactsPage.navigateToContacts();
      await tester.pumpAndSettle();

      // Verify empty state
      expect(contactsPage.isEmptyStateVisible(), isTrue);

      // Open add contact form
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();

      // Fill form
      await contactsPage.enterName('John Doe');
      await contactsPage.enterPhone('+1234567890');
      await contactsPage.enterEmail('john@example.com');
      await contactsPage.selectPriority('High');

      // Save contact
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify contact appears in list
      expect(contactsPage.isContactVisible('John Doe'), isTrue);
      expect(contactsPage.getContactPriority('John Doe'), 'High');

      // Verify empty state is gone
      expect(contactsPage.isEmptyStateVisible(), isFalse);
    });

    testWidgets('should add multiple contacts successfully', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Initialize page objects
      loginPage = LoginPage(tester);
      contactsPage = ContactsPage(tester);

      // Login
      await loginPage.login('test@example.com', 'testPassword123');
      await tester.pumpAndSettle();

      // Navigate to contacts
      await contactsPage.navigateToContacts();
      await tester.pumpAndSettle();

      // Add first contact
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();
      await contactsPage.enterName('Alice Smith');
      await contactsPage.enterPhone('+1111111111');
      await contactsPage.selectPriority('High');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Add second contact
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();
      await contactsPage.enterName('Bob Johnson');
      await contactsPage.enterPhone('+2222222222');
      await contactsPage.selectPriority('Medium');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Add third contact
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();
      await contactsPage.enterName('Charlie Brown');
      await contactsPage.enterPhone('+3333333333');
      await contactsPage.selectPriority('Low');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify all contacts are visible
      expect(contactsPage.isContactVisible('Alice Smith'), isTrue);
      expect(contactsPage.isContactVisible('Bob Johnson'), isTrue);
      expect(contactsPage.isContactVisible('Charlie Brown'), isTrue);

      // Verify priorities
      expect(contactsPage.getContactPriority('Alice Smith'), 'High');
      expect(contactsPage.getContactPriority('Bob Johnson'), 'Medium');
      expect(contactsPage.getContactPriority('Charlie Brown'), 'Low');
    });

    testWidgets('should edit contact successfully', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Initialize page objects
      loginPage = LoginPage(tester);
      contactsPage = ContactsPage(tester);

      // Login
      await loginPage.login('test@example.com', 'testPassword123');
      await tester.pumpAndSettle();

      // Navigate to contacts
      await contactsPage.navigateToContacts();
      await tester.pumpAndSettle();

      // Add initial contact
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();
      await contactsPage.enterName('Original Name');
      await contactsPage.enterPhone('+1234567890');
      await contactsPage.enterEmail('original@example.com');
      await contactsPage.selectPriority('Low');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Open contact for editing
      await contactsPage.tapContact('Original Name');
      await tester.pumpAndSettle();
      await contactsPage.tapEditButton();
      await tester.pumpAndSettle();

      // Modify fields
      await contactsPage.clearName();
      await contactsPage.enterName('Updated Name');
      await contactsPage.clearEmail();
      await contactsPage.enterEmail('updated@example.com');
      await contactsPage.selectPriority('High');

      // Save changes
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify changes
      expect(contactsPage.isContactVisible('Updated Name'), isTrue);
      expect(contactsPage.isContactVisible('Original Name'), isFalse);
      expect(contactsPage.getContactPriority('Updated Name'), 'High');

      // Open contact details to verify email
      await contactsPage.tapContact('Updated Name');
      await tester.pumpAndSettle();
      expect(contactsPage.getContactEmail(), 'updated@example.com');
    });

    testWidgets('should delete contact successfully', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Initialize page objects
      loginPage = LoginPage(tester);
      contactsPage = ContactsPage(tester);

      // Login
      await loginPage.login('test@example.com', 'testPassword123');
      await tester.pumpAndSettle();

      // Navigate to contacts
      await contactsPage.navigateToContacts();
      await tester.pumpAndSettle();

      // Add contact
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();
      await contactsPage.enterName('Delete Me');
      await contactsPage.enterPhone('+9999999999');
      await contactsPage.selectPriority('Medium');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify contact exists
      expect(contactsPage.isContactVisible('Delete Me'), isTrue);

      // Open contact and delete
      await contactsPage.tapContact('Delete Me');
      await tester.pumpAndSettle();
      await contactsPage.tapDeleteButton();
      await tester.pumpAndSettle();

      // Confirm deletion
      await contactsPage.confirmDelete();
      await tester.pumpAndSettle();

      // Verify contact is gone
      expect(contactsPage.isContactVisible('Delete Me'), isFalse);
      expect(contactsPage.isEmptyStateVisible(), isTrue);
    });

    testWidgets('should reorder contacts by priority', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Initialize page objects
      loginPage = LoginPage(tester);
      contactsPage = ContactsPage(tester);

      // Login
      await loginPage.login('test@example.com', 'testPassword123');
      await tester.pumpAndSettle();

      // Navigate to contacts
      await contactsPage.navigateToContacts();
      await tester.pumpAndSettle();

      // Add contacts in mixed priority order
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();
      await contactsPage.enterName('Low Priority');
      await contactsPage.enterPhone('+1111111111');
      await contactsPage.selectPriority('Low');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();
      await contactsPage.enterName('High Priority');
      await contactsPage.enterPhone('+2222222222');
      await contactsPage.selectPriority('High');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();
      await contactsPage.enterName('Medium Priority');
      await contactsPage.enterPhone('+3333333333');
      await contactsPage.selectPriority('Medium');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify contacts are ordered by priority (High, Medium, Low)
      final contactOrder = contactsPage.getContactsInOrder();
      expect(contactOrder[0], 'High Priority');
      expect(contactOrder[1], 'Medium Priority');
      expect(contactOrder[2], 'Low Priority');
    });
  });
}
