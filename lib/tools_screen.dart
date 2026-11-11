import 'package:flutter/material.dart';

class ToolsScreen extends StatefulWidget {
  final Function(double) onShowQr;
  const ToolsScreen({super.key, required this.onShowQr});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final Map<int, int> notes = {500: 0, 200: 0, 100: 0, 50: 0, 20: 0, 10: 0};
  final calcC = TextEditingController();
  double aepsFee = 0, aepsTot = 0;

  final rates = const [
    {'s': 'मूल / जाति प्रमाण पत्र', 'r': '₹100'},
    {'s': 'जन आधार नया/संशोधन', 'r': '₹50-100'},
    {'s': 'पैन कार्ड नया/सुधार', 'r': '₹150-200'},
    {'s': 'परीक्षा फॉर्म फीस', 'r': '₹100+टोकन'},
    {'s': 'फोटोकॉपी प्रति पेज', 'r': '₹3 (बोथ ₹5)'},
    {'s': '8 पासपोर्ट फोटो शीट', 'r': '₹50'},
    {'s': 'A4 लेमिनेशन', 'r': '₹30'},
  ];

  @override
  Widget build(BuildContext context) {
    int sum = 0;
    notes.forEach((k, v) => sum += (k * v));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade800,
          child: Text('गल्ला कुल नकदी: ₹$sum', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 10),
        const Text('💵 नोटों की गिनती', style: TextStyle(fontWeight: FontWeight.bold)),
        ...notes.keys.map((k) => Card(
              child: ListTile(
                dense: true,
                leading: Text('₹$k', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                title: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'संख्या', isDense: true),
                  onChanged: (v) => setState(() => notes[k] = int.tryParse(v) ?? 0),
                ),
                trailing: Text('= ₹${k * notes[k]!}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
            )),
        const SizedBox(height: 15),
        const Text('⚡ AEPS चार्ज कैलकुलेटर', style: TextStyle(fontWeight: FontWeight.bold)),
        Card(
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(
                controller: calcC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'रकम (₹)'),
                onChanged: (v) {
                  double a = double.tryParse(v) ?? 0;
                  double f = a <= 1000 ? 20 : (a <= 3000 ? 40 : (a <= 10000 ? 100 : a * 0.01));
                  setState(() {
                    aepsFee = f;
                    aepsTot = a + f;
                  });
                },
              ),
              const SizedBox(height: 6),
              Text('चार्ज: ₹$aepsFee | कुल लें: ₹$aepsTot', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              if (aepsTot > 0) ElevatedButton(onPressed: () => widget.onShowQr(aepsTot), child: const Text('QR दिखाएं')),
            ]),
          ),
        ),
        const SizedBox(height: 15),
        const Text('📋 सर्विस रेट लिस्ट', style: TextStyle(fontWeight: FontWeight.bold)),
        ...rates.map((r) => Card(child: ListTile(dense: true, title: Text(r['s']!), trailing: Text(r['r']!, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))))),
      ],
    );
  }
}
