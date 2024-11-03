import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class EnhanceScreen extends StatefulWidget {
  File image;
  EnhanceScreen(this.image);

  @override
  State<EnhanceScreen> createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<EnhanceScreen> {
  late img.Image inputImage;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    inputImage = img.decodeImage(this.widget.image.readAsBytesSync())!;
    enhanceImage();
  }

  enhanceImage() {
    img.Image temp = img.decodeImage(this.widget.image.readAsBytesSync())!;
    inputImage = img.adjustColor(temp, brightness: brightness);
    inputImage = img.contrast(inputImage, contrast: contrast);
    setState(() {
      inputImage;
    });
  }

  double contrast = 150;
  double brightness = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: Text(
          'Enhance',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          InkWell(
            onTap: () async {
              final result =
                  await ImageGallerySaver.saveImage(Uint8List.fromList(img.encodePng(inputImage)));
              print(result);
              SnackBar sn = SnackBar(content: Text('Saved'));
              ScaffoldMessenger.of(context).showSnackBar(sn);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.save_alt_outlined),
            ),
          ),
          InkWell(
            onTap: () async {
              final editedImage = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageFilters(
                    image: Uint8List.fromList(img.encodePng(inputImage)), // <-- Uint8List of image
                  ),
                ),
              );
              inputImage = img.decodeImage(editedImage)!;
              setState(() {
                inputImage;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.filter_b_and_w),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Card(
                margin: EdgeInsets.all(10),
                color: Colors.grey,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 1.5,
                  margin: EdgeInsets.all(15),
                  child: Image.memory(
                      Uint8List.fromList(img.encodeBmp(inputImage))),),
              ),
              Container(
                margin: EdgeInsets.only(left: 20, right: 10),
                child: Row(
                  children: [
                    Icon(Icons.contrast, size: 30, color: Colors.blueAccent,),
                    Expanded(
                      child: Slider(value: contrast, onChanged: (v){
                        contrast = v;
                        enhanceImage();
                        setState(() {
                          contrast;
                        });
                            }, min: 80, max: 200, divisions: 12, label: contrast.toStringAsFixed(2), activeColor: Colors.blueAccent,),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 20, right: 10),
                child: Row(
                  children: [
                    Icon(Icons.brightness_6, size: 30, color: Colors.blueAccent,),
                    Expanded(
                      child: Slider(value: brightness, onChanged: (v){
                        brightness = v;
                        enhanceImage();
                        setState(() {
                          brightness;
                        });
                      }, min: 1, max: 10, divisions: 10, label: brightness.toStringAsFixed(2), activeColor: Colors.blueAccent,),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
