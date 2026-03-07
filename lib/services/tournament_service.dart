import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TournamentService {
  TournamentService._();

  static final TournamentService instance = TournamentService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<User> ensureUser() async {
    User? user = _auth.currentUser;
    if (user == null) {
      final credential = await _auth.signInAnonymously();
      user = credential.user;
    }
    user ??= _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'Unable to get current user',
      );
    }

    // Ensure user document with default balance
    final userRef = _firestore.collection('users').doc(user.uid);
    final snap = await userRef.get();
    if (!snap.exists) {
      await userRef.set({
        'balance': 500.0, // default starting money
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return user;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> tournamentsStream() {
    return _firestore
        .collection('tournaments')
        .orderBy('startTime', descending: false)
        .snapshots();
  }

  Future<void> createOrUpdateTournament({
    String? id,
    required String title,
    required String prize,
    required String entryFee,
    required String perKill,
    required String type,
    required String map,
    required String version,
    required int totalSlots,
    required String timeLabel,
    bool isMega = false,
    bool isFeatured = false,
    bool isUpcoming = true,
  }) async {
    final docRef =
        id == null ? _firestore.collection('tournaments').doc() : _firestore.collection('tournaments').doc(id);

    await docRef.set({
      'title': title,
      'prize': prize,
      'entryFee': entryFee,
      'perKill': perKill,
      'type': type,
      'map': map,
      'version': version,
      'totalSlots': totalSlots,
      'joinedPlayers': 0,
      'timeLabel': timeLabel,
      'isMega': isMega,
      'isFeatured': isFeatured,
      'isUpcoming': isUpcoming,
      'startTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateTournamentFlags(
    String id, {
    bool? isMega,
    bool? isFeatured,
    bool? isUpcoming,
  }) async {
    final data = <String, dynamic>{};
    if (isMega != null) data['isMega'] = isMega;
    if (isFeatured != null) data['isFeatured'] = isFeatured;
    if (isUpcoming != null) data['isUpcoming'] = isUpcoming;
    if (data.isEmpty) return;
    await _firestore.collection('tournaments').doc(id).update(data);
  }

  Future<void> joinTournament(String tournamentId, String inGameName, String phoneNumber) async {
    final user = await ensureUser();
    final userId = user.uid;

    final tournamentRef =
        _firestore.collection('tournaments').doc(tournamentId);

    await _firestore.runTransaction((tx) async {
      final tournamentSnap = await tx.get(tournamentRef);
      if (!tournamentSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Tournament not found',
        );
      }

      // Check for duplicate registration
      final regRef = tournamentRef.collection('registrations').doc(userId);
      final regSnap = await tx.get(regRef);
      if (regSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'ALREADY_JOINED',
        );
      }

      final tData = tournamentSnap.data() ?? {};
      final entryFeeStr = (tData['entryFee'] ?? '0').toString();
      final entryAmount = _parseEntryAmount(entryFeeStr);

      final userRef = _firestore.collection('users').doc(userId);
      final userSnap = await tx.get(userRef);
      final balanceRaw = userSnap.data()?['balance'] ?? 0;
      final currentBalance = (balanceRaw is int)
          ? balanceRaw.toDouble()
          : (balanceRaw as num).toDouble();

      if (entryAmount > currentBalance) {
        throw FirebaseException(
          plugin: 'wallet',
          message: 'INSUFFICIENT_FUNDS',
        );
      }

      // Deduct entry fee and update user doc
      tx.set(
        userRef,
        {
          'balance': currentBalance - entryAmount,
          'lastJoinedTournamentId': tournamentId,
          'phoneNumber': phoneNumber, // Update the user's latest phone number
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Create / update registration
      tx.set(
        regRef,
        {
          'userId': userId,
          'inGameName': inGameName,
          'phoneNumber': phoneNumber,
          'joinedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Increment joinedPlayers count
      tx.set(
        tournamentRef,
        {
          'joinedPlayers': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    });
  }

  Stream<List<Map<String, dynamic>>> myTournamentsStream() {
    return _firestore
        .collectionGroup('registrations')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> results = [];
      for (var doc in snapshot.docs) {
        // The parent of a registration doc is the 'registrations' collection.
        // The parent of that collection is the tournament document.
        final tournamentRef = doc.reference.parent.parent;
        if (tournamentRef != null) {
          final tournamentSnap = await tournamentRef.get();
          if (tournamentSnap.exists) {
            final tData = tournamentSnap.data() as Map<String, dynamic>;
            tData['id'] = tournamentSnap.id;
            // Also include registration time if needed
            tData['joinedAt'] = doc.data()['joinedAt'];
            results.add(tData);
          }
        }
      }
      return results;
    });
  }

  /// Stream of current user's wallet balance (from Firestore users/{uid}).
  /// Returns null if not logged in; otherwise balance as double.
  Stream<double> balanceStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0.0);
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return 0.0;
          final raw = snap.data()?['balance'];
          if (raw == null) return 0.0;
          if (raw is int) return raw.toDouble();
          return (raw as num).toDouble();
        });
  }

  /// Add amount to current user's balance (e.g. after buying credits in shop).
  Future<void> addBalance(double amount) async {
    final user = await ensureUser();
    final ref = _firestore.collection('users').doc(user.uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final raw = snap.data()?['balance'] ?? 0;
      final current = (raw is int) ? raw.toDouble() : (raw as num).toDouble();
      tx.set(
        ref,
        {
          'balance': current + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}

double _parseEntryAmount(String entry) {
  final cleaned = entry.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return 0;
  return double.tryParse(cleaned) ?? 0;
}

