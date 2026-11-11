import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      title: 'Sidharth Shop Manager',
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
  String shopUpi = '9257161097@sbi';

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
      shopUpi = prefs.getString('shop_upi') ?? '9257161097@sbi';
    });
  }

  void _editShopProfileDialog() {
    final nameCtrl = TextEditingController(text: shopName);
    final addrCtrl = TextEditingController(text: shopAddress);
    final phoneCtrl = TextEditingController(text: shopPhone);
    final upiCtrl = TextEditingController(text: shopUpi);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('दुकान प्रोफाइल व UPI सेटिंग'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'दुकान का नाम')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'पता / मार्केट')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'मोबाइल नंबर'), keyboardType: TextInputType.phone),
              TextField(controller: upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID (QR के लिए)')),
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
              await prefs.setString('shop_upi', upiCtrl.text);
              setState(() {
                shopName = nameCtrl.text;
                shopAddress = addrCtrl.text;
                shopPhone = phoneCtrl.text;
                shopUpi = upiCtrl.text;
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('सेव करें'),
          ),
        ],
      ),
    );
  }

  void _showUpiQrDialog(double amount, String note) {
    final upiUrl = 'upi://pay?pa=$shopUpi&pn=${Uri.encodeComponent(shopName)}&am=$amount&cu=INR&tn=${Uri.encodeComponent(note)}';
    final qrApiUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(upiUrl)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(child: Text(shopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('भुगतान राशि: ₹$amount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            Text('UPI ID: $shopUpi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Image.network(
                qrApiUrl,
                height: 200,
                width: 200,
                loadingBuilder: (c, child, progress) => progress == null ? child : const SizedBox(height: 200, width: 200, child: Center(child: CircularProgressIndicator())),
                errorBuilder: (c, e, s) => const Text('QR लोड करने में विफल'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('PhonePe, GPay, Paytm से स्कैन करें', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('बंद करें')),
        ],
      ),
    );
  }

  void _sendDailyClosingReport() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cashRaw = prefs.getString('cash_data');
    final String? khataRaw = prefs.getString('khata_data');

    final List cashList = cashRaw != null ? json.decode(cashRaw) : [];
    final List khataList = khataRaw != null ? json.decode(khataRaw) : [];

    double cashBal = 0.0, sbiBal = 0.0, pnbBal = 0.0, totalIncome = 0.0, totalExpense = 0.0;
    for (var t in cashList) {
      double amt = (t['amount'] ?? 0.0);
      bool isIn = t['type'].toString().contains('In');
      if (isIn) {
        totalIncome += amt;
      } else {
        totalExpense += amt;
      }

      if (t['account'] == 'Cash (गल्ला)') {
        cashBal += isIn ? amt : -amt;
      } else if (t['account'] == 'SBI Bank') {
        sbiBal += isIn ? amt : -amt;
      } else if (t['account'] == 'PNB Bank') {
        pnbBal += isIn ? amt : -amt;
      }
    }

    double totalUdhar = 0.0;
    for (var k in khataList) {
      totalUdhar += (k['amount'] ?? 0.0);
    }

    final date = DateTime.now().toString().split(' ')[0];
    final msg = Uri.encodeComponent(
      '📊 *दैनिक क्लोजिंग रिपोर्ट ($date)*\n'
      '🏪 *$shopName*\n'
      '📍 $shopAddress\n'
      '-----------------------------\n'
      '💵 गल्ला (नकद): ₹$cashBal\n'
      '🏦 SBI बैलेंस: ₹$sbiBal\n'
      '🏦 PNB बैलेंस: ₹$pnbBal\n'
      '-----------------------------\n'
      '📈 आज की कुल आवक: ₹$totalIncome\n'
      '📉 आज का कुल खर्च: ₹$totalExpense\n'
      '📌 कुल बकाया उधार: ₹$totalUdhar\n'
      '-----------------------------\n'
      'रिपोर्ट समय: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'
    );

    final cleanPhone = shopPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullNumber = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final url = Uri.parse('https://wa.me/$fullNumber?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _exportExcelBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final String? khataRaw = prefs.getString('khata_data');
    final String? cashRaw = prefs.getString('cash_data');
    final String? ssoRaw = prefs.getString('sso_data');
    final String? workRaw = prefs.getString('work_diary_data');

    final List khataList = khataRaw != null ? json.decode(khataRaw) : [];
    final List cashList = cashRaw != null ? json.decode(cashRaw) : [];
    final List ssoList = ssoRaw != null ? json.decode(ssoRaw) : [];
    final List workList = workRaw != null ? json.decode(workRaw) : [];

    StringBuffer csv = StringBuffer();
    csv.writeln('=== $shopName ===');
    csv.writeln('दिनांक: ${DateTime.now().toString().split(' ')[0]}');
    csv.writeln('');

    csv.writeln('--- 1. ग्राहक उधार सूची ---');
    csv.writeln('क्र.सं.,नाम,मोबाइल,काम,राशि (रु)');
    for (int i = 0; i < khataList.length; i++) {
      final c = khataList[i];
      csv.writeln('${i + 1},"${c['name']}","${c['phone']}","${c['work']}",${c['amount']}');
    }
    csv.writeln('');

    csv.writeln('--- 2. कैश & बैंक रजिस्टर ---');
    csv.writeln('क्र.सं.,श्रेणी,खाता,प्रकार,राशि (रु),विवरण');
    for (int i = 0; i < cashList.length; i++) {
      final t = cashList[i];
      csv.writeln('${i + 1},"${t['category']}","${t['account']}","${t['type']}",${t['amount']},"${t['desc']}"');
    }
    csv.writeln('');

    csv.writeln('--- 3. ग्राहक SSO व दस्तावेज डायरेक्टरी ---');
    csv.writeln('क्र.सं.,नाम,मोबाइल,SSO ID,जन आधार,आधार');
    for (int i = 0; i < ssoList.length; i++) {
      final s = ssoList[i];
      csv.writeln('${i + 1},"${s['name']}","${s['phone']}","${s['sso']}","${s['jan']}","${s['aadhaar']}"');
    }
    csv.writeln('');

    csv.writeln('--- 4. आवेदन व फॉर्म वर्क डायरी ---');
    csv.writeln('क्र.सं.,ग्राहक,मोबाइल,कार्य,टोकन/आईडी,स्थिति');
    for (int i = 0; i < workList.length; i++) {
      final w = workList[i];
      csv.writeln('${i + 1},"${w['name']}","${w['phone']}","${w['work']}","${w['token']}","${w['status']}"');
    }

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/Shop_Master_Backup_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv.toString());
      await Share.shareXFiles([XFile(path)], text: '$shopName - संपूर्ण बहीखाता व बैकअप');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('बैकअप त्रुटि: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      KhataScreen(
        shopName: shopName,
        shopPhone: shopPhone,
        shopAddress: shopAddress,
        onShowQr: (amt) => _showUpiQrDialog(amt, 'उधार चुकता'),
      ),
      const BankSplitCashRegister(),
      WorkDiaryScreen(shopName: shopName, shopPhone: shopPhone),
      DenominationCounterScreen(),
      const CustomerVaultScreen(),
      ShopToolsAndRatesScreen(
        shopName: shopName,
        shopPhone: shopPhone,
        onGenerateCustomQr: (amt) => _showUpiQrDialog(amt, 'ई-मित्र सेवा शुल्क'),
      ),
      const ExamCalendarScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text('$shopAddress | 📞 $shopPhone', style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'दुकान UPI QR कोड',
            onPressed: () => _showUpiQrDialog(0.0, 'दुकान भुगतान'),
          ),
          IconButton(
            icon: const Icon(Icons.send_to_mobile),
            tooltip: 'WhatsApp क्लोजिंग रिपोर्ट',
            onPressed: _sendDailyClosingReport,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Excel बैकअप',
            onPressed: _exportExcelBackup,
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'प्रोफ़ाइल बदलें',
            onPressed: _editShopProfileDialog,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'उधार खाता'),
          NavigationDestination(icon: Icon(Icons.account_balance), label: 'कैश/बैंक'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'वर्क डायरी'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'नोट गिनती'),
          NavigationDestination(icon: Icon(Icons.folder_shared), label: 'SSO वॉल्ट'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'रेट & टूल'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'एग्जाम 2026'),
        ],
      ),
    );
  }
}

// ---------------- 1. खाता स्क्रीन & UPI QR ----------------
class KhataScreen extends StatefulWidget {
  final String shopName;
  final String shopPhone;
  final String shopAddress;
  final Function(double) onShowQr;
  const KhataScreen({super.key, required this.shopName, required this.shopPhone, required this.shopAddress, required this.onShowQr});

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
      setState(() => customers = json.decode(data));
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
        title: const Text('नया उधार खाता जोड़ें'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ग्राहक का नाम *')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'मोबाइल नंबर'), keyboardType: TextInputType.phone),
              TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'काम का विवरण')),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'उधार राशि (₹) *'), keyboardType: TextInputType.number),
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
      'संपर्क: ${widget.shopPhone}'
    );
    final url = Uri.parse('https://wa.me/$fullNumber?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _settlePayment(int index) {
    final item = customers[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('उधार चुकता / पेमेंट रसीद'),
        content: Text('${item['name']} जी का ₹${item['amount']} का भुगतान प्राप्त हुआ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onShowQr((item['amount'] as num).toDouble());
            },
            child: const Text('UPI QR दिखाएं'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final phone = (item['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
              final fullNumber = phone.length == 10 ? '91$phone' : phone;
              final receiptMsg = Uri.encodeComponent(
                '🧾 *भुगतान पावती (Payment Receipt)*\n'
                '----------------------------\n'
                '🏪 *${widget.shopName}*\n'
                '📍 ${widget.shopAddress} | 📞 ${widget.shopPhone}\n'
                '----------------------------\n'
                '👤 ग्राहक: ${item['name']}\n'
                '📝 विवरण: ${item['work']}\n'
                '💰 प्राप्त राशि: ₹${item['amount']}\n'
                '📅 दिनांक: ${DateTime.now().toString().split(' ')[0]}\n'
                '✅ स्थिति: पूर्ण भुगतान (PAID)\n'
                '----------------------------\n'
                'धन्यवाद!'
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
            child: const Text('प्राप्त & रसीद भेजें'),
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
                          mainAx
