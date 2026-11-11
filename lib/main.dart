import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'khata_screen.dart';
import 'inventory_screen.dart';
import 'tools_screen.dart';

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
  String shopName = ShopConfig.defName;
  String shopAddress = ShopConfig.defAddress;
  String shopPhone = ShopConfig.defPhone;
  String shopUpi = ShopConfig.defUpi;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      shopName = p.getString('sn') ?? shopName;
      shopAddress = p.getString('sa') ?? shopAddress;
      shopPhone = p.getString('sp') ?? shopPhone;
      shopUpi = p.getString('su') ?? shopUpi;
    });
  }

  // 1-टैप डायरेक्ट WhatsApp (नंबर सेव किए बिना)
  void _openDirectWhatsApp(String phone, String msg) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final targetNum = clean.length == 10 ? '91$clean' : clean;
    if (targetNum.isNotEmpty) {
      final url = Uri.parse('https://wa.me/$targetNum?text=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
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
            Text('UPI ID: $shopUpi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Image.network(q, height: 180, width: 180, errorBuilder: (x, y, z) => const Text('QR त्रुटि')),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('बंद करें'))],
      ),
    );
  }

  void _editProfile() {
    final n = TextEditingController(text: shopName);
    final a = TextEditingController(text: shopAddress);
    final p = TextEditingController(text: shopPhone);
    final u = TextEditingController(text: shopUpi);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('दुकान प्रोफाइल सेटिंग'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'दुकान का नाम')),
            TextField(controller: a, decoration: const InputDecoration(labelText: 'मार्केट / पता')),
            TextField(controller: p, decoration: const InputDecoration(labelText: 'मोबाइल नंबर')),
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
    Widget currentBody;
    if (_tab == 0) {
      currentBody = KhataScreen(
        shopName: shopName,
        shopPhone: shopPhone,
        onShowQr: _showQr,
      );
    } else if (_tab == 1) {
      currentBody = const InventoryScreen();
    } else {
      currentBody = ToolsScreen(onShowQr: _showQr);
    }

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
          IconButton(icon: const Icon(Icons.qr_code), tooltip: 'दुकान QR', onPressed: () => _showQr(0)),
          IconButton(icon: const Icon(Icons.edit), tooltip: 'एडिट प्रोफाइल', onPressed: _editProfile),
        ],
      ),
      body: currentBody,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'उधार खाता'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'स्टेशनरी स्टॉक'),
          NavigationDestination(icon: Icon(Icons.calculate), label: 'नोट & टूल्स'),
        ],
      ),
    );
  }
}
