import 'package:flutter/material.dart';

class Investment extends StatefulWidget {
  const Investment({super.key});

  @override
  State<Investment> createState() => _InvestmentState();
}

class _InvestmentState extends State<Investment> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Investment'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text('Investment')
          ],
        ),
      ),
    );
  }
}