import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/eintraege_provider.dart';
import '../providers/profil_provider.dart';
import 'profil_screen.dart';
import '../widgets/stichpunkt_liste.dart';
import '../widgets/notizen_feld.dart';
import '../services/pdf_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Future<void> _showNextWeekDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nächste Woche'),
        content: const Text(
          'Aktuelle Woche abschließen und neue Woche beginnen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(eintraegeProvider.notifier).nextWeek();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eintragAsync = ref.watch(eintraegeProvider);

    return Scaffold(
      appBar: AppBar(
        title: eintragAsync.maybeWhen(
          data: (eintrag) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Berichtsheft'),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_formatDate(eintrag.vonDatum)} – ${_formatDate(eintrag.bisDatum)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          orElse: () => const Text('Berichtsheft'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Vorherige Woche',
            onPressed: () {
              ref.read(eintraegeProvider.notifier).previousWeek();
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Nächste Woche',
            onPressed: () => _showNextWeekDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfilScreen(isFirstSetup: false),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: eintragAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Fehler beim Laden: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(eintraegeProvider),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (eintrag) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.work_outline, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Betriebliche Tätigkeiten', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          StichpunktListe(
                            label: 'Tätigkeiten',
                            items: eintrag.betriebliches,
                            onChanged: (items) {
                              ref.read(eintraegeProvider.notifier).updateBetriebliches(items);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school_outlined, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Schulische Tätigkeiten', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ...() {
                final faecher = ref.watch(profilProvider).value?.faecher ?? [];
                if (faecher.isEmpty) {
                  return [
                    const Text(
                      'Keine Fächer im Profil hinterlegt (unter Profil hinzufügen)',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ];
                }
                
                return faecher.map((fach) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: StichpunktListe(
                      label: fach,
                      items: eintrag.schulischesProFach[fach] ?? const [],
                      onChanged: (items) {
                        final map = Map<String, List<String>>.from(eintrag.schulischesProFach);
                        map[fach] = items;
                        ref.read(eintraegeProvider.notifier).updateSchulischesProFach(map);
                      },
                    ),
                  );
                }).toList();
              }(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Besonderheiten & Notizen', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          NotizenFeld(
                            label: 'Besonderheiten',
                            value: eintrag.besonderheiten,
                            onChanged: (value) {
                              ref.read(eintraegeProvider.notifier).updateBesonderheiten(value);
                            },
                          ),
                          const SizedBox(height: 24),
                          NotizenFeld(
                            label: 'Notizen',
                            value: eintrag.notizen,
                            onChanged: (value) {
                              ref.read(eintraegeProvider.notifier).updateNotizen(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.print_outlined, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Export & PDF', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.start,
                            children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF anzeigen'),
                    onPressed: () async {
                      final profil = ref.read(profilProvider).value;
                      if (profil == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil noch nicht geladen, bitte kurz warten'),
                            ),
                          );
                        }
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        final monthStart = DateTime(eintrag.vonDatum.year, eintrag.vonDatum.month, 1);
                        final monthEnd = DateTime(eintrag.vonDatum.year, eintrag.vonDatum.month + 1, 0);
                        final sameMonth = await fetchEintraegeInRange(monthStart, monthEnd);
                        final pdfBytes = await generateEintragPdf(eintrag, sameMonth, profil);
                        if (context.mounted) {
                          Navigator.of(context).pop(); // dismiss loading dialog
                        }
                        final filename =
                            'berichtsheft_${DateFormat('yyyy-MM-dd').format(eintrag.vonDatum)}.pdf';
                        await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename: filename,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // dismiss loading dialog
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler bei der PDF-Erstellung: $e')),
                          );
                        }
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: const Text('Zeitraum exportieren'),
                    onPressed: () async {
                      final profil = ref.read(profilProvider).value;
                      if (profil == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil noch nicht geladen, bitte kurz warten'),
                            ),
                          );
                        }
                        return;
                      }

                      final maxDate = await fetchLatestBisDatum() ?? DateTime.now();
                      if (!context.mounted) return;
                      
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2026, 1, 1),
                        lastDate: maxDate,
                        initialDateRange: null,
                      );
                      
                      if (range == null) return;

                      // Ask whether to include a cover page
                      if (!context.mounted) return;
                      final includeDeckblatt = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          bool checked = false;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: const Text('Export-Optionen'),
                                content: CheckboxListTile(
                                  title: const Text('Deckblatt hinzufügen'),
                                  value: checked,
                                  onChanged: (value) {
                                    setState(() => checked = value ?? false);
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(null),
                                    child: const Text('Abbrechen'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(checked),
                                    child: const Text('Exportieren'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );

                      if (includeDeckblatt == null) return;

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      try {
                        final eintraege = await fetchEintraegeInRange(range.start, range.end);
                        final pdfBytes = await generateEintraegeRangePdf(
                          eintraege,
                          profil,
                          includeDeckblatt: includeDeckblatt,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop(); // dismiss loading dialog
                        }
                        final filename =
                            'berichtsheft_${DateFormat('yyyy-MM-dd').format(range.start)}_bis_${DateFormat('yyyy-MM-dd').format(range.end)}.pdf';
                        await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename: filename,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // dismiss loading dialog
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler beim Zeitraum-Export: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
