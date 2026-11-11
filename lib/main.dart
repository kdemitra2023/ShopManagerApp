import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ShopHome(),
    ));

class ShopHome extends StatefulWidget {
  const ShopHome({super.key});
  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  int _tab = 0;
  String shopName = 'Sidharth E-Mitra & Book Store';
  String shopAddress = 'नेताजी मार्केट, लूणकरणसर';
  String shopPhone = '9257161097';
  String shopUpi = '9257161097@sbi';

  List khata = [];
  List cash = [];
  List work = [];
  List sso = [];
  final Map<int, int> notes = {500: 0, 200: 0, 100: 0, 50: 0, 20: 0, 10: 0};
  final calcC = TextEditingController();
  double aepsFee = 0, aepsTot = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      shopName = p.getString('sn') ?? shopName;
      shopAddress = p.getString('sa') ?? shopAddress;
      shopPhone = p.getString('sp') ?? shopPhone;
      shopUpi = p.getString('su') ?? shopUpi;
      khata = json.decode(p.getString('k_d') ?? '[]');
      cash = json.decode(p.getString('c_d') ?? '[]');
      work = json.decode(p.getString('w_d') ?? '[]');
      sso = json.decode(p.getString('s_d') ?? '[]');
    });
  }

  void _save(String k, dynamic v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(k, json.encode(v));
  }

  void _wa(String num, String msg) async {
    final c = num.replaceAll(RegExp(r'[^0-9]'), '');
    final f = c.length == 10 ? '91$c' : c;
    if (f.isNotEmpty) {
      final u = Uri.parse('https://wa.me/$f?text=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  void _showQr(double amt) {
    final u = 'upi://pay?pa=$shopUpi&pn=${Uri.encodeComponent(shopName)}&am=$amt&cu=INR';
    final q = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(u)}';
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(shopName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('राशि: ₹$amt', style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
            Text('UPI: $shopUpi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Image.network(q, height: 180, width: 180, errorBuilder: (x, y, z) => const Text('QR त्रुटि')),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('बंद करें'))],
      ),
    );
  }

  void _closingReport() {
    double cB = 0, sB = 0, pB = 0, inc = 0, exp = 0;
    for (var t in cash) {
      double a = (t['a'] as num?)?.toDouble() ?? 0;
      bool isIn = t['t'] == 'In';
      isIn ? inc += a : exp += a;
      if (t['ac'] == 'Cash') cB += isIn ? a : -a;
      if (t['ac'] == 'SBI') sB += isIn ? a : -a;
      if (t['ac'] == 'PNB') pB += isIn ? a : -a;
    }
    double due = 0;
    for (var k in khata) due += (k['a'] as num?)?.toDouble() ?? 0;
    final rep = '📊 *दुकान क्लोजिंग समरी*\n🏪 *$shopName*\n--------------------\n💵 गल्ला कैश: ₹$cB\n🏦 SBI: ₹$sB | PNB: ₹$pB\n--------------------\n📈 आवक: ₹$inc | 📉 खर्च: ₹$exp\n📌 कुल उधार: ₹$due';
    _wa(shopPhone, rep);
  }

  void _copyBackup() {
    StringBuffer b = StringBuffer();
    b.writeln('=== $shopName Backup ===\n[उधार खाता]');
    for (var k in khata) b.writeln('${k['n']},${k['p']},${k['w']},${k['a']}');
    b.writeln('\n[कैश रजिस्टर]');
    for (var c in cash) b.writeln('${c['m']},${c['ac']},${c['t']},${c['a']}');
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
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'नाम')),
            TextField(controller: a, decoration: const InputDecoration(labelText: 'पता')),
            TextField(controller: p, decoration: const InputDecoration(labelText: 'मोबाइल')),
            TextField(controller: u, decoration: const InputDecoration(labelText: 'UPI ID')),
          ]),
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
        title: Text(shopName, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code), tooltip: 'QR', onPressed: () => _showQr(0)),
          IconButton(icon: const Icon(Icons.send), tooltip: 'रिपोर्ट', onPressed: _closingReport),
          IconButton(icon: const Icon(Icons.copy), tooltip: 'बैकअप', onPressed: _copyBackup),
          IconButton(icon: const Icon(Icons.edit), tooltip: 'एडिट', onPressed: _editProfile),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'खाता'),
          NavigationDestination(icon: Icon(Icons.account_balance), label: 'कैश/बैंक'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'डायरी'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'नोट गिनती'),
          NavigationDestination(icon: Icon(Icons.security), label: 'SSO'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'रेट/टूल'),
          NavigationDestination(icon: Icon(Icons.event), label: 'एग्जाम'),
        ],
      ),
    );
  }

  Widget _getBody() {
    if (_tab == 0) return _viewKhata();
    if (_tab == 1) return _viewCash();
    if (_tab == 2) return _viewWork();
    if (_tab == 3) return _viewNotes();
    if (_tab == 4) return _viewSso();
    if (_tab == 5) return _viewRates();
    return _viewExams();
  }

  Widget _viewKhata() {
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
          child: ListView.builder(
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
                    IconButton(icon: const Icon(Icons.qr_code, color: Colors.purple), onPressed: () => _showQr((it['a'] as num).toDouble())),
                    IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _wa(it['p'], 'नमस्ते ${it['n']} जी, $shopName का ₹${it['a']} बकाया है।')),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.blue),
                      onPressed: () {
                        _wa(it['p'], '🧾 *भुगतान रसीद*\nदुकान: $shopName\nग्राहक: ${it['n']}\nरकम: ₹${it['a']} (PAID)\nधन्यवाद!');
                        setState(() => khata.removeAt(i));
                        _save('k_d', khata);
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
                        _save('k_d', khata);
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

  Widget _viewCash() {
    double bal(String ac) {
      double b = 0;
      for (var t in cash) if (t['ac'] == ac) b += (t['t'] == 'In' ? (t['a'] as num).toDouble() : -(t['a'] as num).toDouble());
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
              Text('गल्ला: ₹${bal('Cash')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              Text('SBI: ₹${bal('SBI')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text('PNB: ₹${bal('PNB')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: cash.length,
            itemBuilder: (c, i) {
              final it = cash[i];
              bool isIn = it['t'] == 'In';
              return ListTile(
                leading: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: isIn ? Colors.green : Colors.red),
                title: Text('${it['m']} (${it['ac']})'),
                trailing: Text('${isIn ? '+' : '-'} ₹${it['a']}', style: TextStyle(color: isIn ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            final a = TextEditingController();
            String ac = 'Cash', t = 'In', m = 'ई-मित्र';
            showDialog(
              context: context,
              builder: (ctx) => StatefulBuilder(
                builder: (ctx, setS) => AlertDialog(
                  title: const Text('कैश एंट्री'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButton<String>(value: t, isExpanded: true, items: const [DropdownMenuItem(value: 'In', child: Text('आवक (+)')), DropdownMenuItem(value: 'Out', child: Text('खर्च (-)'))], onChanged: (v) => setS(() => t = v!)),
                    DropdownButton<String>(value: ac, isExpanded: true, items: const [DropdownMenuItem(value: 'Cash', child: Text('गल्ला (Cash)')), DropdownMenuItem(value: 'SBI', child: Text('SBI खाता')), DropdownMenuItem(value: 'PNB', child: Text('PNB खाता'))], onChanged: (v) => setS(() => ac = v!)),
                    TextField(controller: a, decoration: const InputDecoration(labelText: 'राशि (₹)'), keyboardType: TextInputType.number),
                  ]),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        if (a.text.isNotEmpty) {
                          setState(() => cash.insert(0, {'m': m, 'ac': ac, 't': t, 'a': double.tryParse(a.text) ?? 0}));
                          _save('c_d', cash);
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
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _viewWork() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: work.length,
            itemBuilder: (c, i) {
              final it = work[i];
              return ListTile(
                leading: const Icon(Icons.assignment, color: Colors.blue),
                title: Text('${it['n']} - ${it['w']}'),
                subtitle: Text('टोकन: ${it['tk']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _wa(it['p'], 'नमस्ते ${it['n']} जी, आपका काम (${it['w']}) तैयार है।')),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () {
                      setState(() => work.removeAt(i));
                      _save('w_d', work);
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            final n = TextEditingController(), p = TextEditingController(), w = TextEditingController(), tk = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('नया काम'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: n, decoration: const InputDecoration(labelText: 'ग्राहक का नाम *')),
                  TextField(controller: p, decoration: const InputDecoration(labelText: 'मोबाइल')),
                  TextField(controller: w, decoration: const InputDecoration(labelText: 'काम का नाम')),
                  TextField(controller: tk, decoration: const InputDecoration(labelText: 'टोकन/आवेदन संख्या')),
                ]),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (n.text.isNotEmpty) {
                        setState(() => work.insert(0, {'n': n.text, 'p': p.text, 'w': w.text, 'tk': tk.text}));
                        _save('w_d', work);
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
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _viewNotes() {
    int sum = 0;
    notes.forEach((k, v) => sum = sum + (k * v));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade800,
          child: Text('गल्ला नकदी: ₹$sum', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 10),
        ...notes.keys.map((k) => Card(
              child: ListTile(
                leading: Text('₹$k', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                title: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'संख्या', isDense: true),
                  onChanged: (v) => setState(() => notes[k] = int.tryParse(v) ?? 0),
                ),
                trailing: Text('= ₹${k * notes[k]!}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
            )),
      ],
    );
  }

  Widget _viewSso() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: sso.length,
            itemBuilder: (c, i) {
              final it = sso[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.security),
                  title: Text(it['n'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: ${it['s']} | Pass: ${it['ps']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${it['s']} / ${it['ps']}'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID/पासवर्ड कॉपी हुआ!')));
                    },
                  ),
                ),
              );
            },
          ),
        ),
        FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            final n = TextEditingController(), s = TextEditingController(), ps = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('SSO रिकॉर्ड'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: n, decoration: const InputDecoration(labelText: 'नाम')),
                  TextField(controller: s, decoration: const InputDecoration(labelText: 'SSO ID')),
                  TextField(controller: ps, decoration: const InputDecoration(labelText: 'पासवर्ड')),
                ]),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (n.text.isNotEmpty) {
                        setState(() => sso.add({'n': n.text, 's': s.text, 'ps': ps.text}));
                        _save('s_d', sso);
                        Navigator.pop(ctx);
                 
