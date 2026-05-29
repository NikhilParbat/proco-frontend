import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

/// Shared formatter — denies emoji characters across all text inputs.
final noEmojiFormatter = FilteringTextInputFormatter.deny(
  RegExp(
    r'[\u{1F000}-\u{1FAFF}]|[\u{2600}-\u{2BFF}]|[\u{FE00}-\u{FE0F}]|\u{200D}',
    unicode: true,
  ),
);

List<String> requirements = [
  'Design and Build sophisticated and highly scalable apps using Flutter.',
  'Build custom packages in Flutter using the functionalities and APIs already available in native Android and IOS.',
  'Translate and Build the designs and Wireframes into high quality responsive UI code.',
  'Explore feasible architectures for implementing new features.',
  'Resolve any problems existing in the system and suggest and add new features in the complete system.',
  'Suggest space and time efficient Data Structures.',
];

String desc =
    "Flutter Developer is responsible for running and designing product application features across multiple devices across platforms. Flutter is Google's UI toolkit for building beautiful, natively compiled apps for mobile, web, and desktop from a single codebase. Flutter works with existing code, is used by developers and organizations around the world, and is free and open source.";

List<String> skills = [
  'Node JS',
  'Java SpringBoot',
  'Flutter and Dart',
  'Firebase',
  'AWS',
];

List<String> profile = [];
