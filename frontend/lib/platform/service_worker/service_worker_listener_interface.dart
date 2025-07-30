import 'package:sessionmanager_app/services/auth_service.dart';

abstract class ServiceWorkerListenerInterface {
  // Method to initialize listening for messages, takes AuthService as dependency
  void initialize(AuthService authService);
  // Method to dispose of any listeners, if necessary
  void dispose();
}
