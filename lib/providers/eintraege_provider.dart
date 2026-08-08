import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/eintrag.dart';

DateTime mondayOfWeek(DateTime date) {
  return date.subtract(Duration(days: date.weekday - 1));
}

class EintraegeNotifier extends AsyncNotifier<Eintrag> {
  @override
  FutureOr<Eintrag> build() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final response = await client
        .from('eintraege')
        .select()
        .eq('user_id', user.id)
        .order('von_datum', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      return Eintrag.fromJson(response);
    } else {
      // Create new Eintrag for current week
      final now = DateTime.now();
      final monday = mondayOfWeek(now);
      final sunday = monday.add(const Duration(days: 6));
      
      // Clean dates
      final vonDatum = DateTime(monday.year, monday.month, monday.day);
      final bisDatum = DateTime(sunday.year, sunday.month, sunday.day);

      final newEintrag = Eintrag(
        userId: user.id,
        ausbildungsjahr: now.year,
        vonDatum: vonDatum,
        bisDatum: bisDatum,
        betriebliches: const [],
        schulisches: const [],
      );

      final insertResponse = await client
          .from('eintraege')
          .insert(newEintrag.toJson())
          .select()
          .single();

      return Eintrag.fromJson(insertResponse);
    }
  }

  Future<void> updateBetriebliches(List<String> items) async {
    final currentEintrag = state.value;
    if (currentEintrag == null || currentEintrag.id == null) return;

    final updatedEintrag = currentEintrag.copyWith(
      betriebliches: items,
      updatedAt: DateTime.now(),
    );

    // Optimistic update
    state = AsyncData(updatedEintrag);

    try {
      await Supabase.instance.client
          .from('eintraege')
          .update({
            'betriebliches': items,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentEintrag.id!);
    } catch (e, st) {
      // If error occurs, you might want to revert the state, 
      // but for now we'll just push the error to the state
      state = AsyncError(e, st);
    }
  }

  Future<void> updateSchulisches(List<String> items) async {
    final currentEintrag = state.value;
    if (currentEintrag == null || currentEintrag.id == null) return;

    final updatedEintrag = currentEintrag.copyWith(
      schulisches: items,
      updatedAt: DateTime.now(),
    );

    state = AsyncData(updatedEintrag);

    try {
      await Supabase.instance.client
          .from('eintraege')
          .update({
            'schulisches': items,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentEintrag.id!);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateZusatz({int? pauseMinuten, int? krankheitstage, int? urlaubstage}) async {
    final currentEintrag = state.value;
    if (currentEintrag == null || currentEintrag.id == null) return;

    final updatedEintrag = currentEintrag.copyWith(
      pauseMinuten: pauseMinuten,
      krankheitstage: krankheitstage,
      urlaubstage: urlaubstage,
      updatedAt: DateTime.now(),
    );

    state = AsyncData(updatedEintrag);

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (pauseMinuten != null) updates['pause_minuten'] = pauseMinuten;
    if (krankheitstage != null) updates['krankheitstage'] = krankheitstage;
    if (urlaubstage != null) updates['urlaubstage'] = urlaubstage;

    try {
      await Supabase.instance.client
          .from('eintraege')
          .update(updates)
          .eq('id', currentEintrag.id!);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> nextWeek() async {
    final currentEintrag = state.value;
    if (currentEintrag == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final newVonDatum = currentEintrag.bisDatum.add(const Duration(days: 1));
    final newBisDatum = newVonDatum.add(const Duration(days: 6));

    final newEintrag = Eintrag(
      userId: user.id,
      ausbildungsjahr: currentEintrag.ausbildungsjahr, 
      vonDatum: newVonDatum,
      bisDatum: newBisDatum,
      betriebliches: const [],
      schulisches: const [],
      pauseMinuten: 30, 
      krankheitstage: 0,
      urlaubstage: 0,
    );
    
    state = const AsyncLoading();

    try {
      final insertResponse = await Supabase.instance.client
          .from('eintraege')
          .insert(newEintrag.toJson())
          .select()
          .single();

      state = AsyncData(Eintrag.fromJson(insertResponse));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final eintraegeProvider = AsyncNotifierProvider<EintraegeNotifier, Eintrag>(
  EintraegeNotifier.new,
);

Future<List<Eintrag>> fetchEintraegeInRange(DateTime von, DateTime bis) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) {
    return [];
  }

  final response = await client
      .from('eintraege')
      .select()
      .eq('user_id', user.id)
      .gte('von_datum', von.toIso8601String())
      .lte('bis_datum', bis.toIso8601String())
      .order('von_datum', ascending: true);

  return (response as List)
      .map((row) => Eintrag.fromJson(row as Map<String, dynamic>))
      .toList();
}

Future<DateTime?> fetchLatestBisDatum() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) {
    return null;
  }

  final response = await client
      .from('eintraege')
      .select('bis_datum')
      .eq('user_id', user.id)
      .order('bis_datum', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response == null) {
    return null;
  }

  return DateTime.parse(response['bis_datum'] as String);
}
