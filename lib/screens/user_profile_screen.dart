// lib/screens/user_profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Đổi mật khẩu
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmNewPasswordCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await FirebaseService.getProfile();
    _nameCtrl.text = data['name'] ?? '';
    _phoneCtrl.text = data['phone'] ?? '';
    _addressCtrl.text = data['address'] ?? '';
  }

  void _updateProfile() async {
    await FirebaseService.updateProfile({
      'name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'address': _addressCtrl.text,
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Cập nhật hồ sơ thành công')));
  }

  void _changePassword() async {
    if (_newPasswordCtrl.text != _confirmNewPasswordCtrl.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mật khẩu mới không khớp!')));
      return;
    }

    if (_newPasswordCtrl.text.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mật khẩu mới phải ≥ 6 ký tự!')));
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _oldPasswordCtrl.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordCtrl.text);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đổi mật khẩu thành công!')));

      // Xóa form
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmNewPasswordCtrl.clear();
    } catch (e) {
      String msg = 'Mật khẩu cũ không đúng!';
      if (e.toString().contains('too-many-requests')) {
        msg = 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hồ sơ')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Thông tin cá nhân
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: 'Họ tên'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(labelText: 'SĐT'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(labelText: 'Địa chỉ'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Cập nhật hồ sơ'),
            ),

            Divider(height: 40, thickness: 1),

            // Đổi mật khẩu
            Text(
              'Đổi mật khẩu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _oldPasswordCtrl,
              obscureText: _obscureOld,
              decoration: InputDecoration(
                labelText: 'Mật khẩu cũ',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureOld ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _newPasswordCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _confirmNewPasswordCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Đổi mật khẩu'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),

            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _logout,
              child: Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
