import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/profil.dart';
import '../providers/profil_provider.dart';
import '../widgets/stichpunkt_liste.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  final bool isFirstSetup;

  const ProfilScreen({
    super.key,
    this.isFirstSetup = false,
  });

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _adresseController;
  late final TextEditingController _ausbildungsberufController;
  late final TextEditingController _fachrichtungController;
  late final TextEditingController _betriebNameController;
  late final TextEditingController _betriebAdresseController;
  late final TextEditingController _ausbilderController;
  late final TextEditingController _ausbildungsbereichController;
  late final TextEditingController _arbeitszeitenController;
  late final TextEditingController _schultageController;
  late final TextEditingController _schulNotizenController;

  List<String> _faecher = [];

  DateTime? _ausbildungsbeginn;
  DateTime? _ausbildungsende;

  bool _initialized = false;
  bool _isSaving = false;
  bool _hideBanner = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _adresseController = TextEditingController();
    _ausbildungsberufController = TextEditingController();
    _fachrichtungController = TextEditingController();
    _betriebNameController = TextEditingController();
    _betriebAdresseController = TextEditingController();
    _ausbilderController = TextEditingController();
    _ausbildungsbereichController = TextEditingController();
    _arbeitszeitenController = TextEditingController();
    _schultageController = TextEditingController();
    _schulNotizenController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _adresseController.dispose();
    _ausbildungsberufController.dispose();
    _fachrichtungController.dispose();
    _betriebNameController.dispose();
    _betriebAdresseController.dispose();
    _ausbilderController.dispose();
    _ausbildungsbereichController.dispose();
    _arbeitszeitenController.dispose();
    _schultageController.dispose();
    _schulNotizenController.dispose();
    super.dispose();
  }

  void _initFields(Profil profil) {
    if (_initialized) return;
    _nameController.text = profil.name;
    _adresseController.text = profil.adresse;
    _ausbildungsberufController.text = profil.ausbildungsberuf;
    _fachrichtungController.text = profil.fachrichtung;
    _betriebNameController.text = profil.betriebName;
    _betriebAdresseController.text = profil.betriebAdresse;
    _ausbilderController.text = profil.ausbilder;
    _ausbildungsbereichController.text = profil.ausbildungsbereich;
    _arbeitszeitenController.text = profil.arbeitszeiten;
    _schultageController.text = profil.schultage;
    _schulNotizenController.text = profil.schulNotizen;
    _faecher = List.from(profil.faecher);
    _ausbildungsbeginn = profil.ausbildungsbeginn;
    _ausbildungsende = profil.ausbildungsende;
    _initialized = true;
  }

  Future<void> _pickDate(bool isBeginn) async {
    final initialDate = isBeginn
        ? (_ausbildungsbeginn ?? DateTime.now())
        : (_ausbildungsende ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        if (isBeginn) {
          _ausbildungsbeginn = picked;
        } else {
          _ausbildungsende = picked;
        }
      });
    }
  }

  Future<void> _saveProfil() async {
    setState(() => _isSaving = true);

    final currentProfil = ref.read(profilProvider).value;

    final updated = Profil(
      name: _nameController.text.trim(),
      adresse: _adresseController.text.trim(),
      ausbildungsberuf: _ausbildungsberufController.text.trim(),
      fachrichtung: _fachrichtungController.text.trim(),
      betriebName: _betriebNameController.text.trim(),
      betriebAdresse: _betriebAdresseController.text.trim(),
      ausbilder: _ausbilderController.text.trim(),
      ausbildungsbereich: _ausbildungsbereichController.text.trim(),
      schultage: _schultageController.text.trim(),
      schulNotizen: _schulNotizenController.text.trim(),
      faecher: _faecher,
      wochenstunden: currentProfil?.wochenstunden ?? '40 Std./Woche',
      pause: currentProfil?.pause ?? '30 min. pro Tag',
      arbeitszeiten: _arbeitszeitenController.text.trim(),
      ausbildungsbeginn: _ausbildungsbeginn,
      ausbildungsende: _ausbildungsende,
    );

    await ref.read(profilProvider.notifier).updateProfil(updated);

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gespeichert')),
    );

    if (widget.isFirstSetup) {
      // If we're the root route (which we likely are in first setup), we shouldn't pop.
      // But if there's a route to pop, we pop.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Nicht gesetzt';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Widget _buildDateField(String label, bool isBeginn) {
    final date = isBeginn ? _ausbildungsbeginn : _ausbildungsende;
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${_formatDate(date)}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _pickDate(isBeginn),
          tooltip: 'Datum auswählen',
        ),
        if (date != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                if (isBeginn) {
                  _ausbildungsbeginn = null;
                } else {
                  _ausbildungsende = null;
                }
              });
            },
            tooltip: 'Datum zurücksetzen',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: profilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
        data: (profil) {
          _initFields(profil);

          return Column(
            children: [
              if (widget.isFirstSetup && !_hideBanner)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bitte fülle deine Ausbildungsdaten aus (kann später jederzeit geändert werden).',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _hideBanner = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
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
                                      Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Persönliche Daten', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name, Vorname',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _adresseController,
                                    decoration: const InputDecoration(
                                      labelText: 'Adresse',
                                    ),
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
                                      Text('Ausbildung', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _ausbildungsberufController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ausbildungsberuf',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _fachrichtungController,
                                    decoration: const InputDecoration(
                                      labelText: 'Fachrichtung, Schwerpunkt',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _ausbildungsbereichController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ausbildungsbereich',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildDateField('Ausbildungsbeginn', true),
                                  const SizedBox(height: 8),
                                  _buildDateField('Ausbildungsende', false),
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
                                      Icon(Icons.business_outlined, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Betrieb', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _betriebNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ausbildungsbetrieb (Name)',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _betriebAdresseController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ausbildungsbetrieb (Adresse)',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _ausbilderController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ausbilder/in',
                                    ),
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
                                      Icon(Icons.menu_book_outlined, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Berufsschule', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _arbeitszeitenController,
                                    decoration: const InputDecoration(
                                      labelText: 'Arbeitszeiten',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  StichpunktListe(
                                    label: 'Fächer (Berufsschule)',
                                    items: _faecher,
                                    onChanged: (items) {
                                      setState(() {
                                        _faecher = items;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _schultageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Schultage (Seite 2)',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _schulNotizenController,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Schulische Notizen (optional)',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          FilledButton(
                            onPressed: _isSaving ? null : _saveProfil,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Speichern',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
