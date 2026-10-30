/// Unicode scalars retained solely as migration tombstones to remove the old
/// Nôm trial entries from local SQLite/SharedPreferences. No readings, meanings,
/// or active lesson data are stored here. Once a canonical dataset is ready,
/// this cleanup list can be retired after the migration policy is reviewed.
const Set<int> retiredNomUnicodeScalars = <int>{
  0x219F2,
  0x204E8,
  0x20332,
  0x21D80,
  0x20F4B,
  0x2846E,
  0x20027,
  0x20129,
  0x29D5C,
  0x2A004,
  0x216A5,
  0x24CC6,
  0x3D1C,
  0x29132,
  0x226B8,
  0x215F6,
  0x221A5,
  0x21F39,
  0x2013C,
  0x21B67,
  0x20F56,
  0x235E5,
  0x2815D,
  0x2025E,
  0x21B88,
  0x225CB,
  0x23395,
  0x8E4E,
  0x20AFE,
};

/// Runtime identifiers used only during cleanup; never a vocabulary source.
final Set<String> retiredNomCodepoints = Set<String>.unmodifiable(
  retiredNomUnicodeScalars.map(String.fromCharCode),
);
