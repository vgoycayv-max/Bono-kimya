import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;
final langPref = ValueNotifier<String>('sys');

const cats = ['Genel', 'Bilim', 'Tarih', 'Edebiyat'];
const langs = {'sys': 'Sistem / System', 'tr': 'Türkçe', 'en': 'English'};

const S = {
  'tr': {
    'feed': 'Akış', 'share': 'Paylaş', 'profile': 'Profil', 'admin': 'Yönetici',
    'search': 'Ara', 'all': 'Hepsi', 'title': 'Başlık', 'text': 'Metin',
    'send': 'Gönder', 'sent': 'Gönderildi, onay bekliyor', 'server': 'Sunucu adresi',
    'save': 'Kaydet', 'lang': 'Dil', 'key': 'Yönetici anahtarı (boş = normal kullanıcı)',
    'empty': 'Sayfa yok', 'approve': 'Seçilenleri onayla', 'approveAll': 'Hepsini onayla',
    'reject': 'Seçilenleri sil', 'block': 'Cihazı engelle', 'refresh': 'Yenile',
    'err': 'Hata', 'saved': 'Kaydedildi', 'welcome': 'Hoş geldin! Bir isim seç',
    'name': 'İsim (zorunlu)', 'about': 'Hakkında (isteğe bağlı)',
    'contact': 'İletişim (isteğe bağlı)', 'nameReq': 'İsim yazmak zorunlu',
    'start': 'Başla', 'write': 'Yorum yaz...', 'comments': 'Yorumlar',
    'commentSent': 'Yorum yayınlandı', 'commentHold': 'Yorum onay bekliyor',
    'savedOnly': 'Sadece kaydedilenler', 'fontSize': 'Yazı boyutu',
    'lineH': 'Satır aralığı', 'font': 'Yazı tipi', 'serif': 'Serif (kitap)',
    'sans': 'Sans (düz)', 'pendingPages': 'Sayfalar', 'pendingComments': 'Yorumlar',
    'commentMode': 'Ayar', 'auto': 'Yorumlar otomatik yayınlansın',
    'hold': 'Yorumlar benim onayımı beklesin', 'noItems': 'Bekleyen yok',
  },
  'en': {
    'feed': 'Feed', 'share': 'Share', 'profile': 'Profile', 'admin': 'Admin',
    'search': 'Search', 'all': 'All', 'title': 'Title', 'text': 'Text',
    'send': 'Send', 'sent': 'Sent, waiting for approval', 'server': 'Server address',
    'save': 'Save', 'lang': 'Language', 'key': 'Admin key (empty = normal user)',
    'empty': 'No pages', 'approve': 'Approve selected', 'approveAll': 'Approve all',
    'reject': 'Delete selected', 'block': 'Block device', 'refresh': 'Refresh',
    'err': 'Error', 'saved': 'Saved', 'welcome': 'Welcome! Pick a name',
    'name': 'Name (required)', 'about': 'About (optional)',
    'contact': 'Contact (optional)', 'nameReq': 'A name is required',
    'start': 'Start', 'write': 'Write a comment...', 'comments': 'Comments',
    'commentSent': 'Comment published', 'commentHold': 'Comment is waiting for approval',
    'savedOnly': 'Saved only', 'fontSize': 'Font size',
    'lineH': 'Line spacing', 'font': 'Font', 'serif': 'Serif (book)',
    'sans': 'Sans (plain)', 'pendingPages': 'Pages', 'pendingComments': 'Comments',
    'commentMode': 'Setting', 'auto': 'Publish comments automatically',
    'hold': 'Hold comments for my approval', 'noItems': 'Nothing pending',
  },
};

String get cl {
  final l = langPref.value == 'sys'
      ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
      : langPref.value;
  return S.containsKey(l) ? l : 'en';
}

String t(String k) => S[cl]![k] ?? k;

void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class Api {
  static String get base => (prefs.getString('server') ?? 'http://10.0.2.2:5000')
      .replaceAll(RegExp(r'/+$'), '');
  static String get dev => prefs.getString('dev')!;
  static Map<String, String> get h => {
        'Content-Type': 'application/json',
        'X-Admin-Key': prefs.getString('adminKey') ?? '',
      };

  static Future<dynamic> get(String p) async {
    final r = await http.get(Uri.parse('$base$p'), headers: h)
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw utf8.decode(r.bodyBytes);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static Future<dynamic> post(String p, Map b) async {
    final r = await http.post(Uri.parse('$base$p'), headers: h, body: jsonEncode(b))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw utf8.decode(r.bodyBytes);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  // Profili sunucuya bildirir (her yazma isleminden once cagrilir)
  static Future<void> reg() => post('/register', {
        'device': dev,
        'name': prefs.getString('name') ?? '',
        'about': prefs.getString('about') ?? '',
        'contact': prefs.getString('contact') ?? '',
      });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  if (prefs.getString('dev') == null) {
    final r = Random.secure();
    await prefs.setString(
        'dev', List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join());
  }
  langPref.value = prefs.getString('lang') ?? 'sys';
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: langPref,
        builder: (_, __, ___) => MaterialApp(
          title: 'Sayfa Paylaş',
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
          home: Root(),
        ),
      );
}

class Root extends StatefulWidget {
  Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  Widget build(BuildContext context) => (prefs.getString('name') ?? '').isEmpty
      ? Setup(onDone: () => setState(() {}))
      : Home();
}

class Setup extends StatefulWidget {
  final VoidCallback onDone;
  Setup({super.key, required this.onDone});
  @override
  State<Setup> createState() => _SetupState();
}

class _SetupState extends State<Setup> {
  final name = TextEditingController(), about = TextEditingController(), contact = TextEditingController();
  String msg = '';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const SizedBox(height: 40),
            Text(t('welcome'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: name, decoration: InputDecoration(labelText: t('name'))),
            TextField(controller: about, decoration: InputDecoration(labelText: t('about'))),
            TextField(controller: contact, decoration: InputDecoration(labelText: t('contact'))),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  setState(() => msg = t('nameReq'));
                  return;
                }
                await prefs.setString('name', name.text.trim());
                await prefs.setString('about', about.text.trim());
                await prefs.setString('contact', contact.text.trim());
                widget.onDone();
              },
              child: Text(t('start')),
            ),
            if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(msg)),
          ]),
        ),
      );
}

class Home extends StatefulWidget {
  Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int i = 0;
  bool get isAdmin => (prefs.getString('adminKey') ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      FeedTab(),
      ShareTab(),
      ProfileTab(onChanged: () => setState(() {})),
      if (isAdmin) AdminTab(),
    ];
    final items = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.dynamic_feed), label: t('feed')),
      NavigationDestination(icon: const Icon(Icons.edit), label: t('share')),
      NavigationDestination(icon: const Icon(Icons.person), label: t('profile')),
      if (isAdmin)
        NavigationDestination(icon: const Icon(Icons.admin_panel_settings), label: t('admin')),
    ];
    if (i >= tabs.length) i = 0;
    return Scaffold(
      body: SafeArea(child: tabs[i]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: items,
      ),
    );
  }
}

// ---------------- AKIS ----------------
class FeedTab extends StatefulWidget {
  FeedTab({super.key});
  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  String q = '', cat = '';
  bool savedOnly = false;
  late Future<dynamic> f;

  @override
  void initState() {
    super.initState();
    f = load();
  }

  Future<dynamic> load() => Api.get(
      '/pages?lang=$cl&device=${Api.dev}&saved=${savedOnly ? 1 : 0}'
      '&category=${Uri.encodeQueryComponent(cat)}&q=${Uri.encodeQueryComponent(q)}');

  void reload() => setState(() => f = load());

  Future<void> toggle(Map p, String what) async {
    try {
      await Api.reg();
      final r = await Api.post('/$what', {'device': Api.dev, 'id': p['id']});
      setState(() {
        if (what == 'like') {
          p['liked'] = r['on'];
          p['likes'] = r['count'];
        } else {
          p['saved'] = r['on'];
        }
      });
    } catch (e) {
      if (mounted) snack(context, '${t('err')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: t('search'), prefixIcon: const Icon(Icons.search)),
                onSubmitted: (v) {
                  q = v;
                  reload();
                },
              ),
            ),
            DropdownButton<String>(
              value: cat,
              items: [
                DropdownMenuItem(value: '', child: Text(t('all'))),
                ...cats.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) {
                cat = v ?? '';
                reload();
              },
            ),
            IconButton(
              tooltip: t('savedOnly'),
              icon: Icon(savedOnly ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () {
                savedOnly = !savedOnly;
                reload();
              },
            ),
          ]),
        ),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: f,
            builder: (_, s) {
              if (s.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.hasError) return Center(child: Text('${t('err')}: ${s.error}'));
              final list = s.data as List;
              if (list.isEmpty) return Center(child: Text(t('empty')));
              return RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(children: [for (final p in list) card(p)]),
              );
            },
          ),
        ),
      ]);

  Widget card(Map p) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Reader(p)))
              .then((_) => reload()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${p['author']} • ${p['category']}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(p['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(p['text'] ?? '', maxLines: 4, overflow: TextOverflow.ellipsis),
              Row(children: [
                IconButton(
                  icon: Icon(p['liked'] == 1 ? Icons.favorite : Icons.favorite_border,
                      color: p['liked'] == 1 ? Colors.red : null),
                  onPressed: () => toggle(p, 'like'),
                ),
                Text('${p['likes']}'),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 4),
                Text('${p['comments']}'),
                const Spacer(),
                IconButton(
                  icon: Icon(p['saved'] == 1 ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () => toggle(p, 'save'),
                ),
              ]),
            ]),
          ),
        ),
      );
}

// ---------------- OKUYUCU ----------------
class Reader extends StatefulWidget {
  final Map p;
  const Reader(this.p, {super.key});
  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  double fs = prefs.getDouble('fs') ?? 19;
  double lh = prefs.getDouble('lh') ?? 1.6;
  String ff = prefs.getString('ff') ?? 'serif';
  final cm = TextEditingController();
  late Future<dynamic> cf;

  @override
  void initState() {
    super.initState();
    cf = Api.get('/comments?id=${widget.p['id']}');
  }

  void settings() => showModalBottomSheet(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (c, ss) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${t('fontSize')}: ${fs.round()}'),
              Slider(
                value: fs, min: 14, max: 34,
                onChanged: (v) {
                  ss(() {});
                  setState(() => fs = v);
                  prefs.setDouble('fs', v);
                },
              ),
              Text('${t('lineH')}: ${lh.toStringAsFixed(1)}'),
              Slider(
                value: lh, min: 1.2, max: 2.2,
                onChanged: (v) {
                  ss(() {});
                  setState(() => lh = v);
                  prefs.setDouble('lh', v);
                },
              ),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'serif', label: Text(t('serif'))),
                  ButtonSegment(value: 'sans-serif', label: Text(t('sans'))),
                ],
                selected: {ff},
                onSelectionChanged: (s) {
                  ss(() {});
                  setState(() => ff = s.first);
                  prefs.setString('ff', s.first);
                },
              ),
            ]),
          ),
        ),
      );

  Future<void> sendComment() async {
    if (cm.text.trim().isEmpty) return;
    try {
      await Api.reg();
      final r = await Api.post('/comment', {'device': Api.dev, 'id': widget.p['id'], 'text': cm.text});
      cm.clear();
      if (mounted) {
        snack(context, r['status'] == 'approved' ? t('commentSent') : t('commentHold'));
        setState(() => cf = Api.get('/comments?id=${widget.p['id']}'));
      }
    } catch (e) {
      if (mounted) snack(context, '${t('err')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.white,
          title: Text(widget.p['author'] ?? ''),
          actions: [IconButton(icon: const Icon(Icons.text_fields), onPressed: settings)],
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
          Text(widget.p['title'],
              style: TextStyle(fontSize: fs + 6, fontWeight: FontWeight.bold,
                  fontFamily: ff, color: Colors.black87, height: 1.3)),
          const SizedBox(height: 16),
          SelectableText(widget.p['text'] ?? '',
              style: TextStyle(fontSize: fs, height: lh, fontFamily: ff, color: Colors.black87)),
          const Divider(height: 40),
          Text(t('comments'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          FutureBuilder<dynamic>(
            future: cf,
            builder: (_, s) {
              if (!s.hasData) return const SizedBox();
              return Column(children: [
                for (final c in s.data as List)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c['name'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    subtitle: Text(c['text'], style: const TextStyle(fontSize: 15, color: Colors.black87)),
                  ),
              ]);
            },
          ),
          Row(children: [
            Expanded(child: TextField(controller: cm, decoration: InputDecoration(hintText: t('write')))),
            IconButton(icon: const Icon(Icons.send), onPressed: sendComment),
          ]),
        ]),
      );
}

// ---------------- PAYLAS ----------------
class ShareTab extends StatefulWidget {
  ShareTab({super.key});
  @override
  State<ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends State<ShareTab> {
  final title = TextEditingController(), body = TextEditingController();
  String cat = cats[0], msg = '';

  Future<void> send() async {
    try {
      await Api.reg();
      await Api.post('/submit', {
        'device': Api.dev, 'title': title.text, 'text': body.text, 'lang': cl, 'category': cat,
      });
      title.clear();
      body.clear();
      setState(() => msg = t('sent'));
    } catch (e) {
      setState(() => msg = '${t('err')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
        TextField(controller: title, decoration: InputDecoration(labelText: t('title'))),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: cat,
          items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => cat = v ?? cats[0]),
        ),
        TextField(
            controller: body, maxLines: 12,
            decoration: InputDecoration(labelText: t('text'), border: const OutlineInputBorder())),
        const SizedBox(height: 8),
        FilledButton(onPressed: send, child: Text(t('send'))),
        if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(msg)),
      ]);
}

// ---------------- PROFIL / AYARLAR ----------------
class ProfileTab extends StatefulWidget {
  final VoidCallback onChanged;
  ProfileTab({super.key, required this.onChanged});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final name = TextEditingController(text: prefs.getString('name') ?? '');
  final about = TextEditingController(text: prefs.getString('about') ?? '');
  final contact = TextEditingController(text: prefs.getString('contact') ?? '');
  final server = TextEditingController(text: prefs.getString('server') ?? 'http://10.0.2.2:5000');
  final key = TextEditingController(text: prefs.getString('adminKey') ?? '');
  String msg = '';

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(12), children: [
        TextField(controller: name, decoration: InputDecoration(labelText: t('name'))),
        TextField(controller: about, decoration: InputDecoration(labelText: t('about'))),
        TextField(controller: contact, decoration: InputDecoration(labelText: t('contact'))),
        const Divider(height: 32),
        TextField(controller: server, decoration: InputDecoration(labelText: t('server'))),
        TextField(controller: key, decoration: InputDecoration(labelText: t('key'))),
        const SizedBox(height: 8),
        Text(t('lang')),
        DropdownButton<String>(
          value: langPref.value,
          items: langs.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) async {
            await prefs.setString('lang', v ?? 'sys');
            langPref.value = v ?? 'sys';
          },
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) {
              setState(() => msg = t('nameReq'));
              return;
            }
            await prefs.setString('name', name.text.trim());
            await prefs.setString('about', about.text.trim());
            await prefs.setString('contact', contact.text.trim());
            await prefs.setString('server', server.text.trim());
            await prefs.setString('adminKey', key.text.trim());
            setState(() => msg = t('saved'));
            widget.onChanged();
          },
          child: Text(t('save')),
        ),
        if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(msg)),
      ]);
}

// ---------------- YONETICI ----------------
class AdminTab extends StatelessWidget {
  AdminTab({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Column(children: [
          TabBar(tabs: [
            Tab(text: t('pendingPages')),
            Tab(text: t('pendingComments')),
            Tab(text: t('commentMode')),
          ]),
          Expanded(
            child: TabBarView(children: [
              ModList(list: '/admin/pending', approve: '/admin/approve', reject: '/admin/reject'),
              ModList(list: '/admin/comments', approve: '/admin/comment_approve', reject: '/admin/comment_reject'),
              ModeSetting(),
            ]),
          ),
        ]),
      );
}

class ModList extends StatefulWidget {
  final String list, approve, reject;
  ModList({super.key, required this.list, required this.approve, required this.reject});
  @override
  State<ModList> createState() => _ModListState();
}

class _ModListState extends State<ModList> {
  List items = [];
  final sel = <int>{};
  String msg = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = await Api.get(widget.list);
      setState(() {
        items = d as List;
        sel.clear();
        msg = '';
      });
    } catch (e) {
      setState(() => msg = '${t('err')}: $e');
    }
  }

  Future<void> act(String path, Map b) async {
    try {
      await Api.post(path, b);
      await load();
    } catch (e) {
      setState(() => msg = '${t('err')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = items.where((p) => sel.contains(p['id'])).map((p) => p['device']).toSet().toList();
    return Column(children: [
      Wrap(spacing: 4, children: [
        TextButton(onPressed: load, child: Text(t('refresh'))),
        TextButton(onPressed: () => act(widget.approve, {'ids': sel.toList()}), child: Text(t('approve'))),
        TextButton(onPressed: () => act(widget.approve, {'all': true}), child: Text(t('approveAll'))),
        TextButton(onPressed: () => act(widget.reject, {'ids': sel.toList()}), child: Text(t('reject'))),
        TextButton(onPressed: () => act('/admin/block', {'devices': devices}), child: Text(t('block'))),
      ]),
      if (msg.isNotEmpty) Text(msg),
      Expanded(
        child: items.isEmpty
            ? Center(child: Text(t('noItems')))
            : ListView(children: [
                for (final p in items)
                  CheckboxListTile(
                    value: sel.contains(p['id']),
                    onChanged: (v) => setState(() {
                      v == true ? sel.add(p['id']) : sel.remove(p['id']);
                    }),
                    title: Text(p['title'] ?? ''),
                    subtitle: Text('${p['name']} • ${p['device'].toString().substring(0, 6)}\n${p['text']}',
                        maxLines: 4, overflow: TextOverflow.ellipsis),
                  ),
              ]),
      ),
    ]);
  }
}

class ModeSetting extends StatefulWidget {
  ModeSetting({super.key});
  @override
  State<ModeSetting> createState() => _ModeSettingState();
}

class _ModeSettingState extends State<ModeSetting> {
  String mode = 'auto', msg = '';

  @override
  void initState() {
    super.initState();
    Api.get('/admin/settings').then((d) => setState(() => mode = d['comment_mode'] ?? 'auto')).catchError(
        (e) => setState(() => msg = '${t('err')}: $e'));
  }

  Future<void> set(String? v) async {
    try {
      await Api.post('/admin/settings', {'comment_mode': v});
      setState(() {
        mode = v ?? 'auto';
        msg = t('saved');
      });
    } catch (e) {
      setState(() => msg = '${t('err')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) => ListView(children: [
        RadioListTile<String>(value: 'auto', groupValue: mode, onChanged: set, title: Text(t('auto'))),
        RadioListTile<String>(value: 'hold', groupValue: mode, onChanged: set, title: Text(t('hold'))),
        if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(msg)),
      ]);
}
