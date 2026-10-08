import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const LaundraiApp());
}

class AppConfig {
  static String baseUrl = 'https://l-dry.my.id'; 
  static String? token;
  static Map<String, dynamic>? userProfile;
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  // URL Logo yang Anda berikan
  static const String logoUrl = 'https://files.oaiusercontent.com/file-V6pA5I30tYisX247E6I6Z9vC?se=2024-10-24T14%3A41%3A36Z&sp=r&sv=2024-08-04&sr=b&rscc=max-age%3D604800%2C%20immutable%2C%20private&rscd=attachment%3B%20filename%3D30743b6e-a3f2-45e0-9426-5f50f96898d9.webp&sig=S9iB3L4vU0j%2BRW7T7o%2Bk8uT6oP%2Bd9Q7i6zZ%2BJ6a7Q7L5Gq%2B9%2B0%3D';
}

class LaundraiApp extends StatelessWidget {
  const LaundraiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'L-DRY Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConfig.primaryBlue,
          primary: AppConfig.primaryBlue,
          secondary: const Color(0xFF1E40AF),
          surface: AppConfig.background,
        ),
        scaffoldBackgroundColor: AppConfig.background,
      ),
      // Mulai dari Splash Screen
      home: const SplashScreen(),
    );
  }
}

// ======================== SPLASH SCREEN (NEW) ========================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Tunggu 3 detik lalu pindah halaman
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                AppConfig.logoUrl,
                width: 220,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.tsunami_rounded, size: 80, color: AppConfig.primaryBlue),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppConfig.primaryBlue, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return AppConfig.token == null ? const LoginScreen() : const MainNavigationScreen();
  }
}

// ======================== LOGIN SCREEN ========================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'customer@laundrai.com');
  final TextEditingController _passwordController = TextEditingController(text: 'password');
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim(), 'password': _passwordController.text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        AppConfig.token = data['token'];
        AppConfig.userProfile = data['user'];
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen()));
      } else {
        setState(() { _errorMessage = data['message'] ?? 'Email atau password salah.'; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Gagal terhubung ke server.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Center(
                child: Image.network(
                  AppConfig.logoUrl,
                  width: 150,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.tsunami_rounded, size: 50, color: AppConfig.primaryBlue),
                ),
              ),
              const SizedBox(height: 30),
              const Center(child: Text('L-DRY PREMIUM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 1))),
              const Center(child: Text('Masuk untuk mulai merawat pakaian Anda', style: TextStyle(color: Color(0xFF64748B)))),
              const SizedBox(height: 40),
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                  child: Row(children: [const Icon(Icons.error_outline, color: Colors.redAccent, size: 18), const SizedBox(width: 10), Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 12)))]),
                ),
                const SizedBox(height: 20),
              ],
              _buildLabel('EMAIL ADDRESS'),
              _buildTextField(_emailController, Icons.email_outlined, 'nama@email.com'),
              const SizedBox(height: 20),
              _buildLabel('PASSWORD'),
              _buildTextField(_passwordController, Icons.lock_outline, '••••••••', obscure: true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 8, shadowColor: AppConfig.primaryBlue.withValues(alpha: 0.3)),
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Masuk Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  child: const Text('Belum punya akun? Daftar Sekarang', style: TextStyle(color: AppConfig.primaryBlue, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1));
  Widget _buildTextField(TextEditingController ctrl, IconData icon, String hint, {bool obscure = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(controller: ctrl, obscureText: obscure, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppConfig.primaryBlue, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.all(16))),
    );
  }
}

// ======================== REGISTER SCREEN ========================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _addr = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': _name.text, 'email': _email.text, 'phone': _phone.text, 'address': _addr.text, 'password': _pass.text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        AppConfig.token = data['token'];
        AppConfig.userProfile = data['user'];
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen()), (r) => false);
      }
    } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          _in(_name, 'Nama Lengkap'), _in(_email, 'Email'), _in(_phone, 'Nomor HP'), _in(_addr, 'Alamat Lengkap', lines: 3), _in(_pass, 'Password', obscure: true),
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _handleRegister, style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Daftar Sekarang')))
        ]),
      ),
    );
  }
  Widget _in(TextEditingController c, String l, {bool obscure = false, int lines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: c, obscureText: obscure, maxLines: lines, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
}

// ======================== MAIN NAVIGATION ========================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const HomeScreen(), const CreateOrderScreen(), const HistoryScreen(), const ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))]),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: AppConfig.primaryBlue.withOpacity(0.1),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppConfig.primaryBlue), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle, color: AppConfig.primaryBlue), label: 'Pesan'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map, color: AppConfig.primaryBlue), label: 'Lacak'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppConfig.primaryBlue), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// ======================== HOME SCREEN ========================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  dynamic _activeOrder;
  bool _isLoading = true;

  @override void initState() { super.initState(); _fetchActiveOrder(); }

  Future<void> _fetchActiveOrder() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/orders'), headers: {'Authorization': 'Bearer ${AppConfig.token}'});
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['orders'] != null && data['orders'].isNotEmpty) {
        setState(() { 
          _activeOrder = data['orders'].firstWhere((o) => o['status'] != 'delivered' && o['status'] != 'done', orElse: () => null);
          _isLoading = false; 
        });
      } else { setState(() => _isLoading = false); }
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final name = AppConfig.userProfile?['name'] ?? 'Guest';
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => launchUrl(Uri.parse('https://wa.me/6281234567890')),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchActiveOrder,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Selamat Datang,', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ]),
                  const CircleAvatar(backgroundColor: AppConfig.primaryBlue, child: Icon(Icons.notifications_none, color: Colors.white)),
                ]),
                const SizedBox(height: 25),
                
                // BANNER VISUAL
                Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1545173168-9f1947eebb7f?q=80&w=1000&auto=format&fit=crop'),
                      fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('DISKON 20%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                      Text('Untuk Pencucian Pertama Anda!', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                if (_activeOrder != null) _buildActiveOrderCard(_activeOrder),
                
                const SizedBox(height: 35),
                const Text('Layanan Unggulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
                  children: const [
                    ServiceCard(title: 'Laundry Kiloan', img: 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?q=80&w=500', icon: Icons.local_laundry_service_outlined),
                    ServiceCard(title: 'Express 24 Jam', img: 'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?q=80&w=500', icon: Icons.bolt_rounded),
                    ServiceCard(title: 'Dry Cleaning', img: 'https://images.unsplash.com/photo-1521503862198-2ae9a997bbc9?q=80&w=500', icon: Icons.dry_cleaning_outlined),
                    ServiceCard(title: 'Setrika Saja', img: 'https://images.unsplash.com/photo-1489274495744-85ff17589d2b?q=80&w=500', icon: Icons.iron_outlined),
                  ],
                ),

                const SizedBox(height: 40),
                _buildFloatingInfo(Icons.auto_awesome, 'Layanan Rapi & Wangi', 'Pakaian Anda diperiksa dengan teliti sebelum dikemas.'),
                const SizedBox(height: 15),
                _buildFloatingInfo(Icons.timer, 'Selesai Tepat Waktu', 'Pakaian bersih siap diantar kembali dalam 24 jam.'),
                
                const SizedBox(height: 40),
                const Text('Apa Kata Mereka?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 15),
                _buildTesti('Budi Santoso', 'Cepat banget! Besoknya langsung diantar ke rumah.'),
                _buildTesti('Siska Amelia', 'Wangi banget laundry-nya, setrikanya juga rapi.'),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(int orderId) async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/payment/snap-token/$orderId'), headers: {'Authorization': 'Bearer ${AppConfig.token}'});
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final url = Uri.parse('https://app.sandbox.midtrans.com/snap/v2/vtweb/${data['snap_token']}');
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw Exception();
      }
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses pembayaran'))); 
    }
  }

  Widget _buildActiveOrderCard(dynamic order) {
    String status = order['status_label'] ?? 'Diproses';
    bool isUnpaid = order['payment_status'] != 'settlement' && (order['total_price'] ?? 0) > 0;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppConfig.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('PESANAN AKTIF', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const Icon(Icons.gps_fixed, color: Colors.white70, size: 16),
        ]),
        const SizedBox(height: 10),
        Text(status, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        Text('Order ID: ${order['order_number']}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        if (isUnpaid) ...[
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _processPayment(order['id']), icon: const Icon(Icons.payment), label: const Text('Bayar Sekarang'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppConfig.primaryBlue))),
        ],
        const Divider(color: Colors.white12, height: 40),
        Row(children: [
          const CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Kurir L-Dry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('Siap Menjemput', style: TextStyle(color: Colors.white70, fontSize: 11))])),
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.phone, color: AppConfig.primaryBlue, size: 18)),
        ]),
      ]),
    );
  }

  Widget _buildFloatingInfo(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: Icon(icon, color: Colors.orange, size: 20)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))])),
      ]),
    );
  }

  Widget _buildTesti(String name, String msg) {
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(msg, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))]));
  }
}

class ServiceCard extends StatelessWidget {
  final String title; final String img; final IconData icon;
  const ServiceCard({super.key, required this.title, required this.img, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white, size: 24),
        const Spacer(),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }
}

// ======================== CREATE ORDER SCREEN ========================
class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});
  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final TextEditingController _addressController = TextEditingController(text: AppConfig.userProfile?['address'] ?? '');
  final TextEditingController _weightController = TextEditingController();
  String _method = 'pickup';
  String _paymentMethod = 'cash';
  List<dynamic> _services = [];
  dynamic _selectedSrv;
  bool _loading = true;
  bool _submitting = false;

  @override void initState() { super.initState(); _fetch(); }
  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/services'));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) setState(() { _services = data['services']; if(_services.isNotEmpty) _selectedSrv = _services[0]; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  Future<void> _submitOrder() async {
    if (_selectedSrv == null) return;
    setState(() => _submitting = true);
    try {
      final response = await http.post(Uri.parse('${AppConfig.baseUrl}/api/orders'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AppConfig.token}'}, body: jsonEncode({'service_id': _selectedSrv['id'], 'weight_kg': _weightController.text, 'delivery_method': _method, 'payment_method': _paymentMethod, 'pickup_address': _addressController.text}));
      if (response.statusCode == 201) { 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan Berhasil!'), backgroundColor: AppConfig.primaryBlue)); 
      }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat pesanan'))); } finally { setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Pilih Layanan'),
          Container(margin: const EdgeInsets.only(top: 10, bottom: 25), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: DropdownButtonHideUnderline(child: DropdownButton<dynamic>(value: _selectedSrv, isExpanded: true, items: _services.map((s) => DropdownMenuItem(value: s, child: Text('${s['name']} - Rp ${s['price_per_kg'] ?? s['price_per_pcs']}/${s['unit']}'))).toList(), onChanged: (v) => setState(() => _selectedSrv = v)))),
          _label('Berat Estimasi (kg)'),
          _input(_weightController, 'Contoh: 3.5', TextInputType.number),
          const SizedBox(height: 25),
          _label('Metode Antar'),
          const SizedBox(height: 10),
          Row(children: [_opt('pickup', Icons.local_shipping, 'Kurir Jemput'), const SizedBox(width: 15), _opt('self_drop', Icons.storefront, 'Antar Sendiri')]),
          const SizedBox(height: 25),
          _label('Metode Pembayaran'),
          const SizedBox(height: 10),
          Row(children: [_payOpt('cash', Icons.payments_outlined, 'Tunai'), const SizedBox(width: 15), _payOpt('transfer', Icons.account_balance_outlined, 'Transfer')]),
          const SizedBox(height: 25),
          if(_method == 'pickup') ...[_label('Alamat Penjemputan'), _input(_addressController, 'Alamat lengkap...', TextInputType.text, lines: 3)],
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitting ? null : _submitOrder, style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Konfirmasi Pesanan'))),
        ]),
      ),
    );
  }
  Widget _label(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)));
  Widget _input(TextEditingController c, String h, TextInputType t, {int lines = 1}) => Container(margin: const EdgeInsets.only(top: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: TextField(controller: c, keyboardType: t, maxLines: lines, decoration: InputDecoration(hintText: h, border: InputBorder.none, contentPadding: const EdgeInsets.all(16))));
  Widget _opt(String m, IconData i, String l) {
    bool sel = _method == m; return Expanded(child: GestureDetector(onTap: () => setState(() => _method = m), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: sel ? AppConfig.primaryBlue.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? AppConfig.primaryBlue : const Color(0xFFE2E8F0), width: 2)), child: Column(children: [Icon(i, color: sel ? AppConfig.primaryBlue : const Color(0xFF64748B)), const SizedBox(height: 8), Text(l, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: sel ? AppConfig.primaryBlue : const Color(0xFF1E293B)))]))));
  }
  Widget _payOpt(String m, IconData i, String l) {
    bool sel = _paymentMethod == m; return Expanded(child: GestureDetector(onTap: () => setState(() => _paymentMethod = m), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: sel ? Colors.green.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? Colors.green : const Color(0xFFE2E8F0), width: 2)), child: Column(children: [Icon(i, color: sel ? Colors.green : const Color(0xFF64748B)), const SizedBox(height: 8), Text(l, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: sel ? Colors.green : const Color(0xFF1E293B)))]))));
  }
}

// ======================== HISTORY SCREEN ========================
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List _orders = [];
  bool _loading = true;
  @override void initState() { super.initState(); _fetch(); }
  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/orders'), headers: {'Authorization': 'Bearer ${AppConfig.token}'});
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) setState(() { _orders = data['orders']; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lacak Pesanan', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, actions: [IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(padding: const EdgeInsets.all(24), itemCount: _orders.length, itemBuilder: (context, i) {
        final o = _orders[i];
        return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppConfig.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.receipt_long_outlined, color: AppConfig.primaryBlue)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o['order_number'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(o['service_name'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))])), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)), child: Text(o['status_label'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConfig.primaryBlue)))]));
      }),
    );
  }
}

// ======================== PROFILE SCREEN ========================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final u = AppConfig.userProfile;
    final avatar = u?['avatar_url'];
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.only(top: 80, bottom: 40),
            decoration: const BoxDecoration(color: AppConfig.primaryBlue, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))),
            child: Column(children: [
              Stack(children: [
                CircleAvatar(radius: 50, backgroundColor: Colors.white24, backgroundImage: avatar != null ? NetworkImage(avatar) : null, child: avatar == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null),
                Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((_) => setState(() {})), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 16, color: AppConfig.primaryBlue)))),
              ]),
              const SizedBox(height: 15),
              Text(u?['name'] ?? 'Guest', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(u?['email'] ?? '', style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              _item(Icons.phone_iphone, 'Nomor WhatsApp', u?['phone'] ?? '-'),
              _item(Icons.map_outlined, 'Alamat Saya', u?['address'] ?? '-'),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () { AppConfig.token = null; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (r) => false); }, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: const Text('Keluar dari Akun', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))))
            ]),
          )
        ]),
      ),
    );
  }
  Widget _item(IconData i, String t, String v) => Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))), child: Row(children: [Icon(i, color: AppConfig.primaryBlue), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))])]));
}

// ======================== EDIT PROFILE SCREEN ========================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _name = TextEditingController(text: AppConfig.userProfile?['name']);
  final TextEditingController _phone = TextEditingController(text: AppConfig.userProfile?['phone']);
  final TextEditingController _addr = TextEditingController(text: AppConfig.userProfile?['address']);
  File? _img;
  bool _up = false;

  Future<void> _pick() async {
    final res = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (res != null) setState(() => _img = File(res.path));
  }

  Future<void> _save() async {
    setState(() => _up = true);
    try {
      var req = http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}/api/user/update'));
      req.headers.addAll({'Authorization': 'Bearer ${AppConfig.token}', 'Accept': 'application/json'});
      req.fields['name'] = _name.text; req.fields['phone'] = _phone.text; req.fields['address'] = _addr.text;
      if (_img != null) req.files.add(await http.MultipartFile.fromPath('avatar', _img!.path));
      var res = await req.send();
      var resp = await http.Response.fromStream(res);
      var data = jsonDecode(resp.body);
      if (res.statusCode == 200) {
        AppConfig.userProfile = data['user'];
        if (mounted) Navigator.pop(context);
      }
    } finally { setState(() => _up = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Profil')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        GestureDetector(onTap: _pick, child: CircleAvatar(radius: 50, backgroundImage: _img != null ? FileImage(_img!) : (AppConfig.userProfile?['avatar_url'] != null ? NetworkImage(AppConfig.userProfile!['avatar_url']) : null) as ImageProvider?, child: _img == null && AppConfig.userProfile?['avatar_url'] == null ? const Icon(Icons.camera_alt) : null)),
        const SizedBox(height: 30),
        _in(_name, 'Nama Lengkap'), _in(_phone, 'Nomor WA'), _in(_addr, 'Alamat', lines: 3),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _up ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)), child: _up ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan')))
      ])),
    );
  }
  Widget _in(TextEditingController c, String label, {int lines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: c, maxLines: lines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
}
