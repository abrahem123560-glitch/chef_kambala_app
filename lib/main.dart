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
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFB8A99C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFB8A99C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
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
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final user = userController.text.trim();
    final pass = passController.text.trim();

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
      const SnackBar(content: Text("بيانات الدخول غير صحيحة")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoft,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chef Kambala',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: kDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: userController,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'دخول',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
  String _filter = 'كل الطلبات';

  bool get isManager => widget.role == 'manager';

  Future<void> _goToAddOrderPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddOrderPage(),
      ),
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
        return 'جاهز';
      default:
        return 'لم يكتمل';
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

    return '$y-$m-$d  $h:$min';
  }

  int _countByStatus(List<QueryDocumentSnapshot> docs, String status) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['status']?.toString() ?? 'pending') == status;
    }).length;
  }

  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    if (_filter == 'كل الطلبات') return docs;
    if (_filter == 'جاهز') {
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['status']?.toString() ?? '') == 'done';
      }).toList();
    }
    if (_filter == 'لم يكتمل') {
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['status']?.toString() ?? 'pending') != 'done';
      }).toList();
    }
    return docs;
  }

  Widget _buildStatsAndFilter(List<QueryDocumentSnapshot> docs) {
    final doneCount = _countByStatus(docs, 'done');
    final notDoneCount = docs.length - doneCount;

    return Column(
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chef Kambala',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: kDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.07),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'لم يكتمل',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$notDoneCount',
                      style: const TextStyle(
                        fontSize: 30,
                        color: kDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.07),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'جاهز',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$doneCount',
                      style: const TextStyle(
                        fontSize: 30,
                        color: kDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _filter,
            items: const [
              DropdownMenuItem(value: 'كل الطلبات', child: Text('كل الطلبات')),
              DropdownMenuItem(value: 'لم يكتمل', child: Text('لم يكتمل')),
              DropdownMenuItem(value: 'جاهز', child: Text('جاهز')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _filter = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'فلترة الطلبات',
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildOrderCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final customerName = data['customerName']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final writer = data['writer']?.toString() ?? '';
    final orderType = data['orderType']?.toString() ?? '';
    final size = data['size']?.toString() ?? '';
    final total = data['total']?.toString() ?? '';
    final paid = data['paid']?.toString() ?? '';
    final details = data['details']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';
    final createdAt = _formatTimestamp(data['createdAt']);
    final updatedAt = _formatTimestamp(data['updatedAt']);

    final remaining = (() {
      final totalNum = double.tryParse(total) ?? 0;
      final paidNum = double.tryParse(paid) ?? 0;
      final remain = totalNum - paidNum;
      if (remain <= 0) return '0';
      return remain.toStringAsFixed(remain.truncateToDouble() == remain ? 0 : 2);
    })();

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
          if (customerName.isNotEmpty)
            Text(
              customerName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kDark,
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (phone.isNotEmpty) _infoChip('الهاتف', phone),
              if (writer.isNotEmpty) _infoChip('كاتب الوصل', writer),
              if (orderType.isNotEmpty) _infoChip('نوع الطلب', orderType),
              if (size.isNotEmpty) _infoChip('القياس', size),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                details,
                style: const TextStyle(
                  fontSize: 17,
                  color: kDark,
                ),
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
                    fontSize: 15,
                  ),
                ),
              if (updatedAt.isNotEmpty)
                Text(
                  'آخر تحديث: $updatedAt',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _moneyCard('المبلغ الكلي', total),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _moneyCard('الواصل', paid),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _moneyCard('الباقي', remaining),
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
                  label: const Text('استلام الطلب'),
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

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 15,
          color: kDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _moneyCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.78),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '0' : value,
            style: const TextStyle(
              fontSize: 18,
              color: kDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isManager ? 'صفحة المدير' : 'صفحة العمال'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              onPressed: _goToAddOrderPage,
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('إضافة طلب'),
            )
          : null,
      body: SafeArea(
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

            final allDocs = snapshot.data!.docs;
            final docs = _applyFilter(allDocs);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: _buildStatsAndFilter(allDocs),
                ),
                Expanded(
                  child: docs.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد طلبات حالياً',
                            style: TextStyle(fontSize: 22),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildOrderCard(context, doc, data);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final customerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final writerController = TextEditingController();
  final sizeController = TextEditingController();
  final totalController = TextEditingController();
  final paidController = TextEditingController();
  final detailsController = TextEditingController();

  String orderType = 'كيكة';

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    writerController.dispose();
    sizeController.dispose();
    totalController.dispose();
    paidController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> sendOrder() async {
    final customerName = customerNameController.text.trim();
    final phone = phoneController.text.trim();
    final writer = writerController.text.trim();
    final size = sizeController.text.trim();
    final total = totalController.text.trim();
    final paid = paidController.text.trim();
    final details = detailsController.text.trim();

    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسم الزبون أولاً')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('orders').add({
      'customerName': customerName,
      'phone': phone,
      'writer': writer,
      'orderType': orderType,
      'size': size,
      'total': total,
      'paid': paid,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdByRole': 'manager',
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoft,
      appBar: AppBar(
        title: const Text("إضافة طلب جديد"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                "assets/logo.png",
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                      controller: customerNameController,
                      decoration: const InputDecoration(
                        labelText: "اسم الزبون",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: "رقم الهاتف",
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: writerController,
                      decoration: const InputDecoration(
                        labelText: "اسم من كتب الوصل",
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: orderType,
                      decoration: const InputDecoration(
                        labelText: "نوع الطلب",
                      ),
                      items: const [
                        DropdownMenuItem(value: "كيكة", child: Text("كيكة")),
                        DropdownMenuItem(value: "حلويات", child: Text("حلويات")),
                        DropdownMenuItem(value: "معجنات", child: Text("معجنات")),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          orderType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(
                        labelText: "القياس",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: totalController,
                      decoration: const InputDecoration(
                        labelText: "المبلغ الكلي",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidController,
                      decoration: const InputDecoration(
                        labelText: "المبلغ الواصل",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailsController,
                      minLines: 4,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "تفاصيل الطلب",
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: sendOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          "حفظ الطلب",
                          style: TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}