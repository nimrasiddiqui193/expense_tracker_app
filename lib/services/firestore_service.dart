import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to access your data.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _transactions {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions');
  }

  CollectionReference<Map<String, dynamic>> get _monthlyBudgets {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('monthly_budgets');
  }

  // ---------------- TRANSACTIONS ----------------

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

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTransactions() {
    return _transactions.orderBy('date', descending: true).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getTransactions() async {
    return _transactions.orderBy('date', descending: true).get();
  }

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

  Future<void> deleteTransaction(String transactionId) async {
    await _transactions.doc(transactionId).delete();
  }

  // ---------------- MONTHLY BUDGETS ----------------

  // Use a stable document ID for each month, such as 2026-11.
  String _monthId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Get the budget saved for a particular month.
  Future<double?> getMonthlyBudget(DateTime month) async {
    final document = await _monthlyBudgets.doc(_monthId(month)).get();

    if (!document.exists) {
      return null;
    }

    final amount = document.data()?['amount'];
    return amount is num ? amount.toDouble() : null;
  }

  // Save this month's budget without changing any previous month's budget.
  Future<void> saveMonthlyBudget({
    required DateTime month,
    required double amount,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Budget must be greater than zero.');
    }

    final document = _monthlyBudgets.doc(_monthId(month));

    await document.set({
      'month': _monthId(month),
      'amount': amount,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Listen to all saved monthly budgets, newest month first.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMonthlyBudgets() {
    return _monthlyBudgets.orderBy('month', descending: true).snapshots();
  }
}
