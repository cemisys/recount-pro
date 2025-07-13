import 'package:mockito/annotations.dart';
import 'package:recount_pro/services/auth_service.dart';
import 'package:recount_pro/services/firebase_service.dart';
import 'package:recount_pro/core/services/app_state_service.dart';
import 'package:recount_pro/core/repositories/conteo_repository.dart';
import 'package:recount_pro/core/repositories/sku_repository.dart';

// This file is used to generate mocks for testing
// Run: flutter packages pub run build_runner build

@GenerateMocks([
  AuthService,
  FirebaseService,
  AppStateService,
  ConteoRepository,
  SkuRepository,
  AuxiliarRepository,
])
void main() {
  // This file is only used for mock generation
  // The actual mocks will be generated in the .mocks.dart file
}
