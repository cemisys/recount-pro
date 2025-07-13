import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/utils/logger.dart';
import '../core/utils/error_handler.dart';
import '../core/exceptions/app_exceptions.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  AppException? _lastError;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  AppException? get lastError => _lastError;
  String? get errorMessage => _lastError != null
      ? ErrorHandler.getUserFriendlyMessage(_lastError!)
      : null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadUserModel(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      Logger.firebaseOperation('GET', 'verificadores', {'uid': uid});
      final doc = await _firestore.collection('verificadores').doc(uid).get();

      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
        Logger.info('User model loaded successfully for uid: $uid');
      } else {
        // Si el documento no existe, crear uno básico con la información del usuario de Firebase Auth
        final user = _auth.currentUser;
        if (user != null) {
          final userModel = UserModel(
            uid: user.uid,
            nombre: user.displayName ?? user.email?.split('@')[0] ?? 'Usuario',
            correo: user.email ?? '',
            rol: 'verificador',
            fechaCreacion: DateTime.now(),
          );

          // Guardar el documento en Firestore
          Logger.firebaseOperation('SET', 'verificadores', userModel.toMap());
          await _firestore
              .collection('verificadores')
              .doc(uid)
              .set(userModel.toMap());

          _userModel = userModel;
          Logger.info('New user model created for uid: $uid');
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Error loading user model', e, stackTrace);
      // En caso de error, crear un modelo básico para evitar el loading infinito
      final user = _auth.currentUser;
      if (user != null) {
        _userModel = UserModel(
          uid: user.uid,
          nombre: user.displayName ?? user.email?.split('@')[0] ?? 'Usuario',
          correo: user.email ?? '',
          rol: 'verificador',
          fechaCreacion: DateTime.now(),
        );
      }
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      Logger.auth('Sign in attempt', email);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserModel(credential.user!.uid);
        Logger.auth('Sign in successful', credential.user!.uid);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      final appException = ErrorHandler.handleFirebaseAuthError(e);
      _setError(appException);
      return false;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleGenericError(e, stackTrace);
      _setError(appException);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUserWithEmailAndPassword(
    String email,
    String password,
    String nombre
  ) async {
    try {
      _setLoading(true);
      _clearError();

      Logger.auth('Create user attempt', email);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Crear documento del usuario en Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          nombre: nombre,
          correo: email,
          rol: 'verificador',
          fechaCreacion: DateTime.now(),
        );

        await _firestore
            .collection('verificadores')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        _userModel = userModel;
        Logger.auth('User created successfully', credential.user!.uid);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      final appException = ErrorHandler.handleFirebaseAuthError(e);
      _setError(appException);
      return false;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleGenericError(e, stackTrace);
      _setError(appException);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      final userId = _user?.uid;
      await _auth.signOut();
      _userModel = null;
      Logger.auth('Sign out successful', userId);
    } catch (e, stackTrace) {
      Logger.error('Error signing out', e, stackTrace);
    }
  }

  Future<void> checkAuthState() async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(AppException error) {
    _lastError = error;
    Logger.error('AuthService Error: ${error.message}', error.originalError);
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }


}