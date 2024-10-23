import 'package:finance_manager/account.dart';
import 'package:finance_manager/budget.dart';
import 'package:finance_manager/databasehelper.dart';
import 'package:finance_manager/investment.dart';
import 'package:finance_manager/report.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> accounts = [];
  TextEditingController _nameController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  bool _isCredit = true;

   @override
  void initState() {
    super.initState();
    _getAccounts(); 
  }

  void _addAccount(){
    String name =_nameController.text;
    int amount = int.tryParse(_amountController.text) ?? 0;
    String type = _isCredit ? 'credit' : 'debit';

    _insertAccount(name, amount,type);
    _getAccounts();
    _nameController.clear();
    _amountController.clear();
    Navigator.of(context).pop();
  }

  Future<void> _insertAccount(String name, int amount, String type) async {
    await DatabaseHelper.instance.insert(name,amount,type);
  }

  Future<void> _getAccounts() async {
    final data = await DatabaseHelper.instance.queryAllRows();
    setState(() {
      accounts = data; 
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Finance Manager'),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: <Widget>[
                  ...accounts.map((account) => ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    Account(account: account)),
                          );
                        },
                        child: Text(
                          '${account[DatabaseHelper.columnName]}: ${account[DatabaseHelper.columnBalance]} (${account[DatabaseHelper.columnType]})',
                        )
                      )),
                  ElevatedButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  title: Text('Insert Account'),
                                  content: StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _nameController,
                                            decoration: InputDecoration(hintText:'Account Name'),
                                          ),
                                          SizedBox(height: 20),
                                          TextField(
                                            controller: _amountController,
                                            decoration: InputDecoration(hintText: "Balance"),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Account Type: ${_isCredit ? 'Credit' : 'Debit'}'),
                                              Switch(
                                                value: _isCredit, 
                                                onChanged: (value) {
                                                  setState(() {
                                                    _isCredit = value;
                                                  });
                                                })
                                            ],
                                          ),
                                          ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _addAccount();
                                                }); 
                                              },
                                              child: Text('Insert'))
                                        ],
                                      );
                                    }
                                  ),
                                ));
                      },
                      child: Text('Insert account')),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => report()));
                    },
                    child: Text('Reports'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => BudgetScreen()));
                    },
                    child: Text('Budget'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => Investment()));
                    },
                    child: Text('Investments'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}