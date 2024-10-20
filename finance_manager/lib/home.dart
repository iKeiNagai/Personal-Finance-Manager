import 'package:finance_manager/account.dart';
import 'package:finance_manager/budget.dart';
import 'package:finance_manager/investment.dart';
import 'package:finance_manager/report.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Finance Manager'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Homepage'),
              OutlinedButton(onPressed: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => Account()));
              },
              child: Text('Account'),),
              SizedBox(height: 20),
              OutlinedButton(onPressed: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => report()));
              },
              child: Text('Reports'),),
              SizedBox(height: 20),
              OutlinedButton(onPressed: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => BudgetScreen()));
              },
              child: Text('Budget'),),
              SizedBox(height: 20),
              OutlinedButton(onPressed: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => Investment()));
              },
              child: Text('Investments'),),
              SizedBox(height: 20),
            ],
          ),
        ),
    );
  }
}