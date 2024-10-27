import 'package:finance_manager/account.dart';
import 'package:finance_manager/budget.dart';
import 'package:finance_manager/databasehelper.dart';
import 'package:finance_manager/investment.dart';
import 'package:finance_manager/report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';
import 'dart:math';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isCredit = true;
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> positions = [];
  double portfolioValue = 0.0;
  double portfolioProfitLoss = 0.0;
  List<FlSpot> chartData = [];
  String selectedTimeframe = '1D';
  double budgetRemaining = 0.0;
  bool isOnBudget = true;

  static const backgroundColor = Color(0xFF282A36);
  static const surfaceColor = Color(0xFF44475A);
  static const primaryColor = Color(0xFF50FA7B);
  static const accentColor = Color(0xFFFF79C6);
  static const textColor = Colors.white;
  static const secondaryTextColor = Colors.white54;

  @override
  void initState() {
    super.initState();
    _getAccounts();
    _loadPositions();
    _loadBudgetStatus();
  }
  void _addAccount(){
    String name =_nameController.text;
    double? amount = double.tryParse(_amountController.text) ?? 0;
    String type = _isCredit ? 'CREDIT' : 'DEBIT';

    _insertAccount(name, amount,type);
    _getAccounts();
    _nameController.clear();
    _amountController.clear();
    Navigator.of(context).pop();
  }

  Future<void> _deleteAccount(int accountId) async {
    await DatabaseHelper.instance.deleteAllTransactionsAccount(accountId);
    await DatabaseHelper.instance.delete(accountId);
    _getAccounts();
  }
  Future<void> _insertAccount(String name, double? amount, String type) async {
    await DatabaseHelper.instance.insert(name,amount,type);
  }

  Future<void> _getAccounts() async {
    final data = await DatabaseHelper.instance.queryAllRows();
    setState(() {
      accounts = data;
    });
  }
  Future<void> _loadBudgetStatus() async {
    // TODO: Implement budget status loading from budget.dart
    // This should be implemented based on your budget tracking logic
    setState(() {
      budgetRemaining = 992.00; // Example value
      isOnBudget = true; // Example value
    });
  }

  // Investment data loading functions
  Future<void> _loadPositions() async {
    final stocks = await DatabaseHelper.instance.queryAllStocks();
    double totalValue = 0.0;
    double totalCost = 0.0;
    List<Map<String, dynamic>> updatedPositions = [];

    for (var stock in stocks) {
      try {
        YahooFinanceResponse response = await YahooFinanceDailyReader().getDailyDTOs(stock['ticker']);
        double currentPrice = response.candlesData.last.close;
        double quantity = stock['quantity'];
        double purchasePrice = stock['purchase_price'];
        double positionValue = quantity * currentPrice;
        double positionCost = quantity * purchasePrice;
        double positionProfitLoss = positionValue - positionCost;
        totalValue += positionValue;
        totalCost += positionCost;
        updatedPositions.add({
          ...stock,
          'current_price': currentPrice,
          'position_value': positionValue,
          'profit_loss': positionProfitLoss,
        });
      } catch (e) {
        print('Error fetching data for ${stock['ticker']}: $e');
        updatedPositions.add({
          ...stock,
          'current_price': stock['purchase_price'],
          'position_value': stock['quantity'] * stock['purchase_price'],
          'profit_loss': 0.0,
        });
      }
    }

    setState(() {
      positions = updatedPositions;
      portfolioValue = totalValue;
      portfolioProfitLoss = totalValue - totalCost;
      _updateChartData();
    });
  }

  // Chart data functions
  Future<void> _updateChartData() async {
    List<FlSpot> spots = [];
    DateTime endDate = DateTime.now();
    DateTime startDate;

    // Set time range based on selected timeframe
    switch (selectedTimeframe) {
      case '1D':
        startDate = endDate.subtract(Duration(days: 1));
        break;
      case '1W':
        startDate = endDate.subtract(Duration(days: 7));
        break;
      case '1M':
        startDate = endDate.subtract(Duration(days: 30));
        break;
      case '3M':
        startDate = endDate.subtract(Duration(days: 90));
        break;
      case '1Y':
        startDate = endDate.subtract(Duration(days: 365));
        break;
      case 'ALL':
      // Find earliest purchase date from positions or default to 1 year
        startDate = endDate.subtract(Duration(days: 365));
        break;
      default:
        startDate = endDate.subtract(Duration(days: 1));
    }

    // Map to store aggregated portfolio value at each date index
    Map<int, double> portfolioValueMap = {};

    // For each position
    for (var position in positions) {
      try {
        // Fetch historical data for the stock
        YahooFinanceResponse response = await YahooFinanceDailyReader().getDailyDTOs(
          position['ticker'],
        );

        double quantity = position['quantity'];

        // Process each candle
        for (int i = 0; i < response.candlesData.length; i++) {
          var candle = response.candlesData[i];
          double price = candle.close;
          double positionValue = quantity * price;

          // Add to portfolio value map
          portfolioValueMap.update(
            i,
                (existingValue) => existingValue + positionValue,
            ifAbsent: () => positionValue,
          );
        }
      } catch (e) {
        print('Error fetching data for ${position['ticker']}: $e');
        // Use current price for missing data points
        double currentPrice = position['current_price'];
        double quantity = position['quantity'];
        double positionValue = quantity * currentPrice;

        // Add to latest data point
        if (portfolioValueMap.isNotEmpty) {
          int lastIndex = portfolioValueMap.keys.reduce(max);
          portfolioValueMap[lastIndex] = (portfolioValueMap[lastIndex] ?? 0) + positionValue;
        }
      }
    }

    // Convert map to spots
    if (portfolioValueMap.isNotEmpty) {
      int maxIndex = portfolioValueMap.keys.reduce(max);

      // Filter points based on selected timeframe
      int startIndex = _getStartIndex(maxIndex, selectedTimeframe);

      // Create spots
      for (int i = startIndex; i <= maxIndex; i++) {
        if (portfolioValueMap.containsKey(i)) {
          double x = (i - startIndex) / (maxIndex - startIndex);
          spots.add(FlSpot(x, portfolioValueMap[i] ?? 0));
        }
      }

      // Interpolate missing points if needed
      spots = _interpolateMissingPoints(spots, _calculateIntervals(endDate.difference(startDate)));
    }

    // Update state
    setState(() {
      chartData = spots;
    });
  }

  // Helper method to calculate appropriate number of intervals
  int _calculateIntervals(Duration timeRange) {
    if (timeRange.inDays <= 1) return 96; // Hourly for 1 day
    if (timeRange.inDays <= 7) return 7 * 96; // Hourly for 1 week
    if (timeRange.inDays <= 30) return 30 * 96; // Daily for 1 month
    if (timeRange.inDays <= 90) return 90 * 96; // Daily for 3 months
    if (timeRange.inDays <= 365) return 365 * 96; // Daily for 1 year
    return timeRange.inDays; // Daily for all time
  }

// Helper method to get start index based on timeframe
  int _getStartIndex(int maxIndex, String timeframe) {
    switch (timeframe) {
      case '1D':
        return maxIndex - 24;
      case '1W':
        return maxIndex - (7 * 1);
      case '1M':
        return maxIndex - (30 * 1);
      case '3M':
        return maxIndex - (90 * 1);
      case '1Y':
        return maxIndex - (365 * 1);
      case 'ALL':
        return 0;
      default:
        return maxIndex - 1;
    }
  }

// Helper method to interpolate missing data points
  List<FlSpot> _interpolateMissingPoints(List<FlSpot> spots, int targetPoints) {
    if (spots.length < 2) return spots;

    List<FlSpot> interpolatedSpots = [];
    for (int i = 0; i < spots.length - 1; i++) {
      FlSpot current = spots[i];
      FlSpot next = spots[i + 1];
      interpolatedSpots.add(current);

      // Calculate number of points to insert between current and next
      int pointsToAdd = ((next.x - current.x) * targetPoints).round();
      if (pointsToAdd > 1) {
        for (int j = 1; j < pointsToAdd; j++) {
          double ratio = j / pointsToAdd;
          double x = current.x + (next.x - current.x) * ratio;
          double y = current.y + (next.y - current.y) * ratio;
          interpolatedSpots.add(FlSpot(x, y));
        }
      }
    }
    interpolatedSpots.add(spots.last);

    return interpolatedSpots;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Gayathri',
        ),
      ),
    );
  }

  Widget _buildDebitAccountCell(Map<String, dynamic> account) {
    return Card(
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Account(
                account: account,
                onUpdate: _getAccounts,
              ),
            ),
          );
        },
        title: Text(
          account['name'] as String? ?? 'Unnamed Account',
          style: const TextStyle(
            color: textColor,
            fontFamily: 'Gayathri',
            fontSize: 20,
          ),
        ),
        subtitle: Text(
          '\$${NumberFormat("#,##0.00").format(account['balance'] ?? 0.0)}',
          style: const TextStyle(
            color: textColor,
            fontFamily: 'Gayathri',
            fontSize: 14,
          ),
        ),

        trailing: IconButton(
          onPressed: (){
            _deleteAccount(account[DatabaseHelper.columnId]);
          },
          icon: const Icon(Icons.delete, color: Colors.red,),
          color: textColor,
        ),
      ),
    );
  }
  Widget _buildCreditAccountCell(Map<String, dynamic> account) {
    return Card(
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Account(
                account: account,
                onUpdate: _getAccounts,
              ),
            ),
          );
        },
        title: Text(
          account['name'] as String? ?? 'Unnamed Account',
          style: const TextStyle(
            color: textColor,
            fontFamily: 'Gayathri',
            fontSize: 20,
          ),
        ),
        subtitle: Text(
          '\$${NumberFormat("#,##0.00").format(account['balance'] ?? 0.0)}',
          style: const TextStyle(
            color: textColor,
            fontFamily: 'Gayathri',
            fontSize: 14,
          ),
        ),

        trailing: IconButton(
          onPressed: (){
            _deleteAccount(account[DatabaseHelper.columnId]);
          },
          icon: const Icon(Icons.delete, color: Colors.red,),
          color: textColor,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final debitAccounts = accounts.where((a) => a['Type'] == 'DEBIT').toList();

    final creditAccounts = accounts.where((a) => a['Type'] == 'CREDIT').toList();

    return Scaffold(
      appBar: AppBar(title: Text(' '),backgroundColor: Color(0x00282A36)),
      backgroundColor: backgroundColor,

      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _getAccounts(),
            _loadPositions(),
            _loadBudgetStatus(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Welcome',

                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD2DDFF),
                    fontFamily: 'Gayathri',
                  ),
                ),
                // const SizedBox(height: 12),

                // Investing Section
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InvestmentScreen()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Investing'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Text(
                            '\$${portfolioValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Gayathri',
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '\$${portfolioProfitLoss.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: portfolioProfitLoss >= 0 ? primaryColor : accentColor,
                                  fontFamily: 'Gayathri',
                                ),
                              ),
                              Icon(
                                portfolioProfitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: portfolioProfitLoss >= 0 ? primaryColor : accentColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: chartData,
                                isCurved: true,
                                color: portfolioProfitLoss >= 0 ? primaryColor : accentColor,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: (portfolioProfitLoss >= 0 ? primaryColor : accentColor).withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['1D', '1W', '1M', '3M', '1Y', 'ALL'].map((timeframe) {
                          return TextButton(
                            onPressed: () {
                              setState(() {
                                selectedTimeframe = timeframe;
                                _updateChartData();
                              });
                            },
                            child: Text(
                              timeframe,
                              style: TextStyle(
                                color: selectedTimeframe == timeframe ? primaryColor : secondaryTextColor,
                                fontWeight: selectedTimeframe == timeframe ? FontWeight.bold : FontWeight.normal,
                                fontFamily: 'Gayathri',
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),


                // accounts


                // add accounts



                // Banking Section
                _buildSectionTitle('Banking'),
                ...debitAccounts.map(_buildDebitAccountCell),
                const SizedBox(height: 4),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0), // Adjust padding as needed
                    child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF282A36),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                title: const Text(
                                  'Insert Account',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 60,
                                      fontFamily: 'Gayathri'
                                  ),
                                ),
                                content: StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _nameController,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Gayathri'
                                            ),
                                            decoration: const InputDecoration(
                                                hintText: 'Account Name',
                                                hintStyle: TextStyle(
                                                    color: Colors.white54,
                                                    fontFamily: 'Gayathri'
                                                )
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: _amountController,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Gayathri'
                                            ),
                                            decoration: const InputDecoration(
                                                hintText: "Balance",
                                                hintStyle: TextStyle(
                                                    color: Colors.white54,
                                                    fontFamily: 'Gayathri'
                                                )
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _isCredit ? 'Credit' : 'Debit',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Gayathri'
                                                ),
                                              ),
                                              Switch(
                                                  value: _isCredit,
                                                  activeColor: Color(0xFF50FA7B),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isCredit = value;
                                                    });
                                                  }
                                              )
                                            ],
                                          ),
                                          TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _addAccount();
                                                });
                                              },
                                              child: const Text(
                                                  'Insert',
                                                  style: TextStyle(
                                                      color: Color(0xFF50FA7B),
                                                      fontFamily: 'Gayathri'
                                                  )
                                              )
                                          )
                                        ],
                                      );
                                    }
                                ),
                              )
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF44475A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
                        ),
                        child: const Text(
                            'Insert account',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Gayathri',
                                fontSize: 20,
                            )
                        )
                    )
                ),

                // Credit Section
                _buildSectionTitle('Credit'),
                ...creditAccounts.map(_buildCreditAccountCell),
                const SizedBox(height: 4),

                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0), // Adjust padding as needed
                    child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF282A36),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                title: const Text(
                                  'Insert Account',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 60,
                                      fontFamily: 'Gayathri'
                                  ),
                                ),
                                content: StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _nameController,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Gayathri'
                                            ),
                                            decoration: const InputDecoration(
                                                hintText: 'Account Name',
                                                hintStyle: TextStyle(
                                                    color: Colors.white54,
                                                    fontFamily: 'Gayathri'
                                                )
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: _amountController,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Gayathri'
                                            ),
                                            decoration: const InputDecoration(
                                                hintText: "Balance",
                                                hintStyle: TextStyle(
                                                    color: Colors.white54,
                                                    fontFamily: 'Gayathri'
                                                )
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _isCredit ? 'Credit' : 'Debit',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Gayathri'
                                                ),
                                              ),
                                              Switch(
                                                  value: _isCredit,
                                                  activeColor: Color(0xFF50FA7B),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isCredit = value;
                                                    });
                                                  }
                                              )
                                            ],
                                          ),
                                          TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _addAccount();
                                                });
                                              },
                                              child: const Text(
                                                  'Insert',
                                                  style: TextStyle(
                                                      color: Color(0xFF50FA7B),
                                                      fontFamily: 'Gayathri'
                                                  )
                                              )
                                          )
                                        ],
                                      );
                                    }
                                ),
                              )
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF44475A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
                        ),
                        child: const Text(
                            'Insert account',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gayathri',
                              fontSize: 20,
                            )
                        )
                    )
                ),

                // Budget Section
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BudgetScreen()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Budget'),
                      Card(
                        color: surfaceColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remaining: \$${budgetRemaining.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: textColor,
                                  fontFamily: 'Gayathri',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isOnBudget ? Icons.check_circle : Icons.warning,
                                    color: isOnBudget ? primaryColor : accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isOnBudget ? 'On Budget' : 'Over Budget',
                                    style: TextStyle(
                                      color: isOnBudget ? primaryColor : accentColor,
                                      fontFamily: 'Gayathri',
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Report Section
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Report()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Reports'),
                      Card(
                        color: surfaceColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Generate Reports',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: textColor,
                                  fontFamily: 'Gayathri',
                                ),
                              ),


                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),
    );
  }
}