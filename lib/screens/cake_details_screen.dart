// lib/screens/cake_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cake.dart';
import '../services/firebase_service.dart';
import '../providers/favorite_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';

class CakeDetailsScreen extends StatefulWidget {
  @override
  _CakeDetailsScreenState createState() => _CakeDetailsScreenState();
}

class _CakeDetailsScreenState extends State<CakeDetailsScreen> {
  String _selectedSize = 'Nhỏ';
  final Map<String, double> _sizeMultipliers = {
    'Nhỏ': 1.0,
    'Trung bình': 1.5,
    'Lớn': 2.0,
  };
  final Map<String, String> _sizeDescriptions = {
    'Nhỏ': '15cm',
    'Trung bình': '20cm',
    'Lớn': '25cm',
  };
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment(String cakeId, String userName) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('cakes')
        .doc(cakeId)
        .collection('comments')
        .add({
          'text': text,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cakeId = ModalRoute.of(context)!.settings.arguments as String;
    final fp = Provider.of<FavoriteProvider>(context);
    final cp = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isLoggedIn = auth.user != null;
    final userName = 'Guest'; // Luôn hiển thị 'Guest'

    return Scaffold(
      body: FutureBuilder<Cake>(
        future: FirebaseService.getCakeById(cakeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          final cake = snapshot.data!;
          final adjustedPrice = (cake.price * _sizeMultipliers[_selectedSize]!)
              .toInt();
          final isFavorite = fp.isFavorite(cake.id);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'cake-${cake.id}',
                    child: CachedNetworkImage(
                      imageUrl: cake.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cake.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isLoggedIn)
                            IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                              onPressed: () async =>
                                  await fp.toggleFavorite(cake.id),
                            ),
                        ],
                      ),
                      Text('Danh mục: ${cake.category}'),
                      Text(
                        'Trạng thái: ${cake.isAvailable ? 'Có sẵn' : 'Hết hàng'}',
                        style: TextStyle(
                          color: cake.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Mô tả: ${cake.description}'),
                      SizedBox(height: 16),
                      Text('Kích thước:'),
                      DropdownButton<String>(
                        value: _selectedSize,
                        items: _sizeMultipliers.keys
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text('$s (${_sizeDescriptions[s]})'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSize = v!),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '$adjustedPrice VNĐ',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      if (cake.isAvailable)
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_shopping_cart),
                          label: Text('Thêm vào giỏ hàng'),
                          onPressed: () async {
                            await cp.addToCart(cake.id, _selectedSize, 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã thêm ${cake.name} ($_selectedSize)',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      SizedBox(height: 32),
                      Text(
                        'Bình luận',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLoggedIn) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: 'Viết bình luận...',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send),
                              onPressed: () => _addComment(cake.id, userName),
                            ),
                          ],
                        ),
                      ] else
                        Text('Vui lòng đăng nhập để bình luận'),
                      SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('cakes')
                            .doc(cake.id)
                            .collection('comments')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return CircularProgressIndicator();
                          final comments = snapshot.data?.docs ?? [];
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment =
                                  comments[index].data()
                                      as Map<String, dynamic>;
                              return ListTile(
                                title: Text(comment['text']),
                                subtitle: Text(
                                  'Bởi: Guest - ${comment['timestamp']?.toDate().toString() ?? 'Vừa xong'}',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
