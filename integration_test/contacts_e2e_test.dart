import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tether_app/main.dart' as app;

import 'helpers/emulator_helper.dart';
import 'helpers/firebase_helper.dart';
import 'page_objects/contacts_page.dart';
import 'page_objects/login_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseHelper firebaseHelper;
  late ContactsPage contactsPage;
  late LoginPage loginPage;

  setUpAll(() async {
    await EmulatorHelper.useEmulators();
  });

  setUp(() async {
    await EmulatorHelper.resetAll();
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

  group('Contacts E2E - Validation Errors', () {
    testWidgets('should show error when name is missing', (tester) async {
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

      // Open add contact form
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();

      // Fill only phone (missing name)
      await contactsPage.enterPhone('+1234567890');
      await contactsPage.selectPriority('Medium');

      // Try to save
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(contactsPage.hasValidationError('Name is required'), isTrue);

      // Verify form is still open (not saved)
      expect(contactsPage.isFormVisible(), isTrue);
    });

    testWidgets('should show error when phone is missing', (tester) async {
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

      // Open add contact form
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();

      // Fill only name (missing phone)
      await contactsPage.enterName('John Doe');
      await contactsPage.selectPriority('Medium');

      // Try to save
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(contactsPage.hasValidationError('Phone is required'), isTrue);

      // Verify form is still open (not saved)
      expect(contactsPage.isFormVisible(), isTrue);
    });

    testWidgets('should show error when phone is too short', (tester) async {
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

      // Open add contact form
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();

      // Fill with invalid phone
      await contactsPage.enterName('John Doe');
      await contactsPage.enterPhone('123');
      await contactsPage.selectPriority('Medium');

      // Try to save
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(contactsPage.hasValidationError('Phone must be at least 10 digits'), isTrue);

      // Verify form is still open (not saved)
      expect(contactsPage.isFormVisible(), isTrue);
    });

    testWidgets('should show error when email format is invalid', (tester) async {
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

      // Open add contact form
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();

      // Fill with invalid email
      await contactsPage.enterName('John Doe');
      await contactsPage.enterPhone('+1234567890');
      await contactsPage.enterEmail('invalid-email');
      await contactsPage.selectPriority('Medium');

      // Try to save
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(contactsPage.hasValidationError('Invalid email format'), isTrue);

      // Verify form is still open (not saved)
      expect(contactsPage.isFormVisible(), isTrue);
    });
  });

  group('Contacts E2E - Business Logic Errors', () {
    testWidgets('should show error when max contacts limit reached', (tester) async {
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

      // Add 3 contacts (max limit)
      for (int i = 1; i <= 3; i++) {
        await contactsPage.tapAddContactButton();
        await tester.pumpAndSettle();
        await contactsPage.enterName('Contact $i');
        await contactsPage.enterPhone('+${i}111111111');
        await contactsPage.selectPriority('Medium');
        await contactsPage.tapSaveButton();
        await tester.pumpAndSettle();
      }

      // Try to add 4th contact
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(contactsPage.hasError('Maximum 3 emergency contacts allowed'), isTrue);

      // Verify add button is disabled
      expect(contactsPage.isAddContactButtonEnabled(), isFalse);
    });

    testWidgets('should cancel add contact operation', (tester) async {
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

      // Open add contact form
      await contactsPage.tapAddContactButton();
      await tester.pumpAndSettle();

      // Fill form
      await contactsPage.enterName('Cancelled Contact');
      await contactsPage.enterPhone('+9999999999');
      await contactsPage.selectPriority('High');

      // Cancel instead of saving
      await contactsPage.tapCancelButton();
      await tester.pumpAndSettle();

      // Verify contact was not added
      expect(contactsPage.isContactVisible('Cancelled Contact'), isFalse);
      expect(contactsPage.isEmptyStateVisible(), isTrue);
    });

    testWidgets('should cancel delete contact operation', (tester) async {
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
      await contactsPage.enterName('Keep Me');
      await contactsPage.enterPhone('+8888888888');
      await contactsPage.selectPriority('Medium');
      await contactsPage.tapSaveButton();
      await tester.pumpAndSettle();

      // Open contact and initiate delete
      await contactsPage.tapContact('Keep Me');
      await tester.pumpAndSettle();
      await contactsPage.tapDeleteButton();
      await tester.pumpAndSettle();

      // Cancel deletion
      await contactsPage.cancelDelete();
      await tester.pumpAndSettle();

      // Verify contact still exists
      expect(contactsPage.isContactVisible('Keep Me'), isTrue);
    });
  });
}
