import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
      return const MaterialApp(home: Scaffold());
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kSoft,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
      ),
      home: role == null
          ? const LoginPage()
          : role == 'manager'
              ? const ManagerPage()
              : const EmployeePage(),
    );
  }
}

class ManagerPage extends StatefulWidget {
  const ManagerPage({super.key});

  @override
  State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _goToAddOrder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddOrderPage()),
    );
  }

  /// 🔥 تأكيد
  Future<bool> confirm(String text) async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('تأكيد'),
            content: Text(text),
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
        ) ??
        false;
  }

  Widget orderCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final archived = data['archived'] == true;
    if (archived) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        title: Text(data['customerName'] ?? ''),
        subtitle: Text(data['orderType'] ?? ''),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailsPage(docId: doc.id, data: data),
            ),
          );
        },

        /// 🔥 أزرار جديدة
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// ✏️ تعديل
            IconButton(
              icon: const Icon(Icons.edit),
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
            ),

            /// 📦 أرشفة
            IconButton(
              icon: const Icon(Icons.archive),
              onPressed: () async {
                final ok = await confirm('أرشفة الطلب؟');
                if (!ok) return;

                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(doc.id)
                    .update({'archived': true});
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدير'),
        actions: [
          IconButton(
            onPressed: _goToAddOrder,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView(
            children: docs.map(orderCard).toList(),
          );
        },
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

  Future<void> login() async {
    final prefs = await SharedPreferences.getInstance();

    if (usernameController.text == kManagerUsername &&
        passwordController.text == kManagerPassword) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', 'manager');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerPage()),
      );
    } else if (usernameController.text == kWorkersUsername &&
        passwordController.text == kWorkersPassword) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', 'worker');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ بالمعلومات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text('Chef Kambala', style: TextStyle(fontSize: 30)),
            const SizedBox(height: 30),

            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: login,
              child: const Text('دخول'),
            )
          ],
        ),
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
  final detailsController = TextEditingController();

  Uint8List? imageBytes;

  bool get isEdit => widget.editDocId != null;

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      final d = widget.existingData!;
      customerNameController.text = d['customerName'] ?? '';
      phoneController.text = d['phone'] ?? '';
      detailsController.text = d['details'] ?? '';

      if (d['imageBase64'] != null && d['imageBase64'] != '') {
        imageBytes = base64Decode(d['imageBase64']);
      }
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 1000,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (bytes.length > 500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الصورة كبيرة')),
      );
      return;
    }

    setState(() {
      imageBytes = bytes;
    });
  }

  Future<void> save() async {
    final name = customerNameController.text.trim();
    if (name.isEmpty) return;

    final data = {
      'customerName': name,
      'phone': phoneController.text,
      'details': detailsController.text,
      'imageBase64':
          imageBytes == null ? '' : base64Encode(imageBytes!),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isEdit) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.editDocId)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('orders').add({
        ...data,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل' : 'إضافة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: customerNameController, decoration: const InputDecoration(labelText: 'اسم')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'هاتف')),
            TextField(controller: detailsController, decoration: const InputDecoration(labelText: 'تفاصيل')),

            const SizedBox(height: 10),

            if (imageBytes != null)
              Image.memory(imageBytes!, height: 120),

            TextButton(
              onPressed: pickImage,
              child: const Text('صورة'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: save,
              child: const Text('حفظ'),
            )
          ],
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

  Future<void> _updateStatus(String docId, String status) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text('هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Widget _employeeCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final name = data['customerName'] ?? '';
    final status = data['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        title: Text(name),
        subtitle: Text(status),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsPage(
                docId: doc.id,
                data: data,
              ),
            ),
          );
        },

        trailing: Wrap(
          spacing: 5,
          children: [

            // استلام
            if (status == 'pending')
              ElevatedButton(
                onPressed: () => _updateStatus(doc.id, 'accepted'),
                child: const Text('استلام'),
              ),

            // اتمام
            if (status == 'accepted')
              ElevatedButton(
                onPressed: () => _updateStatus(doc.id, 'done'),
                child: const Text('إنهاء'),
              ),

            // تراجع
            if (status != 'pending')
              IconButton(
                onPressed: () => _updateStatus(doc.id, 'pending'),
                icon: const Icon(Icons.undo),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العمال'),
        actions: [
          IconButton(
            onPressed: logout,
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
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) => _employeeCard(docs[i]),
          );
        },
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> deleteOrder(String docId) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف'),
        content: const Text('تأكيد حذف الطلب؟'),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('لا')),
          ElevatedButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('نعم')),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('orders').doc(docId).delete();
  }

  Future<void> archiveOrder(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': 'archived',
    });
  }

  Widget _orderCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final name = data['customerName'] ?? '';
    final status = data['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        title: Text(name),
        subtitle: Text(status),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsPage(
                docId: doc.id,
                data: data,
              ),
            ),
          );
        },

        trailing: Wrap(
          spacing: 5,
          children: [

            // ✏ تعديل
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
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
            ),

            // 🗑 حذف
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteOrder(doc.id),
            ),

            // 📦 أرشفة
            IconButton(
              icon: const Icon(Icons.archive, color: Colors.orange),
              onPressed: () => archiveOrder(doc.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddOrderPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدير'),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: goToAdd,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] != 'archived'; // اخفاء المؤرشف
          }).toList();

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) => _orderCard(docs[i]),
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

  Uint8List? _decodeImage(String base64Str) {
    try {
      if (base64Str.isEmpty) return null;

      final bytes = base64Decode(base64Str);

      // 🛑 حماية من الكراش
      if (bytes.length > 700000) return null;

      return bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _row(String title, String value) {
    if (value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '$title: $value',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBase64 = data['imageBase64'] ?? '';
    final imageBytes = _decodeImage(imageBase64);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🖼 صورة محسنة بدون تهنيگ
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(
                  imageBytes,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.low,
                ),
              ),

            const SizedBox(height: 20),

            _row('الاسم', data['customerName'] ?? ''),
            _row('الهاتف', data['phone'] ?? ''),
            _row('النوع', data['orderType'] ?? ''),
            _row('التفاصيل', data['details'] ?? ''),
            _row('الحالة', data['status'] ?? ''),
          ],
        ),
      ),
    );
  }
}