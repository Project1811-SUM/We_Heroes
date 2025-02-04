import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import 'package:we_heroes/utils/quotes.dart';
import 'package:we_heroes/widgets/home_widgets/safewebview.dart';

class CustomCarousel extends StatelessWidget {
  const CustomCarousel({Key? key}) : super(key: key);

  void navigateToRoute(BuildContext context, Widget route) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => route));
  }

  @override
  Widget build(BuildContext context) {
    // List of YouTube URLs
    List<String> videoUrls = [
      "https://www.youtube.com/embed/qviM_GnJbOM?si=gJzeX11hwzlOM4i7",
      "https://www.youtube.com/embed/2GS_gsd98r4?si=Npz62YfwIy6vZBYg",
      "https://www.youtube.com/embed/MOqIotJrFVM?si=uuAxzR70cfzzl9A1",
      "https://www.youtube.com/embed/Tdp3AK9K13o?si=nsdR7-EtHWFgKeRF",
      "https://www.youtube.com/embed/uWi5iXnguTU?si=Kyq3NZokPV04xT0D",
      "https://www.youtube.com/embed/Q0Dg226G2Z8?si=-PkTKcRUp82YSamb",
    ];

    return Container(
      child: CarouselSlider(
        options: CarouselOptions(
          aspectRatio: 2.0,
          autoPlay: true,
          enlargeCenterPage: true,
        ),
        items: List.generate(
          imageSliders.length,
              (index) => Card(
            elevation: 5.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: () {
                navigateToRoute(
                  context,
                  SafeWebView(url: videoUrls[index]), // Use list for URLs
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(imageSliders[index]),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 8),
                      child: Text(
                        articleTitle[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
