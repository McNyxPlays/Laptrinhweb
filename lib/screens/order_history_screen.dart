// lib/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // THÊM ĐỂ HIỂN THỊ HÌNH
import '../services/firebase_service.dart';

class OrderHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử đơn hàng'),
        backgroundColor: Colors.pink,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: FirebaseService.getOrderHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(child: Text('Chưa có đơn hàng'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final item =
                  order['items'][0] ??
                  {}; // Lấy item đầu tiên (giả sử 1 item/đơn)
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HÌNH ẢNH BÁNH (HÀNG NGANG)
                      Container(
                        width: 80,
                        height: 80,
                        child: CachedNetworkImage(
                          imageUrl:
                              item['image'] ??
                              'https://placeholder.com/80x80', // Fallback nếu không có image
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.cake, size: 40),
                        ),
                      ),
                      SizedBox(width: 16),
                      // INFO (TÊN, GIÁ, TRẠNG THÁI)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã đơn: ${order['orderId']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tên bánh: ${item['name'] ?? 'Không xác định'}',
                            ),
                            SizedBox(height: 4),
                            Text('Giá: ${order['total']} VNĐ'),
                            SizedBox(height: 4),
                            Text(
                              'Trạng thái: ${order['status']}',
                              style: TextStyle(
                                color: order['status'] == 'Pending'
                                    ? Colors.orange
                                    : Colors.green,
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
