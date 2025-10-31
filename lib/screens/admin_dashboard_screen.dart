// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  List<FlSpot> _revenueData = [];
  Map<String, int> _topCakes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .get();
    _totalOrders = snapshot.docs.length;
    _totalRevenue = snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + (data['total'] as num? ?? 0).toDouble();
    });

    // Tính doanh thu theo tháng (giả sử từ timestamp)
    Map<int, double> monthlyRevenue = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final month = date.month;
        monthlyRevenue[month] =
            (monthlyRevenue[month] ?? 0) +
            (data['total'] as num? ?? 0).toDouble();
      }
    }
    _revenueData = monthlyRevenue.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    // Top bánh bán chạy
    Map<String, int> cakeSales = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final cakeName = item['name'] as String? ?? 'Unknown';
        cakeSales[cakeName] =
            (cakeSales[cakeName] ?? 0) + (item['quantity'] as int? ?? 0);
      }
    }
    _topCakes = cakeSales;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thống kê tổng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Tổng đơn hàng', _totalOrders.toString()),
                _buildStatCard(
                  'Doanh thu',
                  '${_totalRevenue.toStringAsFixed(0)} VNĐ',
                ),
              ],
            ),
            SizedBox(height: 24),

            // Biểu đồ doanh thu theo tháng
            Text(
              'Doanh thu theo tháng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: _bottomTitles()),
                    leftTitles: AxisTitles(sideTitles: _leftTitles()),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _revenueData,
                      isCurved: true,
                      color: Colors.pink,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Top bánh bán chạy
            Text(
              'Top bánh bán chạy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _topCakes.entries.take(5).map((e) {
                    return PieChartSectionData(
                      value: e.value.toDouble(),
                      title: e.key,
                      color:
                          Colors.primaries[_topCakes.keys.toList().indexOf(
                                e.key,
                              ) %
                              Colors.primaries.length],
                      radius: 100,
                      titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  SideTitles _bottomTitles() => SideTitles(
    showTitles: true,
    getTitlesWidget: (value, meta) => Text('Th${value.toInt()}'),
  );

  SideTitles _leftTitles() => SideTitles(
    showTitles: true,
    getTitlesWidget: (value, meta) =>
        Text('${(value / 1000000).toStringAsFixed(0)}M'),
  );
}
