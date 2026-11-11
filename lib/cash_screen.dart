import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  List cash = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      cash = json.decode(p.getString('c_d') ?? '[]');
    });
  }

  void _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('c_d', json.encode(cash));
  }

  double _getBal(String ac) {
    double b = 0;
    for (var t in cash) {
      if (t['ac'] == ac) {
        double a = (t['a'] as num?)?.toDouble() ?? 0;
        b += (t['t'] == 'In' ? a : -a);
      }
    }
    return b;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          color: Colors.teal.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tile('गल्ला (Cash)', _getBal('Cash'), Colors.orange.shade800),
              _tile('SBI बैंक', _getBal('SBI'), Colors.blue.shade800),
              _tile('PNB बैंक', _getBal('PNB'), Colors.purple.shade800),
            ],
          ),
        ),
        Expanded(
          child: cash.isEmpty
              ? const Center(child: Text('आज कोई एंट्री नहीं है।'))
              : ListView.builder(
                  itemCount: cash.length,
                  itemBuilder: (c, i) {
                    final it = cash[i];
                    bool isIn = it['t'] == 'In';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIn ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: isIn ? Colors.green : Colors.red),
                      ),
                      title: Text('${it['m']} (${it['ac']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(it['d'] ?? ''),
                      trailing: Text(
                        '${isIn ? '+' : '-'} ₹${it['a']}',
                        style: TextStyle(color: isIn ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    );
                  },
                ),
        ),
        FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            final a = TextEditingController(), d = TextEditingController();
            String ac = 'Cash', t = 'In', m = 'ई-मित्र टोकन';
            final cats = ['ई-मित्र टोकन', 'फोटोकॉपी/प्रिंट', 'स्टेशनरी बिक्री', 'ऑनलाइन फॉर्म फीस', 'रिचार्ज/बिल', 'दुकान खर्च'];

            showDialog(
              context: context,
              builder: (ctx) => StatefulBuilder(
                builder: (ctx, setS) => AlertDialog(
                  title: const Text('दैनिक लेन-देन दर्ज करें'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: t,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'In', child: Text('आवक / कमाई (+)')),
                            DropdownMenuItem(value: 'Out', child: Text('खर्च / निकासी (-)')),
                          ],
                          onChanged: (v) => setS(() => t = v!),
                        ),
                        DropdownButton<String>(
                          value: m,
                          isExpanded: true,
                          items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setS(() => m = v!),
                        ),
                        DropdownButton<String>(
                          value: ac,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('गल्ला (Cash)')),
                            DropdownMenuItem(value: 'SBI', child: Text('SBI खाता')),
                            DropdownMenuItem(value: 'PNB', child: Text('PNB खाता')),
                          ],
                          onChanged: (v) => setS(() => ac = v!),
                        ),
                        TextField(controller: a, decoration: const InputDecoration(labelText: 'राशि (₹) *'), keyboardType: TextInputType.number),
                        TextField(controller: d, decoration: const InputDecoration(labelText: 'विवरण / टिप्पणी')),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द')),
                    ElevatedButton(
                      onPressed: () {
                        if (a.text.isNotEmpty) {
                          setState(() => cash.insert(0, {
                                'm': m,
                                'ac': ac,
                                't': t,
                                'a': double.tryParse(a.text) ?? 0.0,
                                'd': d.text,
                              }));
                          _save();
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('सेव करें'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _tile(String t, double amt, Color col) {
    return Column(
      children: [
        Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('₹$amt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: col)),
      ],
    );
  }
}
