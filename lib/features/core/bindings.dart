import 'package:get/get.dart';
import 'package:open_street_map/features/home/controller/home_controller.dart';

class AppBindings extends Bindings{
  @override
  void dependencies() {
   Get.lazyPut<HomeController>(()=> HomeController());
  }

}