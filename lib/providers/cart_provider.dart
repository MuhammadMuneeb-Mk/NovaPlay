import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartProvider extends ChangeNotifier {
  Set<int> _itemIds = {};

  Set<int> get itemIds => _itemIds;
  int get itemCount => _itemIds.length;

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('cart');
    if (saved != null) {
      final List<int> decoded = List<int>.from(jsonDecode(saved));
      _itemIds = decoded.toSet();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final List<int> list = _itemIds.toList();
    await prefs.setString('cart', jsonEncode(list));
  }

  bool isInCart(int gameId) => _itemIds.contains(gameId);

  void addToCart(int gameId) {
    if (!_itemIds.contains(gameId)) {
      _itemIds.add(gameId);
      _saveCart();
      notifyListeners();
    }
  }

  void removeFromCart(int gameId) {
    if (_itemIds.remove(gameId)) {
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _itemIds.clear();
    _saveCart();
    notifyListeners();
  }
}