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
  double openCash = 0.0;
  double openSbi = 0.0;
  double openPnb = 0.0;
  int viewMode = 0; // 0 = आज (Daily), 1 = इस महीने (Monthly), 2 = सभी (All)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      cash = json.decode(p.getString('c_d') ?? '[]');
      openCash = p.getDouble('op_cash') ?? 0.0;
      openSbi = p.getDouble('op_sbi') ?? 0.0;
      openPnb = p.getDouble('op_pnb') ?? 0.0;
    });
  }

  void _saveCash() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('c_d', json.encode(cash));
  }

  // ओपनिंग बैलेंस बदलने का डायलॉग
  void _editOpeningBalance() {
    final cCtrl = TextEditingController(text: openCash.toStringAsFixed(0));
    final sCtrl = TextEditingController(text: openSbi.toStringAsFixed(0));
    final pCtrl = TextEditingController(text: openPnb.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ओपनिंग बैलेंस सेट करें'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'गल्ला नकद (Cash) ₹'), keyboardType: TextInputType.number),
              TextField(controller: sCtrl, decoration: const InputDecoration(labelText: 'SBI खाता बैलेंस ₹'), keyboardType: TextInputType.number),
              TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'PNB खाता बैलेंस ₹'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              final sp = await SharedPreferences.getInstance();
              final nc = double.tryParse(cCtrl.text) ?? 0.0;
              final ns = double.tryParse(sCtrl.text) ?? 0.0;
              final np = double.tryParse(pCtrl.text) ?? 0.0;
              await sp.setDouble('op_cash', nc);
              await sp.setDouble('op_sbi', ns);
              await sp.setDouble('op_pnb', np);
              setState(() {
                openCash = nc;
                openSbi = ns;
                openPnb = np;
              });
              Navigator.pop(ctx);
            },
            child: const Text('सेव करें'),
          ),
        ],
      ),
    );
  }

  double _getBal(String ac) {
    double base = (ac == 'Cash') ? openCash : (ac == 'SBI' ? openSbi : openPnb);
    double diff = 0.0;
    for (var t in cash) {
      if (t['ac'] == ac) {
        final a = (t['a'] as num?)?.toDouble() ?? 0.0;
        diff += (t['t'] == 'In') ? a : -a;
      }
    }
    return base + diff;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    List filteredList = [];
    if (viewMode == 0) {
      filteredList = cash.where((x) => (x['d'] ?? '').toString().startsWith(todayStr)).toList();
    } else if (viewMode == 1) {
      filteredList = cash.where((x) => (x['d'] ?? '').toString().startsWith(monthStr)).toList();
    } else {
      filteredList = cash;
    }

    double periodIn = 0.0, periodOut = 0.0;
    for (var item in filteredList) {
      final a = (item['a'] as num?)?.toDouble() ?? 0.0;
      if (item['t'] == 'In') {
        periodIn += a;
      } else {
        periodOut += a;
      }
    }

    return Column(
      children: [
        // ऊपर बैलेंस समरी कार्ड + ओपनिंग बैलेंस एडिट बटन
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('कुल चालू बैलेंस (Net Total)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.indigo),
                    tooltip: 'ओपनिंग बैलेंस बदलें',
                    onPressed: _editOpeningBalance,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _balBox('गल्ला (Cash)', _getBal('Cash'), Colors.orange.shade800),
                  _balBox('SBI खाता', _getBal('SBI'), Colors.blue.shade800),
                  _balBox('PNB खाता', _getBal('PNB'), Colors.purple.shade800),
                ],
              ),
            ],
          ),
        ),

        // दैनिक (Daily), मासिक (Monthly), और ऑल फ़िल्टर स्विच
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('आज (Daily)')),
              ButtonSegment(value: 1, label: Text('इस माह (Monthly)')),
              ButtonSegment(value: 2, label: Text('पूरा रजिस्टर')),
            ],
            selected: {viewMode},
            onSelectionChanged: (set) => setState(() => viewMode = set.first),
          ),
        ),

        // चुने हुए समय की आवक/खर्च पट्टी
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('आवक: +₹$periodIn', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('खर्च: -₹$periodOut', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('बचत: ₹${periodIn - periodOut}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),

        // लेन-देन की लिस्ट
        Expanded(
          child: filteredList.isEmpty
              ? const Center(child: Text('इस अवधि में कोई लेन-देन नहीं है।', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (ctx, i) {
                    final it = filteredList[i];
                    final bool isIn = it['t'] == 'In';
                    final origIdx = cash.indexOf(it);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIn ? Colors.green.shade50 : Colors.red.shade50,
                          child: Icon(isIn ? Icons.south_west : Icons.north_east, color: isIn ? Colors.green : Colors.red, size: 20),
                        ),
                        title: Text('${it['m']} (${it['ac']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${it['desc'] ?? ''}\nतारीख: ${it['d'] ?? ''}', style: const TextStyle(fontSize: 11)),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isIn ? '+' : '-'} ₹${it['a']}',
                              style: TextStyle(color: isIn ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                              onPressed: () {
                                setState(() => cash.removeAt(origIdx));
                                _saveCash();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // नई एंट्री जोड़ने का फ्लोटिंग बटन
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('नई एंट्री'),
              onPressed: () {
                final amtCtrl = TextEditingController();
                final descCtrl = TextEditingController();
                String ac = 'Cash', t = 'In', cat = 'ई-मित्र टोकन';

                showDialog(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setD) => AlertDialog(
                      title: const Text('कैश / बैंक एंट्री जोड़ें'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: t,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'In', child: Text('आवक / जमा (+)')),
                                DropdownMenuItem(value: 'Out', child: Text('खर्च / निकासी (-)')),
                              ],
                              onChanged: (v) => setD(() => t = v!),
                            ),
                            DropdownButton<String>(
                              value: ac,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'Cash', child: Text('गल्ला (Cash)')),
                                DropdownMenuItem(value: 'SBI', child: Text('SBI बैंक खाता')),
                                DropdownMenuItem(value: 'PNB', child: Text('PNB बैंक खाता')),
                              ],
                              onChanged: (v) => set
                              
