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
  bool showHistory = false;

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

  // ग्राहक विवरण एडिट करने का डायलॉग
  void _editCustomerDialog(int originalIndex) {
    final item = khata[originalIndex];
    final nCtrl = TextEditingController(text: item['n'] ?? '');
    final pCtrl = TextEditingController(text: item['p'] ?? '');
    final wCtrl = TextEditingController(text: item['w'] ?? '');
    final aCtrl = TextEditingController(text: (item['a'] ?? '').toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ग्राहक विवरण सुधारें (Edit)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'ग्राहक का नाम *')),
              TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'मोबाइल नंबर'), keyboardType: TextInputType.phone),
              TextField(controller: wCtrl, decoration: const InputDecoration(labelText: 'काम / विवरण')),
              TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'बाकी रकम (₹) *'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () {
              if (nCtrl.text.isNotEmpty && aCtrl.text.isNotEmpty) {
                setState(() {
                  khata[originalIndex]['n'] = nCtrl.text;
                  khata[originalIndex]['p'] = pCtrl.text;
                  khata[originalIndex]['w'] = wCtrl.text;
                  khata[originalIndex]['a'] = double.tryParse(aCtrl.text) ?? 0.0;
                });
                _save();
                Navigator.pop(ctx);
              }
            },
            child: const Text('अपडेट करें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = khata.where((k) => (k['st'] ?? 'PENDING') == 'PENDING').toList();
    final paidList = khata.where((k) => (k['st'] ?? 'PENDING') == 'PAID').toList();

    double due = 0;
    for (var k in pendingList) {
      due += (k['a'] as num?)?.toDouble() ?? 0;
    }

    final activeList = showHistory ? paidList : pendingList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(showHistory ? 'कुल चुकता रिकॉर्ड:' : 'कुल बकाया उधार:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(
                    showHistory ? '${paidList.length} ग्राहक' : '₹$due',
                    style: TextStyle(fontSize: 20, color: showHistory ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: showHistory ? Colors.indigo : Colors.green.shade800,
                  side: BorderSide(color: showHistory ? Colors.indigo : Colors.green.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(showHistory ? Icons.arrow_back : Icons.history, size: 18),
                label: Text(showHistory ? 'बकाया देखें' : 'चुकता हिस्ट्री (${paidList.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => showHistory = !showHistory),
              ),
            ],
          ),
        ),
        Expanded(
          child: activeList.isEmpty
              ? Center(
                  child: Text(
                    showHistory ? 'कोई चुकता रिकॉर्ड मौजूद नहीं है।' : 'कोई उधार बकाया नहीं है। नीचे + से नया जोड़ें।',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: activeList.length,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemBuilder: (c, i) {
                    final it = activeList[i];
                    final originalIndex = khata.indexOf(it);
                    final bool isPaid = (it['st'] ?? 'PENDING') == 'PAID';

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? Colors.green.shade100 : Colors.indigo.shade50,
                          child: Icon(isPaid ? Icons.check : Icons.person, color: isPaid ? Colors.green.shade800 : Colors.indigo),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text('${it['n']} (₹${it['a']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            if (!isPaid)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                                tooltip: 'एडिट करें',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                onPressed: () => _editCustomerDialog(originalIndex),
                              ),
                          ],
                        ),
                        subtitle: Text('${it['w']} | 📞 ${it['p']}\nदिनांक: ${it['d'] ?? ''} ${isPaid ? '• [PAID]' : ''}', style: const TextStyle(fontSize: 11)),
                        isThreeLine: true,
                        trailing: isPaid
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                tooltip: 'हिस्ट्री से हटाएं',
                                onPressed: () {
                                  setState(() => khata.removeAt(originalIndex));
                                  _save();
                                },
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.qr_code, color: Colors.purple, size: 22),
                                    tooltip: 'QR दिखाएं',
                                    onPressed: () => widget.onShowQr((it['a'] as num).toDouble()),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: Colors.green, size: 22),
                                    tooltip: 'WhatsApp तकाजा',
                                    onPressed: () => _sendWa(it['p'], 'नमस्ते ${it['n']} जी, ${widget.shopName} का ₹${it['a']} बकाया है। कृपया समय पर भुगतान करें।'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.blue, size: 24),
                                    tooltip: 'चुकता करें (Clear)',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('उधार चुकता करें?'),
                                          content: Text('${it['n']} जी से ₹${it['a']} प्राप्त हो गए हैं? यह रिकॉर्ड हिस्ट्री में सुरक्षित रहेगा।'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _sendWa(it['p'], '🧾 *भुगतान पावती (Payment Receipt)*\n🏪 *${widget.shopName}*\nग्राहक: ${it['n']}\nविवरण: ${it['w']}\nप्राप्त रकम: ₹${it['a']}\nस्थिति: पूर्ण चुकता (PAID)\nदिनांक: ${DateTime.now().toString().split(' ')[0]}\nधन्यवाद!');
                                                setState(() {
                                                  khata[originalIndex]['st'] = 'PAID';
                                                  khata[originalIndex]['paid_date'] = DateTime.now().toString().split(' ')[0];
                                                });
                                                _save();
                                              },
                                              child: const Text('हाँ, चुकता करें & रसीद भेजें'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
        ),
        if (!showHistory)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('नया उधार जोड़ें'),
                onPressed: () {
                  final n = TextEditingController(), p = TextEditingController(), w = TextEditingController(), a = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('नया उधार दर्ज करें'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: n, decoration: const InputDecoration(labelText: 'ग्राहक का नाम *')),
                          TextField(controller: p, decoration: const InputDecoration(labelText: 'मोबाइल नंबर'), keyboardType: TextInputType.phone),
                          TextField(controller: w, decoration: const InputDecoration(labelText: 'काम (फॉर्म / प्रिंट / स्टेशनरी)')),
                          TextField(controller: a, decoration: const InputDecoration(labelText: 'रुपये (₹) *'), keyboardType: TextInputType.number),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
                        ElevatedButton(
                          onPressed: () {
                            if (n.text.isNotEmpty && a.text.isNotEmpty) {
                              setState(() => khata.insert(0, {
                                    'n': n.text,
                                    'p': p.text,
                                    'w': w.text,
                                    'a': double.tryParse(a.text) ?? 0,
                                    'd': DateTime.now().toString().split(' ')[0],
                                    'st': 'PENDING',
                                  }));
                              _save();
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text('सेव करें'),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
