import 'package:get/get.dart';
import 'package:open_street_map/features/core/bindings.dart';
import 'package:open_street_map/features/home/views/home_screen.dart';
import 'package:open_street_map/features/routes/app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
        name: Routes.HOME,
        page: ()=> HomeScreen(),
      binding: AppBindings()
    )
  ];
}