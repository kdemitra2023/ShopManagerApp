import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() {
  runApp(const ShopApp());
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    KhataScreen(),
    CashRegisterScreen(),
    JobAlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'खाता / उधार'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'कैश रजिस्टर'),
          NavigationDestination(icon: Icon(Icons.notifications_active), label: 'जॉब अलर्ट'),
        ],
      ),
    );
  }
}

// ---------------- 1. खाता स्क्रीन ----------------
class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  List customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('khata_data');
    if (data != null) {
      setState(() {
        customers = json.decode(data);
      });
    }
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('khata_data', json.encode(customers));
  }

  void _addCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final workCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नया खाता / उधार जोड़ें'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ग्राहक का नाम')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'मोबाइल नंबर'), keyboardType: TextInputType.phone),
              TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'काम का विवरण')),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'बकाया राशि (₹)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                setState(() {
                  customers.add({
                    'name': nameCtrl.text,
                    'phone': phoneCtrl.text,
                    'work': workCtrl.text,
                    'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                  });
                });
                _saveData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('सेव करें'),
          ),
        ],
      ),
    );
  }

  void _sendWhatsApp(String phone, String name, dynamic amount) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullNumber = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = Uri.encodeComponent('नमस्ते $name जी, दुकान का बकाया ₹$amount है। कृपया भुगतान करें।');
    final url = Uri.parse('https://wa.me/$fullNumber?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalDues = 0.0;
    for (var c in customers) {
      totalDues += (c['amount'] ?? 0.0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ग्राहक खाता & उधार'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('कुल बकाया (उधार):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('₹ $totalDues', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? const Center(child: Text('कोई खाता नहीं है। नीचे + दबाकर जोड़ें।'))
                : ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (ctx, i) {
                      final item = customers[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item['work'] ?? ''} | ${item['phone'] ?? ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('₹${item['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                              IconButton(
                                icon: const Icon(Icons.message, color: Colors.green),
                                onPressed: () => _sendWhatsApp(item['phone'] ?? '', item['name'] ?? '', item['amount']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
                                onPressed: () {
                                  setState(() => customers.removeAt(i));
                                  _saveData();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomerDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---------------- 2. कैश रजिस्टर स्क्रीन ----------------
class CashRegisterScreen extends StatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  State<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends State<CashRegisterScreen> {
  List transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTxns();
  }

  void _loadTxns() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('cash_data');
    if (data != null) {
      setState(() {
        transactions = json.decode(data);
      });
    }
  }

  void _saveTxns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cash_data', json.encode(transactions));
  }

  void _addTxnDialog() {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String type = 'Cash In (कमाई)';
    String mode = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('दैनिक लेन-देन जोड़ें'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'विवरण')),
                TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'राशि (₹)'), keyboardType: TextInputType.number),
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'Cash In (कमाई)', child: Text('कमाई (In)')),
                    DropdownMenuItem(value: 'Cash Out (खर्चा)', child: Text('खर्चा (Out)')),
                  ],
                  onChanged: (val) => setDialogState(() => type = val!),
                ),
                DropdownButton<String>(
                  value: mode,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('गल्ला (Cash)')),
                    DropdownMenuItem(value: 'Bank/UPI', child: Text('बैंक / UPI')),
                  ],
                  onChanged: (val) => setDialogState(() => mode = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () {
                if (descCtrl.text.isNotEmpty && amtCtrl.text.isNotEmpty) {
                  setState(() {
                    transactions.insert(0, {
                      'desc': descCtrl.text,
                      'amount': double.tryParse(amtCtrl.text) ?? 0.0,
                      'type': type,
                      'mode': mode,
                    });
                  });
                  _saveTxns();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('सेव करें'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalIn = 0.0;
    double totalOut = 0.0;
    for (var t in transactions) {
      if (t['type'].toString().contains('In')) {
        totalIn += (t['amount'] ?? 0.0);
      } else {
        totalOut += (t['amount'] ?? 0.0);
      }
    }
    double netBalance = totalIn - totalOut;

    return Scaffold(
      appBar: AppBar(
        title: const Text('कैश & गल्ला रजिस्टर'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [const Text('कुल आवक'), Text('₹$totalIn', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18))]),
                Column(children: [const Text('कुल खर्चा'), Text('₹$totalOut', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))]),
                Column(children: [const Text('बचत'), Text('₹$netBalance', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18))]),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('आज कोई एंट्री नहीं है।'))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (ctx, i) {
                      final item = transactions[i];
                      final isIn = item['type'].toString().contains('In');
                      return ListTile(
                        leading: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: isIn ? Colors.green : Colors.red),
                        title: Text(item['desc'] ?? ''),
                        subtitle: Text(item['mode'] ?? ''),
                        trailing: Text(
                          '${isIn ? '+' : '-'} ₹${item['amount']}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isIn ? Colors.green : Colors.red),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTxnDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---------------- 3. जॉब अलर्ट स्क्रीन ----------------
class JobAlertsScreen extends StatelessWidget {
  const JobAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {'title': 'RPSC Programmer Admit Card 2026', 'date': 'अंतिम तिथि: 25/11/2026', 'link': 'https://rpsc.rajasthan.gov.in'},
      {'title': 'Rajasthan CET (Graduation / 12th) Result', 'date': 'अपडेटेड: 2026', 'link': 'https://rsmssb.rajasthan.gov.in'},
      {'title': 'Rajasthan LDC & Junior Assistant भर्ती', 'date': 'नोटिफिकेशन लाइव', 'link': 'https://sso.rajasthan.gov.in'},
      {'title': 'Railway RRB NTPC फॉर्म संशोधन विंडो', 'date': 'लास्ट डेट पास है', 'link': 'https://indianrailways.gov.in'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('सरकारी योजना व जॉब अलर्ट'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (ctx, i) {
          final alert = alerts[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.campaign, color: Colors.deepOrange),
              title: Text(alert['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(alert['date']!),
              trailing: const Icon(Icons.open_in_new),
              onTap: () async {
                final url = Uri.parse(alert['link']!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
