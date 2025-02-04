import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:we_heroes/db/db_services.dart';
import 'package:we_heroes/model/contactsm.dart';
import 'package:we_heroes/utils/constants.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  TextEditingController searchController = TextEditingController();
  DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    askPermissions();
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  void filterContact() {
    List<Contact> _contacts = [];
    _contacts.addAll(contacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((element) {
        String searchTerm = searchController.text.toLowerCase();
        bool nameMatch = (element.displayName?.toLowerCase().contains(searchTerm) ?? false);
        if (nameMatch) {
          return true;
        }
        var phoneMatch = element.phones?.any((p) {
          String phnFlattered = flattenPhoneNumber(p.number);
          return phnFlattered.contains(searchTerm);
        }) ?? false;
        return phoneMatch;
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  Future<void> askPermissions() async {
    var permissionStatus = await getContactsPermission();
    if (permissionStatus == PermissionStatus.granted) {
      getAllContacts();
      searchController.addListener(filterContact);
    } else {
      handInvalidPermissions(permissionStatus);
    }
  }

  void handInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      dialogueBox(context, "Access to the contacts denied by user");
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      dialogueBox(context, "Contacts access was permanently denied. Please enable it in settings.");
    }
  }

  Future<PermissionStatus> getContactsPermission() async {
    var status = await Permission.contacts.request();
    return status;
  }

  Future<void> getAllContacts() async {
    // Check if the contacts permission is granted
    if (await Permission.contacts.isGranted) {
      // Fetch all contacts with properties
      List<Contact> fetchedContacts = await FlutterContacts.getContacts(withProperties: true);

      setState(() {
        contacts = fetchedContacts;
        print('Fetched contacts: ${fetchedContacts.length}'); // Log for debugging
      });
    } else {
      handInvalidPermissions(PermissionStatus.denied);
    }
  }

  String getInitials(Contact contact) {
    String initials = '';
    if (contact.name.first.isNotEmpty) {
      initials += contact.name.first[0].toUpperCase(); // First letter of first name
    }
    if (contact.name.last.isNotEmpty) {
      initials += contact.name.last[0].toUpperCase(); // First letter of last name
    }
    return initials.isNotEmpty ? initials : '?'; // Return '?' if no initials are found
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    bool listItemExists = contactsFiltered.isNotEmpty || contacts.isNotEmpty;

    return Scaffold(
      body: contacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search Contact",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            if (listItemExists)
              Expanded(
                child: ListView.builder(
                  itemCount: isSearching
                      ? contactsFiltered.length
                      : contacts.length,
                  itemBuilder: (BuildContext context, int index) {
                    Contact contact = isSearching
                        ? contactsFiltered[index]
                        : contacts[index];
                    return ListTile(
                      title: Text(contact.displayName ?? 'No Name'),
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(getInitials(contact)), // Use the new method here
                      ),
                      onTap: () {
                        if (contact.phones.isNotEmpty) {
                          final String phoneNum = contact.phones.first.number;
                          final String name = contact.displayName ?? 'No Name';
                          _addContact(TContact(phoneNum, name));
                        } else {
                          Fluttertoast.showToast(
                              msg: "Oops! Phone Number Does Not Exist");
                        }
                      },
                    );
                  },
                ),
              )
            else
              Center(
                child: Text("No contacts found"),
              ),
          ],
        ),
      ),
    );
  }

  void _addContact(TContact newContact) async {
    int result = await _databaseHelper.insertContact(newContact);
    if (result != 0) {
      Fluttertoast.showToast(msg: "Contact Added Successfully");
    } else {
      Fluttertoast.showToast(msg: "Failed To Add Contact");
    }
    Navigator.of(context).pop(true);
  }
}
