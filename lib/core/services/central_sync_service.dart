import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SyncService(this._firestore, this._auth);


  Future<Map<String, dynamic>> getLatestUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Get current user from auth for fallback
        final currentUser = _auth.currentUser;

        return {
          'displayName': data['displayName'] ?? currentUser?.displayName ?? 'User',
          'photoUrl': data['photoUrl'] ?? currentUser?.photoURL,
          'email': data['email'] ?? currentUser?.email ?? '',
          'userId': userId,
        };
      } else {
        // Create user document if not exists
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          await _firestore.collection('users').doc(userId).set({
            'email': currentUser.email ?? '',
            'displayName': currentUser.displayName ?? currentUser.email?.split('@').first ?? 'User',
            'photoUrl': currentUser.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'pollsCreated': 0,
            'totalVotes': 0,
            'commentsCount': 0,
          });

          return {
            'displayName': currentUser.displayName ?? currentUser.email?.split('@').first ?? 'User',
            'photoUrl': currentUser.photoURL,
            'email': currentUser.email ?? '',
            'userId': userId,
          };
        }
      }
    } catch (e) {
      log('❌ Error getting latest user data: $e');
    }

    // Fallback to current auth user
    final currentUser = _auth.currentUser;
    return {
      'displayName': currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'User',
      'photoUrl': currentUser?.photoURL,
      'email': currentUser?.email ?? '',
      'userId': userId,
    };
  }

  Future<void> syncAllUserData(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) return;

      final userData = userSnapshot.data() as Map<String, dynamic>;

      // Sync user's polls
      await _syncUserPolls(userId, userData);

      // Update last sync timestamp
      await userDoc.update({
        'lastSynced': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> _syncUserPolls(String userId, Map<String, dynamic> userData) async {
    final pollsQuery = await _firestore
        .collection('polls')
        .where('creatorId', isEqualTo: userId)
        .get();

    for (final pollDoc in pollsQuery.docs) {
      final pollData = pollDoc.data();

      // Ensure poll has latest user data
      if (pollData['creatorName'] != userData['displayName'] ||
          pollData['creatorPhotoUrl'] != userData['photoUrl']) {

        await pollDoc.reference.update({
          'creatorName': userData['displayName'],
          'creatorPhotoUrl': userData['photoUrl'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> syncAfterProfileUpdate(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final userSnapshot = await userDoc.get();

    if (!userSnapshot.exists) return;

    final userData = userSnapshot.data() as Map<String, dynamic>;

    // Update all user's polls
    final batch = _firestore.batch();
    final pollsQuery = await _firestore
        .collection('polls')
        .where('creatorId', isEqualTo: userId)
        .get();

    for (final pollDoc in pollsQuery.docs) {
      batch.update(pollDoc.reference, {
        'creatorName': userData['displayName'],
        'creatorPhotoUrl': userData['photoUrl'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Update all user's comments
    final commentsQuery = await _firestore
        .collection('comments')
        .where('userId', isEqualTo: userId)
        .get();

    for (final commentDoc in commentsQuery.docs) {
      batch.update(commentDoc.reference, {
        'userName': userData['displayName'],
        'userPhotoUrl': userData['photoUrl'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }


  // 🔄 Sync user profile with Firestore Auth
  Future<void> syncAuthProfile(String userId) async {
    try {
      final userData = await getLatestUserData(userId);
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        await currentUser.updateProfile(
          displayName: userData['displayName'],
          photoURL: userData['photoUrl'],
        );
        await currentUser.reload();
        log('✅ Auth profile synced');
      }
    } catch (e) {
      log('❌ Error syncing auth profile: $e');
    }
  }
}