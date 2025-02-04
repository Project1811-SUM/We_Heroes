import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:we_heroes/child/bottom_page.dart';
import 'package:we_heroes/child/child_login_screen.dart';
import 'package:we_heroes/components/PrimaryButton.dart';
import 'package:we_heroes/components/custom_textfield.dart';
import 'package:we_heroes/utils/constants.dart';

class CheckUserStatusBeforeChatOnProfile extends StatelessWidget {
  const CheckUserStatusBeforeChatOnProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          if (snapshot.hasData) {
            return ProfilePage();
          } else {
            Fluttertoast.showToast(msg: 'Please log in first');
            return LoginScreen();
          }
        }
      },
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameC = TextEditingController();
  TextEditingController guardianEmailC = TextEditingController();
  TextEditingController childEmailC = TextEditingController();
  TextEditingController phoneC = TextEditingController();

  final key = GlobalKey<FormState>();
  String? id;
  String? profilePic;
  String? downloadUrl;
  bool isSaving = false;

  // Fetch user data from Firestore
  getData() async {
    await FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        setState(() {
          nameC.text = value.docs.first['name'];
          childEmailC.text = value.docs.first['childEmail'];
          guardianEmailC.text = value.docs.first['guardianEmail'];
          phoneC.text = value.docs.first['phone'];
          id = value.docs.first.id;
          profilePic = value.docs.first['profilePic'];
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: isSaving
          ? Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.pink,
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Center(
              child: Form(
                key: key,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "UPDATE YOUR PROFILE",
                      style: TextStyle(fontSize: 25),
                    ),
                    SizedBox(height: 15),
                    GestureDetector(
                      onTap: () async {
                        final XFile? pickImage = await ImagePicker()
                            .pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 50);
                        if (pickImage != null) {
                          setState(() {
                            profilePic = pickImage.path;
                          });
                        }
                      },
                      child: Container(
                        child: profilePic == null
                            ? CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          radius: 80,
                          child: Center(
                              child: Image.asset(
                                'assets/add_pic.png',
                                height: 80,
                                width: 80,
                              )),
                        )
                            : profilePic!.contains('http')
                            ? CircleAvatar(
                          backgroundColor: Color(0xFFB39DDB),
                          radius: 80,
                          backgroundImage:
                          NetworkImage(profilePic!),
                        )
                            : CircleAvatar(
                            backgroundColor: Color(0xFFB39DDB),
                            radius: 80,
                            backgroundImage:
                            FileImage(File(profilePic!))),
                      ),
                    ),
                    CustomTextField(
                      controller: nameC,
                      hintText: nameC.text,
                      validate: (v) {
                        if (v!.isEmpty) {
                          return 'Please enter your updated name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    CustomTextField(
                      controller: childEmailC,
                      hintText: "Child email",
                      readOnly: true,
                      validate: (v) {
                        if (v!.isEmpty) {
                          return 'Please enter your child email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    CustomTextField(
                      controller: guardianEmailC,
                      hintText: "Parent email",
                      readOnly: false,
                      validate: (v) {
                        if (v!.isEmpty) {
                          return 'Please enter your guardian email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    CustomTextField(
                      controller: phoneC,
                      hintText: "Phone number",
                      readOnly: false,
                      validate: (v) {
                        if (v!.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 25),
                    PrimaryButton(
                      title: "UPDATE",
                      onPressed: () async {
                        if (key.currentState!.validate()) {
                          SystemChannels.textInput
                              .invokeMethod('TextInput.hide');
                          if (profilePic == null) {
                            Fluttertoast.showToast(
                                msg:
                                'Please select a profile picture');
                          } else {
                            update();
                          }
                        }
                      },
                    ),
                    SizedBox(height: 25),
                    // Add logout button here
                    PrimaryButton(
                      title: "LOGOUT",
                      onPressed: () async {
                        await logout(); // Call logout function
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        Fluttertoast.showToast(msg: 'File does not exist at $filePath');
        return null;
      }
      final fileName = Uuid().v4();
      final Reference fbStorage =
      FirebaseStorage.instance.ref('profile').child(fileName);
      final UploadTask uploadTask = fbStorage.putFile(file);

      await uploadTask.whenComplete(() async {
        downloadUrl = await fbStorage.getDownloadURL();
        print('Uploaded image URL: $downloadUrl');
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      Fluttertoast.showToast(msg: e.toString());
      return null;
    }
  }

  update() async {
    setState(() {
      isSaving = true;
    });

    String? uploadedUrl;
    if (profilePic != null && !profilePic!.contains('http')) {
      uploadedUrl = await uploadImage(profilePic!);
    } else {
      uploadedUrl = profilePic;
    }

    if (uploadedUrl != null) {
      Map<String, dynamic> data = {
        'name': nameC.text,
        'guardianEmail': guardianEmailC.text,
        'phone': phoneC.text,
        'profilePic': uploadedUrl,
      };

      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update(data)
          .then((_) {
        setState(() {
          isSaving = false;
          goTo(context, BottomPage());
        });
      }).catchError((error) {
        print("Error updating profile: $error");
        Fluttertoast.showToast(msg: "Failed to update profile.");
        setState(() {
          isSaving = false;
        });
      });
    } else {
      setState(() {
        isSaving = false;
      });
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Fluttertoast.showToast(msg: "Logged out successfully");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print("Error during logout: $e");
      Fluttertoast.showToast(msg: "Failed to log out");
    }
  }
}
