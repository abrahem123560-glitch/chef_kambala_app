import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChefKambalaApp());
}

const String kManagerUsername = 'manager';
const String kManagerPassword = '1234';
const String kWorkersUsername = 'workers';
const String kWorkersPassword = '1111';

const Color kPrimary = Color(0xFFD98A3A);
const Color kPrimaryDark = Color(0xFFB96E27);
const Color kDark = Color(0xFF33261D);
const Color kSoft = Color(0xFFF4EEE8);
const Color kCard = Colors.white;

class ChefKambalaApp extends StatefulWidget {
  const ChefKambalaApp({super.key});

  @override
  State<ChefKambalaApp> createState() => _ChefKambalaAppState();
}

class _ChefKambalaAppState extends State<ChefKambalaApp> {
  bool _loading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('role');
    setState(() {
      _role = savedRole;
      _loading = false;
    });
  }

  Future<void> _login(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    setState(() => _role = role);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    setState(() => _role = null);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chef Kambala',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: kSoft,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimary,
            primary: kPrimary,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: kPrimary,
            foregroundColor: Colors.black,
            centerTitle: false,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFB8A99C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFB8A99C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: kPrimaryDark, width: 1.5),
            ),
          ),
        ),
        home: _loading
            ? const SplashPage()
            : _role == null
                ? LoginPage(onLogin: _login)
                : HomePage(role: _role!, onLogout: _logout),
      ),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: kPrimaryDark),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final Future<void> Function(String role) onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (user == kManagerUsername && pass == kManagerPassword) {
      await widget.onLogin('manager');
      return;
    }

    if (user == kWorkersUsername && pass == kWorkersPassword) {
      await widget.onLogin('worker');
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اسم المستخدم أو كلمة المرور غير صحيحة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chef Kambala',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _hidePassword = !_hidePassword);
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'دخول',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'حساب المدير: manager / 1234',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'حساب العمال: workers / 1111',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String role;
  final Future<void> Function() onLogout;

  const HomePage({
    super.key,
    required this.role,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();

  bool get isManager => widget.role == 'manager';

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _addOrder() async {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب عنوان الطلب أولاً')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('orders').add({
      'title': title,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdByRole': widget.role,
    });

    _titleController.clear();
    _detailsController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال الطلب بنجاح')),
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث الحالة إلى: ${_statusLabel(status)}')),
    );
  }

  Future<void> _deleteOrder(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الطلب')),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'قيد التنفيذ';
      case 'done':
        return 'مكتمل';
      default:
        return 'بانتظار العمال';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Color _cardColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue.shade50;
      case 'done':
        return Colors.green.shade50;
      default:
        return Colors.white;
    }
  }

  String _formatTimestamp(dynamic value) {
    if (value == null) return '';
    if (value is! Timestamp) return value.toString();
    final dt = value.toDate();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min  $d-$m-$y';
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الطلب',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsController,
            minLines: 4,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'تفاصيل الطلب',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _addOrder,
              child: const Text(
                'إرسال الطلب',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final title = data['title']?.toString() ?? '';
    final details = data['details']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';
    final createdAt = _formatTimestamp(data['createdAt']);
    final updatedAt = _formatTimestamp(data['updatedAt']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor(status),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: kDark,
              ),
            ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              details,
              style: const TextStyle(
                fontSize: 20,
                color: kDark,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              if (createdAt.isNotEmpty)
                Text(
                  'أنشئ: $createdAt',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              if (updatedAt.isNotEmpty)
                Text(
                  'آخر تحديث: $updatedAt',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!isManager && status == 'pending')
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(doc.id, 'accepted'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('استلام'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              if (!isManager && status != 'done')
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(doc.id, 'done'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('تم الإنجاز'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              if (isManager)
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(doc.id, 'pending'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إرجاع للانتظار'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              if (isManager)
                ElevatedButton.icon(
                  onPressed: () => _deleteOrder(doc.id),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isManager ? 'لوحة المدير' : 'لوحة العمال'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isManager) _buildHeaderCard(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'صار خطأ:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: kPrimaryDark),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد طلبات حالياً',
                        style: TextStyle(fontSize: 22),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildOrderCard(context, doc, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}