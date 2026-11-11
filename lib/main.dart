import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

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

  String shopName = 'Sidharth E-Mitra & Book Store';
  String shopAddress = 'नेताजी मार्केट, लूणकरणसर';
  String shopPhone = '9257161097';

  @override
  void initState() {
    super.initState();
    _loadShopProfile();
  }

  void _loadShopProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      shopName = prefs.getString('shop_name') ?? 'Sidharth E-Mitra & Book Store';
      shopAddress = prefs.getString('shop_address') ?? 'नेताजी मार्केट, लूणकरणसर';
      shopPhone = prefs.getString('shop_phone') ?? '9257161097';
    });
  }

  void _editShopProfileDialog() {
    final nameCtrl = TextEditingController(text: shopName);
    final addrCtrl = TextEditingController(text: shopAddress);
    final phoneCtrl = TextEditingController(text: shopPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('दुकान प्रोफ़ाइल संपादित करें'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'दुकान का नाम')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'पता / मार्केट')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'मोबाइल नंबर'), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('shop_name', nameCtrl.text);
              await prefs.setString('shop_address', addrCtrl.text);
              await prefs.setString('shop_phone', phoneCtrl.text);
              setState(() {
                shopName = nameCtrl.text;
                shopAddress = addrCtrl.text;
                shopPhone = phoneCtrl.text;
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('सेव करें'),
          ),
        ],
      ),
    );
  }

  void _exportExcelBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final String? khataRaw = prefs.getString('khata_data');
    final String? cashRaw = prefs.getString('cash_data');

    final List khataList = khataRaw != null ? json.decode(khataRaw) : [];
    final List cashList = cashRaw != null ? json.decode(cashRaw) : [];

    StringBuffer csv = StringBuffer();
    csv.writeln('=== $shopName ===');
    csv.writeln('पता: $shopAddress | फोन: $shopPhone');
    csv.writeln('दिनांक: ${DateTime.now().toString().split(' ')[0]}');
    csv.writeln('');

    csv.writeln('--- ग्राहक खाता / उधार विवरण ---');
    csv.writeln('क्र.सं.,ग्राहक का नाम,मोबाइल नंबर,काम,बकाया राशि (रु)');
    for (int i = 0; i < khataList.length; i++) {
      final c = khataList[i];
      csv.writeln('${i + 1},"${c['name']}","${c['phone']}","${c['work']}",${c['amount']}');
    }
    csv.writeln('');

    csv.writeln('--- दैनिक कैश & बैंक रजिस्टर ---');
    csv.writeln('क्र.सं.,श्रेणी,विवरण,प्रकार,खाता,राशि (रु)');
    for (int i = 0; i < cashList.length; i++) {
      final t = cashList[i];
      csv.writeln('${i + 1},"${t['category']}","${t['desc']}","${t['type']}","${t['account']}",${t['amount']}');
    }

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/Shop_Full_Backup_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv.toString());

      await Share.shareXFiles([XFile(path)], text: '$shopName - संपूर्ण बहीखाता बैकअप (Excel File)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('बैकअप एरर: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      KhataScreen(shopName: shopName, shopPhone: shopPhone),
      const BankSplitCashRegister(),
      const JobAlertsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.storefront, color: Colors.indigo),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shopName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text('$shopAddress | 📞 $shopPhone', style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), tooltip: 'Excel बैकअप', onPressed: _exportExcelBackup),
          IconButton(icon: const Icon(Icons.edit_note), tooltip: 'प्रोफ़ाइल बदलें', onPressed: _editShopProfileDialog),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'खाता / उधार'),
          NavigationDestination(icon: Icon(Icons.account_balance), label: 'कैश & बैंक'),
          NavigationDestination(icon: Icon(Icons.notifications_active), label: 'जॉब अलर्ट'),
        ],
      ),
    );
  }
}

// ---------------- 1. खाता स्क्रीन & व्हाट्सएप रसीद ----------------
class KhataScreen extends StatefulWidget {
  final String shopName;
  final String shopPhone;
  const KhataScreen({super.key, required this.shopName, required this.shopPhone});

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
        title: const Text('नया उधार जोड़ें'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ग्राहक का नाम')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'मोबाइल नंबर'), keyboardType: TextInputType.phone),
              TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'काम (फॉर्म / फोटोकॉपी / टोकन)')),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'उधार राशि (₹)'), keyboardType: TextInputType.number),
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
                    'date': DateTime.now().toString().split(' ')[0],
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

  void _sendReminder(String phone, String name, dynamic amount, String work) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullNumber = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = Uri.encodeComponent(
      '📌 *उधार रिमाइंडर / सूचना*\n'
      'दुकान: ${widget.shopName}\n'
      'प्रिय $name जी,\n'
      'आपके द्वारा कराए गए कार्य ($work) का ₹$amount बकाया है।\n'
      'कृपया समय पर भुगतान करें।\n'
      '📞 संपर्क: ${widget.shopPhone}'
    );
    final url = Uri.parse('https://wa.me/$fullNumber?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _settlePaymentDialog(int index) {
    final item = customers[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('उधार चुकता / पेमेंट रसीद'),
        content: Text('${item['name']} जी का ₹${item['amount']} का भुगतान प्राप्त हुआ? क्या आप डिजिटल रसीद भेजना चाहते हैं?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final phone = (item['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
              final fullNumber = phone.length == 10 ? '91$phone' : phone;
              final receiptMsg = Uri.encodeComponent(
                '🧾 *भुगतान रसीद (Payment Receipt)*\n'
                '----------------------------\n'
                '🏪 *${widget.shopName}*\n'
                '📍 ${widget.shopAddress}\n'
                '📞 ${widget.shopPhone}\n'
                '----------------------------\n'
                '👤 ग्राहक: ${item['name']}\n'
                '📝 विवरण: ${item['work']}\n'
                '💰 प्राप्त राशि: ₹${item['amount']}\n'
                '📅 दिनांक: ${DateTime.now().toString().split(' ')[0]}\n'
                '✅ स्थिति: पूर्ण भुगतान (PAID)\n'
                '----------------------------\n'
                'धन्यवाद! आपका दिन शुभ हो।'
              );

              setState(() => customers.removeAt(index));
              _saveData();

              if (fullNumber.isNotEmpty) {
                final url = Uri.parse('https://wa.me/$fullNumber?text=$receiptMsg');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text('भुगतान लें & रसीद भेजें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalDues = 0.0;
    for (var c in customers) {
      totalDues += (c['amount'] ?? 0.0);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('कुल बकाया (उधार खाता):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₹ $totalDues', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ),
        Expanded(
          child: customers.isEmpty
              ? const Center(child: Text('कोई उधार बकाया नहीं है। नीचे + दबाकर जोड़ें।'))
              : ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (ctx, i) {
                    final item = customers[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['work'] ?? ''}\n📞 ${item['phone'] ?? ''}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${item['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.green),
                              tooltip: 'व्हाट्सएप तकाजा',
                              onPressed: () => _sendReminder(item['phone'] ?? '', item['name'] ?? '', item['amount'], item['work'] ?? ''),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.blue),
                              tooltip: 'चुकता करें & रसीद दें',
                              onPressed: () => _settlePaymentDialog(i),
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
              onPressed: _addCustomerDialog,
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- 2. बैंक स्प्लिट & अकाउंटिंग श्रेणियां ----------------
class BankSplitCashRegister extends StatefulWidget {
  const BankSplitCashRegister({super.key});

  @override
  State<BankSplitCashRegister> createState() => _BankSplitCashRegisterState();
}

class _BankSplitCashRegisterState extends State<BankSplitCashRegister> {
  List transactions = [];

  final List<String> categories = [
    'ई-मित्र टोकन फीस',
    'फोटोकॉपी & प्रिंटिंग',
    'स्टेशनरी & बुक्स बिक्री',
    'ऑनलाइन फॉर्म फीस',
    'रिचार्ज & बिल भुगतान',
    'दुकान दैनिक खर्च',
  ];

  final List<String> accountTypes = [
    'Cash (गल्ला)',
    'SBI Bank',
    'PNB Bank',
  ];

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
    String selectedCategory = categories[0];
    String selectedAccount = accountTypes[0];
    String type = 'In (आवक)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('लेन-देन जोड़ें'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'In (आवक)', child: Text('आवक / कमाई (+)')),
                    DropdownMenuItem(value: 'Out (खर्च)', child: Text('खर्च / निकासी (-)')),
                  ],
                  onChanged: (val) => setDialogState(() => type = val!),
                ),
                const SizedBox(height: 8),
                const Text('अकाउंटिंग श्रेणी:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 8),
                const Text('खाता / माध्यम:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedAccount,
                  isExpanded: true,
                  items: accountTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) => setDialogState(() => selectedAccount = val!),
                ),
                TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'राशि (₹)'), keyboardType: TextInputType.number),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'विवरण / टिप्पणी')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () {
                if (amtCtrl.text.isNotEmpty) {
                  setState(() {
                    transactions.insert(0, {
                      'category': selectedCategory,
                      'account': selectedAccount,
                      'type': type,
                      'amount': double.tryParse(amtCtrl.text) ?? 0.0,
                      'desc': descCtrl.text,
                      'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
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

  double _getAccountBalance(String acc) {
    double bal = 0.0;
    for (var t in transactions) {
      if (t['account'] == acc) {
        if (t['type'].toString().contains('In')) {
          bal += (t['amount'] ?? 0.0);
        } else {
          bal -= (t['amount'] ?? 0.0);
        }
      }
    }
    return bal;
  }

  @override
  Widget build(Build
