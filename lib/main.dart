import 'package:flutter/material.dart';
import 'package:flutter_gas/network/tcp_server.dart';
import 'package:flutter_gas/pages/home_page.dart';

void main() {
  startServer();
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue
      ),
      home: HomePage(),
    );
  }
}

