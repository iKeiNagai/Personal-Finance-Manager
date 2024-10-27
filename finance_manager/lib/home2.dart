import 'package:finance_manager/account.dart';
import 'package:finance_manager/budget.dart';
import 'package:finance_manager/databasehelper.dart';
import 'package:finance_manager/investment.dart';
import 'package:finance_manager/report.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class Home2 extends StatefulWidget {
  const Home2({super.key});

  @override
  State<Home2> createState() => _HomeState();
}

class _HomeState extends State<Home2> {
  List<Map<String, dynamic>> accounts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isCredit = true;

  @override
  void initState() {
    super.initState();
    _getAccounts();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF282A36),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor:  const Color(0xFF44475A),
        title: const Text('Personal Finance Manager',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Gayathri'
          ),),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: <Widget>[
                    ...accounts.map((account) => Column(
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        Account(account: account, onUpdate: _getAccounts)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF44475A),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                        account[DatabaseHelper.columnName],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Gayathri',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold
                                        )
                                    ),
                                    Text(
                                      NumberFormat("#,##0.00").format(account[DatabaseHelper.columnBalance]),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Gayathri',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(account[DatabaseHelper.columnType],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Gayathri',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold
                                  ),),
                                IconButton(
                                    onPressed: (){
                                      _deleteAccount(account[DatabaseHelper.columnId]);
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red,))
                              ],
                            )
                        ),
                        const SizedBox(height: 10)
                      ],
                    )),
                    ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF282A36),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)
                                ),
                                title: const Text('Insert Account',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Gayathri'
                                  ),),
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
                                            decoration: const InputDecoration(hintText:'Account Name',
                                                hintStyle: TextStyle(
                                                    color: Colors.white54,
                                                    fontFamily: 'Gayathri'
                                                )),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: _amountController,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Gayathri'
                                            ),
                                            decoration: const InputDecoration(hintText: "Balance",
                                                hintStyle: TextStyle(
                                                    color: Colors.white54,
                                                    fontFamily: 'Gayathri'
                                                )),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(_isCredit ? 'Credit' : 'Debit',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Gayathri'
                                                ),),
                                              Switch(
                                                  value: _isCredit,
                                                  activeColor: Color(0xFF50FA7B),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isCredit = value;
                                                    });
                                                  })
                                            ],
                                          ),
                                          TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _addAccount();
                                                });
                                              },
                                              child: const Text('Insert',
                                                  style: TextStyle(
                                                      color: Color(0xFF50FA7B),
                                                      fontFamily: 'Gayathri'
                                                  )))
                                        ],
                                      );
                                    }
                                ),
                              ));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF44475A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
                        ),
                        child: const Text('Insert account',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gayathri'
                          ),)),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const Report()));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF44475A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
                      ),
                      child: const Text('Reports',
                        style: TextStyle(
                            color:Colors.white,
                            fontFamily: 'Gayathri'
                        ),),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => BudgetScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF44475A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
                      ),
                      child: const Text('Budget',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Gayathri'
                        ),),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => InvestmentScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF44475A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
                      ),
                      child: const Text('Investments',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Gayathri'
                        ),),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}