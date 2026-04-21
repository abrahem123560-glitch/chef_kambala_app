import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

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
  'المؤرشفة',
];

const List<String> kBranches = [
  'استلام فرع الدور',
  'استلام فرع الدولعي',
  'توصيل'
];

const List<String> kBranchFilterOptions = [
  'كل الفروع',
  'استلام فرع الدور',
  'استلام فرع الدولعي',
  'توصيل'
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

    if (!mounted) return;
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kPrimary, width: 1.4),
          ),
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
    return Scaffold(
      backgroundColor: kSoft,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: kPrimary),
          ],
        ),
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
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    if (username == kManagerUsername && password == kManagerPassword) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', 'manager');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerPage()),
      );
      return;
    }

    if (username == kWorkersUsername && password == kWorkersPassword) {
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
                  fit: BoxFit.contain,
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
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(20),
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
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kDark,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.black,
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
  String selectedBranchFilter = 'كل الفروع';

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

  Future<bool> _confirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _archiveOrder(String docId) async {
    final ok = await _confirmDialog('أرشفة', 'هل تريد أرشفة هذا الطلب؟');
    if (!ok) return;

    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'archived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الأرشفة')),
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

  int _countDone(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['archived'] == true) return false;
      return (data['status']?.toString() ?? '') == 'done';
    }).length;
  }

  int _countNotDone(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['archived'] == true) return false;
      final status = data['status']?.toString() ?? 'pending';
      return status != 'done' && status != 'delivered';
    }).length;
  }

  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    List<QueryDocumentSnapshot> filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      bool isArchived = data['archived'] == true;
      if (selectedFilter == 'المؤرشفة') return isArchived;
      return !isArchived;
    }).toList();

    if (selectedFilter != 'كل الطلبات' && selectedFilter != 'المؤرشفة' && selectedFilter != 'هذا الأسبوع') {
      String targetDay = selectedFilter;
      if (selectedFilter == 'اليوم') {
        targetDay = kWeekDays[DateTime.now().weekday % 7];
      } else if (selectedFilter == 'غدًا') {
        targetDay = kWeekDays[DateTime.now().add(const Duration(days: 1)).weekday % 7];
      }
      
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['deliveryDay']?.toString() ?? '') == targetDay;
      }).toList();
    }

    if (selectedBranchFilter != 'كل الفروع') {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['branch']?.toString() ?? 'استلام فرع الدور') == selectedBranchFilter;
      }).toList();
    }

    return filtered;
  }

  Widget _buildTopSection(List<QueryDocumentSnapshot> docs) {
    final doneCount = _countDone(docs);
    final notDoneCount = _countNotDone(docs);
    
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          height: 30,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 2),
        const Text(
          'Chef Kambala',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kDark,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('لم يكتمل', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('$notDoneCount', style: const TextStyle(fontSize: 14, color: kDark, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('جاهز', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('$doneCount', style: const TextStyle(fontSize: 14, color: kDark, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedFilter,
                  iconSize: 18,
                  items: kFilterOptions
                      .map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(fontSize: 11))))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedFilter = value);
                  },
                  decoration: const InputDecoration(contentPadding: EdgeInsets.zero, isDense: true, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedBranchFilter,
                  iconSize: 18,
                  items: kBranchFilterOptions
                      .map((branch) => DropdownMenuItem(value: branch, child: Text(branch, style: const TextStyle(fontSize: 11))))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedBranchFilter = value);
                  },
                  decoration: const InputDecoration(contentPadding: EdgeInsets.zero, isDense: true, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                ),
              ),
            ),
          ],
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
    
    final rawTime = data['deliveryTime']?.toString() ?? '';
    final period = data['period']?.toString() ?? '';
    final cleanTime = rawTime.replaceAll(RegExp(r'[^0-9:]'), '').trim();
    final deliveryTime = cleanTime.isNotEmpty ? '\u200E$cleanTime $period' : '';

    final status = data['status']?.toString() ?? 'pending';
    final branch = data['branch']?.toString() ?? 'استلام فرع الدور';

    final isDoneOrDelivered = status == 'done' || status == 'delivered';
    final cardColor = isDoneOrDelivered ? const Color(0xFF1B5E20) : Colors.white;
    final textColor = isDoneOrDelivered ? Colors.white : kDark;
    final subtitleColor = isDoneOrDelivered ? Colors.white70 : kDark;

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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDoneOrDelivered ? Border.all(color: Colors.greenAccent, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: branch == 'توصيل' ? Colors.redAccent : (isDoneOrDelivered ? Colors.green.shade800 : kPrimary),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Text(
                branch,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (customerName.isNotEmpty)
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (phone.isNotEmpty)
                    Text(
                      phone,
                      style: TextStyle(fontSize: 18, color: textColor),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (orderType.isNotEmpty) _smallChip('النوع', orderType, isDoneOrDelivered),
                      if (deliveryDay.isNotEmpty) _smallChip('اليوم', deliveryDay, isDoneOrDelivered),
                      if (deliveryDate.isNotEmpty) _smallChip('التاريخ', deliveryDate, isDoneOrDelivered),
                      if (deliveryTime.isNotEmpty) _smallChip('الوقت', deliveryTime, isDoneOrDelivered),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDoneOrDelivered ? Colors.white24 : _statusColor(status).withOpacity(.13),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: isDoneOrDelivered ? Colors.white : _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddOrderPage(
                                editDocId: doc.id,
                                existingData: data,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.edit_outlined, color: textColor),
                        label: Text('تعديل', style: TextStyle(color: textColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: subtitleColor),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _archiveOrder(doc.id),
                        icon: Icon(Icons.archive_outlined, color: textColor),
                        tooltip: 'أرشفة',
                      ),
                      IconButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('حذف الطلب'),
                              content: const Text('هل أنت متأكد من حذف الطلب؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('إلغاء'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );

                          if (ok != true) return;

                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(doc.id)
                              .delete();

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حذف الطلب')),
                          );
                        },
                        icon: Icon(Icons.delete_outline, color: isDoneOrDelivered ? Colors.redAccent : Colors.red),
                        tooltip: 'حذف',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallChip(String title, String value, bool isDoneOrDelivered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDoneOrDelivered ? Colors.white24 : kSoft,
        borderRadius: BorderRadius.circular(16),
        border: isDoneOrDelivered ? Border.all(color: Colors.white54) : null,
      ),
      child: Text(
        '$title: $value',
        style: TextStyle(
          fontSize: 12,
          color: isDoneOrDelivered ? Colors.white : kDark,
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArchivedOrdersPage(),
                ),
              );
            },
            icon: const Icon(Icons.archive_outlined),
          ),
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

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: docs.isEmpty ? 2 : docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: _buildTopSection(docs),
                );
              }
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'لا توجد طلبات مطابقة للفلتر',
                      style: TextStyle(fontSize: 20, color: kDark),
                    ),
                  ),
                );
              }
              return _orderCard(docs[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class AddOrderPage extends StatefulWidget {
  final String? editDocId;
  final Map<String, dynamic>? existingData;

  const AddOrderPage({
    super.key,
    this.editDocId,
    this.existingData,
  });

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

  String orderType = 'قالب كيك';
  String period = 'صباحًا';
  String branch = 'استلام فرع الدور'; 
  
  Uint8List? pickedImageBytes1;
  Uint8List? pickedImageBytes2;

  String formatTime12(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final dateTime = DateTime(0, 0, 0, hour, minute);

      return DateFormat('hh:mm a', 'ar').format(dateTime);
    } catch (e) {
      return time24;
    }
  }

  bool get isEditMode => widget.editDocId != null;

  @override
  void initState() {
    super.initState();

    final data = widget.existingData;
    if (data == null) return;

    customerNameController.text = data['customerName']?.toString() ?? '';
    phoneController.text = data['phone']?.toString() ?? '';
    writerController.text = data['writer']?.toString() ?? '';
    sizeController.text = data['size']?.toString() ?? '';
    quantityController.text = data['quantity']?.toString() ?? '';
    totalController.text = data['total']?.toString() ?? '';
    paidController.text = data['paid']?.toString() ?? '';
    detailsController.text = data['details']?.toString() ?? '';
    orderDateController.text = data['orderDate']?.toString() ?? '';
    deliveryDateController.text = data['deliveryDate']?.toString() ?? '';
    deliveryTimeController.text = data['deliveryTime']?.toString() ?? '';

    orderType = data['orderType']?.toString() ?? 'قالب كيك';
    period = data['period']?.toString() ?? 'صباحًا';
    branch = data['branch']?.toString() ?? 'استلام فرع الدور'; 

    final imageBase64_1 = data['imageBase64_1']?.toString() ?? data['imageBase64']?.toString() ?? '';
    final imageBase64_2 = data['imageBase64_2']?.toString() ?? '';

    if (imageBase64_1.isNotEmpty) {
      try { pickedImageBytes1 = base64Decode(imageBase64_1); } catch (_) {}
    }
    if (imageBase64_2.isNotEmpty) {
      try { pickedImageBytes2 = base64Decode(imageBase64_2); } catch (_) {}
    }
  }

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

  Future<void> _pickImage(int imageNumber) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (bytes.lengthInBytes > 700 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الصورة كبيرة جدًا، اختر صورة أصغر')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        if (imageNumber == 1) {
          pickedImageBytes1 = bytes;
        } else {
          pickedImageBytes2 = bytes;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء اختيار الصورة')),
      );
    }
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    
    setState(() {
      deliveryTimeController.text = DateFormat('hh:mm a', 'en_US').format(dt);
    });
  }

  Future<void> _saveOrder() async {
    bool showSize = orderType == 'قالب كيك' || orderType == 'قالب كيك وقطع كيك';
    bool showQuantity = orderType == 'قطع كيك' || orderType == 'قالب كيك وقطع كيك';

    if (customerNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        writerController.text.trim().isEmpty ||
        (showSize && sizeController.text.trim().isEmpty) ||
        (showQuantity && quantityController.text.trim().isEmpty) ||
        totalController.text.trim().isEmpty ||
        paidController.text.trim().isEmpty ||
        detailsController.text.trim().isEmpty ||
        orderDateController.text.trim().isEmpty ||
        deliveryDateController.text.trim().isEmpty ||
        deliveryTimeController.text.trim().isEmpty) {
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('تنبيه هام'),
            ],
          ),
          content: const Text(
            'يجب ملئ جميع خانات الإدخال بالكامل.\nلا يمكن إرسال الطلب في حال وجود حقل فارغ.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              child: const Text('حسناً، سأكمل البيانات', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final payload = {
      'customerName': customerNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'writer': writerController.text.trim(),
      'orderType': orderType,
      'branch': branch, 
      'size': showSize ? sizeController.text.trim() : '',
      'quantity': showQuantity ? quantityController.text.trim() : '',
      'total': totalController.text.trim(),
      'paid': paidController.text.trim(),
      'remaining': remainingAmount,
      'details': detailsController.text.trim(),
      'orderDate': orderDateController.text.trim(),
      'deliveryDate': deliveryDateController.text.trim(),
      'deliveryDay': deliveryDay,
      'deliveryTime': deliveryTimeController.text.trim(),
      'period': period,
      'imageBase64_1': pickedImageBytes1 == null ? '' : base64Encode(pickedImageBytes1!),
      'imageBase64_2': pickedImageBytes2 == null ? '' : base64Encode(pickedImageBytes2!),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isEditMode) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.editDocId)
          .update(payload);
    } else {
      await FirebaseFirestore.instance.collection('orders').add({
        ...payload,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'createdByRole': 'manager',
        'archived': false,
      });
    }

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

  Widget _imagePickerBox(int index, Uint8List? imageBytes) {
    return Column(
      children: [
        if (imageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              imageBytes,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: kSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(index),
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text('صورة $index', style: const TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
   bool showSize = orderType == 'قالب كيك' || orderType == 'قالب كيك وقطع كيك';
   bool showQuantity = orderType == 'قطع كيك' || orderType == 'قالب كيك وقطع كيك';

    return Scaffold(
      backgroundColor: kSoft,
      appBar: AppBar(
        title: Text(isEditMode ? 'تعديل الطلب' : 'إضافة طلب جديد'),
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
                    DropdownButtonFormField<String>(
                      value: branch,
                      items: kBranches
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => branch = val);
                      },
                      decoration: const InputDecoration(labelText: 'الفرع / الاستلام'),
                    ),
                    const SizedBox(height: 12),
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
                      DropdownMenuItem(value: 'قالب كيك', child: Text('قالب كيك')),
                      DropdownMenuItem(value: 'قطع كيك', child: Text('قطع كيك')),
                      DropdownMenuItem(value: 'قالب كيك وقطع كيك', child: Text('قالب كيك وقطع كيك')), 
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        orderType = value;

                        if (orderType == 'قالب كيك') {
                          quantityController.clear();
                        } else if (orderType == 'قطع كيك') {
                          sizeController.clear();
                        }
                      });
                    },
                    ),
                    const SizedBox(height: 12),
                    if (showSize)
                      TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: 'القياس',
                        ),
                      ),
                    if (showQuantity)
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
                    _sectionTitle('صور الطلب'),
                    Row(
                      children: [
                        Expanded(child: _imagePickerBox(1, pickedImageBytes1)),
                        const SizedBox(width: 12),
                        Expanded(child: _imagePickerBox(2, pickedImageBytes2)),
                      ],
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
                        child: Text(
                          isEditMode ? 'حفظ التعديلات' : 'حفظ الطلب',
                          style: const TextStyle(fontSize: 22),
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
  String selectedBranchFilter = 'كل الفروع'; 

  DateTime parseDeliveryDateTime(String date, String time) {
    try {
      final dateParts = date.split('-');
      final timeParts = time.split(':');

      final year = dateParts.isNotEmpty ? int.parse(dateParts[0]) : 9999;
      final month = dateParts.length > 1 ? int.parse(dateParts[1]) : 12;
      final day = dateParts.length > 2 ? int.parse(dateParts[2]) : 31;

      final hour = timeParts.isNotEmpty ? int.parse(timeParts[0]) : 23;
      final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 59;

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime(9999, 12, 31, 23, 59);
    }
  }

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

  Future<bool> _confirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _updateStatus(String docId, String status) async {
    final ok = await _confirmDialog('تأكيد', 'هل أنت متأكد من تنفيذ العملية؟');
    if (!ok) return;

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

  int _countDone(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['archived'] == true) return false;
      return (data['status']?.toString() ?? '') == 'done';
    }).length;
  }

  int _countNotDone(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['archived'] == true) return false;
      final status = data['status']?.toString() ?? 'pending';
      return status != 'done' && status != 'delivered';
    }).length;
  }

  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    List<QueryDocumentSnapshot> filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      bool isArchived = data['archived'] == true;
      if (selectedFilter == 'المؤرشفة') return isArchived;
      return !isArchived;
    }).toList();

    if (selectedFilter != 'كل الطلبات' && selectedFilter != 'المؤرشفة' && selectedFilter != 'هذا الأسبوع') {
      String targetDay = selectedFilter;
      if (selectedFilter == 'اليوم') {
        targetDay = kWeekDays[DateTime.now().weekday % 7];
      } else if (selectedFilter == 'غدًا') {
        targetDay = kWeekDays[DateTime.now().add(const Duration(days: 1)).weekday % 7];
      }
      
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['deliveryDay']?.toString() ?? '') == targetDay;
      }).toList();
    }

    if (selectedBranchFilter != 'كل الفروع') {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['branch']?.toString() ?? 'استلام فرع الدور') == selectedBranchFilter;
      }).toList();
    }

    return filtered;
  }

  Widget _buildWorkerTopSection(List<QueryDocumentSnapshot> docs) {
    final doneCount = _countDone(docs);
    final notDoneCount = _countNotDone(docs);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.pending_actions, size: 16, color: Colors.orange),
                    Column(
                      children: [
                        const Text('لم يكتمل', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$notDoneCount', style: const TextStyle(fontSize: 14, color: kDark, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.done_all, size: 16, color: Colors.green),
                    Column(
                      children: [
                        const Text('جاهز', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$doneCount', style: const TextStyle(fontSize: 14, color: kDark, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 36, 
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedFilter,
                  iconSize: 18,
                  items: kFilterOptions.map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedFilter = value);
                  },
                  decoration: const InputDecoration(contentPadding: EdgeInsets.zero, isDense: true, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 36, 
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedBranchFilter,
                  iconSize: 18,
                  items: kBranchFilterOptions.map((branch) => DropdownMenuItem(value: branch, child: Text(branch, style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedBranchFilter = value);
                  },
                  decoration: const InputDecoration(contentPadding: EdgeInsets.zero, isDense: true, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _employeeCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final customerName = data['customerName']?.toString() ?? '';
    final orderType = data['orderType']?.toString() ?? '';
    final deliveryDay = data['deliveryDay']?.toString() ?? '';
    final deliveryDate = data['deliveryDate']?.toString() ?? '';
    
    final rawTime = data['deliveryTime']?.toString() ?? '';
    final period = data['period']?.toString() ?? '';
    final cleanTime = rawTime.replaceAll(RegExp(r'[^0-9:]'), '').trim();
    final deliveryTime = cleanTime.isNotEmpty ? '\u200E$cleanTime $period' : '';

    final status = data['status']?.toString() ?? 'pending';
    final branch = data['branch']?.toString() ?? 'استلام فرع الدور';

    final isDoneOrDelivered = status == 'done' || status == 'delivered';
    final cardColor = isDoneOrDelivered ? const Color(0xFF1B5E20) : Colors.white;
    final textColor = isDoneOrDelivered ? Colors.white : kDark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(docId: doc.id, data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDoneOrDelivered ? Border.all(color: Colors.greenAccent, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: branch == 'توصيل' ? Colors.redAccent : (isDoneOrDelivered ? Colors.green.shade800 : kPrimary),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Text(branch, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (customerName.isNotEmpty)
                    Text(customerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: [
                      if (orderType.isNotEmpty) _detailsChip('النوع', orderType, isDoneOrDelivered),
                      if (deliveryDay.isNotEmpty) _detailsChip('اليوم', deliveryDay, isDoneOrDelivered),
                      if (deliveryDate.isNotEmpty) _detailsChip('التاريخ', deliveryDate, isDoneOrDelivered),
                      if (deliveryTime.isNotEmpty) _detailsChip('الوقت', deliveryTime, isDoneOrDelivered),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDoneOrDelivered ? Colors.white24 : _statusColor(status).withOpacity(.13),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(_statusLabel(status), style: TextStyle(color: isDoneOrDelivered ? Colors.white : _statusColor(status), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (status == 'pending')
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(doc.id, 'accepted'),
                              icon: const Icon(Icons.play_arrow, size: 16), label: const Text('استلام', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                            ),
                          if (status == 'accepted')
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(doc.id, 'done'),
                              icon: const Icon(Icons.check_circle_outline, size: 16), label: const Text('إنجاز', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                            ),
                          if (status == 'done') ...[
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(doc.id, 'accepted'),
                              icon: const Icon(Icons.undo, size: 16), label: const Text('تراجع', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final ok = await _confirmDialog('تأكيد الاستلام', 'هل تم استلام الطلب من قبل الزبون؟');
                                if (!ok) return;
                                await FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'status': 'delivered', 'archived': true, 'updatedAt': FieldValue.serverTimestamp()});
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاستلام وأُرشف الطلب')));
                              },
                              icon: const Icon(Icons.archive, size: 16), label: const Text('سُلِم للزبون', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsChip(String title, String value, bool isDoneOrDelivered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDoneOrDelivered ? Colors.white24 : kSoft, 
        borderRadius: BorderRadius.circular(8),
        border: isDoneOrDelivered ? Border.all(color: Colors.white54) : null,
      ),
      child: Text(
        '$title: $value',
        style: TextStyle(
          fontSize: 11, 
          color: isDoneOrDelivered ? Colors.white : kDark, 
          fontWeight: FontWeight.w600
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
          final filteredDocs = _applyFilter(allDocs);

          final docs = [...filteredDocs];
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final dateA = dataA['deliveryDate']?.toString() ?? '';
            final dateB = dataB['deliveryDate']?.toString() ?? '';
            final timeA = dataA['deliveryTime']?.toString() ?? '';
            final timeB = dataB['deliveryTime']?.toString() ?? '';

            final dateTimeA = parseDeliveryDateTime(dateA, timeA);
            final dateTimeB = parseDeliveryDateTime(dateB, timeB);

            return dateTimeA.compareTo(dateTimeB);
          });

          // دمج الفلاتر بداخل اللستة حتى تختفي عند النزول (Scroll)
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: docs.isEmpty ? 2 : docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: _buildWorkerTopSection(allDocs),
                );
              }
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'لا توجد طلبات مطابقة للفلتر',
                      style: TextStyle(fontSize: 18, color: kDark),
                    ),
                  ),
                );
              }
              return _employeeCard(docs[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const OrderDetailsPage({super.key, required this.docId, required this.data});

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted': return 'قيد التنفيذ';
      case 'done': return 'جاهز';
      case 'delivered': return 'تم التسليم';
      default: return 'لم يكتمل';
    }
  }

  Widget _styledRow(String title, String value, {bool isLast = false}) {
    final displayValue = (value.isEmpty) ? "غير متوفر" : value;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Color(0xFF2B2118), fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$title :',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
      ],
    );
  }

  Widget _buildSection(String sectionTitle, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(color: Color(0xFFD98A3A), borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
            child: Text(sectionTitle, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img1 = data['imageBase64_1']?.toString() ?? data['imageBase64']?.toString() ?? '';
    final img2 = data['imageBase64_2']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE8),
      appBar: AppBar(title: const Text('تفاصيل الوصل')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (img1.isNotEmpty || img2.isNotEmpty)
              Container(
                height: 220, margin: const EdgeInsets.only(bottom: 20),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (img1.isNotEmpty) _imgPreview(context, img1),
                    if (img1.isNotEmpty && img2.isNotEmpty) const SizedBox(width: 12),
                    if (img2.isNotEmpty) _imgPreview(context, img2),
                  ],
                ),
              ),

            _buildSection('معلومات الزبون والكاتب', [
              _styledRow('اسم الزبون', data['customerName']?.toString() ?? ''),
              _styledRow('رقم الهاتف', data['phone']?.toString() ?? ''),
              _styledRow('اسم الكاتب', data['writer']?.toString() ?? ''),
              _styledRow('الفرع / الاستلام', data['branch']?.toString() ?? '', isLast: true),
            ]),

            _buildSection('تفاصيل الطلب', [
              _styledRow('نوع الطلب', data['orderType']?.toString() ?? ''),
              _styledRow('القياس', data['size']?.toString() ?? ''),
              _styledRow('الكمية', data['quantity']?.toString() ?? ''),
              _styledRow('التفاصيل', data['details']?.toString() ?? '', isLast: true),
            ]),

            _buildSection('المواعيد', [
              _styledRow('تاريخ الطلب', data['orderDate']?.toString() ?? ''),
              _styledRow('يوم الاستلام', data['deliveryDay']?.toString() ?? ''),
              _styledRow('تاريخ الاستلام', data['deliveryDate']?.toString() ?? ''),
              _styledRow('وقت الاستلام', data['deliveryTime']?.toString() ?? ''),
              _styledRow('الفترة', data['period']?.toString() ?? '', isLast: true),
            ]),

            _buildSection('الحسابات والحالة', [
              _styledRow('المبلغ الكلي', "${data['total']?.toString() ?? 0} د.ع"),
              _styledRow('المبلغ الواصل', "${data['paid']?.toString() ?? 0} د.ع"),
              _styledRow('المبلغ الباقي', "${data['remaining']?.toString() ?? 0} د.ع"),
              _styledRow('حالة الطلب', _statusLabel(data['status']?.toString() ?? 'pending'), isLast: true),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _imgPreview(BuildContext context, String base64) {
    try {
      final bytes = base64Decode(base64);
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullImagePage(imageBytes: bytes))),
        child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(bytes, width: 250, fit: BoxFit.cover)),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 50);
    }
  }
}

class FullImagePage extends StatelessWidget {
  final Uint8List imageBytes;

  const FullImagePage({super.key, required this.imageBytes});

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final status = await Permission.storage.request();
      if (status.isGranted || await Permission.photos.request().isGranted) {
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 100,
          name: "Order_Image_${DateTime.now().millisecondsSinceEpoch}",
        );
        if (!context.mounted) return;
        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ الصورة في الاستوديو بنجاح!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء الحفظ'), backgroundColor: Colors.red),
          );
        }
      } else {
         if (!context.mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم منح صلاحية الوصول للاستوديو'), backgroundColor: Colors.orange),
          );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الحفظ'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('الصورة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context),
            tooltip: 'حفظ الصورة في الجهاز',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class ArchivedOrdersPage extends StatelessWidget {
  const ArchivedOrdersPage({super.key});

  Widget _smallChip(String title, String value, bool isDoneOrDelivered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDoneOrDelivered ? Colors.white24 : kSoft,
        borderRadius: BorderRadius.circular(16),
        border: isDoneOrDelivered ? Border.all(color: Colors.white54) : null,
      ),
      child: Text(
        '$title: $value',
        style: TextStyle(
          fontSize: 15,
          color: isDoneOrDelivered ? Colors.white : kDark,
          fontWeight: FontWeight.w600,
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSoft,
      appBar: AppBar(
        title: const Text('الطلبات المؤرشفة'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['archived'] == true;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات مؤرشفة',
                style: TextStyle(fontSize: 20, color: kDark),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final customerName = data['customerName']?.toString() ?? '';
              final phone = data['phone']?.toString() ?? '';
              final orderType = data['orderType']?.toString() ?? '';
              final deliveryDay = data['deliveryDay']?.toString() ?? '';
              final deliveryDate = data['deliveryDate']?.toString() ?? '';
              final deliveryTime = data['deliveryTime']?.toString() ?? '';
              final period = data['period']?.toString() ?? '';
              
              final timeStr = "$deliveryTime $period".trim();
              
              final status = data['status']?.toString() ?? 'pending';
              final branch = data['branch']?.toString() ?? 'استلام فرع الدور';

              final isDoneOrDelivered = status == 'done' || status == 'delivered';
              final cardColor = isDoneOrDelivered ? const Color(0xFF1B5E20) : Colors.white;
              final textColor = isDoneOrDelivered ? Colors.white : kDark;

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
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: branch == 'توصيل' ? Colors.redAccent : (isDoneOrDelivered ? Colors.green.shade800 : kPrimary),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Text(
                          branch,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customerName.isNotEmpty)
                              Text(
                                customerName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (phone.isNotEmpty)
                              Text(
                                phone,
                                style: TextStyle(fontSize: 16, color: textColor),
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (orderType.isNotEmpty) _smallChip('النوع', orderType, isDoneOrDelivered),
                                if (deliveryDay.isNotEmpty) _smallChip('اليوم', deliveryDay, isDoneOrDelivered),
                                if (deliveryDate.isNotEmpty) _smallChip('التاريخ', deliveryDate, isDoneOrDelivered),
                                if (timeStr.isNotEmpty) _smallChip('الوقت', timeStr, isDoneOrDelivered),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDoneOrDelivered ? Colors.white24 : _statusColor(status).withOpacity(.13),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: isDoneOrDelivered ? Colors.white : _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(doc.id)
                                    .update({
                                  'archived': false,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              },
                              icon: Icon(Icons.unarchive_outlined, color: textColor),
                              label: Text('إلغاء الأرشفة', style: TextStyle(color: textColor)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDoneOrDelivered ? Colors.white70 : kDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}