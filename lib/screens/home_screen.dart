import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/eintraege_provider.dart';
import '../providers/profil_provider.dart';
import 'profil_screen.dart';
import '../widgets/stichpunkt_liste.dart';
import '../widgets/zusatz_bereich.dart';
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
              Text(
                '${_formatDate(eintrag.vonDatum)} – ${_formatDate(eintrag.bisDatum)}',
                style: Theme.of(context).textTheme.bodySmall,
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
        data: (eintrag) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StichpunktListe(
                label: 'Betriebliche Tätigkeiten',
                items: eintrag.betriebliches,
                onChanged: (items) {
                  ref.read(eintraegeProvider.notifier).updateBetriebliches(items);
                },
              ),
              const SizedBox(height: 24),
              StichpunktListe(
                label: 'Schulische Tätigkeiten',
                items: eintrag.schulisches,
                onChanged: (items) {
                  ref.read(eintraegeProvider.notifier).updateSchulisches(items);
                },
              ),
              const SizedBox(height: 24),
              ZusatzBereich(
                pauseMinuten: eintrag.pauseMinuten,
                krankheitstage: eintrag.krankheitstage,
                urlaubstage: eintrag.urlaubstage,
                onChanged: ({pauseMinuten, krankheitstage, urlaubstage}) {
                  ref.read(eintraegeProvider.notifier).updateZusatz(
                        pauseMinuten: pauseMinuten,
                        krankheitstage: krankheitstage,
                        urlaubstage: urlaubstage,
                      );
                },
              ),
              const SizedBox(height: 24),
              NotizenFeld(
                value: eintrag.notizen,
                onChanged: (value) {
                  ref.read(eintraegeProvider.notifier).updateNotizen(value);
                },
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
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
                        final pdfBytes = await generateEintragPdf(eintrag, profil);
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
                  ElevatedButton.icon(
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
    );
  }
}
