import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'databasehelper.dart';

class Report extends StatefulWidget {
  Report({super.key});

  @override
  State<Report> createState() => _reportState();
}

class _reportState extends State<Report> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly')
          ],),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MonthlyReport(),
          YearlyReport()
        ]),
    );
  }
}

class MonthlyReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getMonthlyReport(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reportData = snapshot.data ?? [];
        if (reportData.isEmpty) {
          return Center(child: Text('No data available.'));
        }

        return ListView.builder(
          itemCount: reportData.length,
          itemBuilder: (context, index) {
            final item = reportData[index];

            String isMonth = item['month'];
            DateTime monthString = DateTime.parse("$isMonth-01");
            String formattedMonthYear = DateFormat('MMMM, yyyy').format(monthString);

            double totalExpenses = (item['total_expenses'] as num).toDouble();
            double totalIncome = (item['total_income'] as num).toDouble();

            double previousExpenses = index < reportData.length - 1
                ? (reportData[index + 1]['total_expenses'] as num).toDouble()
                : 0.0;
            double previousIncome = index < reportData.length - 1
                ? (reportData[index + 1]['total_income'] as num).toDouble()
                : 0.0;

            return ListTile(
              title: Text('Month: $formattedMonthYear'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Expenses: \$${totalExpenses.toStringAsFixed(2)}'),
                  Text('Previous Month: \$${previousExpenses.toStringAsFixed(2)}'),
                  SizedBox(height: 20),
                  Text('Total Income: \$${totalIncome.toStringAsFixed(2)}'),
                  Text('Previous Month: \$${previousIncome.toStringAsFixed(2)}')
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class YearlyReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getYearlyReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reportData = snapshot.data ?? [];
        if (reportData.isEmpty) {
          return Center(child: Text('No data available.'));
        }

        return ListView.builder(
          itemCount: reportData.length,
          itemBuilder: (context, index) {
            final item = reportData[index];

            return ListTile(
              title: Text('Year: ${item['year']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Expenses: \$${item['total_expenses'].toStringAsFixed(2)}'),
                  Text('Total Income: \$${item['total_income'].toStringAsFixed(2)}'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

