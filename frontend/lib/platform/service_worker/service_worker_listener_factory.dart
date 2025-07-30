export 'package:sessionmanager_app/platform/service_worker/service_worker_listener_mobile_impl.dart' // This is the default (for non-web)
    if (dart.library.html) 'package:sessionmanager_app/platform/service_worker/service_worker_listener_web_impl.dart'; // This overrides for web
