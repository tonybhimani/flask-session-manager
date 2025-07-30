import 'package:sessionmanager_app/services/auth_service.dart';
import 'service_worker_listener_interface.dart'; // Import the abstract interface

// A default, do-nothing implementation for non-web platforms.
// This will be used when building for Android/iOS.
class ServiceWorkerListenerImpl implements ServiceWorkerListenerInterface {
  @override
  void initialize(AuthService authService) {
    // On mobile, this does nothing as there are no service workers.
    print('ServiceWorkerListenerImpl: Initialized (no-op for mobile).');
  }

  @override
  void dispose() {
    // No-op
  }
}
