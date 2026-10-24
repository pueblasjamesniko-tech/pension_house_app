/// Small helpers so the models never crash on a null / int-vs-double / string.
int asInt(dynamic v, [int fallback = 0]) =>
    v is num ? v.toInt() : (int.tryParse('${v ?? ''}') ?? fallback);

double asDouble(dynamic v, [double fallback = 0]) =>
    v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? fallback);

String asStr(dynamic v, [String fallback = '']) => v == null ? fallback : '$v';

String? asStrOrNull(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// The API sends SQL Server dates without a time-zone (already local to the
/// pension house). If a "Z" is present we convert to local time.
DateTime asDate(dynamic v) {
  final d = DateTime.tryParse('${v ?? ''}');
  if (d == null) return DateTime.now();
  return d.isUtc ? d.toLocal() : d;
}

DateTime? asDateOrNull(dynamic v) =>
    (v == null || '$v'.isEmpty) ? null : asDate(v);
