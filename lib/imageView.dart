import 'package:flutter/material.dart';


class ImageView extends StatefulWidget {
  final List<Image> images;
  ImageView(this.images);
  @override
  State<StatefulWidget> createState() {
    return ImageViewState(images);
  }
}

class ImageViewState extends State<ImageView> {
  final List<Image> images;
  int imageCount = 0;
  ImageViewState(this.images);
  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final height = query.size.height;
    final width = query.size.width;
    return Material(child:Stack(children: <Widget>[Center(child: images[imageCount]),
    Positioned(top: height/2,child: SizedBox(width: width,child:Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
           IconButton(iconSize: 35,
              onPressed: () {
                if (imageCount > 0) {
                  setState(() {
                    imageCount--;
                  });
                }
              },
              icon: Icon(Icons.arrow_back_ios, color: Colors.deepOrangeAccent),
            ) ,IconButton(iconSize: 35,
              onPressed: () {
                if (imageCount < images.length-1) {
                  setState(() {
                    imageCount++;
                  });
                }
              },
              icon: Icon(
                Icons.arrow_forward_ios,
                color: Colors.deepOrangeAccent,
              ),
            ),
            
          ],
        )),)],));
    
  }
}
