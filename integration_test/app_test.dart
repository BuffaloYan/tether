import 'package:integration_test/integration_test.dart';

import 'contacts_e2e_test.dart' as contacts_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  contacts_tests.main();
}
