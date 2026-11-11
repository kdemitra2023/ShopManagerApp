import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class KhataScreen extends StatefulWidget {
  final String shopName;
  final String shopPhone;
  final Function(double) onShowQr;

  const KhataScreen({
    super.key,
    required this.shopName,
    required this.shopPhone,
    required this.onShowQr,
  });

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  List khata = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      khata = json.decode(p.getString('k_d') ?? '[]');
    });
  }

  void _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('k_d', json.encode(khata));
  }

  void _sendWa(String phone, String msg) async {
    final c = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final f = c.length == 10 ? '91$c' : c;
    if (f.isNotEmpty) {
      final u = Uri.parse('https://wa.me/$f?text=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    double due = 0;
    for (var k in khata) due += (k['a'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.indigo.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('कुल बकाया उधार:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₹$due', style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: khata.isEmpty
              ? const Center(child: Text('कोई उधार नहीं है।'))
              : ListView.builder(
                  itemCount: khata.length,
                  itemBuilder: (c, i) {
                    final it = khata[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('${it['n']} (₹${it['a']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${it['w']} | ${it['p']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.qr_code, color: Colors.purple), onPressed: () => widget.onShowQr((it['a'] as num).toDouble())),
                          IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _sendWa(it['p'], 'नमस्ते ${it['n']} जी, ${widget.shopName} का ₹${it['a']} बकाया है।')),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.blue),
                            onPressed: () {
                              _sendWa(it['p'], '🧾 *भुगतान रसीद*\nदुकान: ${widget.shopName}\nग्राहक: ${it['n']}\nरकम: ₹${it['a']} (PAID)\nधन्यवाद!');
                              setState(() => khata.removeAt(i));
                              _save();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            final n = TextEditingController(), p = TextEditingController(), w = TextEditingController(), a = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('नया उधार'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: n, decoration: const InputDecoration(labelText: 'नाम *')),
                  TextField(controller: p, decoration: const InputDecoration(labelText: 'मोबाइल')),
                  TextField(controller: w, decoration: const InputDecoration(labelText: 'काम')),
                  TextField(controller: a, decoration: const InputDecoration(labelText: 'रुपये *'), keyboardType: TextInputType.number),
                ]),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (n.text.isNotEmpty && a.text.isNotEmpty) {
                        setState(() => khata.add({'n': n.text, 'p': p.text, 'w': w.text, 'a': double.tryParse(a.text) ?? 0}));
                        _save();
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('जोड़ें'),
                  )
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
