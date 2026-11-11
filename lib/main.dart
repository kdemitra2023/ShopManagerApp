import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'khata_screen.dart';
import 'inventory_screen.dart';
import 'tools_screen.dart';
import 'cash_screen.dart';
import 'vault_screen.dart';

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

  void _showQr(double amt) {
    final u = 'upi://pay?pa=$shopUpi&pn=${Uri.encodeComponent(shopName)}&am=$amt&cu=INR';
    final q = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(u)}';
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(shopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text('राशि: ₹$amt', style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            Text('UPI ID: $shopUpi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(q, height: 180, width: 180, errorBuilder: (x, y, z) => const Text('QR लोड विफल')),
            ),
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
    final List<Widget> pages = [
      KhataScreen(shopName: shopName, shopPhone: shopPhone, onShowQr: _showQr),
      const CashScreen(),
      const InventoryScreen(),
      const VaultScreen(),
      ToolsScreen(onShowQr: _showQr),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(shopName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text('$shopAddress | 📞 $shopPhone', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
                    tooltip: 'दुकान QR',
                    onPressed: () => _showQr(0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 22),
                    tooltip: 'सेटिंग',
                    onPressed: _editProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        height: 65,
        elevation: 8,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book, color: Colors.indigo), label: 'उधार खाता'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: Colors.teal), label: 'कैश/बैंक'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2, color: Colors.deepOrange), label: 'स्टॉक'),
          NavigationDestination(icon: Icon(Icons.folder_shared_outlined), selectedIcon: Icon(Icons.folder_shared, color: Colors.purple), label: 'डायरी/SSO'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view, color: Colors.blue), label: 'टूल्स & रेट'),
        ],
      ),
    );
  }
}
