import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      items = json.decode(p.getString('inv_d') ?? '[]');
    });
  }

  void _saveItems() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('inv_d', json.encode(items));
  }

  void _addItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नया सामान जोड़ें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'सामान / किताब का नाम *')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'बिक्री मूल्य (₹) *'), keyboardType: TextInputType.number),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'स्टॉक मात्रा (संख्या)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                setState(() {
                  items.insert(0, {
                    'name': nameCtrl.text,
                    'price': double.tryParse(priceCtrl.text) ?? 0.0,
                    'qty': int.tryParse(qtyCtrl.text) ?? 1,
                  });
                });
                _saveItems();
                Navigator.pop(ctx);
              }
            },
            child: const Text('सेव करें'),
          ),
        ],
      ),
    );
  }

  void _updateQty(int index, int delta) {
    setState(() {
      int current = (items[index]['qty'] as num?)?.toInt() ?? 0;
      int updated = current + delta;
      items[index]['qty'] = updated < 0 ? 0 : updated;
    });
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.orange.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('स्टेशनरी & बुक्स स्टॉक', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('कुल आइटम्स: ${items.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('कोई आइटम नहीं है। नीचे + दबाकर जोड़ें।'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final int qty = (item['qty'] as num?)?.toInt() ?? 0;
                    final bool isLow = qty <= 5;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLow ? Colors.red.shade100 : Colors.teal.shade100,
                          child: Icon(Icons.inventory_2, color: isLow ? Colors.red : Colors.teal),
                        ),
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('मूल्य: ₹${item['price']} | स्टॉक: $qty पीस', style: TextStyle(color: isLow ? Colors.red : Colors.black87, fontWeight: isLow ? FontWeight.bold : FontWeight.normal)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              tooltip: '1 बिका (-1)',
                              onPressed: () => _updateQty(i, -1),
                            ),
                            Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              tooltip: 'नया माल आया (+1)',
                              onPressed: () => _updateQty(i, 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                              onPressed: () {
                                setState(() => items.removeAt(i));
                                _saveItems();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: _addItemDialog,
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
