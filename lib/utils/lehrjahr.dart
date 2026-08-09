/// Computes which "Lehrjahr" (training year) a given date falls into, based on the training start date's anniversary.
///
/// For example, if `ausbildungsbeginn` is 01.08.2026:
/// * Any date from 01.08.2026 to 31.07.2027 is Lehrjahr 1.
/// * Any date from 01.08.2027 to 31.07.2028 is Lehrjahr 2, etc.
///
/// Examples:
/// * `berechneLehrjahr(DateTime(2026, 8, 3), DateTime(2026, 8, 1)) == 1`
/// * `berechneLehrjahr(DateTime(2027, 7, 31), DateTime(2026, 8, 1)) == 1`
/// * `berechneLehrjahr(DateTime(2027, 8, 1), DateTime(2026, 8, 1)) == 2`
int? berechneLehrjahr(DateTime datum, DateTime? ausbildungsbeginn) {
  if (ausbildungsbeginn == null) return null;
  if (datum.isBefore(ausbildungsbeginn)) return null;

  int jahre = datum.year - ausbildungsbeginn.year;
  final anniversaryThisYear = DateTime(
      ausbildungsbeginn.year + jahre,
      ausbildungsbeginn.month,
      ausbildungsbeginn.day);
  
  if (datum.isBefore(anniversaryThisYear)) {
    jahre -= 1;
  }
  return jahre + 1;
}
