export 'package:sessionmanager_app/platform/storage/storage_mobile_impl.dart' // This is the default (for non-web)
    if (dart.library.html) 'package:sessionmanager_app/platform/storage/storage_web_impl.dart'; // This overrides for web
