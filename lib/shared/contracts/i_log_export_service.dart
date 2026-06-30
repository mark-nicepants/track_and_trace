/// Bundles the rotating on-disk log files into a single archive the UI can
/// hand to the platform share sheet (`share_plus`).
///
/// Distinct from [ICrashReportService]: that one zips the same logs and
/// POSTs them to the backend crash endpoint, whereas this one only writes a
/// local archive and returns its path so the operator can share it
/// manually (e-mail, chat, …). Lives in `shared/contracts/` so the UI can
/// depend on the interface without importing `data`.
abstract interface class ILogExportService {
  /// Zips every `log.*.logcat` file into a single archive and returns its
  /// absolute path, or `null` when there are no log files on disk yet.
  Future<String?> exportLogArchive();
}
