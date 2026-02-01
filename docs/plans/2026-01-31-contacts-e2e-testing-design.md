# Contact E2E Testing Design

**Date:** 2026-01-31
**Status:** Approved
**Author:** Design Session with User

## Overview

Comprehensive end-to-end testing strategy for contact saving functionality, addressing the critical Firestore security rules bug and establishing robust test infrastructure for the Tether app.

## Problem Statement

1. **Critical Bug:** Firestore security rules missing for `/users/{deviceId}/contacts/{contactId}` subcollection, causing all contact save operations to fail with permission denied errors.

2. **Testing Gap:** No E2E tests exist to verify contact CRUD operations work end-to-end, including Firebase integration, validation, and security rules.

## Goals

- Fix Firestore security rules to allow authenticated users to manage their own contacts
- Build reusable E2E testing infrastructure using Page Object Model pattern
- Achieve comprehensive test coverage: happy paths + error scenarios
- Use Firebase Emulator Suite for fast, reliable automated tests
- Enable manual verification on real Firebase test project

## Architecture

### Test Environment Strategy

**Automated Tests (Primary):**
- Run against Firebase Emulator Suite (Firestore on port 8080, Auth on port 9099)
- Fast execution (~3-5 seconds per test)
- No quota limits, no costs
- Perfect for CI/CD pipelines
- Fresh state before each test file

**Manual Tests (Secondary):**
- Run against dedicated Firebase test project
- Verify real-world behavior before production deployment
- Catch environment-specific issues
- Used sparingly to avoid quota consumption

### Project Structure

```
integration_test/
├── contacts_e2e_test.dart          # Main test scenarios
├── helpers/
│   └── emulator_helper.dart        # Emulator setup & reset utilities
├── page_objects/
│   ├── contacts_page.dart          # ContactsScreen interactions
│   └── contact_dialog_page.dart    # Add/Edit dialog interactions
└── fixtures/
    └── test_data.dart              # Reusable test data
```

### Dependencies

Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
  http: ^1.2.0  # For emulator REST API calls
```

## Component Design

### 1. EmulatorHelper

**Responsibilities:**
- Configure Firebase SDK to use local emulators
- Clear Firestore data between tests via REST API
- Clear Auth users between tests via REST API
- Create authenticated test users with proper Firestore documents

**Key Methods:**
```dart
class EmulatorHelper {
  static Future<void> useEmulators()
  static Future<void> clearFirestore()
  static Future<void> clearAuth()
  static Future<void> resetAll()
  static Future<String> createTestUser()
}
```

**REST Endpoints:**
- Firestore: `DELETE http://localhost:8080/emulator/v1/projects/tether-app-prod-ee05c/databases/(default)/documents`
- Auth: `DELETE http://localhost:9099/emulator/v1/projects/tether-app-prod-ee05c/accounts`

**Test Setup Pattern:**
```dart
void main() {
  setUpAll(() async {
    await EmulatorHelper.useEmulators();
  });

  setUp(() async {
    await EmulatorHelper.resetAll(); // Fresh state per test file
  });

  testWidgets('test name', (tester) async {
    // Test implementation...
  });
}
```

### 2. ContactsPage (Page Object)

**Encapsulates:** All interactions with the contacts list screen

**Navigation:**
- `navigateToContacts()` - Navigate from home to contacts screen

**Actions:**
- `tapAddContact()` - Tap the floating action button
- `tapEditContact(String name)` - Open edit dialog for specific contact
- `tapDeleteContact(String name)` - Open delete confirmation
- `confirmDelete()` - Confirm deletion in dialog
- `cancelDelete()` - Cancel deletion

**Verifications:**
- `hasContact(String name, String phone)` - Check contact exists in list
- `getContactCount()` - Count visible contacts
- `isAddButtonVisible()` - Verify FAB visibility (hidden when 3 contacts)
- `showsEmptyState()` - Verify empty state UI
- `getSnackbarMessage()` - Capture success/error snackbar text
- `getContactPriority(String name)` - Get priority badge number

### 3. ContactDialogPage (Page Object)

**Encapsulates:** Add/Edit contact dialog interactions

**Form Filling:**
- `enterName(String name)` - Fill name field
- `enterPhone(String phone)` - Fill phone field
- `enterEmail(String email)` - Fill email field (optional)
- `selectPriority(int priority)` - Choose priority from dropdown

**Actions:**
- `tapSave()` - Submit form
- `tapCancel()` - Close dialog without saving

**Verifications:**
- `isVisible()` - Check dialog is displayed
- `getValidationError(String fieldLabel)` - Get error text for field
- `hasTitle(String title)` - Verify "Add Contact" vs "Edit Contact"
- `getAvailablePriorities()` - List available priority options

## Test Coverage

### Happy Path Tests (5 scenarios)

1. **Add first contact**
   - Start from empty state
   - Add contact with all fields
   - Verify contact appears in list with correct priority badge

2. **Add multiple contacts**
   - Add 3 contacts with priorities 1, 2, 3
   - Verify all appear in correct order
   - Verify FAB disappears after 3rd contact

3. **Edit contact**
   - Change name, phone, email, priority
   - Verify updates persist after closing and reopening screen
   - Verify priority badge updates

4. **Delete contact**
   - Delete contact with confirmation
   - Verify removal from list
   - Verify count decrements
   - Verify FAB reappears if was at limit

5. **Priority reordering**
   - Edit contact to change priority
   - Verify list reorders by priority
   - Verify priority badges update correctly

### Error Scenario Tests (9 scenarios)

6. **Validation - missing name**
   - Submit form without name
   - Verify "Name is required" error appears
   - Verify form doesn't close

7. **Validation - missing phone**
   - Submit form without phone
   - Verify "Phone number is required" error

8. **Validation - invalid phone**
   - Enter "123" (< 10 digits)
   - Verify "Enter a valid phone number" error

9. **Validation - invalid email**
   - Enter "notanemail" in email field
   - Verify "Enter a valid email" error

10. **Max contacts limit**
    - Add 3 contacts successfully
    - Attempt to add 4th contact
    - Verify snackbar: "Maximum of 3 emergency contacts allowed"
    - Verify dialog doesn't open

11. **Priority conflict**
    - Add contact with priority 1
    - Try to update different contact to priority 1
    - Verify save fails with error snackbar

12. **Network/Firestore failure**
    - Simulate permission denied (wrong user trying to access contacts)
    - Verify error snackbar appears
    - Verify contact not added to list

13. **Cancel add operation**
    - Open add dialog
    - Fill form
    - Tap Cancel
    - Verify dialog closes without saving

14. **Cancel delete operation**
    - Start delete flow
    - Tap Cancel in confirmation
    - Verify contact remains in list

### Security Rule Tests (1 scenario)

15. **Cannot access other user's contacts**
    - Create User A with contacts
    - Sign out and create User B
    - Attempt to read User A's contacts as User B
    - Verify permission denied (empty list returned)

## Test Data Strategy

**Valid Contacts:**
```dart
final validContact1 = Contact(
  id: uuid.v4(),
  name: 'John Doe',
  phone: '+15551234567',
  email: 'john@example.com',
  priority: 1,
);

final validContact2 = Contact(
  id: uuid.v4(),
  name: 'Jane Smith',
  phone: '+15559876543',
  priority: 2,
);
```

**Invalid Data:**
- Phone: "123", "abc", "" (empty)
- Email: "notanemail", "missing@", "test@"
- Edge cases: 50+ character names, international phone formats

## Firestore Security Rules Fix

**Current Issue:**
The `/users/{deviceId}/contacts/{contactId}` subcollection has no explicit rules, so falls through to default deny.

**Fix:**
Add to `firestore.rules` after line 35 (inside `/users/{deviceId}` block):

```javascript
// Subcollection for emergency contacts
match /contacts/{contactId} {
  allow read, write: if isAuthenticated() &&
                        request.auth.uid == get(/databases/$(database)/documents/users/$(deviceId)).data.uid;
}
```

**What this does:**
- Allows authenticated users to read/write their own contacts
- Prevents users from accessing other users' contacts
- Uses the parent document's `uid` field to verify ownership
- Applies to all CRUD operations (create, read, update, delete)

**Deployment:**
```bash
firebase deploy --only firestore:rules
```

## Error Handling Strategy

### Page Object Resilience

- **Timeouts:** Wait up to 10 seconds for widgets to appear using `tester.pumpAndSettle()`
- **Snackbar Capture:** Find snackbar widgets and extract text for assertions
- **Animation Handling:** Use `pumpAndSettle()` to wait for all animations to complete
- **Screenshot on Failure:** Capture widget tree state when tests fail (saved to `integration_test/screenshots/`)

### Test Isolation

- **Fresh state:** Call `EmulatorHelper.resetAll()` before each test file
- **Independent tests:** Each test creates its own user and data
- **No shared state:** Tests can run in any order without interference

## Running Tests

### Start Emulators

Create `scripts/start_emulators.sh`:
```bash
#!/bin/bash
firebase emulators:start --only firestore,auth
```

Run once before testing:
```bash
chmod +x scripts/start_emulators.sh
./scripts/start_emulators.sh
```

### Run E2E Tests

```bash
# Run all integration tests
flutter test integration_test/

# Run specific test file
flutter test integration_test/contacts_e2e_test.dart

# Run with verbose output
flutter test integration_test/ --verbose
```

### Expected Execution Time

- Each test: ~3-5 seconds
- Full suite (14 tests): ~60-90 seconds
- Can parallelize later with `--concurrency` flag

## Success Criteria

✅ All 14 test scenarios pass consistently
✅ Tests run in under 2 minutes
✅ Firestore security rules deployed and verified
✅ Contact save/edit/delete works in production
✅ Page objects are reusable for future tests (check-ins, alerts)
✅ Zero flaky tests (runs 10 times, passes 10 times)

## Future Enhancements

- Add tests for check-in functionality using same pattern
- Add tests for alert triggering and management
- Implement screenshot comparison tests for UI regressions
- Add performance benchmarks (time to save contact)
- Run tests in CI/CD pipeline (GitHub Actions)

## Implementation Sequence

1. Fix Firestore security rules → Deploy → Manual verification
2. Add dependencies to `pubspec.yaml`
3. Create `emulator_helper.dart` with reset utilities
4. Create page objects (`contacts_page.dart`, `contact_dialog_page.dart`)
5. Create `test_data.dart` fixtures
6. Implement happy path tests (5 scenarios)
7. Implement error scenario tests (9 scenarios)
8. Implement security rule test (1 scenario)
9. Run full suite 10 times to verify stability
10. Document in README and update DEVELOPMENT_CHECKLIST

## Risks & Mitigations

**Risk:** Emulator behavior differs from production Firebase
**Mitigation:** Run manual tests on real Firebase before major releases

**Risk:** Tests become flaky due to timing issues
**Mitigation:** Use `pumpAndSettle()` consistently, increase timeouts if needed

**Risk:** Page objects become outdated when UI changes
**Mitigation:** Keep page objects in sync with UI, add comments about dependencies

**Risk:** Security rules deployed incorrectly
**Mitigation:** Test rules with security rule test, verify manually before production

---

**Ready for Implementation:** Yes
**Estimated Time:** 4-6 hours for full implementation
**Priority:** High (blocking contact functionality)
