import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    title: 'Sidharth Shop Manager',
    debugShowCheckedModeBanner: false,
    home: ShopMainView(),
  ));
}

class ShopMainView extends StatefulWidget {
  const ShopMainView({super.key});
  @override
  State<ShopMainView> createState() => _ShopMainViewState();
}

class _ShopMainViewState extends State<ShopMainView> {
  int _idx = 0;
  String shopName = 'Sidharth E-Mitra & Book Store';
  String shopAddress = 'नेताजी मार्केट, लूणकरणसर';
  String shopPhone = '9257161097';
  String shopUpi = '9257161097@sbi';

  List khata = [];
  List cash = [];
  List work = [];
  List sso = [];

  final Map<int, int> notes = {500: 0, 200: 0, 100: 0, 50: 0, 20: 0, 10: 0};
  final calcCtrl = TextEditingController();
  double aepsFee = 0.0, aepsTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      shopName = p.getString('sn') ?? shopName;
      shopAddress = p.getString('sa') ?? shopAddress;
      shopPhone = p.getString('sp') ?? shopPhone;
      shopUpi = p.getString('su') ?? shopUpi;
      khata = json.decode(p.getString('k_data') ?? '[]');
      cash = json.decode(p.getString('c_data') ?? '[]');
      work = json.decode(p.getString('w_data') ?? '[]');
      sso = json.decode(p.getString('s_data') ?? '[]');
    });
  }

  void _save(String k, dynamic val) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(k, json.encode(val));
  }

  void _openUrl(String link) async {
    final u = Uri.parse(link);
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  void _sendWa(String phone, String msg) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final num = clean.length == 10 ? '91$clean' : clean;
    if (num.isNotEmpty) {
      _openUrl('https://wa.me/$num?text=${Uri.encodeComponent(msg)}');
    }
  }

  void _showQr(double amt) {
    final u = 'upi://pay?pa=$shopUpi&pn=${Uri.encodeComponent(shopName)}&am=$amt&cu=INR';
    final img = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(u)}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(shopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('राशि: ₹$amt', style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
            Text('UPI ID: $shopUpi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Image.network(img, height: 180, width: 180, errorBuilder: (c, e, s) => const Text('QR एरर')),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('बंद करें'))],
      ),
    );
  }

  void _closingReport() {
    double cBal = 0, sbiBal = 0, pnbBal = 0, inc = 0, exp = 0;
    for (var t in cash) {
      double a = (t['amount'] as num?)?.toDouble() ?? 0.0;
      bool isIn = t['t'].toString().contains('In');
      if (isIn) {
        inc += a;
      } else {
        exp += a;
      }
      if (t['acc'] == 'Cash') cBal += isIn ? a : -a;
      if (t['acc'] == 'SBI') sbiBal += isIn ? a : -a;
      if (t['acc'] == 'PNB') pnbBal += isIn ? a : -a;
    }
    double due = 0;
    for (var k in khata) {
      due += (k['amount'] as num?)?.toDouble() ?? 0.0;
    }
    final r = '📊 *दुकान क्लोजिंग समरी*\n🏪 *$shopName*\n📍 $shopAddress\n--------------------\n💵 गल्ला कैश: ₹$cBal\n🏦 SBI: ₹$sbiBal\n🏦 PNB: ₹$pnbBal\n--------------------\n📈 आवक: ₹$inc | 📉 खर्च: ₹$exp\n📌 कुल उधार बकाया: ₹$due';
    _sendWa(shopPhone, r);
  }

  void _copyBackup() {
    StringBuffer b = StringBuffer();
    b.writeln('=== $shopName Backup ===\n-- UDHAT KHATA --\nनाम,फोन,काम,रकम');
    for (var k in khata) {
      b.writeln('${k['name']},${k['phone']},${k['work']},${k['amount']}');
    }
    b.writeln('\n-- CASH BOOK --\nमद,खाता,प्रकार,रकम');
    for (var c in cash) {
      b.writeln('${c['cat']},${c['acc']},${c['t']},${c['amount']}');
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('पूरा बैकअप कॉपी हो गया!')));
  }

  void _editProfile() {
    final n = TextEditingController(text: shopName);
    final a = TextEditingController(text: shopAddress);
    final p = TextEditingController(text: shopPhone);
    final u = TextEditingController(text: shopUpi);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('दुकान प्रोफाइल'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'दुकान का नाम')),
            TextField(controller: a, decoration: const InputDecoration(labelText: 'पता/मार्केट')),
            TextField(controller: p, decoration: const InputDecoration(labelText: 'मोबाइल नंबर')),
            TextField(controller: u, decoration: const InputDecoration(labelText: 'UPI ID')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final sp = await SharedPreferences.getInstance();
              await sp.setString('sn', n.text);
              await sp.setString('sa', a.text);
              await sp.setString('sp', p.text);
              await sp.setString('su', u.text);
              setState(() {
                shopName = n.text;
                shopAddress = a.text;
                shopPhone = p.text;
                shopUpi = u.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('सेव करें'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shopName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text('$shopAddress | 📞 $shopPhone', style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code), tooltip: 'दुकान QR', onPressed: () => _showQr(0.0)),
          IconButton(icon: const Icon(Icons.send_to_mobile), tooltip: 'WhatsApp समरी', onPressed: _closingReport),
          IconButton(icon: const Icon(Icons.copy), tooltip: 'डेटा बैकअप', onPressed: _copyBackup),
          IconButton(icon: const Icon(Icons.edit), tooltip: 'प्रोफ़ाइल', onPressed: _editProfile),
        ],
      ),
      body: _buildPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'खाता'),
          NavigationDestination(icon: Icon(Icons.account_balance), label: 'कैश/बैंक'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'डायरी'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'नोट गिनती'),
          NavigationDestination(icon: Icon(Icons.security), label: 'SSO'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'रेट/AEPS'),
          NavigationDestination(icon: Icon(Icons.event), label: 'एग्जाम'),
        ],
      ),
    );
  }

  Widget _buildPage() {
    if (_idx == 0) return _tabKhata();
    if (_idx == 1) return _tabCash();
    if (_idx == 2) return _tabWork();
    if (_idx == 3) return _tabNotes();
    if (_idx == 4) return _tabSso();
    if (_idx == 5) return _tabRates();
    return _tabExams();
  }

  // 1. खाता स्क्रीन
  Widget _tabKhata() {
    double totalDue = 0;
    for (var k in khata) {
      totalDue += (k['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.indigo.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('कुल बकाया उधार:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₹$totalDue', style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: khata.isEmpty
              ? const Center(child: Text('कोई उधार बकाया नहीं है।'))
              : ListView.builder(
                  itemCount: khata.length,
                  itemBuilder: (ctx, i) {
                    final item = khata[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['work']} | ${item['phone']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${item['amount']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(icon: const Icon(Icons.qr_code, color: Colors.purple), onPressed: () => _showQr((item['amount'] as num).toDouble())),
                            IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _sendWa(item['phone'] ?? '', 'नमस्ते ${item['name']} जी, $shopName का ₹${item['amount']} बकाया है। कृपया भुगतान करें।')),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.blue),
                              onPressed: () {
                                _sendWa(item['phone'] ?? '', '🧾 *भुगतान रसीद*\nदुकान: $shopName\nग्राहक: ${item['name']}\nराशि: ₹${item['amount']} (PAID)\nदिनांक: ${DateTime.now().toString().split(' ')[0]}\nधन्यवाद!');
                                setState(() => khata.removeAt(i));
                                _save('k_data', khata);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        FloatingActionButton(
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
                  TextField(controller: a, decoration: const InputDecoration(labelText: 'रकम (₹) *'), keyboardType: TextInputType.number),
                ]),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (n.text.isNotEmpty && a.text.isNotEmpty) {
                        setState(() => khata.add({'name': n.text, 'phone': p.text, 'work': w.text, 'amount': double.tryParse(a.text) ?? 0.0}));
                        _save('k_data', khata);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('जोड़ें'),
                  )
                ],
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // 2. कैश / बैंक स्क्रीन
  Widget _tabCash() {
    double getBal(String acc) {
      double b = 0;
      for (var t in cash) {
        if (t['acc'] == acc) {
          b += (t['t'] == 'In' ? (t['amount'] as num).toDouble() : -(t['amount'] as num).toDouble());
        }
      }
      return b;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('गल्ला: ₹${getBal('Cash')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              Text('SBI: ₹${getBal('SBI')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text('PNB: ₹${getBal('PNB')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            ],
          ),
        ),
        Expanded(
          child: cash.isEmpty
              ? const Center(child: Text('कोई एंट्री नहीं है।'))
              : ListView.builder(
                  itemCount: cash.length,
                  itemBuilder: (ctx, i) {
                    final item = cash[i];
                    final isIn = item['t'] == 'In';
                    return ListTile(
                      leading: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: isIn ? Colors.green : Colors.red),
                      title: Text(item['cat'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item['acc']} • ${item['desc']}'),
                      trailing: Text('${isIn ? '+' : '-'} ₹${item['amount']}', style: TextStyle(color: isIn ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    );
                  },
                ),
        ),
        FloatingActionButton(
          onPressed: () {
            final a = TextEditingController(), d = TextEditingController();
            String cat = 'ई-मित्र टोकन', acc = 'Cash', t = 'In';
            showDialog(
              context: context,
              builder: (ctx) => StatefulBuilder(
                builder: (ctx, setD) => AlertDialog(
                  title: const Text('एंट्री जोड़ें'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButton<String>(value: t, isExpanded: true, items: const [DropdownMenuItem(value: 'In', child: Text('आवक (+)')), DropdownMenuItem(value: 'Out', child: Text('खर्च (-)'))], onChanged: (v) => setD(() => t = v!)),
                    DropdownButton<String>(value: acc, isExpanded: true, items: const [DropdownMenuItem(value: 'Cash', child: Text('गल्ला (Cash)')), DropdownMenuItem(value: 'SBI', child: Text('SBI खाता')), DropdownMenuItem(value: 'PNB', child: Text('PNB खाता'))], onChanged: (v) => setD(() => acc = v!)),
                    TextField(controller: a, decoration: const InputDecoration(labelText: 'राशि (₹)'), keyboardType: TextInputType.number),
                    TextField(controller: d, decoration: const InputDecoration(labelText: 'विवरण')),
                  ]),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        if (a.text.isNotEmpty) {
                          setState(() => cash.insert(0, {'cat': cat, 'acc': acc, 't': t, 'amount': double.tryParse(a.text) ?? 0.0, 'desc': d.text}));
                          _save('c_data', cash);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('सेव करें'),
                    )
                  ],
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // 3. वर्क डायरी
  Widget _tabWork() {
    return Column(
      children: [
        Expanded(
          child: work.isEmpty
              ? const Center(child: Text('कोई काम पेंडिंग नहीं है।'))
              : ListView.builder(
                  itemCount: work.length,
                  itemBuilder: (ctx, i) {
                    final item = work[i];
                    bool done = item['st'] == 'Done';
                    return ListTile(
                      leading: Icon(done ? Icons.check_circle : Icons.hourglass_top, color: done ? Colors.green : Colors.orange),
                      title: Text('${item['name']} - ${item['work']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('टोकन: ${item['token']} | स्थिति: ${item['st']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _sendWa(item['phone'] ?? '', 'नमस्ते ${item['name']} जी, आपका कार्य (${item['work']}) टोकन: ${item['token']} तैयार है। दुकान $shopName से प्राप्त कर लें।')),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () {
                              setState(() => work.removeAt(i));
                              _save('w_data', work);
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),
        FloatingActionButton(
          onPressed: () {
            final n = TextEditingController(), p = TextEditingController(), w = TextEditingController(), tk = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('नया काम दर्ज करें'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: n, decoration: const InputDecoration(labelText: 'ग्राहक का नाम *')),
                  TextField(controller: p, decoration: const InputDecoration(labelText: 'मोबाइल')),
                  TextField(controller: w, decoration: const InputDecoration(labelText: 'काम (जाति/मूल/फॉर्म)')),
                  TextField(controller: tk, decoration: const InputDecoration(labelText: 'टोकन/आवेदन संख्या')),
                ]),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (n.text.isNotEmpty) {
                        setState(() => work.insert(0, {'name': n.text, 'phone': p.text, 'work': w.text, 'token': tk.text, 'st': 'Done'}));
                        _save('w_data', work);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('सेव करें'),
                  )
                ],
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // 4. नोट गिनती
  Widget _tabNotes() {
    int sum = 0;
    notes.forEach((k, v) => sum += k * v);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade800,
          child: Text('कुल गल्ला नकदी: ₹$sum', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
