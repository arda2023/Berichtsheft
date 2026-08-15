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
      arbeitszeiten: currentProfil?.arbeitszeiten ?? '8:00 - 16:30 Uhr',
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
                Material(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Bitte fülle deine Ausbildungsdaten aus (kann später jederzeit geändert werden).',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name, Vorname',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adresseController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ausbildungsberufController,
                        decoration: const InputDecoration(
                          labelText: 'Ausbildungsberuf',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fachrichtungController,
                        decoration: const InputDecoration(
                          labelText: 'Fachrichtung, Schwerpunkt',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _betriebNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ausbildungsbetrieb (Name)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _betriebAdresseController,
                        decoration: const InputDecoration(
                          labelText: 'Ausbildungsbetrieb (Adresse)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ausbilderController,
                        decoration: const InputDecoration(
                          labelText: 'Ausbilder/in',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ausbildungsbereichController,
                        decoration: const InputDecoration(
                          labelText: 'Ausbildungsbereich',
                          border: OutlineInputBorder(),
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
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _schulNotizenController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Schulische Notizen (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDateField('Ausbildungsbeginn', true),
                      const SizedBox(height: 8),
                      _buildDateField('Ausbildungsende', false),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfil,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
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
            ],
          );
        },
      ),
    );
  }
}
