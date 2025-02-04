import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:we_heroes/components/PrimaryButton.dart';
import 'package:we_heroes/components/custom_textfield.dart';
import 'package:we_heroes/utils/constants.dart';

class ReviewPage extends StatefulWidget {
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  TextEditingController locationC = TextEditingController();
  TextEditingController viewsC = TextEditingController();
  bool isSaving = false;
  double ratings = 1.0; // Default rating value

  // Show review dialog
  showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          title: Text("Review your place"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                hintText: 'Enter location',
                controller: locationC,
              ),
              SizedBox(height: 10),
              CustomTextField(
                controller: viewsC,
                hintText: 'Enter your review',
                maxLines: 3,
              ),
              SizedBox(height: 15),
              RatingBar.builder(
                initialRating: ratings,
                minRating: 1,
                direction: Axis.horizontal,
                itemCount: 5,
                unratedColor: Colors.grey.shade300,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: kColorDarkRed),
                onRatingUpdate: (rating) {
                  setState(() {
                    ratings = rating;
                  });
                },
              ),
            ],
          ),
          actions: [
            isSaving
                ? Center(child: CircularProgressIndicator())
                : PrimaryButton(
              title: "SAVE",
              onPressed: () async {
                await saveReview();
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // Save review to Firestore
  Future<void> saveReview() async {
    setState(() {
      isSaving = true;
    });

    await FirebaseFirestore.instance.collection('reviews').add({
      'location': locationC.text,
      'views': viewsC.text,
      "ratings": ratings,
    }).then((_) {
      Fluttertoast.showToast(msg: 'Review uploaded successfully');
      locationC.clear();
      viewsC.clear();
    }).catchError((error) {
      Fluttertoast.showToast(msg: 'Error uploading review: $error');
    });

    setState(() {
      isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Recent Reviews",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No reviews yet."));
                  }

                  return ListView.separated(
                    separatorBuilder: (_, __) => Divider(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index];

                      return Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "📍 ${data['location']}",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "💬 ${data['views']}",
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 5),
                                RatingBar.builder(
                                  initialRating:
                                  (data['ratings'] as num?)?.toDouble() ??
                                      1.0, // Ensures no null error
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  itemCount: 5,
                                  ignoreGestures: true,
                                  unratedColor: Colors.grey.shade300,
                                  itemPadding:
                                  EdgeInsets.symmetric(horizontal: 4.0),
                                  itemBuilder: (context, _) =>
                                      Icon(Icons.star, color: kColorDarkRed),
                                  onRatingUpdate: (_) {},
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () => showAlert(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
