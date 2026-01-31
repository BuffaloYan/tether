import 'package:uuid/uuid.dart';
import '../../lib/models/contact.dart';

class TestData {
  static const uuid = Uuid();

  // Valid test contacts
  static Contact validContact1({int priority = 1}) => Contact(
    id: uuid.v4(),
    name: 'John Doe',
    phone: '+15551234567',
    email: 'john@example.com',
    priority: priority,
  );

  static Contact validContact2({int priority = 2}) => Contact(
    id: uuid.v4(),
    name: 'Jane Smith',
    phone: '+15559876543',
    email: 'jane@example.com',
    priority: priority,
  );

  static Contact validContact3({int priority = 3}) => Contact(
    id: uuid.v4(),
    name: 'Bob Johnson',
    phone: '+15555555555',
    priority: priority,
  );

  // Invalid data for validation tests
  static const invalidPhoneShort = '123';
  static const invalidPhoneLetters = 'abc';
  static const invalidEmail1 = 'notanemail';
  static const invalidEmail2 = 'missing@';
  static const invalidEmail3 = 'test@';

  // Edge cases
  static const longName = 'A' * 100;
  static const internationalPhone = '+44 20 7946 0958';
}
