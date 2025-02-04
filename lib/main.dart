import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_heroes/child/bottom_page.dart';
import 'package:we_heroes/db/shared_preferences.dart';
import 'package:we_heroes/parent/parent_home_screen.dart';
import 'package:we_heroes/utils/constants.dart';


import 'child/child_login_screen.dart';
import 'firebase_options.dart';

final navigatorkey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MySharedPreference.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.firaSansCondensedTextTheme(
            Theme.of(context).textTheme,
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: FutureBuilder(
            future: MySharedPreference.getUserType(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == "") {
                return LoginScreen();
              }
              if (snapshot.data == "child") {
                return BottomPage();
              }
              if (snapshot.data == "parent") {
                return ParentHomeScreen();
              }

              return progressIndicator(context);
            }));
  }
}

//class CheckAuth extends StatelessWidget {
//  // const CheckAuth({Key? key}) : super(key: key);
//
//  checkData() {
//    if (MySharedPreference.getUserType()== 'parent') {
//
//    }
//  }
//
//  @override
//  Widget build(BuildContext context) {
//   return const Placeholder();
//  }
//}
