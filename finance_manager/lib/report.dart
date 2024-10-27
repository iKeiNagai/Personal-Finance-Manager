import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'databasehelper.dart';

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _reportState();
}

class _reportState extends State<Report> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  static const backgroundColor = Color(0xFF282A36);
  static const surfaceColor = Color(0xFF44475A);
  static const primaryColor = Color(0xFF50FA7B);
  static const textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: const Text('Report',
        style: TextStyle(color: textColor, fontFamily: 'Gayathri'),),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Text('Monthly',
              style: TextStyle(
                color: _selectedIndex == 0 ? primaryColor : textColor,
                fontFamily: 'Gayathri'
              )),),
            Tab(child: Text('Yearly',
              style: TextStyle(
                color: _selectedIndex == 1 ? primaryColor : textColor,
                fontFamily: 'Gayathri'
              )),)
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
  const MonthlyReport({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getMonthlyReport(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reportData = snapshot.data ?? [];
        if (reportData.isEmpty) {
          return const Center(child: Text('No data available.'));
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

            double previousExpenses = 0.0;
            double previousIncome = 0.0;

            if (index < reportData.length -1) {
              final previousItem = reportData[index + 1];
              String previousMonth = previousItem['month'];
              DateTime previousMonthString = DateTime.parse("$previousMonth-01");
              if (previousMonthString.year == monthString.year &&
                  previousMonthString.month == monthString.month - 1) {
                previousExpenses = (previousItem['total_expenses'] as num).toDouble();
                previousIncome = (previousItem['total_income'] as num).toDouble();
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF44475A),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      formattedMonthYear,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gayathri'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total Expenses: \$${NumberFormat("#,##0.00").format(totalExpenses)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Gayathri'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Previous Month: \$${NumberFormat("#,##0.00").format(previousExpenses)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontFamily: 'Gayathri'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Total Income: \$${NumberFormat("#,##0.00").format(totalIncome)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Gayathri'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Previous Month: \$${NumberFormat("#,##0.00").format(previousIncome)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontFamily: 'Gayathri'
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reportData = snapshot.data ?? [];
        if (reportData.isEmpty) {
          return const Center(child: Text('No data available.'));
        }

        return ListView.builder(
          itemCount: reportData.length,
          itemBuilder: (context, index) {
            final item = reportData[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal:16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF44475A),
                  borderRadius: BorderRadius.circular(12)
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Year: ${item['year']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gayathri'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total Expenses: \$${NumberFormat("#,##0.00").format(item['total_expenses'])}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Gayathri'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total Income: \$${NumberFormat("#,##0.00").format(item['total_income'])}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Gayathri'
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

