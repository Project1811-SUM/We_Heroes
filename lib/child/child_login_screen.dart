import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:we_heroes/child/bottom_page.dart';
import 'package:we_heroes/child/register_child.dart';
import 'package:we_heroes/child/reset_pass.dart';
import 'package:we_heroes/components/SecondaryButton.dart';
import 'package:we_heroes/components/custom_textfield.dart';
import 'package:we_heroes/db/shared_preferences.dart';
import 'package:we_heroes/parent/parent_home_screen.dart';
import 'package:we_heroes/utils/constants.dart';
import '../components/PrimaryButton.dart';
import '../parent/parent_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordShown = true;
  final _formKey = GlobalKey<FormState>();
  final _formData = {'Email': '', 'Password': ''};
  bool isLoading = false;

  // Text controllers for handling user input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    try {
      setState(() {
        isLoading = true;
      });
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (documentSnapshot.exists) {
          var data = documentSnapshot.data() as Map<String, dynamic>?;
          var userType = data?['type'];

          if (userType == 'Parent') {
            MySharedPreference.saveUserType('parent');
            goTo(context, ParentHomeScreen());
          } else if (userType == 'Child') {
            MySharedPreference.saveUserType('child');
            goTo(context, BottomPage());
          } else {
            dialogueBox(context, "User type not recognized.");
          }
        } else {
          dialogueBox(context, "User document not found.");
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });
      if (e.code == 'user-not-found') {
        dialogueBox(context, 'No user found for that email.');
      } else if (e.code == 'wrong-password') {
        dialogueBox(context, 'Incorrect Password.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      dialogueBox(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              isLoading
                  ? progressIndicator(context)
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "USER LOGIN",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Image.asset(
                            'assets/logo.png',
                            height: 100,
                            width: 100,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomTextField(
                              controller: _emailController,
                              hintText: 'Enter Email',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.emailAddress,
                              prefix: Icon(Icons.person),
                              onsave: (email) {
                                _formData['Email'] = email ?? "";
                              },
                              validate: (email) {
                                if (email!.isEmpty ||
                                    email.length < 3 ||
                                    !email.contains("@")) {
                                  return 'Enter Correct Email';
                                }
                                return null;
                              },
                            ),
                            CustomTextField(
                              controller: _passwordController,
                              hintText: 'Enter Password',
                              isPassword: isPasswordShown,
                              prefix: Icon(Icons.vpn_key_rounded),
                              onsave: (password) {
                                _formData['Password'] =
                                    password ?? "";
                              },
                              validate: (password) {
                                if (password!.isEmpty ||
                                    password.length < 7) {
                                  return 'Enter Correct Password';
                                }
                                return null;
                              },
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPasswordShown =
                                    !isPasswordShown;
                                  });
                                },
                                icon: isPasswordShown
                                    ? Icon(Icons.visibility_off)
                                    : Icon(Icons.visibility),
                              ),
                            ),
                            PrimaryButton(
                              title: "LOGIN",
                              onPressed: () {
                                if (_formKey.currentState!
                                    .validate()) {
                                  _onSubmit();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Forgot Password",
                            style: TextStyle(fontSize: 18),
                          ),
                          SecondaryButton(
                            title: 'Click Here',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ResetPasswordPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SecondaryButton(
                      title: 'Register as Child',
                      onPressed: () {
                        goTo(context, RegisterChildScreen());
                      },
                    ),
                    SecondaryButton(
                      title: 'Register as Parent',
                      onPressed: () {
                        goTo(context, RegisterParentScreen());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/////UK changed code