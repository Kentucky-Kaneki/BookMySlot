import 'package:flutter/material.dart';

const Color kMainColor = Color(0xFF091755);

const TextStyle kAppBarTextStyle1 = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

const TextStyle kAppBarTextStyle2 = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const TextStyle kHeaderStyle = TextStyle(
  fontWeight: FontWeight.w900,
  fontSize: 20,
);

const BoxDecoration kCustomBoxDecoration = BoxDecoration(
  color: kMainColor,
  borderRadius: BorderRadius.all(Radius.circular(48.0)),
  boxShadow: [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 10,
      spreadRadius: 7,
      offset: Offset(1, 4),
    ),
  ],
);
