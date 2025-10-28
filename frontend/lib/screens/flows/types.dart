import 'package:get/get.dart';
import 'flows_controller.dart';

enum Direction {
  down,
  right,
  left,
}

enum FlowType {
  terminal,
  process,
  condition,
}

class Defaults {
  static double lineHeight = 25;
  static double flowWidth = 100;
}

class FlowClass {
  int id;
  int? pid;
  double width;
  double height;
  double x;
  double y;
  String value;
  FlowType type;
  Direction? direction;
  Line down;
  Line right;
  Line left;
  Direction? yes;
  
  FlowClass({
    required this.id,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.value,
    required this.type,
    required this.down,
    required this.left,
    required this.right,
    this.pid,
    this.direction,
    this.yes,
  });
}

class Line {
  double lineHeight = Defaults.lineHeight;
  bool hasChild = false;
  
  Line({this.lineHeight = 0, this.hasChild = false}) {
    if (lineHeight == 0) {
      lineHeight = Defaults.lineHeight;
    }
  }
}

class LoopLink {
  int fromId;
  int toId;
  LoopLink({required this.fromId, required this.toId});
}

// Global controller instance for observable flows management
final FlowsController flowsController = Get.put(FlowsController());
