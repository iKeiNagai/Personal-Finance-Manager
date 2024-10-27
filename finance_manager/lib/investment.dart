import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';
import 'databasehelper.dart';
import 'dart:math';

class InvestmentScreen extends StatefulWidget {
  @override
  _InvestmentScreenState createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  List<Map<String, dynamic>> positions = [];
  double portfolioValue = 0.0;
  double portfolioProfitLoss = 0.0;
  List<FlSpot> chartData = [];
  String selectedTimeframe = '1D';

  static const backgroundColor = Color(0xFF282A36);
  static const surfaceColor = Color(0xFF44475A);
  static const primaryColor = Color(0xFF50FA7B);
  static const accentColor = Color(0xFFFF79C6);
  static const textColor = Colors.white;
  static const secondaryTextColor = Colors.white54;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }


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
      _updateChartData(); // ensures chart updates with new data
    });
  }

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




  Future<void> _addPosition(String ticker, double quantity, double purchasePrice) async {
    await DatabaseHelper.instance.insertStock(ticker, quantity, purchasePrice);
    await _loadPositions();
  }


  Future<void> _updatePosition(int stockId, double newQuantity, double newPurchasePrice) async {
    await DatabaseHelper.instance.updateStock(stockId, newQuantity, newPurchasePrice);
    await _loadPositions();
  }

  Future<void> _deletePosition(int stockId) async {
    await DatabaseHelper.instance.deleteStock(stockId);
    await _loadPositions();
  }

  void _showAddPositionDialog() {
    String ticker = '';
    double quantity = 0.0;
    double purchasePrice = 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Add Position',
          style: TextStyle(
            color: textColor,
            fontFamily: 'Gayathri',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Ticker Symbol',
                labelStyle: TextStyle(color: secondaryTextColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
              ),
              style: TextStyle(color: textColor),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => ticker = value.toUpperCase(),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Quantity',
                labelStyle: TextStyle(color: secondaryTextColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
              onChanged: (value) => quantity = double.tryParse(value) ?? 0,
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Purchase Price',
                labelStyle: TextStyle(color: secondaryTextColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
              onChanged: (value) => purchasePrice = double.tryParse(value) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              if (ticker.isNotEmpty && quantity > 0 && purchasePrice > 0) {
                _addPosition(ticker, quantity, purchasePrice);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Add',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPositionDialog(Map<String, dynamic> position) {
    double newQuantity = position['quantity'];
    double newPurchasePrice = position['purchase_price'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Edit ${position['ticker']}',
          style: TextStyle(
            color: textColor,
            fontFamily: 'Gayathri',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Quantity',
                labelStyle: TextStyle(color: secondaryTextColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: newQuantity.toString()),
              onChanged: (value) => newQuantity = double.tryParse(value) ?? newQuantity,
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Purchase Price',
                labelStyle: TextStyle(color: secondaryTextColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: newPurchasePrice.toString()),
              onChanged: (value) => newPurchasePrice = double.tryParse(value) ?? newPurchasePrice,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => _deletePosition(position['stock_id'])
                .then((_) => Navigator.pop(context)),
            child: Text(
              'Delete',
              style: TextStyle(color: accentColor),
            ),
          ),
          TextButton(
            onPressed: () {
              _updatePosition(position['stock_id'], newQuantity, newPurchasePrice);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text(
          'Investments',
          style: TextStyle(
            color: textColor,
            fontFamily: 'Gayathri',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPositions,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${portfolioValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
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
                            fontSize: 16,
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
                SizedBox(height: 24),
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
                SizedBox(height: 16),
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
                SizedBox(height: 24),
                Text(
                  'Positions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Gayathri',
                  ),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final position = positions[index];
                    return Card(
                      color: surfaceColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        onTap: () => _showEditPositionDialog(position),
                        title: Text(
                          position['ticker'],
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Gayathri',
                          ),
                        ),
                        subtitle: Text(
                          '${position['quantity']} shares @ \$${position['purchase_price'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontFamily: 'Gayathri',
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${position['position_value'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontFamily: 'Gayathri',
                              ),
                            ),
                            Text(
                              '\$${position['profit_loss'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color: position['profit_loss'] >= 0 ? primaryColor : accentColor,
                                fontFamily: 'Gayathri',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _showAddPositionDialog,
        child: Icon(Icons.add, color: backgroundColor),
      ),
    );
  }
}