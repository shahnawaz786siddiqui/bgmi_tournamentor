import 'dart:async';
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
        'balance': 0.0,
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
    String status = 'UPCOMING',
    String? imageUrl,
    String? mapImageUrl,
  }) async {
    final docRef =
        id == null ? _firestore.collection('tournaments').doc() : _firestore.collection('tournaments').doc(id);

    final Map<String, dynamic> data = {
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
      'status': status,
      'startTime': FieldValue.serverTimestamp(),
    };
    if (imageUrl != null && imageUrl.isNotEmpty) data['imageUrl'] = imageUrl;
    if (mapImageUrl != null && mapImageUrl.isNotEmpty) data['mapImageUrl'] = mapImageUrl;

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<void> updateTournamentFlags(
    String id, {
    bool? isMega,
    bool? isFeatured,
    bool? isUpcoming,
    String? status,
    String? imageUrl,
    String? mapImageUrl,
  }) async {
    final data = <String, dynamic>{};
    if (isMega != null) data['isMega'] = isMega;
    if (isFeatured != null) data['isFeatured'] = isFeatured;
    if (isUpcoming != null) data['isUpcoming'] = isUpcoming;
    if (status != null) data['status'] = status;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (mapImageUrl != null) data['mapImageUrl'] = mapImageUrl;
    if (data.isEmpty) return;
    await _firestore.collection('tournaments').doc(id).update(data);
  }

  Future<void> deleteTournament(String id) async {
    await _firestore.collection('tournaments').doc(id).delete();
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
          'registeredTournaments': FieldValue.arrayUnion([tournamentId]),
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
    final userId = _auth.currentUser?.uid;
    print('MY_MATCHES_DEBUG: myTournamentsStream called, userId=$userId');
    if (userId == null) {
      print('MY_MATCHES_DEBUG: userId is null, returning empty stream');
      return Stream.value([]);
    }

    final userStream = _firestore.collection('users').doc(userId).snapshots();
    final tournamentsStream = _firestore.collection('tournaments').snapshots();

    late StreamController<List<Map<String, dynamic>>> controller;
    DocumentSnapshot<Map<String, dynamic>>? latestUser;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> latestTournaments = [];
    bool userReady = false;
    bool tournamentsReady = false;

    StreamSubscription? userSub;
    StreamSubscription? tournamentSub;

    void emit() {
      if (!userReady || !tournamentsReady) return;
      if (controller.isClosed) return;
      try {
        // Get registered IDs from latest user doc
        List<String> registeredIds = [];
        if (latestUser != null && latestUser!.exists) {
          final data = latestUser!.data();
          print('MY_MATCHES_DEBUG: User doc data keys: ${data?.keys.toList()}');
          print('MY_MATCHES_DEBUG: registeredTournaments raw: ${data?['registeredTournaments']}');
          if (data != null && data.containsKey('registeredTournaments')) {
            registeredIds = List<String>.from(data['registeredTournaments'] ?? []);
          }
        } else {
          print('MY_MATCHES_DEBUG: User doc does not exist or is null');
        }

        print('MY_MATCHES_DEBUG: registeredIds=$registeredIds');
        print('MY_MATCHES_DEBUG: total tournaments in DB=${latestTournaments.length}');

        // Build a map of all tournaments
        final Map<String, Map<String, dynamic>> cache = {};
        for (final doc in latestTournaments) {
          final d = Map<String, dynamic>.from(doc.data());
          d['id'] = doc.id;
          cache[doc.id] = d;
        }

        // Return only the tournaments this user has registered for
        final result = registeredIds
            .where((id) => cache.containsKey(id))
            .map((id) => cache[id]!)
            .toList();

        print('MY_MATCHES_DEBUG: final result count=${result.length}');
        for (final r in result) {
          print('MY_MATCHES_DEBUG: match title=${r['title']}, status=${r['status']}');
        }

        controller.add(result);
      } catch (e) {
        print('MY_MATCHES_DEBUG: emit error: $e');
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        print('MY_MATCHES_DEBUG: StreamController onListen called');
        userSub = userStream.listen(
          (snap) {
            latestUser = snap;
            userReady = true;
            emit();
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
        );
        tournamentSub = tournamentsStream.listen(
          (snap) {
            latestTournaments = snap.docs;
            tournamentsReady = true;
            emit();
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
        );
      },
      onCancel: () {
        userSub?.cancel();
        tournamentSub?.cancel();
      },
    );

    return controller.stream;
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

  /// Submit a withdrawal request — deducts balance & writes a Pending payout doc atomically.
  /// Submit a withdrawal request — deducts balance & writes a Pending payout doc atomically.
  Future<void> requestWithdrawal({
    required double amount,
    required String upiOrPhone,
    required String paymentMethod,
    String? accountNumber,
    String? ifscCode,
  }) async {
    final user = await ensureUser();
    final uid = user.uid;

    final userRef = _firestore.collection('users').doc(uid);
    final payoutRef = _firestore.collection('payouts').doc();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final raw = snap.data()?['balance'] ?? 0;
      final current = (raw is int) ? raw.toDouble() : (raw as num).toDouble();

      if (amount < 50) {
        throw FirebaseException(
          plugin: 'wallet',
          message: 'MINIMUM_WITHDRAWAL',
        );
      }

      if (amount > current) {
        throw FirebaseException(
          plugin: 'wallet',
          message: 'INSUFFICIENT_FUNDS',
        );
      }

      // Deduct balance
      tx.update(userRef, {
        'balance': current - amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create payout request
      final userName = snap.data()?['name'] ?? 'Unknown';
      
      final Map<String, dynamic> payoutData = {
        'userId': uid,
        'userName': userName,
        'amount': amount,
        'phoneNumber': upiOrPhone,
        'paymentMethod': paymentMethod,
        'status': 'Pending',
        'requestedAt': FieldValue.serverTimestamp(),
      };
      
      if (accountNumber != null && accountNumber.isNotEmpty) {
        payoutData['accountNumber'] = accountNumber;
      }
      if (ifscCode != null && ifscCode.isNotEmpty) {
        payoutData['ifscCode'] = ifscCode;
      }
      
      tx.set(payoutRef, payoutData);
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

