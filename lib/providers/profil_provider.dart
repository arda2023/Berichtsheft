import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profil.dart';

class ProfilNotifier extends AsyncNotifier<Profil> {
  @override
  FutureOr<Profil> build() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final response = await client
        .from('profil')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      return Profil.fromJson(response);
    } else {
      const defaultProfil = Profil();
      final insertData = {
        'user_id': user.id,
        ...defaultProfil.toJson(),
      };

      final insertResponse = await client
          .from('profil')
          .insert(insertData)
          .select()
          .single();

      return Profil.fromJson(insertResponse);
    }
  }

  Future<void> updateProfil(Profil updated) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final profilToSave = updated.copyWith(updatedAt: now);

    // Optimistic update
    state = AsyncData(profilToSave);

    try {
      final data = {
        'user_id': user.id,
        ...profilToSave.toJson(),
      };
      await Supabase.instance.client.from('profil').upsert(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final profilProvider =
    AsyncNotifierProvider<ProfilNotifier, Profil>(ProfilNotifier.new);
