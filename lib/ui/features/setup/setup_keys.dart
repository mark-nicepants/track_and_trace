/// Keys for SetupScreen persistence. The same keys are read by the
/// launch-time redirect to detect a previously-completed setup.
const String machineTypeKey = 'setup.machine_type';
const String machineCapacityKey = 'setup.capacity';

/// Caches the last-fetched list of machine types so the SetupScreen has
/// something to show when launched offline.
const String machineTypesCacheKey = 'setup.machine_types_cache';
