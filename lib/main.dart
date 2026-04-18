import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
const Color kDark = Color(0xFF2B2118);
const Color kSoft = Color(0xFFF6EFE8);

const List<String> kWeekDays = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

const List<String> kFilterOptions = [
  'كل الطلبات',
  'اليوم',
  'غدًا',
  'هذا الأسبوع',
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

class ChefKambalaApp extends StatefulWidget {
  const ChefKambalaApp({super.key});

  @override
  State<ChefKambalaApp> createState() => _ChefKambalaAppState();
}

class _ChefKambalaAppState extends State<ChefKambalaApp> {
  bool loading = true;
  String? role;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedRole = prefs.getString('role');

    setState(() {
      loading = false;
      role = loggedIn ? savedRole : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashPage(),
      );
    }

    return MaterialApp(
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
          backgroundColor: Colors.white,
          foregroundColor: kDark,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: role == null
          ? const LoginPage()
          : role == 'manager'
              ? const ManagerPage()
              : const EmployeePage(),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kSoft,
      body: Center(
        child: CircularProgressIndicator(color: kPrimary),
      ),
    );
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final user = usernameController.text.trim();
    final pass = passwordController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    if (user == kManagerUsername && pass == kManagerPassword) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', 'manager');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerPage()),
      );
      return;
    }

    if (user == kWorkersUsername && pass == kWorkersPassword) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', 'worker');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeePage()),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('بيانات الدخول غير صحيحة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoft,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 160,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Chef Kambala',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: 'اسم المستخدم',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'دخول',
                            style: TextStyle(fontSize: 20),
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
class ManagerPage extends StatefulWidget {
  const ManagerPage({super.key});

  @override
  State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  String selectedFilter = 'كل الطلبات';

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('role');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _goToAddOrder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddOrderPage()),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'قيد التنفيذ';
      case 'done':
        return 'جاهز';
      case 'delivered':
        return 'تم التسليم';
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
      case 'delivered':
        return Colors.teal;
      default:
        return Colors.orange;
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

  int _countDone(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['status']?.toString() ?? '') == 'done';
    }).length;
  }

  int _countNotDone(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'pending';
      return status != 'done' && status != 'delivered';
    }).length;
  }

  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    if (selectedFilter == 'كل الطلبات') return docs;

    if (selectedFilter == 'اليوم') {
      final now = DateTime.now();
      final todayName = kWeekDays[now.weekday % 7];
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['deliveryDay']?.toString() ?? '') == todayName;
      }).toList();
    }

    if (selectedFilter == 'غدًا') {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowName = kWeekDays[tomorrow.weekday % 7];
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['deliveryDay']?.toString() ?? '') == tomorrowName;
      }).toList();
    }

    if (selectedFilter == 'هذا الأسبوع') {
      return docs;
    }

    if (kWeekDays.contains(selectedFilter)) {
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['deliveryDay']?.toString() ?? '') == selectedFilter;
      }).toList();
    }

    return docs;
  }

  Widget _buildTopSection(List<QueryDocumentSnapshot> docs) {
    final doneCount = _countDone(docs);
    final notDoneCount = _countNotDone(docs);

    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          height: 110,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const Text(
          'Chef Kambala',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: kDark,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.07),
                      blurRadius: 12,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$notDoneCount',
                      style: const TextStyle(
                        fontSize: 28,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.07),
                      blurRadius: 12,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$doneCount',
                      style: const TextStyle(
                        fontSize: 28,
                        color: kDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.07),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: selectedFilter,
            items: kFilterOptions
                .map(
                  (day) => DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedFilter = value;
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

  Widget _orderCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final customerName = data['customerName']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final orderType = data['orderType']?.toString() ?? '';
    final deliveryDay = data['deliveryDay']?.toString() ?? '';
    final deliveryDate = data['deliveryDate']?.toString() ?? '';
    final deliveryTime = data['deliveryTime']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(docId: doc.id, data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 12,
              offset: const Offset(0, 5),
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
                  fontWeight: FontWeight.bold,
                  color: kDark,
                ),
              ),
            const SizedBox(height: 8),
            if (phone.isNotEmpty)
              Text(
                phone,
                style: const TextStyle(fontSize: 18, color: kDark),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (orderType.isNotEmpty) _smallChip('النوع', orderType),
                if (deliveryDay.isNotEmpty) _smallChip('اليوم', deliveryDay),
                if (deliveryDate.isNotEmpty)
                  _smallChip('التاريخ', deliveryDate),
                if (deliveryTime.isNotEmpty)
                  _smallChip('الوقت', deliveryTime),
              ],
            ),
            const SizedBox(height: 12),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$title: $value',
        style: const TextStyle(
          fontSize: 15,
          color: kDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoft,
      appBar: AppBar(
        title: const Text('صفحة المدير'),
        actions: [
          IconButton(
            onPressed: _goToAddOrder,
            icon: const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddOrder,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          final allDocs = snapshot.data!.docs;
          final docs = _applyFilter(allDocs);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: _buildTopSection(allDocs),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد طلبات في هذا التصنيف',
                          style: TextStyle(fontSize: 20, color: kDark),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          return _orderCard(docs[index]);
                        },
                      ),
              ),
            ],
          );
        },
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
  final quantityController = TextEditingController();
  final totalController = TextEditingController();
  final paidController = TextEditingController();
  final detailsController = TextEditingController();
  final orderDateController = TextEditingController();
  final deliveryDateController = TextEditingController();
  final deliveryTimeController = TextEditingController();

  String orderType = 'كيكة';
  String period = 'صباحًا';
  Uint8List? pickedImageBytes;

  String get remainingAmount {
    final total = double.tryParse(totalController.text.trim()) ?? 0;
    final paid = double.tryParse(paidController.text.trim()) ?? 0;
    final remain = total - paid;
    if (remain <= 0) return '0';
    return remain.toStringAsFixed(remain.truncateToDouble() == remain ? 0 : 2);
  }

  String get deliveryDay {
    if (deliveryDateController.text.trim().isEmpty) return '';
    try {
      final parts = deliveryDateController.text.trim().split('-');
      if (parts.length != 3) return '';
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return kWeekDays[date.weekday % 7];
    } catch (_) {
      return '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      pickedImageBytes = bytes;
    });
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    final y = picked.year.toString().padLeft(4, '0');
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');

    setState(() {
      controller.text = '$y-$m-$d';
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return;

    final h = picked.hour.toString().padLeft(2, '0');
    final m = picked.minute.toString().padLeft(2, '0');

    setState(() {
      deliveryTimeController.text = '$h:$m';
    });
  }

  Future<void> _saveOrder() async {
    final customerName = customerNameController.text.trim();

    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسم الزبون أولاً')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('orders').add({
      'customerName': customerNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'writer': writerController.text.trim(),
      'orderType': orderType,
      'size': sizeController.text.trim(),
      'quantity': quantityController.text.trim(),
      'total': totalController.text.trim(),
      'paid': paidController.text.trim(),
      'remaining': remainingAmount,
      'details': detailsController.text.trim(),
      'orderDate': orderDateController.text.trim(),
      'deliveryDate': deliveryDateController.text.trim(),
      'deliveryDay': deliveryDay,
      'deliveryTime': deliveryTimeController.text.trim(),
      'period': period,
      'status': 'pending',
      'imageBase64':
          pickedImageBytes == null ? '' : base64Encode(pickedImageBytes!),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdByRole': 'manager',
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    writerController.dispose();
    sizeController.dispose();
    quantityController.dispose();
    totalController.dispose();
    paidController.dispose();
    detailsController.dispose();
    orderDateController.dispose();
    deliveryDateController.dispose();
    deliveryTimeController.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kDark,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCake = orderType == 'كيكة';

    return Scaffold(
      backgroundColor: kSoft,
      appBar: AppBar(
        title: const Text('إضافة طلب جديد'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    _sectionTitle('بيانات الزبون'),
                    TextField(
                      controller: customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الزبون',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: writerController,
                      decoration: const InputDecoration(
                        labelText: 'اسم من كتب الوصل',
                      ),
                    ),

                    _sectionTitle('بيانات الطلب'),
                    DropdownButtonFormField<String>(
                      value: orderType,
                      decoration: const InputDecoration(
                        labelText: 'نوع الطلب',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'كيكة', child: Text('كيكة')),
                        DropdownMenuItem(value: 'حلويات', child: Text('حلويات')),
                        DropdownMenuItem(value: 'معجنات', child: Text('معجنات')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          orderType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    if (isCake)
                      TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: 'القياس',
                        ),
                      ),

                    if (!isCake)
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الكمية',
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: totalController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'المبلغ الكلي',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: paidController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'المبلغ الواصل',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'المبلغ الباقي: $remainingAmount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: detailsController,
                      minLines: 4,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'تفاصيل الطلب',
                        alignLabelWithHint: true,
                      ),
                    ),

                    _sectionTitle('المواعيد'),
                    TextField(
                      controller: orderDateController,
                      readOnly: true,
                      onTap: () => _pickDate(orderDateController),
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الطلب',
                        suffixIcon: Icon(Icons.date_range),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deliveryDateController,
                      readOnly: true,
                      onTap: () => _pickDate(deliveryDateController),
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الاستلام',
                        suffixIcon: Icon(Icons.date_range),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        deliveryDay.isEmpty
                            ? 'يوم الاستلام: —'
                            : 'يوم الاستلام: $deliveryDay',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: deliveryTimeController,
                      readOnly: true,
                      onTap: _pickTime,
                      decoration: const InputDecoration(
                        labelText: 'وقت الاستلام',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: period,
                      decoration: const InputDecoration(
                        labelText: 'الفترة',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'صباحًا',
                          child: Text('صباحًا'),
                        ),
                        DropdownMenuItem(
                          value: 'مساءً',
                          child: Text('مساءً'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          period = value;
                        });
                      },
                    ),

                    _sectionTitle('الصورة'),
                    if (pickedImageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          pickedImageBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: kSoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text(
                            'لم يتم اختيار صورة',
                            style: TextStyle(fontSize: 18, color: kDark),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('اختيار صورة'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text(
                          'حفظ الطلب',
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
class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  String selectedFilter = 'كل الطلبات';

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('role');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث حالة الطلب')),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'قيد التنفيذ';
      case 'done':
        return 'جاهز';
      case 'delivered':
        return 'تم التسليم';
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
      case 'delivered':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    if (selectedFilter == 'كل الطلبات') return docs;

    if (selectedFilter == 'اليوم') {
      final now = DateTime.now();
      final todayName = kWeekDays[now.weekday % 7];
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['deliveryDay']?.toString() ?? '') == todayName;
      }).toList();
    }

    if (selectedFilter == 'غدًا') {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowName = kWeekDays[tomorrow.weekday % 7];
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['deliveryDay']?.toString() ?? '') == tomorrowName;
      }).toList();
    }

    if (selectedFilter == 'هذا الأسبوع') {
      return docs;
    }

    if (kWeekDays.contains(selectedFilter)) {
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['deliveryDay']?.toString() ?? '') == selectedFilter;
      }).toList();
    }

    return docs;
  }

  Widget _employeeCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final customerName = data['customerName']?.toString() ?? '';
    final orderType = data['orderType']?.toString() ?? '';
    final deliveryDay = data['deliveryDay']?.toString() ?? '';
    final deliveryDate = data['deliveryDate']?.toString() ?? '';
    final deliveryTime = data['deliveryTime']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(docId: doc.id, data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 12,
              offset: const Offset(0, 5),
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kDark,
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (orderType.isNotEmpty) _detailsChip('النوع', orderType),
                if (deliveryDay.isNotEmpty) _detailsChip('اليوم', deliveryDay),
                if (deliveryDate.isNotEmpty)
                  _detailsChip('التاريخ', deliveryDate),
                if (deliveryTime.isNotEmpty)
                  _detailsChip('الوقت', deliveryTime),
              ],
            ),
            const SizedBox(height: 14),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (status == 'pending')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(doc.id, 'accepted'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('استلام الطلب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (status != 'done')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(doc.id, 'done'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('تم الإنجاز'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$title: $value',
        style: const TextStyle(
          fontSize: 15,
          color: kDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoft,
      appBar: AppBar(
        title: const Text('صفحة العمال'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          final allDocs = snapshot.data!.docs;
          final docs = _applyFilter(allDocs);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.07),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    items: kFilterOptions
                        .map(
                          (day) => DropdownMenuItem(
                            value: day,
                            child: Text(day),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedFilter = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'فلترة الطلبات',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد طلبات حالياً',
                          style: TextStyle(fontSize: 20, color: kDark),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          return _employeeCard(docs[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const OrderDetailsPage({
    super.key,
    required this.docId,
    required this.data,
  });

  Widget _detailRow(String title, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          '$title: $value',
          style: const TextStyle(
            fontSize: 17,
            color: kDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBase64 = data['imageBase64']?.toString() ?? '';

    Uint8List? bytes;
    if (imageBase64.isNotEmpty) {
      try {
        bytes = base64Decode(imageBase64);
      } catch (_) {
        bytes = null;
      }
    }

    return Scaffold(
      backgroundColor: kSoft,
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
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
                if (bytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.memory(
                      bytes,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (bytes != null) const SizedBox(height: 18),

                _detailRow('اسم الزبون', data['customerName']?.toString() ?? ''),
                _detailRow('رقم الهاتف', data['phone']?.toString() ?? ''),
                _detailRow('اسم من كتب الوصل', data['writer']?.toString() ?? ''),
                _detailRow('نوع الطلب', data['orderType']?.toString() ?? ''),
                _detailRow('القياس', data['size']?.toString() ?? ''),
                _detailRow('الكمية', data['quantity']?.toString() ?? ''),
                _detailRow('المبلغ الكلي', data['total']?.toString() ?? ''),
                _detailRow('المبلغ الواصل', data['paid']?.toString() ?? ''),
                _detailRow('المبلغ الباقي', data['remaining']?.toString() ?? ''),
                _detailRow('تفاصيل الطلب', data['details']?.toString() ?? ''),
                _detailRow('تاريخ الطلب', data['orderDate']?.toString() ?? ''),
                _detailRow('تاريخ الاستلام', data['deliveryDate']?.toString() ?? ''),
                _detailRow('يوم الاستلام', data['deliveryDay']?.toString() ?? ''),
                _detailRow('وقت الاستلام', data['deliveryTime']?.toString() ?? ''),
                _detailRow('الفترة', data['period']?.toString() ?? ''),
                _detailRow('الحالة', data['status']?.toString() ?? ''),
              ],
            ),
          ),
        ),
      ),
    );
  }
}