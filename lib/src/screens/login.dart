import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_new/src/component/toast.dart';
import 'home.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String _email, _password;
  final auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('loggedIn') ?? false;
    if (loggedIn) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => TaskListScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue,
          title: Text('Login',style: TextStyle(color: Colors.white,),)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5),borderSide: BorderSide(color: Colors.grey.shade400)),

                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  _email = value.trim();
                },
              ),
              SizedBox(height: 10),
              TextFormField(

                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5),borderSide: BorderSide(color: Colors.grey.shade400)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  _password = value.trim();
                },
              ),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      style:ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: Text('Signin',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600,fontSize: 18)),

                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            await auth.signInWithEmailAndPassword(email: _email, password: _password);
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            prefs.setBool('loggedIn', true);
                            ToastUtils.showToast(
                              message: "Login Successfully",
                              backgroundColor: Colors.black,
                            );
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => TaskListScreen()));
                          } catch (e) {
                            ToastUtils.showToast(
                              message: e.toString(),
                              backgroundColor: Colors.black,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  TextButton(
                    child: Text('Signup',style: TextStyle(color: Colors.black),),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignupScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


}
