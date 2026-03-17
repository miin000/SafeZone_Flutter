import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/presentation/providers/statistics_provider.dart';
import 'package:mobile_flutter/presentation/providers/health_info_provider.dart';
import 'statistics_tab.dart';
import 'health_info_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SafeZone'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Thống kê'),
              Tab(text: 'Thông tin Y tế'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StatisticsTab(),
            HealthInfoTab(),
          ],
        ),
      ),
    );
  }
}
