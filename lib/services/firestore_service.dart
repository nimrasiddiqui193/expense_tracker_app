import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Get the currently signed-in user's ID.
  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to access transactions.');
    }

    return user.uid;
  }

  // Reference to the current user's transactions collection.
  CollectionReference<Map<String, dynamic>> get _transactions {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions');
  }

  // Add a new income or expense transaction.
  Future<String> addTransaction(Map<String, dynamic> transaction) async {
    final data = Map<String, dynamic>.from(transaction);

    final date = data['date'];

    if (date is DateTime) {
      data['date'] = Timestamp.fromDate(date);
    }

    data['createdAt'] = FieldValue.serverTimestamp();

    final document = await _transactions.add(data);

    return document.id;
  }

  // Stream transactions in real time, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamTransactions() {
    return _transactions.orderBy('date', descending: true).snapshots();
  }

  // Retrieve all transactions once.
  Future<QuerySnapshot<Map<String, dynamic>>> getTransactions() async {
    return await _transactions.orderBy('date', descending: true).get();
  }

  // Update an existing transaction without creating a duplicate.
  Future<void> updateTransaction(
    String transactionId,
    Map<String, dynamic> transaction,
  ) async {
    final data = Map<String, dynamic>.from(transaction);

    final date = data['date'];

    if (date is DateTime) {
      data['date'] = Timestamp.fromDate(date);
    }

    await _transactions.doc(transactionId).update(data);
  }

  // Permanently delete a transaction.
  Future<void> deleteTransaction(String transactionId) async {
    await _transactions.doc(transactionId).delete();
  }
}
