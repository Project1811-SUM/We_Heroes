import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:we_heroes/utils/constants.dart';
import '../child/child_login_screen.dart';
import '../components/PrimaryButton.dart';
import '../components/SecondaryButton.dart';
import '../components/custom_textfield.dart';
import '../model/user_model.dart';

class RegisterParentScreen extends StatefulWidget {
  @override
  State<RegisterParentScreen> createState() => _RegisterParentScreenState();
}

class _RegisterParentScreenState extends State<RegisterParentScreen> {
  bool isPasswordShown = true;
  bool isRetypePasswordShown = true;

  final _formKey = GlobalKey<FormState>();
  final _formData = <String, Object>{};
  bool isLoading = false;

  Future<void> _onSubmit() async {
    _formKey.currentState!.save();

    if (_formData['Password'] != _formData['RPassword']) {
      dialogueBox(context, 'Password & Retype Password must be Same!');
      return;
    }

    progressIndicator(context);
    try {
      setState(() {
        isLoading = true;
      });
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _formData['GEmail'].toString(),
        password: _formData['Password'].toString(),
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        DocumentReference<Map<String, dynamic>> db =
            FirebaseFirestore.instance.collection("users").doc(uid);

        final user = UserModel(
          name: _formData['Name'].toString(),
          phone: _formData['Phone'].toString(),
          childEmail: _formData['CEmail'].toString(),
          parentEmail: _formData['GEmail'].toString(), // Ensure correct mapping
          id: uid,
          type: 'Parent',
        );

        final jsonData = user.toJson();

        await db.set(jsonData).whenComplete(() {
          goTo(context, LoginScreen());
          setState(() {
            isLoading = false;
          });
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });
      if (e.code == 'weak-password') {
        dialogueBox(context, 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        dialogueBox(context, 'The account already exists for that email.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      dialogueBox(context, e.toString());
    }

    print(_formData['GEmail']);
    print(_formData['Password']);
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
                                  "REGISTER AS PARENT",
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
                                    hintText: 'Enter Guardian Email',
                                    textInputAction: TextInputAction.next,
                                    keyboardtype: TextInputType.emailAddress,
                                    prefix: Icon(Icons.person),
                                    onsave: (gemail) {
                                      _formData['GEmail'] = gemail ?? "";
                                    },
                                    validate: (gemail) {
                                      if (gemail!.isEmpty ||
                                          gemail.length < 3 ||
                                          !gemail.contains("@")) {
                                        return 'Enter Correct Guardian Email';
                                      }
                                      return null;
                                    },
                                  ),
                                  CustomTextField(
                                    hintText: 'Enter Child Email',
                                    textInputAction: TextInputAction.next,
                                    keyboardtype: TextInputType.emailAddress,
                                    prefix: Icon(Icons.person),
                                    onsave: (cemail) {
                                      _formData['CEmail'] = cemail ?? "";
                                    },
                                    validate: (cemail) {
                                      if (cemail!.isEmpty ||
                                          cemail.length < 3 ||
                                          !cemail.contains("@")) {
                                        return 'Enter Correct Child Email';
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
                                    isPassword: isRetypePasswordShown,
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
                                          isRetypePasswordShown =
                                              !isRetypePasswordShown;
                                        });
                                      },
                                      icon: isRetypePasswordShown
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
