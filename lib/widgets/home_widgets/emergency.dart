import 'package:flutter/cupertino.dart';
import 'package:we_heroes/widgets/home_widgets/emergencies/WomenEmergency.dart';


import 'emergencies/AmbulanceEmergency.dart';
import 'emergencies/FirebrigadeEmergency.dart';
import 'emergencies/policeemergency.dart';

class Emergency extends StatelessWidget {
  const Emergency({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 180,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          PoliceEmergency(),
          AmbulanceEmergency(),
          FirebrigadeEmergency(),
          WomenEmergency(),
        ],
      ),
    );
  }
}
