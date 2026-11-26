import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

Icon visibilityOnIcon = Icon(Icons.visibility);
Icon visibilityOffIcon = Icon(Icons.visibility_off);

Text loginHeading = Text(
  "Log In",
  style: TextStyle(fontSize: 17.0, color: Colors.white),
);

const InputDecoration usernameDecoration = InputDecoration(
  labelText: 'Username',
  prefixIcon: Icon(Icons.person),
);
SizedBox sizedBox(double height) {
  return SizedBox(height: height);
}

Widget containsBranding(BuildContext context, double _width, double _height) {
  return Container(
    width: _width * 0.75,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Icon(
            Icons.feedback,
            size: _width * 0.15,
            color: Colors.blueAccent[200],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Channel i',
            style: TextStyle(
              color: Colors.blueAccent[200],
              fontSize: _width * 0.1,
            ),
          ),
        ),
      ],
    ),
  );
}

Container buildContactImgContainer(double _width) {
  return Container(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("Having trouble signing in?", style: TextStyle(fontSize: 12.0)),
        SizedBox(width: 5),
        Text(
          "Contact IMG",
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: 12.0,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget startupCredit(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Updated by',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.4, color: context.mutedText),
        ),
        const SizedBox(height: 2),
        Text(
          'HUKA_Taro',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: context.isDark
                ? context.colors.primary
                : const Color(0xFF5287D9),
          ),
        ),
      ],
    ),
  );
}
