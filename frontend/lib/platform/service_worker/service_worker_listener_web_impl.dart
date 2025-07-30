import 'package:web/web.dart' as web;
import 'dart:js_interop';

import 'package:sessionmanager_app/services/auth_service.dart';
import 'service_worker_listener_interface.dart'; // Import the abstract interface

class ServiceWorkerListenerImpl implements ServiceWorkerListenerInterface {
  // Store a reference to the AuthService
  AuthService? _authService;
  // Store a reference to the JS function to be able to remove it later
  JSFunction? _jsMessageListener;

  @override
  void initialize(AuthService authService) {
    _authService = authService;
    print('ServiceWorkerListenerWeb: Initializing for web...');

    // Define the Dart function that will handle the message event
    void handleMessageEvent(web.Event event) {
      final web.MessageEvent messageEvent = event as web.MessageEvent;
      final JSAny? eventData = messageEvent.data;

      if (eventData != null) {
        final dartData = eventData.dartify();

        if (dartData case {'type': String typeValue}) {
          if (typeValue == 'LOGOUT_COMMAND') {
            _authService?.clearTokens(); // Use null-safe call
            print(
              'ServiceWorkerListenerWeb: LOGOUT_COMMAND received from Service Worker.',
            );
          }
        }
      }
    }

    // Convert the Dart function to a JS function for addEventListener
    _jsMessageListener = handleMessageEvent.toJS;

    // Use addEventListener directly. The event name is 'message'.
    web.window.navigator.serviceWorker.addEventListener(
      'message',
      _jsMessageListener!, // Use the stored JSFunction
    );
    print('ServiceWorkerListenerWeb: Service Worker message listener added.');
  }

  @override
  void dispose() {
    // Remove the event listener when disposing
    if (_jsMessageListener != null) {
      web.window.navigator.serviceWorker.removeEventListener(
        'message',
        _jsMessageListener!,
      );
      print(
        'ServiceWorkerListenerWeb: Service Worker message listener removed.',
      );
    }
    _authService = null;
    _jsMessageListener = null;
  }
}
