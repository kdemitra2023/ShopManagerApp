import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class VaultScreen extends StatefulWidget {
  final String shopName;
  final String shopPhone;
  const VaultScreen({super.key, required this.shopName, required this.shopPhone});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  int _subTab = 0;
  List sso = [];
  List work = [];

  final exams = const [
    {'n': 'Rajasthan CET (समान पात्रता परीक्षा)', 'd': 'वर्ष 2026 अपडेट', 'b': 'RSMSSB जयपुर'},
    {'n': 'REET Mains (शिक्षक भर्ती)', 'd': 'घोषित शिड्यूल 2026', 'b': 'RSSB बोर्ड'},
    {'n': 'Rajasthan LDC / कनिष्ठ सहायक', 'd': '10,644 पद (2026)', 'b': 'RSMSSB बोर्ड'},
    {'n': 'RPSC Programmer & 1st Grade', 'd': 'परीक्षा वर्ष 2026', 'b': 'RPSC अजमेर'},
    {'n': 'Railway RRB भर्ती', 'd': 'राष्ट्रीय भर्ती 2026', 'b': 'भारतीय रेलवे'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      sso = json.decode(p.getString('s_d') ?? '[]');
      work = json.decode(p.getString('w_d') ?? '[]');
    });
  }

  void _save(String k, dynamic val) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(k, json.encode(val));
  }

  void _sendWa(String phone, String msg) async {
    final c = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final f = c.length == 10 ? '91$c' : c;
    if (f.isNotEmpty) {
      final u = Uri.parse('https://wa.me/$f?text=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _subTab == 0 ? Colors.indigo : Colors.grey),
              onPressed: () => setState(() => _subTab = 0),
              child: const Text('SSO लॉकर', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _subTab == 1 ? Colors.indigo : Colors.grey),
              onPressed: () => setState(() => _subTab = 1),
              child: const Text('वर्क डायरी', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _subTab == 2 ? Colors.indigo : Colors.grey),
              onPressed: () => setState(() => _subTab = 2),
              child: const Text('एग्जाम 2026', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: _subTab == 0 ? _ssoView() : (_subTab == 1 ? _workView() : _examView()),
        ),
      ],
    );
  }

  Widget _ssoView() {
    return Scaffold(
      body: sso.isEmpty
          ? const Center(child: Text('कोई SSO क्रेडेंशियल नहीं है।'))
          : ListView.builder(
              itemCount: sso.length,
              itemBuilder: (c, i) {
                final it = sso[i];
                return Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.security, color: Colors.blueGrey),
                    title: Text(it['n'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('SSO: ${it['s']}'),
                    children: [
                      ListTile(
                        title: Text('Password: ${it['ps']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: it['ps'] ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('पासवर्ड कॉपी हो गया!')));
                          },
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          final n = TextEditingController(), s = TextEditingController(), ps = TextEditingController();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('नया SSO जोड़ें'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: n, decoration: const InputDecoration(labelText: 'ग्राहक का नाम *')),
                TextField(controller: s, decoration: const InputDecoration(labelText: 'SSO ID')),
                TextField(controller: ps, decoration: const InputDecoration(labelText: 'SSO पासवर्ड')),
              ]),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (n.text.isNotEmpty) {
                      setState(() => sso.add({'n': n.text, 's': s.text, 'ps': ps.text}));
                      _save('s_d', sso);
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
    );
  }

  Widget _workView() {
    return Scaffold(
      body: work.isEmpty
          ? const Center(child: Text('कोई काम पेंडिंग नहीं है।'))
          : ListView.builder(
              itemCount: work.length,
              itemBuilder: (c, i) {
                final it = work[i];
                return ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.blue),
                  title: Text('${it['n']} - ${it['w']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('टोकन: ${it['tk']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.green),
                        tooltip: 'तैयार है WhatsApp भेजें',
                        onPressed: () => _sendWa(it['p'], 'नमस्ते ${it['n']} जी, आपका कार्य (${it['w']}) टोकन: ${it['tk']} तैयार है। दुकान ${widget.shopName} से प्राप्त कर लें।'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                          setState(() => work.removeAt(i));
                          _save('w_d', work);
                        },
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
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
    );
  }

  Widget _examView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: exams.length,
      itemBuilder: (c, i) => Card(
        child: ListTile(
          leading: const Icon(Icons.event, color: Colors.deepOrange),
          title: Text(exams[i]['n']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${exams[i]['b']} • ${exams[i]['d']}'),
        ),
      ),
    );
  }
}
