import 'package:finance_manager/databasehelper.dart';
import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  final Map<String, dynamic> account;
  final VoidCallback onUpdate;
  Account({required this.account, required this.onUpdate});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  List<Map<String, dynamic>> transactions =[];
  TextEditingController _amounttController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  bool _isPositive = true;
  late double currentBalance;

  @override
  void initState(){
    super.initState();
    currentBalance = widget.account['balance'];
    _getTransactions();
  }

  void addTransaction(bool isPositive){
    double? amount = double.tryParse(_amounttController.text);
    String category = _categoryController.text;
    String date = _dateController.text;
    int accountId = widget.account['_id'];

    double newBalance = isPositive
      ? currentBalance - amount!
      : currentBalance + amount!;


    _insertTransaction(amount, category, date, accountId);
    _updateAccountBalance(accountId, newBalance);
    
    setState(() {
      currentBalance = newBalance;
    });
    widget.onUpdate();
    _getTransactions();

    Navigator.of(context).pop();
  }

  Future<void> _insertTransaction(double amount, String category, String date, int account_id) async {
    await DatabaseHelper.instance.insertTransaction(amount, category, date, account_id);
  }

  Future<void> _updateAccountBalance(int accountId, double newBalance) async {
    await DatabaseHelper.instance.updateAccountBalance(accountId, newBalance);
  }

  Future<void> _getTransactions() async {
    int accountId = widget.account['_id'];
    final data = await DatabaseHelper.instance.queryAllRowsTransaction(accountId);
    setState(() {
      transactions = data;
    });
  }

  Future<void> _deleteTransaction(int transactionId) async {
    await DatabaseHelper.instance.deleteTransaction(transactionId);
    _getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text(currentBalance.toString()),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index){
                  return ListTile(
                    title: Text(transactions[index]['amount'].toString()),
                    subtitle: Row(children: [
                      Text(transactions[index]['category']),
                      SizedBox(width: 30),
                      Text(transactions[index]['date']),
                    ],),
                    trailing: IconButton(
                      onPressed: (){
                        _deleteTransaction(transactions[index]['id']);
                      }, 
                      icon: Icon(Icons.delete)),
                  );
                })
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:(){
          showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Insert Transaction'),
                  content: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState){
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _amounttController,
                            decoration: InputDecoration(hintText:'Amount'),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _categoryController,
                            decoration: InputDecoration(hintText: 'Category'),
                          ),
                          SizedBox(height:20),
                          TextField(
                            controller: _dateController,
                            decoration: InputDecoration(hintText: 'Date: YYYY-MM-DD'),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_isPositive ? 'Subtract' : 'Add'),
                              Switch(
                                value: _isPositive, 
                                onChanged: (value){
                                  setState((){
                                    _isPositive = value;
                                  });
                                })
                            ],
                          ),
                          ElevatedButton(
                            onPressed: (){
                              addTransaction(_isPositive);
                            }, 
                            child: Text('Save')),
                          Text(_isPositive.toString())
                        ],
                      );
                    }),
                ));
        },
        child: Icon(Icons.add)),
    );
    
  }
}