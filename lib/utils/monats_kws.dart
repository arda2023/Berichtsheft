/// Represents a single calendar week (Kalenderwoche) slot.
class KwSlot {
  final int kwNummer;
  final DateTime montag;
  final DateTime sonntag;

  const KwSlot({
    required this.kwNummer,
    required this.montag,
    required this.sonntag,
  });

  @override
  String toString() {
    return 'KwSlot(KW $kwNummer, ${montag.toIso8601String().split('T').first} to ${sonntag.toIso8601String().split('T').first})';
  }
}

/// Returns the ISO 8601 week number (1-53) for a given date.
///
/// The standard algorithm: find the Thursday of the date's week (Monday-based),
/// then the week number is based on that Thursday's position in its year.
int isoWeekNumber(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final dayOfWeek = d.weekday; // Mon=1..Sun=7
  final thursday = d.add(Duration(days: 4 - dayOfWeek));
  final firstDayOfYear = DateTime(thursday.year, 1, 1);
  final diff = thursday.difference(firstDayOfYear).inDays;
  return 1 + (diff ~/ 7);
}

/// Returns a list of [KwSlot] for all weeks whose MONDAY falls within the
/// given year and month.
///
/// Example: for November 2024, `kwSlotsForMonth(2024, 11)` yields 4 slots:
/// - 04.11.2024 (KW 45)
/// - 11.11.2024 (KW 46)
/// - 18.11.2024 (KW 47)
/// - 25.11.2024 (KW 48)
///
/// IMPORTANT DECISION: This implementation explicitly selects weeks where the
/// *Monday* is inside the target month. This keeps the logic cleaner.
/// If the user's data or template expects weeks that merely *overlap* with the
/// month (e.g., KW 44 starting on 28.10.2024 but overlaps into November 1st),
/// this logic would need to be adjusted in the future.
List<KwSlot> kwSlotsForMonth(int year, int month) {
  final List<KwSlot> slots = [];
  
  // Find the 1st of the month
  DateTime current = DateTime(year, month, 1);
  
  // Back up to the Monday of that week
  if (current.weekday != DateTime.monday) {
    current = current.subtract(Duration(days: current.weekday - 1));
  }
  
  // Iterate through Mondays
  while (true) {
    // If we've moved past the target month and the current Monday is in a new month, stop.
    // Since we only want weeks where the Monday is *in* the given month.
    if (current.month != month && current.isAfter(DateTime(year, month, 1))) {
      break;
    }

    // Only add if the Monday is actually in the target month.
    // (If the 1st of the month was e.g. a Wednesday, the preceding Monday is in the previous month.)
    if (current.month == month) {
      final kw = isoWeekNumber(current);
      slots.add(KwSlot(
        kwNummer: kw,
        montag: current,
        sonntag: current.add(const Duration(days: 6)),
      ));
    }
    
    // Move to the next Monday
    current = current.add(const Duration(days: 7));
  }
  
  return slots;
}

/// Returns every Monday-based week (Mon–Sun) that **overlaps** the given
/// [year]/[month], i.e. the week's Sunday >= firstDay AND the week's Monday
/// <= lastDay of the month.
///
/// This is the overlap-based counterpart to [kwSlotsForMonth]:
/// - A week starting Mon 28.10 and ending Sun 03.11 appears on **both**
///   the October and November page.
/// - Each [KwSlot] stores the true [montag]/[sonntag] (not clipped). The
///   PDF layer clips them to the month boundary for display purposes.
///
/// Example: for November 2024, yields 5 slots:
/// - KW 44: Mon 28.10 – Sun 03.11  (overlaps from October)
/// - KW 45: Mon 04.11 – Sun 10.11
/// - KW 46: Mon 11.11 – Sun 17.11
/// - KW 47: Mon 18.11 – Sun 24.11
/// - KW 48: Mon 25.11 – Sun 01.12  (overlaps into December)
List<KwSlot> kwSlotsOverlappingMonth(int year, int month) {
  final firstDay = DateTime(year, month, 1);
  // DateTime(year, month + 1, 0) gives the last day of [month].
  final lastDay = DateTime(year, month + 1, 0);

  // Start from the Monday of the week that contains [firstDay].
  DateTime current = firstDay;
  if (current.weekday != DateTime.monday) {
    current = current.subtract(Duration(days: current.weekday - 1));
  }

  final List<KwSlot> slots = [];
  while (!current.isAfter(lastDay)) {
    final sonntag = current.add(const Duration(days: 6));
    // Include the week if it overlaps the month (sonntag >= firstDay is always
    // true here since current started from the Monday containing firstDay).
    slots.add(KwSlot(
      kwNummer: isoWeekNumber(current),
      montag: current,
      sonntag: sonntag,
    ));
    current = current.add(const Duration(days: 7));
  }

  return slots;
}
