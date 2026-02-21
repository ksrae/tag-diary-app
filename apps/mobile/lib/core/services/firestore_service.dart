import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_service.g.dart';

enum SubscriptionPlan { free, basic, pro }

class UserProfile {
  final SubscriptionPlan plan;
  final int usedBytes;
  final int dailyAiCount; // Tracks how many times AI was used today. We should also store a date to reset this daily.
  final DateTime? lastAiUsedDate;
  final int extraCapacityGbs; // Users can add 1GB capacity for $0.99

  UserProfile({
    required this.plan,
    required this.usedBytes,
    required this.dailyAiCount,
    this.lastAiUsedDate,
    this.extraCapacityGbs = 0,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.toString() == 'SubscriptionPlan.${data['plan'] ?? 'free'}',
        orElse: () => SubscriptionPlan.free,
      ),
      usedBytes: data['usedBytes'] ?? 0,
      dailyAiCount: data['dailyAiCount'] ?? 0,
      lastAiUsedDate: data['lastAiUsedDate'] != null ? (data['lastAiUsedDate'] as Timestamp).toDate() : null,
      extraCapacityGbs: data['extraCapacityGbs'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan.toString().split('.').last,
      'usedBytes': usedBytes,
      'dailyAiCount': dailyAiCount,
      'lastAiUsedDate': lastAiUsedDate != null ? Timestamp.fromDate(lastAiUsedDate!) : null,
      'extraCapacityGbs': extraCapacityGbs,
    };
  }

  /// Calculates max allowed bytes based on plan and extra capacity.
  int get maxAllowedBytes {
    int maxGb = 0;
    if (plan == SubscriptionPlan.free) {
      maxGb = 0; // Free essentially has no 'hard' storage, but only keeps 3 days. 
    } else if (plan == SubscriptionPlan.basic) {
      maxGb = 1; // 1 GB
    } else if (plan == SubscriptionPlan.pro) {
      maxGb = 5; // 5 GB
    }
    return (maxGb + extraCapacityGbs) * 1024 * 1024 * 1024;
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserProfile?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromMap(snap.data()!);
    });
  }

  Future<void> createUserProfileIfNone(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(uid).set(
        UserProfile(plan: SubscriptionPlan.free, usedBytes: 0, dailyAiCount: 0).toMap(),
      );
    }
  }

  Future<void> updateUserPlan(String uid, SubscriptionPlan newPlan, int extraGbsAdded) async {
    await _db.collection('users').doc(uid).set({
      'plan': newPlan.toString().split('.').last,
      'extraCapacityGbs': FieldValue.increment(extraGbsAdded),
    }, SetOptions(merge: true));
  }

  /// To be called after uploading an image to adjust used capacity.
  Future<void> incrementUsedBytes(String uid, int bytesToAdd) async {
    await _db.collection('users').doc(uid).set({
      'usedBytes': FieldValue.increment(bytesToAdd),
    }, SetOptions(merge: true));
  }

  // --- Diary Operations ---
  Future<void> saveDiary(String uid, String diaryId, Map<String, dynamic> diaryData) async {
    await _db.collection('users').doc(uid).collection('diaries').doc(diaryId).set(
      diaryData,
      SetOptions(merge: true),
    );
  }

  Future<void> deleteDiary(String uid, String diaryId) async {
    await _db.collection('users').doc(uid).collection('diaries').doc(diaryId).delete();
  }

  Stream<List<Map<String, dynamic>>> streamDiaries(String uid) {
    return _db.collection('users').doc(uid).collection('diaries').orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((d) {
        var map = d.data();
        map['id'] = d.id;
        return map;
      }).toList();
    });
  }
}

@riverpod
FirestoreService firestoreService(FirestoreServiceRef ref) {
  return FirestoreService();
}

@riverpod
Stream<UserProfile?> userProfileStream(UserProfileStreamRef ref, String uid) {
  return ref.watch(firestoreServiceProvider).streamUserProfile(uid);
}
