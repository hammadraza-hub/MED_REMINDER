import '../../repositories/prefs_fda_label_cache.dart';
import '../ai/fda_label_client.dart';

/// The app's single [FdaLabelClient] (memory first, then the phone's storage).
class FdaLabelService {
  FdaLabelService._();

  static final FdaLabelClient instance = FdaLabelClient(
    cache: PrefsFdaLabelCache(),
  );
}
