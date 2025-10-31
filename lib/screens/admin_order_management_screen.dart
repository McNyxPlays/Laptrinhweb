// lib/screens/admin_order_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đơn hàng'),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final orders = snapshot.data?.docs ?? [];
          if (orders.isEmpty) {
            return Center(child: Text('Chưa có đơn hàng'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final order = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('Mã đơn: ${order['orderId']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng: ${order['total']} VNĐ'),
                      Text('Tên: ${order['name']}'),
                      Text('Địa chỉ: ${order['address']}'),
                      Text('Ghi chú: ${order['note'] ?? 'Không có'}'),
                      Text('Phương thức: ${order['paymentMethod']}'),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: order['status'],
                    items: ['Pending', 'Đang giao', 'Hoàn thành', 'Hủy']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (newStatus) async {
                      if (newStatus != null) {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(docId)
                            .update({'status': newStatus});
                      }
                    },
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
