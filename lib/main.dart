import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChefKambalaApp());
}

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

class ChefKambalaApp extends StatelessWidget {
  const ChefKambalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chef Kambala',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
          primary: kPrimary,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: kSoft,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kDark,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      home: const AppStartPage(),
    );
  }
}

class AppStartPage extends StatefulWidget {
  const AppStartPage({super.key});

  @override
  State<AppStartPage> createState() => _AppStartPageState();
}

class _AppStartPageState extends State<AppStartPage> {
  bool loading = true;
  String? role;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await AppStorage.initDefaultAccounts();
    await AppStorage.loadOrders();
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
      return const SplashPage();
    }

    if (role == 'manager') {
      return const ManagerPage();
    }

    if (role == 'employee') {
      return const EmployeePage();
    }

    return const LoginPage();
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
          children: const [
            _LogoHeader(big: true),
            SizedBox(height: 18),
            CircularProgressIndicator(color: kPrimary),
          ],
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  final bool big;
  const _LogoHeader({required this.big});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          height: big ? 180 : 90,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        Text(
          'Chef Kambala',
          style: TextStyle(
            fontSize: big ? 30 : 22,
            fontWeight: FontWeight.bold,
            color: kDark,
          ),
        ),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  bool hidePassword = true;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMsg('يرجى إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    final accounts = await AppStorage.getAccounts();

    if (!accounts.containsKey(username)) {
      _showMsg('اسم المستخدم غير صحيح');
      return;
    }

    final account = accounts[username]!;
    if (account['password'] != password) {
      _showMsg('كلمة المرور غير صحيحة');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
    await prefs.setString('role', account['role'] ?? 'employee');

    if (!mounted) return;

    if (account['role'] == 'manager') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeePage()),
      );
    }
  }

  void _showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 20),
                const _LogoHeader(big: true),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                          controller: userController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passController,
                          obscureText: hidePassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: login,
                            child: const Text('دخول'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordPage(),
                              ),
                            );
                          },
                          child: const Text('تغيير كلمة المرور'),
                        ),
                      ],
                    ),
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

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final usernameController = TextEditingController();
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    oldPassController.dispose();
    newPassController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    final username = usernameController.text.trim();
    final oldPass = oldPassController.text.trim();
    final newPass = newPassController.text.trim();

    if (username.isEmpty || oldPass.isEmpty || newPass.isEmpty) {
      _msg('املأ جميع الحقول');
      return;
    }

    final accounts = await AppStorage.getAccounts();
    if (!accounts.containsKey(username)) {
      _msg('اسم المستخدم غير صحيح');
      return;
    }

    if (accounts[username]!['password'] != oldPass) {
      _msg('كلمة المرور القديمة غير صحيحة');
      return;
    }

    accounts[username]!['password'] = newPass;
    await AppStorage.saveAccounts(accounts);

    if (!mounted) return;
    _msg('تم تغيير كلمة المرور بنجاح');
    Navigator.pop(context);
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تغيير كلمة المرور')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'اسم المستخدم'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: oldPassController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور القديمة'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPassController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: changePassword,
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('isLoggedIn');
  await prefs.remove('role');
  await prefs.remove('username');

  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

class AppStorage {
  static const String ordersKey = 'orders_json';
  static const String accountsKey = 'accounts_json';

  static Future<void> initDefaultAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(accountsKey);
    if (existing != null && existing.isNotEmpty) return;

    final defaults = {
      'manager': {'password': '1234', 'role': 'manager'},
      'emp': {'password': '1111', 'role': 'employee'},
    };

    await prefs.setString(accountsKey, jsonEncode(defaults));
  }

  static Future<Map<String, Map<String, String>>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(accountsKey);
    if (raw == null || raw.isEmpty) {
      await initDefaultAccounts();
      return getAccounts();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        Map<String, String>.from(value as Map),
      ),
    );
  }

  static Future<void> saveAccounts(
    Map<String, Map<String, String>> accounts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accountsKey, jsonEncode(accounts));
  }

  static Future<void> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ordersKey);
    if (raw == null || raw.isEmpty) {
      globalOrders = [];
      return;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    globalOrders = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ordersKey, jsonEncode(globalOrders));
  }
}

List<Map<String, dynamic>> globalOrders = [];

class DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 8) digits = digits.substring(0, 8);

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      formatted += digits[i];
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        formatted += '/';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

DateTime? parseDate(String value) {
  try {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

String getArabicWeekday(String date) {
  final parsed = parseDate(date);
  if (parsed == null) return 'غير محدد';

  switch (parsed.weekday) {
    case DateTime.monday:
      return 'الاثنين';
    case DateTime.tuesday:
      return 'الثلاثاء';
    case DateTime.wednesday:
      return 'الأربعاء';
    case DateTime.thursday:
      return 'الخميس';
    case DateTime.friday:
      return 'الجمعة';
    case DateTime.saturday:
      return 'السبت';
    case DateTime.sunday:
      return 'الأحد';
    default:
      return 'غير محدد';
  }
}

DateTime? pickupDateTime(Map<String, dynamic> order) {
  final date = parseDate(order['pickupDate']?.toString() ?? '');
  if (date == null) return null;

  int hour = int.tryParse(order['pickupHour']?.toString() ?? '') ?? 0;
  final period = order['pickupPeriod']?.toString() ?? 'صباحًا';

  if (hour == 12) hour = 0;
  if (period == 'مساءً') hour += 12;

  return DateTime(date.year, date.month, date.day, hour);
}

int pickupSortValue(Map<String, dynamic> order) {
  final dt = pickupDateTime(order);
  return dt?.millisecondsSinceEpoch ?? 0;
}

String pickupTimeText(Map<String, dynamic> order) {
  return '${order['pickupHour']} ${order['pickupPeriod']}';
}

String sizeOrQuantityText(Map<String, dynamic> order) {
  if (order['orderType'] == 'كيكة') {
    return 'القياس: ${order['size']}';
  }
  return 'الكمية: ${order['quantity']}';
}

Color statusColor(String status) {
  switch (status) {
    case 'جاهز':
      return Colors.green;
    case 'استلمه الزبون':
      return Colors.blueGrey;
    default:
      return Colors.orange;
  }
}

String relativeDateLabel(Map<String, dynamic> order) {
  final dt = pickupDateTime(order);
  if (dt == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dt.year, dt.month, dt.day);

  if (target == today) return 'اليوم';
  if (target == today.add(const Duration(days: 1))) return 'غدًا';
  if (target.isAfter(today.add(const Duration(days: 1)))) return 'لاحقًا';
  return 'متأخر';
}

List<Map<String, dynamic>> filteredOrders(
  String filter, {
  bool includeArchived = false,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final weekEnd = today.add(const Duration(days: 7));

  bool matches(Map<String, dynamic> order) {
    final isArchived = order['status'] == 'استلمه الزبون';
    if (!includeArchived && isArchived) return false;
    if (includeArchived && !isArchived) return false;

    final dt = pickupDateTime(order);
    if (dt == null) return false;
    final target = DateTime(dt.year, dt.month, dt.day);

    switch (filter) {
      case 'اليوم':
        return target == today;
      case 'غدًا':
        return target == tomorrow;
      case 'هذا الأسبوع':
        return (target == today || target.isAfter(today)) &&
            target.isBefore(weekEnd);
      case 'كل الطلبات':
        return true;
      default:
        return order['pickupWeekday'] == filter;
    }
  }

  final result = globalOrders.where(matches).toList();
  result.sort((a, b) => pickupSortValue(a).compareTo(pickupSortValue(b)));
  return result;
}

class SectionCard extends StatelessWidget {
  final Widget child;
  const SectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
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

  int countByStatus(String status) {
    return filteredOrders(selectedFilter)
        .where((order) => order['status'] == status)
        .length;
  }

  Future<void> confirmDelete(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نعم، حذف'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        globalOrders.removeAt(index);
      });
      await AppStorage.saveOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الطلب')),
      );
    }
  }

  Widget infoCard(String title, int value, Color color) {
    return Expanded(
      child: SectionCard(
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final realIndex = globalOrders.indexOf(order);
    final Uint8List? imageBytes = order['imageBase64'] == null
        ? null
        : base64Decode(order['imageBase64']);

    return SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsPage(orderIndex: realIndex),
            ),
          );
          setState(() {});
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  imageBytes,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (imageBytes != null) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'الزبون: ${order['customerName']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(relativeDateLabel(order)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('نوع الطلب: ${order['orderType']}'),
            Text(sizeOrQuantityText(order)),
            Text('يوم الاستلام: ${order['pickupWeekday']}'),
            Text('تاريخ الاستلام: ${order['pickupDate']}'),
            Text('وقت الاستلام: ${pickupTimeText(order)}'),
            Text(
              'الحالة: ${order['status']}',
              style: TextStyle(
                color: statusColor(order['status']),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('تعديل'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderFormPage(orderIndex: realIndex),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('حذف'),
                    onPressed: () => confirmDelete(realIndex),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentOrders = filteredOrders(selectedFilter);
    final incompleteCount = countByStatus('لم يكتمل');
    final readyCount = countByStatus('جاهز');

    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحة المدير'),
        actions: [
          IconButton(
            tooltip: 'الأرشيف',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchivePage()),
              );
            },
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrderFormPage()),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LogoHeader(big: false),
          const SizedBox(height: 14),
          Row(
            children: [
              infoCard('لم يكتمل', incompleteCount, Colors.orange),
              const SizedBox(width: 10),
              infoCard('جاهز', readyCount, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: const InputDecoration(
                labelText: 'فلترة الطلبات',
              ),
              items: kFilterOptions
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFilter = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          if (currentOrders.isEmpty)
            const SectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'لا توجد طلبات في هذا التصفية',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            )
          else
            ...currentOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: buildOrderCard(order),
              ),
            ),
        ],
      ),
    );
  }
}

class OrderFormPage extends StatefulWidget {
  final int? orderIndex;
  const OrderFormPage({super.key, this.orderIndex});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  late final bool isEdit;

  final customerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final writerNameController = TextEditingController();
  final sizeController = TextEditingController();
  final quantityController = TextEditingController();
  final totalPriceController = TextEditingController();
  final paidAmountController = TextEditingController();
  final detailsController = TextEditingController();
  final writeDateController = TextEditingController();
  final pickupDateController = TextEditingController();
  final pickupHourController = TextEditingController();

  String selectedOrderType = 'كيكة';
  String selectedPickupPeriod = 'صباحًا';
  String pickupWeekdayPreview = 'غير محدد';
  Uint8List? selectedImageBytes;

  @override
  void initState() {
    super.initState();
    isEdit = widget.orderIndex != null;

    if (isEdit) {
      final order = globalOrders[widget.orderIndex!];
      customerNameController.text = order['customerName'] ?? '';
      phoneController.text = order['phone'] ?? '';
      writerNameController.text = order['writerName'] ?? '';
      sizeController.text = order['size'] ?? '';
      quantityController.text = order['quantity'] ?? '';
      totalPriceController.text = order['totalPrice'] ?? '';
      paidAmountController.text = order['paidAmount'] ?? '';
      detailsController.text = order['details'] ?? '';
      writeDateController.text = order['writeDate'] ?? '';
      pickupDateController.text = order['pickupDate'] ?? '';
      pickupHourController.text = order['pickupHour'] ?? '';
      selectedOrderType = order['orderType'] ?? 'كيكة';
      selectedPickupPeriod = order['pickupPeriod'] ?? 'صباحًا';
      pickupWeekdayPreview = order['pickupWeekday'] ?? 'غير محدد';
      if (order['imageBase64'] != null) {
        selectedImageBytes = base64Decode(order['imageBase64']);
      }
    }

    pickupDateController.addListener(() {
      setState(() {
        pickupWeekdayPreview = getArabicWeekday(pickupDateController.text);
      });
    });
  }

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    writerNameController.dispose();
    sizeController.dispose();
    quantityController.dispose();
    totalPriceController.dispose();
    paidAmountController.dispose();
    detailsController.dispose();
    writeDateController.dispose();
    pickupDateController.dispose();
    pickupHourController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
      });
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  int parseIntSafe(String value) => int.tryParse(value.trim()) ?? 0;

  Future<void> saveOrder() async {
    final isCake = selectedOrderType == 'كيكة';

    if (customerNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        writerNameController.text.trim().isEmpty ||
        totalPriceController.text.trim().isEmpty ||
        paidAmountController.text.trim().isEmpty ||
        detailsController.text.trim().isEmpty ||
        writeDateController.text.trim().isEmpty ||
        pickupDateController.text.trim().isEmpty ||
        pickupHourController.text.trim().isEmpty ||
        (isCake && sizeController.text.trim().isEmpty) ||
        (!isCake && quantityController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    final total = parseIntSafe(totalPriceController.text);
    final paid = parseIntSafe(paidAmountController.text);
    final remain = (total - paid).clamp(0, 999999999);

    final order = <String, dynamic>{
      'customerName': customerNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'writerName': writerNameController.text.trim(),
      'orderType': selectedOrderType,
      'size': sizeController.text.trim(),
      'quantity': quantityController.text.trim(),
      'totalPrice': total.toString(),
      'paidAmount': paid.toString(),
      'remainingAmount': remain.toString(),
      'details': detailsController.text.trim(),
      'imageBase64':
          selectedImageBytes == null ? null : base64Encode(selectedImageBytes!),
      'writeDate': writeDateController.text.trim(),
      'pickupDate': pickupDateController.text.trim(),
      'pickupHour': pickupHourController.text.trim(),
      'pickupPeriod': selectedPickupPeriod,
      'pickupWeekday': getArabicWeekday(pickupDateController.text.trim()),
      'status': isEdit ? globalOrders[widget.orderIndex!]['status'] : 'لم يكتمل',
    };

    if (isEdit) {
      globalOrders[widget.orderIndex!] = order;
    } else {
      globalOrders.insert(0, order);
    }

    await AppStorage.saveOrders();

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isCake = selectedOrderType == 'كيكة';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل الطلب' : 'إضافة طلب جديد'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LogoHeader(big: false),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: [
                field(customerNameController, 'اسم الزبون'),
                field(
                  phoneController,
                  'رقم الهاتف',
                  keyboardType: TextInputType.phone,
                ),
                field(writerNameController, 'اسم من كتب الوصل'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: selectedOrderType,
                    decoration: const InputDecoration(labelText: 'نوع الطلب'),
                    items: const [
                      DropdownMenuItem(value: 'كيكة', child: Text('كيكة')),
                      DropdownMenuItem(value: 'معجنات', child: Text('معجنات')),
                      DropdownMenuItem(value: 'حلويات', child: Text('حلويات')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedOrderType = value;
                        });
                      }
                    },
                  ),
                ),
                if (isCake) field(sizeController, 'القياس'),
                if (!isCake) field(quantityController, 'الكمية'),
                field(
                  totalPriceController,
                  'المبلغ الكلي',
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                field(
                  paidAmountController,
                  'المبلغ الواصل',
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                field(detailsController, 'تفاصيل الطلب', maxLines: 3),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'صورة التصميم (اختياري)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: selectedImageBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 40,
                                color: kPrimary,
                              ),
                              SizedBox(height: 8),
                              Text('اضغط لإضافة صورة'),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                field(
                  writeDateController,
                  'تاريخ كتابة الطلب',
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DateSlashFormatter(),
                  ],
                ),
                field(
                  pickupDateController,
                  'تاريخ الاستلام',
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DateSlashFormatter(),
                  ],
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text('يوم الاستلام: $pickupWeekdayPreview'),
                ),
                field(
                  pickupHourController,
                  'ساعة الاستلام',
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: selectedPickupPeriod,
                    decoration: const InputDecoration(labelText: 'الفترة'),
                    items: const [
                      DropdownMenuItem(value: 'صباحًا', child: Text('صباحًا')),
                      DropdownMenuItem(value: 'مساءً', child: Text('مساءً')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedPickupPeriod = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: saveOrder,
                    icon: const Icon(Icons.save),
                    label: Text(isEdit ? 'حفظ التعديل' : 'حفظ الطلب'),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Future<void> completeOrder(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text('هل أنت متأكد أن الطلب اكتمل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        globalOrders[index]['status'] = 'جاهز';
      });
      await AppStorage.saveOrders();
    }
  }

  Future<void> markDelivered(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text('هل استلمه الزبون فعلًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        globalOrders[index]['status'] = 'استلمه الزبون';
      });
      await AppStorage.saveOrders();
    }
  }

  Future<void> undoComplete(int index) async {
    setState(() {
      globalOrders[index]['status'] = 'لم يكتمل';
    });
    await AppStorage.saveOrders();
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final realIndex = globalOrders.indexOf(order);
    final Uint8List? imageBytes = order['imageBase64'] == null
        ? null
        : base64Decode(order['imageBase64']);

    return SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsPage(orderIndex: realIndex),
            ),
          );
          setState(() {});
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  imageBytes,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (imageBytes != null) const SizedBox(height: 10),
            Text(
              'الزبون: ${order['customerName']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text('الطلب: ${order['orderType']}'),
            Text(sizeOrQuantityText(order)),
            Text('يوم الاستلام: ${order['pickupWeekday']}'),
            Text('تاريخ الاستلام: ${order['pickupDate']}'),
            Text('وقت الاستلام: ${pickupTimeText(order)}'),
            const SizedBox(height: 6),
            Text(
              'الحالة: ${order['status']}',
              style: TextStyle(
                color: statusColor(order['status']),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (order['status'] == 'لم يكتمل')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => completeOrder(realIndex),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('اكتمل الطلب'),
                ),
              ),
            if (order['status'] == 'جاهز') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => markDelivered(realIndex),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('استلمه الزبون'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => undoComplete(realIndex),
                  icon: const Icon(Icons.undo),
                  label: const Text('تراجع عن الاكتمال'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentOrders = filteredOrders(selectedFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحة الموظف'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LogoHeader(big: false),
          const SizedBox(height: 12),
          SectionCard(
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: const InputDecoration(labelText: 'فلترة الطلبات'),
              items: kFilterOptions
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFilter = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          if (currentOrders.isEmpty)
            const SectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لا توجد طلبات'),
                ),
              ),
            )
          else
            ...currentOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: buildOrderCard(order),
              ),
            ),
        ],
      ),
    );
  }
}

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  String selectedFilter = 'كل الطلبات';

  @override
  Widget build(BuildContext context) {
    final archiveOrders = filteredOrders(
      selectedFilter,
      includeArchived: true,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('الأرشيف')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LogoHeader(big: false),
          const SizedBox(height: 12),
          SectionCard(
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: const InputDecoration(labelText: 'فلترة الأرشيف'),
              items: kFilterOptions
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFilter = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          if (archiveOrders.isEmpty)
            const SectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لا توجد طلبات مؤرشفة'),
                ),
              ),
            )
          else
            ...archiveOrders.map((order) {
              final realIndex = globalOrders.indexOf(order);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsPage(orderIndex: realIndex),
                        ),
                      );
                    },
                    title: Text('الزبون: ${order['customerName']}'),
                    subtitle: Text(
                      '${order['pickupDate']} - ${pickupTimeText(order)}',
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final int orderIndex;
  const OrderDetailsPage({super.key, required this.orderIndex});

  @override
  Widget build(BuildContext context) {
    final order = globalOrders[orderIndex];
    final Uint8List? imageBytes = order['imageBase64'] == null
        ? null
        : base64Decode(order['imageBase64']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderFormPage(orderIndex: orderIndex),
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LogoHeader(big: false),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      imageBytes,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  'الزبون: ${order['customerName']}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('رقم الهاتف: ${order['phone']}'),
                Text('اسم من كتب الوصل: ${order['writerName']}'),
                Text('نوع الطلب: ${order['orderType']}'),
                Text(sizeOrQuantityText(order)),
                Text('المبلغ الكلي: ${order['totalPrice']}'),
                Text('المبلغ الواصل: ${order['paidAmount']}'),
                Text('باقي المبلغ: ${order['remainingAmount']}'),
                Text('تفاصيل الطلب: ${order['details']}'),
                Text('تاريخ كتابة الطلب: ${order['writeDate']}'),
                Text('يوم الاستلام: ${order['pickupWeekday']}'),
                Text('تاريخ الاستلام: ${order['pickupDate']}'),
                Text('وقت الاستلام: ${pickupTimeText(order)}'),
                const SizedBox(height: 8),
                Text(
                  'الحالة: ${order['status']}',
                  style: TextStyle(
                    color: statusColor(order['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}