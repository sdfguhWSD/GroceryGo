import 'package:flutter/material.dart';

class Order {
  final String id;
  final DateTime date;
  final double total;
  final List<Map<String, dynamic>> items;

  Order({
    required this.id,
    required this.date,
    required this.total,
    required this.items,
  });
}

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => _orders;

  void addOrder(double total, List<Map<String, dynamic>> items) {
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      total: total,
      items: items,
    );
    _orders.insert(0, order); // Newest order first
    notifyListeners();
  }
}
