import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  final String account;
  Account({required this.account});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF282A36),
      appBar: AppBar(
        backgroundColor: Color(0xFF44475A),
        title: Text('Account'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text('Account')
          ],
        ),
      ),
    );
  }
}