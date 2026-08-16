import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/transaction_model.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/store_context.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  
  List<Transaction> _transactions = [];
  List<InstallmentPayment> _allInstallments = [];
  List<HoldOrder> _holdOrders = [];
  List<StockEntry> _stockEntries = [];
  List<StockOpnameEntry> _stockOpnames = [];
  bool _isLoading = true;

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<Transaction> get transactions => _transactions;
  List<Transaction> get salesTransactions => _transactions.where((t) => t.type == 'sale').toList();
  List<Transaction> get purchaseTransactions => _transactions.where((t) => t.type == 'purchase').toList();
  List<InstallmentPayment> get allInstallments => _allInstallments;
  List<HoldOrder> get holdOrders => _holdOrders;
  List<StockEntry> get stockEntries => _stockEntries;
  List<StockOpnameEntry> get stockOpnames => _stockOpnames;
  bool get isLoading => _isLoading;

  final List<StreamSubscription> _subs = [];
  StreamSubscription? _txSub;
  StreamSubscription? _storeSub;

  TransactionProvider() {
    final now = DateTime.now();
    _filterStartDate = DateTime(now.year, now.month, 1);
    
    _storeSub = StoreContext().storeIdStream.listen((storeId) {
      _cancelSubs();
      if (storeId == null) {
        _transactions = [];
        _allInstallments = [];
        _holdOrders = [];
        _stockEntries = [];
        _stockOpnames = [];
        _isLoading = true;
        notifyListeners();
      } else {
        _initSubs();
      }
    });

    if (StoreContext().storeIdOrNull != null) {
      _initSubs();
    }
  }

  void _initSubs() {
    _startTransactionStream();

    _subs.add(_transactionService.streamHoldOrders().listen((orders) {
      _holdOrders = orders;
      notifyListeners();
    }));

    _subs.add(_transactionService.streamStockEntries().listen((entries) {
      _stockEntries = entries;
      notifyListeners();
    }));

    _subs.add(_transactionService.streamStockOpnames().listen((entries) {
      _stockOpnames = entries;
      notifyListeners();
    }));

    _subs.add(_transactionService.streamAllInstallments().listen((installments) {
      _allInstallments = installments;
      notifyListeners();
    }));
  }

  void _cancelSubs() {
    _txSub?.cancel();
    for (var sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  void _startTransactionStream() {
    _txSub?.cancel();
    _isLoading = true;
    notifyListeners();
    
    _txSub = _transactionService
        .streamTransactions(startDate: _filterStartDate, endDate: _filterEndDate)
        .listen((transactions) {
      _transactions = transactions;
      _isLoading = false;
      notifyListeners();
    });
  }

  void setDateRangeFilter({DateTime? startDate, DateTime? endDate}) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _startTransactionStream();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionService.addTransaction(transaction);
  }

  Future<void> saveHoldOrder(HoldOrder order) async {
    await _transactionService.saveHoldOrder(order);
  }

  Future<void> deleteHoldOrder(String id) async {
    await _transactionService.deleteHoldOrder(id);
  }

  Future<void> addStockEntry(StockEntry entry) async {
    await _transactionService.addStockEntry(entry);
  }

  Future<void> addStockOpname(StockOpnameEntry entry) async {
    await _transactionService.addStockOpname(entry);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionService.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionService.deleteTransaction(id);
  }

  Future<void> addInstallment(String txId, InstallmentPayment installment) async {
    await _transactionService.addInstallment(txId, installment);
  }

  Stream<List<InstallmentPayment>> streamInstallments(String txId) {
    return _transactionService.streamInstallments(txId);
  }

  @override
  void dispose() {
    _cancelSubs();
    _storeSub?.cancel();
    super.dispose();
  }
}
