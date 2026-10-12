import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';

dynamic unwrap(String raw) {
  final dynamic b = jsonDecode(raw);
  if (b is! Map) return b;
  if (!b.containsKey('identical_code') || b['content'] == null) return b;
  return b['content'];
}

/// Reproduces the reads HistoryItemWidget performs, to prove the row can be built.
String renderRow(Transaction t, {required bool fromWallet}) {
  if (fromWallet) {
    final double amount = (t.transactionType == 'order_place' || t.transactionType == 'partial_payment')
        ? (t.debit ?? 0) + (t.adminBonus ?? 0)
        : (t.credit ?? 0) + (t.adminBonus ?? 0);
    return '$amount | ${(t.transactionType ?? '')} | ${t.createdAt}';
  }
  final String points = t.transactionType == 'point_to_wallet'
      ? '-${(t.debit ?? 0).toStringAsFixed(0)}'
      : '+${(t.credit ?? 0).toStringAsFixed(0)}';
  return '$points | ${(t.transactionType ?? '')} | ${t.createdAt}';
}

void main() {
  // Live GET /api/v1/customer/loyalty-point/transactions?offset=1&limit=10
  const String loyaltyLive = r'''
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
{"credit":15,"debit":0,"transaction_type":"order_place","reference":"102292","created_at":"2026-03-10 09:23:33"},
{"credit":6,"debit":0,"transaction_type":"order_place","reference":"102957","created_at":"2026-07-15 00:21:59"},
{"credit":0,"debit":50,"transaction_type":"point_to_wallet","reference":"x","created_at":"2026-07-15 00:09:14"}],
"pagination":{"current_page":1,"last_page":3,"per_page":10,"total":28,"from":1,"to":10}},"errors":[]}''';

  // Live GET /api/v1/customer/wallet/transactions?offset=1&limit=5
  const String walletLive = r'''
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
{"credit":0,"debit":95.89,"admin_bonus":0,"transaction_type":"partial_payment","reference":"102575","created_at":"2026-05-07 13:12:40"},
{"credit":100,"debit":0,"admin_bonus":5,"transaction_type":"add_fund","reference":"ssl_commerz","created_at":"2026-05-07 13:00:00"}],
"pagination":{"current_page":1,"last_page":2,"per_page":5,"total":9,"from":1,"to":5}},"errors":[]}''';

  // The legacy flat shape, to prove nothing regressed for a backend still sending it.
  const String legacy = r'''
{"total_size":42,"limit":"10","offset":"1","data":[
{"user_id":21,"transaction_id":"TX1","credit":10,"debit":0,"admin_bonus":1,"balance":500,
 "transaction_type":"add_fund","reference":"ssl","created_at":"2026-01-01 10:00:00","updated_at":"2026-01-02 11:00:00"}]}''';

  test('loyalty transactions parse (previously threw on row 0)', () {
    final TransactionModel m = TransactionModel.fromJson(unwrap(loyaltyLive) as Map<String, dynamic>);
    expect(m.data, isNotNull);
    expect(m.data!.length, 3);
    // pagination now comes from `pagination`
    expect(m.totalSize, 28, reason: 'was null, so the list could not page');
    expect(m.limit, '10');
    expect(m.offset, '1');

    final Transaction first = m.data!.first;
    expect(first.credit, 15.0);
    expect(first.debit, 0.0);
    expect(first.transactionType, 'order_place');
    expect(first.reference, '102292');
    expect(first.createdAt, DateTime(2026, 3, 10, 9, 23, 33));
    // absent fields resolve to null instead of throwing
    expect(first.balance, isNull);
    expect(first.updatedAt, isNull);
    expect(first.adminBonus, isNull);
    expect(first.userId, isNull);

    for (final Transaction t in m.data!) {
      expect(() => renderRow(t, fromWallet: false), returnsNormally);
    }
    expect(renderRow(m.data![0], fromWallet: false), startsWith('+15'));
    expect(renderRow(m.data![2], fromWallet: false), startsWith('-50'));
  });

  test('wallet transactions parse and render (same model, same crash)', () {
    final TransactionModel m = TransactionModel.fromJson(unwrap(walletLive) as Map<String, dynamic>);
    expect(m.data!.length, 2);
    expect(m.totalSize, 9);
    expect(m.data![0].adminBonus, 0.0);
    expect(m.data![0].debit, 95.89);
    expect(m.data![0].balance, isNull, reason: 'wallet no longer sends balance either');
    expect(m.data![1].adminBonus, 5.0);
    for (final Transaction t in m.data!) {
      expect(() => renderRow(t, fromWallet: true), returnsNormally);
    }
  });

  test('legacy flat shape is unchanged', () {
    final TransactionModel m = TransactionModel.fromJson(unwrap(legacy) as Map<String, dynamic>);
    expect(m.totalSize, 42);
    expect(m.limit, '10');
    expect(m.offset, '1');
    final Transaction t = m.data!.single;
    expect(t.userId, 21);
    expect(t.transactionId, 'TX1');
    expect(t.balance, 500.0);
    expect(t.adminBonus, 1.0);
    expect(t.createdAt, DateTime(2026, 1, 1, 10, 0, 0));
    expect(t.updatedAt, DateTime(2026, 1, 2, 11, 0, 0));
  });

  test('hostile rows do not take the list down', () {
    final TransactionModel m = TransactionModel.fromJson(<String, dynamic>{
      'data': <dynamic>[
        <String, dynamic>{},                                              // everything absent
        <String, dynamic>{'credit': '12.5', 'created_at': 'garbage'},      // string number, bad date
        <String, dynamic>{'credit': 3, 'created_at': '2026-07-15T00:21:59.000000Z'}, // ISO date
      ],
    });
    expect(m.data!.length, 3);
    expect(m.data![0].credit, isNull);
    expect(m.data![1].credit, 12.5);
    expect(m.data![1].createdAt, isNull);
    expect(m.data![2].createdAt, isNotNull);
    expect(m.totalSize, isNull);
    for (final Transaction t in m.data!) {
      expect(() => renderRow(t, fromWallet: false), returnsNormally);
      expect(() => renderRow(t, fromWallet: true), returnsNormally);
    }
  });

  test('toJson survives the trimmed payload', () {
    final TransactionModel m = TransactionModel.fromJson(unwrap(loyaltyLive) as Map<String, dynamic>);
    expect(() => m.toJson(), returnsNormally, reason: 'createdAt!/updatedAt! used to throw here too');
    expect(m.toJson()['data'], isA<List<dynamic>>());
  });
}
