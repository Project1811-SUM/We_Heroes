import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:we_heroes/child/bottom_screens/contacts_page.dart';
import 'package:we_heroes/components/PrimaryButton.dart';
import 'package:we_heroes/db/db_services.dart';
import 'package:we_heroes/model/contactsm.dart';

class AddContactsPage extends StatefulWidget {
  const AddContactsPage({super.key});

  @override
  State<AddContactsPage> createState() => _AddContactsPageState();
}

class _AddContactsPageState extends State<AddContactsPage> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<TContact>? contactList;
  int count = 0;

  void showList() {
    Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<TContact>> contactListFuture = databaseHelper.getContactList();
      contactListFuture.then((value) {
        setState(() {
          this.contactList = value;
          this.count = value.length;
        });
      });
    });
  }

  void deleteContact(TContact contact) async {
    int result = await databaseHelper.deleteContact(contact.id);
    if (result != 0) {
      Fluttertoast.showToast(msg: "Contact Removed Successfully");
      showList();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      showList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (contactList == null) {
      contactList = [];
    }
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            PrimaryButton(
                title: "Add Trusted Contacts",
                onPressed: () async {
                  bool result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactsPage(),
                      ));
                  if (result == true) {
                    showList();
                  }
                }),
            Expanded(
              child: ListView.builder(
                itemCount: count,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: ListTile(
                        title: Text(contactList![index].name),
                        subtitle: Text(contactList![index].number),
                        trailing: Container(
                          width: 140,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await FlutterPhoneDirectCaller.callNumber(
                                      contactList![index].number);
                                },
                                icon: Icon(
                                  Icons.call,
                                  color: Colors.green,
                                ),
                              ),
                              // Delete button added here
                              IconButton(
                                onPressed: () {
                                  // Call deleteContact method to remove the contact
                                  deleteContact(contactList![index]);
                                },
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
