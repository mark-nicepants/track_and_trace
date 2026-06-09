/// Service the crash screen calls into to collect, zip, and upload the
/// rotating log files. Lives in `shared/contracts/` because the UI layer
/// needs to depend on the interface (and `ui` cannot import `data`); the
/// production implementation in `data/services/` reads the rotating log
/// directory and POSTs the zipped bundle to `/forward-logs`.
abstract interface class ICrashReportService {
  /// Zips the rotating log files and POSTs them as a multipart upload to
  /// `/forward-logs`. Returns `true` on success, `false` on any failure
  /// (network, missing files, etc.). The upload flow is one-shot: the
  /// caller should re-invoke on retry.
  Future<bool> uploadLogs();
}
