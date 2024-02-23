import 'package:flutter/widgets.dart';

class SizeConfig {
  static MediaQueryData? _mediaQueryData;
  static double? screenWidth; // Make screenWidth nullable
  static double? screenHeight; // Make screenHeight nullable
  static TextScaler? textType;
  static double? blockSizeHorizontal; // Make blockSizeHorizontal nullable
  static double? blockSizeVertical; // Make blockSizeVertical nullable

  static double? _safeAreaHorizontal; // Make _safeAreaHorizontal nullable
  static double? _safeAreaVertical; // Make _safeAreaVertical nullable
  static double? safeBlockHorizontal; // Make safeBlockHorizontal nullable
  static double? safeBlockVertical; // Make safeBlockVertical nullable

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    textType = _mediaQueryData!.textScaler;
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    blockSizeHorizontal = screenWidth! / 100;
    blockSizeVertical = screenHeight! / 100;

    _safeAreaHorizontal = _mediaQueryData!.padding.left +
        _mediaQueryData!.padding.right;
    _safeAreaVertical = _mediaQueryData!.padding.top +
        _mediaQueryData!.padding.bottom;
    safeBlockHorizontal = (screenWidth! -
        _safeAreaHorizontal!) / 100;
    safeBlockVertical = (screenHeight! -
        _safeAreaVertical!) / 100;
  }
}
