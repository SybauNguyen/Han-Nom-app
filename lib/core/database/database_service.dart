/// Native platforms use SQLite; Flutter Web uses the same repository API with
/// an in-memory catalogue so the app can still run in Edge/Chrome.
export 'database_service_web.dart'
    if (dart.library.io) 'database_service_native.dart';
