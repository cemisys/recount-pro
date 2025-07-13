import 'package:flutter_test/flutter_test.dart';
import 'package:recount_pro/core/services/app_state_service.dart';
import 'package:recount_pro/core/exceptions/app_exceptions.dart';

void main() {
  group('AppStateService', () {
    late AppStateService appStateService;

    setUp(() {
      appStateService = AppStateService();
    });

    group('Initial State', () {
      test('should have idle state initially', () {
        expect(appStateService.loadingState, LoadingState.idle);
        expect(appStateService.lastError, null);
        expect(appStateService.loadingMessage, null);
        expect(appStateService.hasError, false);
        expect(appStateService.isLoading, false);
      });

      test('should have all specific states as false initially', () {
        expect(appStateService.isAuthenticating, false);
        expect(appStateService.isSavingConteo, false);
        expect(appStateService.isLoadingVh, false);
        expect(appStateService.isLoadingSkus, false);
        expect(appStateService.isLoadingEstadisticas, false);
      });
    });

    group('setLoadingState', () {
      test('should update loading state and message', () {
        const message = 'Loading data...';
        appStateService.setLoadingState(LoadingState.loading, message: message);

        expect(appStateService.loadingState, LoadingState.loading);
        expect(appStateService.loadingMessage, message);
        expect(appStateService.isLoading, true);
        expect(appStateService.lastError, null);
      });

      test('should clear error when setting non-error state', () {
        // First set an error
        final error = AuthException.invalidCredentials();
        appStateService.setError(error);
        expect(appStateService.hasError, true);

        // Then set loading state
        appStateService.setLoadingState(LoadingState.loading);
        expect(appStateService.lastError, null);
        expect(appStateService.hasError, false);
      });
    });

    group('setError', () {
      test('should set error state and clear loading message', () {
        final error = AuthException.invalidCredentials();
        appStateService.setError(error);

        expect(appStateService.loadingState, LoadingState.error);
        expect(appStateService.lastError, error);
        expect(appStateService.loadingMessage, null);
        expect(appStateService.hasError, true);
        expect(appStateService.errorMessage, isNotNull);
      });
    });

    group('clearError', () {
      test('should clear error and reset to idle if in error state', () {
        final error = AuthException.invalidCredentials();
        appStateService.setError(error);
        expect(appStateService.hasError, true);

        appStateService.clearError();
        expect(appStateService.lastError, null);
        expect(appStateService.hasError, false);
        expect(appStateService.loadingState, LoadingState.idle);
      });

      test('should only clear error if not in error state', () {
        appStateService.setLoadingState(LoadingState.loading);
        final error = AuthException.invalidCredentials();
        appStateService.setError(error);
        appStateService.setLoadingState(LoadingState.success);

        appStateService.clearError();
        expect(appStateService.lastError, null);
        expect(appStateService.loadingState, LoadingState.success);
      });
    });

    group('setAuthenticating', () {
      test('should set authenticating state and loading', () {
        appStateService.setAuthenticating(true);

        expect(appStateService.isAuthenticating, true);
        expect(appStateService.loadingState, LoadingState.loading);
        expect(appStateService.loadingMessage, 'Autenticando...');
      });

      test('should clear authenticating state', () {
        appStateService.setAuthenticating(true);
        appStateService.setAuthenticating(false);

        expect(appStateService.isAuthenticating, false);
        expect(appStateService.loadingState, LoadingState.idle);
      });

      test('should use custom message', () {
        const customMessage = 'Iniciando sesión...';
        appStateService.setAuthenticating(true, message: customMessage);

        expect(appStateService.loadingMessage, customMessage);
      });
    });

    group('setSavingConteo', () {
      test('should set saving conteo state', () {
        appStateService.setSavingConteo(true);

        expect(appStateService.isSavingConteo, true);
        expect(appStateService.loadingState, LoadingState.loading);
        expect(appStateService.loadingMessage, 'Guardando conteo...');
      });

      test('should clear saving conteo state and set success', () {
        appStateService.setSavingConteo(true);
        appStateService.setSavingConteo(false);

        expect(appStateService.isSavingConteo, false);
        expect(appStateService.loadingState, LoadingState.success);
      });
    });

    group('executeWithState', () {
      test('should execute operation successfully', () async {
        const expectedResult = 'success';
        const loadingMessage = 'Processing...';

        final result = await appStateService.executeWithState<String>(
          operation: () async {
            await Future.delayed(const Duration(milliseconds: 10));
            return expectedResult;
          },
          loadingMessage: loadingMessage,
        );

        expect(result, expectedResult);
        expect(appStateService.loadingState, LoadingState.idle);
      });

      test('should handle operation failure', () async {
        const loadingMessage = 'Processing...';
        final expectedException = Exception('Test error');

        final result = await appStateService.executeWithState<String>(
          operation: () async {
            throw expectedException;
          },
          loadingMessage: loadingMessage,
        );

        expect(result, null);
        expect(appStateService.loadingState, LoadingState.error);
        expect(appStateService.hasError, true);
      });

      test('should show success state when requested', () async {
        const expectedResult = 'success';
        const loadingMessage = 'Processing...';
        const successMessage = 'Done!';

        final result = await appStateService.executeWithState<String>(
          operation: () async => expectedResult,
          loadingMessage: loadingMessage,
          successMessage: successMessage,
          showSuccess: true,
        );

        expect(result, expectedResult);
        expect(appStateService.loadingState, LoadingState.success);
        expect(appStateService.loadingMessage, successMessage);
      });
    });

    group('canPerformOperation', () {
      test('should return true when not loading', () {
        expect(appStateService.canPerformOperation(), true);
      });

      test('should return false when loading', () {
        appStateService.setLoadingState(LoadingState.loading);
        expect(appStateService.canPerformOperation(), false);
      });
    });

    group('getStateDescription', () {
      test('should return correct description for each state', () {
        expect(appStateService.getStateDescription(), 'Listo');

        appStateService.setLoadingState(LoadingState.loading, message: 'Loading...');
        expect(appStateService.getStateDescription(), 'Loading...');

        appStateService.setLoadingState(LoadingState.success, message: 'Success!');
        expect(appStateService.getStateDescription(), 'Success!');

        final error = AuthException.invalidCredentials();
        appStateService.setError(error);
        expect(appStateService.getStateDescription(), contains('Correo o contraseña'));
      });
    });

    group('reset', () {
      test('should reset all states to initial values', () {
        // Set various states
        appStateService.setAuthenticating(true);
        appStateService.setSavingConteo(true);
        appStateService.setLoadingVh(true);
        final error = AuthException.invalidCredentials();
        appStateService.setError(error);

        // Reset
        appStateService.reset();

        // Verify all states are reset
        expect(appStateService.loadingState, LoadingState.idle);
        expect(appStateService.lastError, null);
        expect(appStateService.loadingMessage, null);
        expect(appStateService.isAuthenticating, false);
        expect(appStateService.isSavingConteo, false);
        expect(appStateService.isLoadingVh, false);
        expect(appStateService.isLoadingSkus, false);
        expect(appStateService.isLoadingEstadisticas, false);
      });
    });
  });
}
