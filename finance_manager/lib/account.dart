import 'package:finance_manager/databasehelper.dart';
import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  final Map<String, dynamic> account;
  Account({required this.account});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  TextEditingController _amounttController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  
  bool _isPositive = true;

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