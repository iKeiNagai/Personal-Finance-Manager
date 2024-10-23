import 'package:finance_manager/databasehelper.dart';
import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  final Map<String, dynamic> account;
  Account({required this.account});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  List<Map<String, dynamic>> transactions =[];
  TextEditingController _amounttController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  bool _isPositive = true;

  @override
  void initState(){
    super.initState();
    _getTransactions();
  }
  void addTransaction(){
    double? amount = double.tryParse(_amounttController.text);
    String category = _categoryController.text;
    String date = _dateController.text;
    int accountId = widget.account['_id'];

    _insertTransaction(amount!, category, date, accountId);
    _getTransactions();
    Navigator.of(context).pop();
  }

  Future<void> _insertTransaction(double amount, String category, String date, int account_id) async {
    await DatabaseHelper.instance.insertTransaction(amount, category, date, account_id);
  }

  Future<void> _getTransactions() async {
    int accountId = widget.account['_id'];
    final data = await DatabaseHelper.instance.queryAllRowsTransaction(accountId);
    setState(() {
      transactions = data; 
    });
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
            Text(widget.account['balance'].toString()),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index){
                  return ListTile(
                    title: Text(transactions[index]['amount'].toString()),
                    subtitle: Row(children: [
                      Text(transactions[index]['category']),
                      SizedBox(width: 30),
                      Text(transactions[index]['date'])
                    ],),
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
                              Text(_isPositive ? '-' : '+'),
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
                              addTransaction();
                            }, 
                            child: Text('Save'))
                        ],
                      );
                    }),
                ));
        },
        child: Icon(Icons.add)),
    );
  }
}