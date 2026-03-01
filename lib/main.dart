import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_street_map/features/core/bindings.dart';
import 'package:open_street_map/features/routes/app_pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
