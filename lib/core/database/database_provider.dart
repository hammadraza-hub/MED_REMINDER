import 'app_database.dart';

/// ============================================================
/// DATABASE PROVIDER
///
/// App ke local phase mein ek shared Drift database instance.
///
/// IMPORTANT:
/// UI/screens is provider ko directly use NAHI karengi.
/// Repositories database ko consume karengi.
///
/// TODO Backend:
/// Firebase migration ke waqt UI repository interfaces use karti
/// rahegi. Firebase repositories ko AppDatabase dependency nahi hogi.
/// ============================================================
class DatabaseProvider {
  DatabaseProvider._();

  static final AppDatabase instance = AppDatabase();

  static Future<void> close() async {
    await instance.close();
  }
}
