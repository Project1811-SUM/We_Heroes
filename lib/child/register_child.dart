import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:we_heroes/model/user_model.dart';
import 'package:we_heroes/utils/constants.dart';

import 'child_login_screen.dart';
import '../components/PrimaryButton.dart';
import '../components/SecondaryButton.dart';
import '../components/custom_textfield.dart';

class RegisterChildScreen extends StatefulWidget {
  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
  bool isPasswordShown = true;
  bool isretypePasswordShown = true;

  final _formKey = GlobalKey<FormState>();
  final _formData = Map<String, Object>();
  bool isLoading = false;

  _onSubmit() async {
    _formKey.currentState!.save();
    if (_formData['Password'] != _formData['RPassword']) {
      dialogueBox(context, 'Password & Retype Password must be Same!');
    } else {
      progressIndicator(context);
      try {
        setState(() {
          isLoading = true;
        });

        // Create user
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _formData['CEmail'].toString(),
          password: _formData['Password'].toString(),
        );

        if (userCredential.user != null) {
          // Get the user ID
          final v = userCredential.user!.uid;

          // Create a reference to the Firestore collection
          DocumentReference<Map<String, dynamic>> db =
          FirebaseFirestore.instance.collection("users").doc(v);

          // Create a UserModel instance
          final user = UserModel(
            name: _formData['Name'].toString(),
            phone: _formData['Phone'].toString(),
            childEmail: _formData['CEmail'].toString(),
            parentEmail: _formData['GEmail'].toString(),
            id: v,
            type: 'Child',
          );

          // Convert UserModel to JSON and save to Firestore
          final jsonData = user.toJson();
          await db.set(jsonData).whenComplete(() {
            setState(() {
              isLoading = false; // Stop loading
            });
            goTo(context, LoginScreen());
          });
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          isLoading = false; // Stop loading
        });
        if (e.code == 'weak-password') {
          dialogueBox(context, 'The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          dialogueBox(context, 'The account already exists for that email.');
        }
      } catch (e) {
        setState(() {
          isLoading = false; // Stop loading
        });
        dialogueBox(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                            "REGISTER AS CHILD",
                            textAlign: TextAlign.center,
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
                      height: MediaQuery.of(context).size.height * 0.75,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomTextField(
                              hintText: 'Enter Name',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.name,
                              prefix: Icon(Icons.person),
                              onsave: (name) {
                                _formData['Name'] = name ?? "";
                              },
                              validate: (name) {
                                if (name!.isEmpty || name.length < 3) {
                                  return 'Enter Correct Name';
                                }
                                return null;
                              },
                            ),
                            CustomTextField(
                              hintText: 'Enter Phone',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.phone,
                              prefix: Icon(Icons.phone),
                              onsave: (phone) {
                                _formData['Phone'] = phone ?? "";
                              },
                              validate: (phone) {
                                if (phone!.isEmpty || phone.length < 10) {
                                  return 'Enter Correct Phone Number';
                                }
                                return null;
                              },
                            ),
                            CustomTextField(
                              hintText: 'Enter Email',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.emailAddress,
                              prefix: Icon(Icons.person),
                              onsave: (email) {
                                _formData['CEmail'] = email ?? "";
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
                              hintText: 'Enter Guardian Email',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.emailAddress,
                              prefix: Icon(Icons.person),
                              onsave: (gemail) {
                                _formData['GEmail'] = gemail ?? "";
                              },
                              validate: (email) {
                                if (email!.isEmpty ||
                                    email.length < 3 ||
                                    !email.contains("@")) {
                                  return 'Enter Correct Guardian Email';
                                }
                                return null;
                              },
                            ),
                            CustomTextField(
                              hintText: 'Enter Password',
                              isPassword: isPasswordShown,
                              prefix: Icon(Icons.vpn_key_rounded),
                              onsave: (password) {
                                _formData['Password'] = password ?? "";
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
                                    isPasswordShown = !isPasswordShown;
                                  });
                                },
                                icon: isPasswordShown
                                    ? Icon(Icons.visibility_off)
                                    : Icon(Icons.visibility),
                              ),
                            ),
                            CustomTextField(
                              hintText: 'Retype Password',
                              isPassword: isretypePasswordShown,
                              prefix: Icon(Icons.vpn_key_rounded),
                              onsave: (password) {
                                _formData['RPassword'] = password ?? "";
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
                                    isretypePasswordShown =
                                    !isretypePasswordShown;
                                  });
                                },
                                icon: isretypePasswordShown
                                    ? Icon(Icons.visibility_off)
                                    : Icon(Icons.visibility),
                              ),
                            ),
                            PrimaryButton(
                              title: "Register",
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _onSubmit();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SecondaryButton(
                      title: 'Login with your account',
                      onPressed: () {
                        goTo(context, LoginScreen());
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
