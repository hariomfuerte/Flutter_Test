import 'package:flutter/material.dart';
import 'package:test_new/src/screens/login.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login App',
      theme: ThemeData(  
        primaryColor: Colors.orange,
        primarySwatch: Colors.blue
      ),
      home: LoginScreen(),
    );
  }
}