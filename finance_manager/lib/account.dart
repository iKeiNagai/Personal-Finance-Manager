import 'package:finance_manager/databasehelper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class Account extends StatefulWidget {
  final Map<String, dynamic> account;
  final VoidCallback onUpdate;
  const Account({super.key, required this.account, required this.onUpdate});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  List<Map<String, dynamic>> transactions =[];
  final TextEditingController _amounttController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isPositive = true;
  late double currentBalance;
  late double transactionAmount;

  @override
  void initState(){
    super.initState();
    currentBalance = widget.account['balance'];
    _getTransactions();
  }

  void addTransaction(bool isExpense){
    double? amount = double.tryParse(_amounttController.text);
    String category = _categoryController.text;
    String date = _dateController.text;
    int accountId = widget.account['_id'];

    if (!_isValidDate(date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid date in YYYY-MM-DD format.')),
      );
      return; 
    }

    double newBalance = isExpense
      ? currentBalance - amount!
      : currentBalance + amount!;


    _insertTransaction(amount, category, date, isExpense ,accountId);
    _updateAccountBalance(accountId, newBalance);
    
    setState(() {
      currentBalance = newBalance;
    });
    widget.onUpdate();
    _amounttController.clear();
    _categoryController.clear();
    _dateController.clear();
    _getTransactions();

    Navigator.of(context).pop();
  }

  Future<void> _insertTransaction(double amount, String category, String date,bool isExpense ,int accountId) async {
    await DatabaseHelper.instance.insertTransaction(amount, category, date, isExpense ,accountId);
  }

  Future<void> _updateAccountBalance(int accountId, double newBalance) async {
    await DatabaseHelper.instance.updateAccountBalance(accountId, newBalance);
  }

  Future<void> _getTransactions() async {
    int accountId = widget.account['_id'];
    final data = await DatabaseHelper.instance.queryAllRowsTransaction(accountId);
    setState(() {
      transactions = data.reversed.toList();
    });
  }

  Future<void> _deleteTransaction(int transactionId, double transactionAmount, bool isExpense) async {
    double newBalance = isExpense 
      ? currentBalance + transactionAmount
      : currentBalance - transactionAmount;

    await DatabaseHelper.instance.deleteTransaction(transactionId);
    _updateAccountBalance(widget.account['_id'], newBalance);

    setState(() {
      currentBalance =  newBalance;
    });

    widget.onUpdate();
    _getTransactions();
  }
  
  Future<void> _updateTransaction(int transactionId, double newAmount, String newCategory, String newDate, bool isExpense) async {
    var transaction = transactions.firstWhere((t) => t['id'] == transactionId);
    double oldAmount = transaction['amount'];
    bool wasExpense = transaction['isExpense'] == 1;

    double newBalance = wasExpense
      ? currentBalance + oldAmount
      : currentBalance - oldAmount;

    await DatabaseHelper.instance.updateTransaction(transactionId, newAmount, newCategory, newDate, isExpense);
    
    newBalance = isExpense 
        ? newBalance - newAmount 
        : newBalance + newAmount;
    _updateAccountBalance(widget.account['_id'], newBalance);
  
    setState(() {
      currentBalance = newBalance;
    });

    widget.onUpdate();
    _getTransactions();
    _amounttController.clear();
    _categoryController.clear();
    _dateController.clear();
  }

  bool _isValidDate(String date) {
    DateTime? parsedDate = DateTime.tryParse(date);
    return parsedDate != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF282A36),
      appBar: AppBar(
        backgroundColor:  const Color(0xFF44475A),
        title: const Text('Account',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Gayathri',
            ),),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 30),
            const Text('Current Balance',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white60,
                  fontFamily: 'Gayathri'
                )),
            Text(NumberFormat("#,##0.00").format(currentBalance),
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontFamily: 'Gayathri'
                )),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index){
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF44475A),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ListTile(
                      title: Text(NumberFormat("#,##0.00").format(transactions[index]['amount']),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Gayathri'

                              ),),
                      subtitle: Row(children: [
                        Text(transactions[index]['category'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gayathri')),
                        const SizedBox(width: 30),
                        Text(transactions[index]['date'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gayathri')),
                      ],),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: (){
                              transactionAmount = transactions[index]['amount'];
                              bool isExpense = transactions[index]['isExpense'] == 1;
                              
                              _deleteTransaction(transactions[index]['id'], transactionAmount, isExpense);
                            }, 
                            icon: const Icon(Icons.delete, color: Colors.red,)),
                          IconButton(
                            onPressed: (){
                              _amounttController.text = transactions[index]['amount'].toString();
                              _categoryController.text = transactions[index]['category'];
                              _dateController.text = transactions[index]['date'];
                    
                              showDialog(
                                context: context, 
                                builder: (_) => AlertDialog(
                                  backgroundColor: const Color(0xFF282A36),
                                  shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                                  title: const Text('Update transaction',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Gayathri'
                                          ),),
                                  content: StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setState){
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _amounttController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Gayathri'
                                            ),
                                            decoration: const InputDecoration(hintText:'New Amount',
                                                        hintStyle: TextStyle(
                                                          color: Colors.white54,
                                                          fontFamily: 'Gayathri'
                                                        )),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: _categoryController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Gayathri'
                                            ),
                                            decoration: const InputDecoration(hintText: 'New Category',
                                                        hintStyle: TextStyle(
                                                          color: Colors.white54,
                                                          fontFamily: 'Gayathri'
                                                        )
                                            ),
                                          ),
                                          const SizedBox(height:20),
                                          TextField(
                                            controller: _dateController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Gayathri'
                                            ),
                                            decoration: const InputDecoration(hintText: 'New Date: YYYY-MM-DD',
                                                        hintStyle: TextStyle(
                                                          color: Colors.white54,
                                                          fontFamily: 'Gayathri'
                                                        )
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(_isPositive ? 'Expense' : 'Income',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily:'Gayathri' 
                                                    ),),
                                              Switch(
                                                value: _isPositive, 
                                                activeColor: const Color(0xFF50FA7B),
                                                onChanged: (value){
                                                  setState((){
                                                    _isPositive = value;
                                                  });
                                                }),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: (){
                                              double newAmount = double.tryParse(_amounttController.text) ?? 0;
                                              String newCategory = _categoryController.text;
                                              String newDate = _dateController.text;
                    
                                              _updateTransaction(transactions[index]['id'], newAmount, newCategory, newDate, _isPositive);
                                              Navigator.of(context).pop();
                                            }, 
                                            child: const Text('Save',
                                                      style: TextStyle(
                                                        color: Color(0xFF50FA7B),
                                                        fontFamily: 'Gayathri'
                                                          )
                                                       ,)),
                                        ],
                                      );
                                    }),
                                ));
                            }, 
                            icon: const Icon(Icons.update, color: Color(0xFF50FA7B),))
                        ],
                      ),
                    ),
                  );
                })
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF50FA7B),
        onPressed:(){
          showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF282A36),
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
                  title: const Text('Insert Transaction',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gayathri',
                            ),),
                  content: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState){
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _amounttController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gayathri'
                            ),
                            decoration: const InputDecoration(hintText:'Amount',
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                          fontFamily: 'Gayathri',
                                        )),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _categoryController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gayathri'
                            ),
                            decoration: const InputDecoration(hintText: 'Category',
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                          fontFamily: 'Gayathri',
                                        )),
                          ),
                          const SizedBox(height:20),
                          TextField(
                            controller: _dateController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gayathri'
                            ),
                            decoration: const InputDecoration(hintText: 'Date: YYYY-MM-DD',
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                          fontFamily: 'Gayathri',
                                        )),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_isPositive ? 'Expense' : 'Income',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Gayathri',
                                  ),),
                              Switch(
                                value: _isPositive, 
                                activeColor: const Color(0xFF50FA7B),
                                onChanged: (value){
                                  setState((){
                                    _isPositive = value;
                                  });
                                })
                            ],
                          ),
                          TextButton(
                            onPressed: (){
                              addTransaction(_isPositive);
                            }, 
                            child: const Text('Save',
                                      style: TextStyle(
                                        color: Color(0xFF50FA7B),
                                        fontFamily: 'Gayathri'
                                      ),)),
                        ],
                      );
                    }),
                ));
        },
        child: const Icon(Icons.add)),
    );
    
  }
}