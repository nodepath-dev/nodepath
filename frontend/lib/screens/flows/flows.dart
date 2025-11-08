import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/widgets/touchable/touchable.dart';
import 'package:flutter/services.dart';

import 'add_flow.dart';
import 'edit_flow.dart';
import 'types.dart';
import 'flows_controller.dart';
import 'widgets.dart' as flow_widgets;
import 'dart:math' as math;
import '../../globals.dart';

class Flows extends StatelessWidget {
  const Flows({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the controller instance
    final FlowsController controller = Get.put(FlowsController());
    
    return Obx(() {
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            if (controller.isSelectingLoop.value || controller.isPickingLoopFrom.value || controller.isPickingLoopTo.value) {
              controller.cancelLoopSelection();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
        children: [
          if (controller.selectedType.value == FlowType.condition)
            Container(
              key: Key(controller.widgetKey.value),
              constraints: BoxConstraints(maxWidth: controller.stageWidth.value - 100),
              // decoration: BoxDecoration(color: Colors.red),
              child: Text(
                controller.valueText.value,
                style: TextStyle(color: Colors.transparent),
              ),
            )
          else
            Column(children: [
              Container(
                key: Key(controller.widgetKey.value),
                width: controller.widthText.value.isEmpty ? 0 : double.parse(controller.widthText.value),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                // decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(40)),
                child: Center(
                    child: Text(
                  controller.valueText.value,
                  style: TextStyle(color: Colors.transparent),
                )),
              ),
            ]),
          FlowCanvas(),
          if (
            controller.window.value == "add" &&
            (
              (controller.selectedFlowId.value.isNotEmpty && controller.flows.isEmpty) ||
              (controller.selectedId.value >= 0)
            )
          )
            Align(alignment: Alignment.topRight, child: AddFlow())
          else if (controller.window.value == "edit")
            Align(alignment: Alignment.topRight, child: EditFlow())
        ],
      ));
    });
  }
  
}

class FlowCanvas extends StatelessWidget {
  const FlowCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final FlowsController controller = Get.find<FlowsController>();
    
    return Obx(() {
      // Use flowCanvasRefreshCounter to force re-rendering when positions change
      controller.flowCanvasRefreshCounter.value;
      
      return InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 2,
        panEnabled: true,
        scaleEnabled: true,
        onInteractionStart: (details) {
          controller.isPanning.value = true;
        },
        onInteractionEnd: (details) {
          controller.isPanning.value = false;
        },
        child: Stack(
          children: [
            // Dimming overlay under lines/nodes? We need it on top to affect visuals; use a separate layer later
            Lines(),
            // Selection overlay dimming only
            Obx(() {
              if (!controller.isSelectingLoop.value || (!controller.isPickingLoopFrom.value && !controller.isPickingLoopTo.value)) {
                return SizedBox.shrink();
              }
              return Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3)));
            }),
            for (var flow in controller.flows)
              if (flow.type == FlowType.terminal)
                Positioned(
                    left: flow.x,
                    top: flow.y,
                    child: InkWell(
                      onTap: () {
                        controller.selectFlow(flow.id, flow.direction!, flow.type);
                      },
                      onHover: (h) {
                        controller.setLoopHover(h ? flow.id : -1);
                      },
                      child: flow_widgets.Terminal(
                        width: flow.width,
                        height: flow.height,
                        label: flow.value,
                        highlight: controller.isSelectingLoop.value && (controller.isPickingLoopFrom.value || controller.isPickingLoopTo.value) && controller.loopHoverId.value == flow.id,
                        mouseCursor: controller.isPanning.value ? SystemMouseCursors.grabbing : SystemMouseCursors.move,
                        onPanStart: (details) {
                          controller.startLineHeightDrag(flow.id, details.globalPosition.dx, details.globalPosition.dy);
                        },
                        onPanUpdate: (details) {
                          controller.updateLineHeightDrag(details.globalPosition.dx, details.globalPosition.dy);
                        },
                        onPanEnd: (details) {
                          controller.endLineHeightDrag();
                        },
                      ),
                    ))
              else if (flow.type == FlowType.process)
                Positioned(
                    left: flow.x,
                    top: flow.y,
                    child: InkWell(
                      onTap: () {
                        controller.selectFlow(flow.id, flow.direction!, flow.type);
                      },
                      onHover: (h) {
                        controller.setLoopHover(h ? flow.id : -1);
                      },
                      child: flow_widgets.Process(
                        width: flow.width,
                        height: flow.height,
                        label: flow.value,
                        highlight: controller.isSelectingLoop.value && (controller.isPickingLoopFrom.value || controller.isPickingLoopTo.value) && controller.loopHoverId.value == flow.id,
                        mouseCursor: controller.isPanning.value ? SystemMouseCursors.grabbing : SystemMouseCursors.move,
                        onPanStart: (details) {
                          controller.startLineHeightDrag(flow.id, details.globalPosition.dx, details.globalPosition.dy);
                        },
                        onPanUpdate: (details) {
                          controller.updateLineHeightDrag(details.globalPosition.dx, details.globalPosition.dy);
                        },
                        onPanEnd: (details) {
                          controller.endLineHeightDrag();
                        },
                      ),
                    ))
              else if (flow.type == FlowType.condition)
                Positioned(
                    left: flow.x,
                    top: flow.y,
                    child: InkWell(
                      onTap: () {
                        controller.selectFlow(flow.id, flow.direction!, flow.type);
                      },
                      onHover: (h) {
                        controller.setLoopHover(h ? flow.id : -1);
                      },
                      child: flow_widgets.Condition(  
                        width: flow.width,
                        height: flow.width,
                        label: flow.value,
                        highlight: controller.isSelectingLoop.value && (controller.isPickingLoopFrom.value || controller.isPickingLoopTo.value) && controller.loopHoverId.value == flow.id,
                        mouseCursor: controller.isPanning.value ? SystemMouseCursors.grabbing : SystemMouseCursors.move,
                        onPanStart: (details) {
                          controller.startLineHeightDrag(flow.id, details.globalPosition.dx, details.globalPosition.dy);
                        },
                        onPanUpdate: (details) {
                          controller.updateLineHeightDrag(details.globalPosition.dx, details.globalPosition.dy);
                        },
                        onPanEnd: (details) {
                          controller.endLineHeightDrag();
                        },
                      ),
                    )),
          ],
        ),
      );
    });
  }
}

class Lines extends StatelessWidget {
  const Lines({super.key});

  @override
  Widget build(BuildContext context) {
    final FlowsController controller = Get.find<FlowsController>();
    
    return Obx(() {
      return SizedBox(
        width: controller.stageWidth.value,
        height: controller.windowHeight.value,
        child: MouseRegion(
          cursor: controller.isPanning.value
              ? SystemMouseCursors.grabbing
              : controller.isDraggingLineHeight.value
                  ? SystemMouseCursors.resizeUpDown
                  : controller.isDraggingLoopPad.value
                      ? (controller.hoveredLoopPadAxis.value == "horizontal"
                          ? SystemMouseCursors.resizeLeftRight
                          : SystemMouseCursors.resizeUpDown)
                      : controller.hoveredLoopPadAxis.value == "horizontal"
                          ? SystemMouseCursors.resizeLeftRight
                          : controller.hoveredLoopPadAxis.value == "vertical"
                              ? SystemMouseCursors.resizeUpDown
                              : controller.isMouseOverDot.value
                                  ? SystemMouseCursors.click
                                  : SystemMouseCursors.basic,
          onHover: (event) {
            // Check if mouse is over any interactive dot
            bool isOverDot = controller.showAddHandles.value && _isMouseOverDot(event.localPosition, controller);
            // This will be handled by the controller to update cursor
            controller.updateMouseOverDot(isOverDot);
            
            // Check for process flow hover
            if (controller.showAddHandles.value) {
              _checkProcessFlowHover(event.localPosition, controller);
            }
            // Detect hover near adjustable loop corridors/lanes
            _updateLoopPadHover(event.localPosition, controller);
          },
          onExit: (event) {
            // Clear hover states when mouse leaves the canvas, but keep process hover if in add mode
            controller.updateMouseOverDot(false);
            if (controller.window.value != "add" || controller.selectedId.value < 0) {
              controller.onProcessUnhover();
            }
            controller.setHoveredLoopPadAxis("");
          },
          child: Listener(
            onPointerDown: (event) {
              if (controller.hoveredLoopPadAxis.value.isNotEmpty) {
                controller.startLoopPadDrag(event.position.dx, event.position.dy);
              }
            },
            onPointerMove: (event) {
              if (controller.isDraggingLoopPad.value) {
                controller.updateLoopPadDrag(event.position.dx, event.position.dy);
              }
            },
            onPointerUp: (event) {
              controller.endLoopPadDrag();
            },
            behavior: HitTestBehavior.translucent,
            child: CanvasTouchDetector(
              gesturesToOverride: const [
                GestureType.onTapDown,
                GestureType.onSecondaryTapDown,
                GestureType.onSecondaryTapUp,
              ],
              builder: (context1) {
                return CustomPaint(
                    // size: Size(controller.stageWidth.value, controller.windowHeight.value),
                    painter: LinePainter2(context1, controller));
              },
            ),
          ),
        ),
      );
    });
  }

  // Detect hover near adjustable loop corridors/lanes and set axis for cursor/drag
  void _updateLoopPadHover(Offset mousePosition, FlowsController controller) {
    if (controller.flows.isEmpty) {
      controller.setHoveredLoopPadAxis("");
      return;
    }
    double minY = controller.flows.map((f) => f.y).reduce((a, b) => a < b ? a : b);
    double maxY = controller.flows.map((f) => f.y + f.height).reduce((a, b) => a > b ? a : b);
    double minX = controller.flows.map((f) => f.x).reduce((a, b) => a < b ? a : b);
    double maxX = controller.flows.map((f) => f.x + f.width).reduce((a, b) => a > b ? a : b);
    final double pad = controller.loopPad.value;
    final double topCorridorY = minY - pad;
    final double bottomCorridorY = maxY + pad;
    final double leftLaneX = minX - pad;
    final double rightLaneX = maxX + pad;
    const double tol = 6.0;

    final bool nearVertical = (mousePosition.dy - topCorridorY).abs() <= tol ||
        (mousePosition.dy - bottomCorridorY).abs() <= tol;
    final bool nearHorizontal = (mousePosition.dx - leftLaneX).abs() <= tol ||
        (mousePosition.dx - rightLaneX).abs() <= tol;

    if (nearVertical) {
      controller.setHoveredLoopPadAxis("vertical");
    } else if (nearHorizontal) {
      controller.setHoveredLoopPadAxis("horizontal");
    } else if (!controller.isDraggingLoopPad.value) {
      controller.setHoveredLoopPadAxis("");
    }
  }

  // Check if mouse position is over any interactive dot
  bool _isMouseOverDot(Offset mousePosition, FlowsController controller) {
    const double dotRadius = 6.0; // 3px dot + 3px padding
    
    for (var flow in controller.flows) {
      // Down direction dot
      if (!(flow.type == FlowType.condition && flow.left.hasChild && flow.right.hasChild)) {
        if (!flow.down.hasChild) {
          Offset dotPosition = Offset(
            flow.x + flow.width / 2,
            flow.y + flow.height + flow.down.lineHeight
          );
          if ((mousePosition - dotPosition).distance <= dotRadius) {
            return true;
          }
        }
      }

      // Condition flow side dots
      if (flow.type == FlowType.condition) {
        // Right side dot
        if (flow.direction != Direction.left && !(flow.down.hasChild && flow.left.hasChild)) {
          if (!flow.right.hasChild) {
            Offset dotPosition = Offset(
              flow.x + flow.width + flow.right.lineHeight,
              flow.y + flow.height / 2
            );
            if ((mousePosition - dotPosition).distance <= dotRadius) {
              return true;
            }
          }
        }

        // Left side dot
        if (flow.direction != Direction.right && !(flow.down.hasChild && flow.right.hasChild)) {
          if (!flow.left.hasChild) {
            Offset dotPosition = Offset(
              flow.x - flow.left.lineHeight,
              flow.y + flow.height / 2
            );
            if ((mousePosition - dotPosition).distance <= dotRadius) {
              return true;
            }
          }
        }
      }
      
      // Process flow side dots (only when hovering)
      if (flow.type == FlowType.process) {
        // Only check for dots when hovering over this specific flow
        bool isHovered = controller.hoveredProcessId.value == flow.id && controller.hoveredSide.value.isNotEmpty;
        
        if (isHovered) {
          // Right side dot
          if (flow.direction != Direction.left && !(flow.down.hasChild && flow.left.hasChild)) {
            if (!flow.right.hasChild && controller.hoveredSide.value == "right") {
              Offset dotPosition = Offset(
                flow.x + flow.width + flow.right.lineHeight,
                flow.y + flow.height / 2
              );
              if ((mousePosition - dotPosition).distance <= dotRadius) {
                return true;
              }
            }
          }

          // Left side dot
          if (flow.direction != Direction.right && !(flow.down.hasChild && flow.right.hasChild)) {
            if (!flow.left.hasChild && controller.hoveredSide.value == "left") {
              Offset dotPosition = Offset(
                flow.x - flow.left.lineHeight,
                flow.y + flow.height / 2
              );
              if ((mousePosition - dotPosition).distance <= dotRadius) {
                return true;
              }
            }
          }
        }
      }
    }
    
    
    return false;
  }
  
  // Check for process flow hover and update controller state
  void _checkProcessFlowHover(Offset mousePosition, FlowsController controller) {
    const double hoverRadius = 15.0; // Hover detection radius
    
    for (var flow in controller.flows) {
      if (flow.type == FlowType.process) {
        // Check left side hover
        if (flow.direction != Direction.right && !(flow.down.hasChild && flow.right.hasChild)) {
          Offset leftCenter = Offset(
            flow.x - flow.left.lineHeight / 2,
            flow.y + flow.height / 2
          );
          if ((mousePosition - leftCenter).distance <= hoverRadius) {
            controller.onProcessHover(flow.id, "left");
            return;
          }
        }
        
        // Check right side hover
        if (flow.direction != Direction.left && !(flow.down.hasChild && flow.left.hasChild)) {
          Offset rightCenter = Offset(
            flow.x + flow.width + flow.right.lineHeight / 2,
            flow.y + flow.height / 2
          );
          if ((mousePosition - rightCenter).distance <= hoverRadius) {
            controller.onProcessHover(flow.id, "right");
            return;
          }
        }
      }
    }
    
    // No hover detected, clear hover state only if not in add mode
    if (controller.window.value != "add" || controller.selectedId.value < 0) {
      controller.onProcessUnhover();
    }
  }
}

class LinePainter2 extends CustomPainter {
  final BuildContext context;
  final FlowsController controller;
  
  LinePainter2(this.context, this.controller); // context from CanvasTouchDetector

  @override
  void paint(Canvas canvas, Size size) {
    var myCanvas = TouchyCanvas(context, canvas);
    var paint = Paint()
      ..color = Pallet.font2
      ..strokeWidth = 1;
    
    // Highlight paint for dragging line height
    var highlightPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3;

    final textStyle = TextStyle(
      color: Pallet.font2,
      fontSize: 11,
    );
    final yesp = TextPainter(
      text: TextSpan(
        text: 'yes',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    yesp.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    final nop = TextPainter(
      text: TextSpan(
        text: 'no',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    final loopp = TextPainter(
      text: TextSpan(
        text: 'loop',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    loopp.layout(minWidth: 0, maxWidth: size.width);
    nop.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    Offset start = Offset(0, 0);
    Offset end = Offset(0, 0);
    final paintText = (text, off, r) {
      if (r == true) {
        canvas.save();
        canvas.translate(off.dx, off.dy);
        canvas.rotate(90 * math.pi / 180);
        canvas.translate(-off.dx, -off.dy);
        if (text == 'yes') {
          yesp.paint(canvas, off);
        } else {
          nop.paint(canvas, off);
        }
        canvas.restore();
      } else {
        if (text == 'yes') {
          yesp.paint(canvas, off);
        } else {
          nop.paint(canvas, off);
        }
      }
    };
    controller.updateFlows();

    // Draw a small triangular arrowhead pointing from `from` to `to`.
    void drawArrowhead(Offset from, Offset to, Color color) {
      const double arrowLength = 8.0;
      const double arrowWidth = 6.0;
      final double angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
      // Pull the tip slightly back to avoid overlapping destination border
      final Offset tip = Offset(
        to.dx - 2 * math.cos(angle),
        to.dy - 2 * math.sin(angle),
      );
      final Offset base = Offset(
        tip.dx - arrowLength * math.cos(angle),
        tip.dy - arrowLength * math.sin(angle),
      );
      final Offset ortho = Offset(
        (arrowWidth / 2) * -math.sin(angle),
        (arrowWidth / 2) *  math.cos(angle),
      );
      final Offset p1 = base + ortho;
      final Offset p2 = base - ortho;
      final Path path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      final Paint arrowPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, arrowPaint);
    }

    for (var flow in controller.flows) {
      if (!(flow.type == FlowType.condition && flow.left.hasChild && flow.right.hasChild)) {
        // For condition flows, use width for both dimensions since diamond is square
        final flowHeight = (flow.type == FlowType.condition) ? flow.width : flow.height;
        
        start = Offset(flow.x + flow.width / 2, flow.y + flowHeight);
        end = Offset(flow.x + flow.width / 2, flow.y + flowHeight + flow.down.lineHeight);
        
        // Check if this line is being dragged
        bool isHighlighted = controller.isDraggingLineHeight.value && 
                            controller.draggedFlowId.value >= 0 &&
                            controller.flows[controller.draggedFlowId.value].pid == flow.id &&
                            controller.flows[controller.draggedFlowId.value].direction == Direction.down;
        
        if (flow.down.hasChild || controller.showAddHandles.value) {
          canvas.drawLine(start, end, isHighlighted ? highlightPaint : paint);
        }
        if (controller.showAddHandles.value && !flow.down.hasChild) {
          myCanvas.drawCircle(end, 3, paint, onTapDown: (tapdetail) {
            print("Down dot tapped for flow ${flow.id}");
            controller.window.value = "add";
            controller.selectedId.value = flow.id;
            controller.selectedDirection.value = Direction.down;
            controller.refresh();
          });
        }
      }

      if (flow.type == FlowType.condition) {
        // For condition flows, use width for both dimensions since diamond is square
        final conditionSize = flow.width;
        final conditionCenterY = flow.y + conditionSize / 2;
        
        // right
        // Hide add handles if this node participates in any loop (as from or to)
        bool hasLoopWithThis = controller.loopLinks.any((l) => l.toId == flow.id || l.fromId == flow.id);

        if (!hasLoopWithThis && flow.direction != Direction.left && !(flow.down.hasChild && flow.left.hasChild)) {
          start = Offset(flow.x + conditionSize, conditionCenterY);
          end = Offset(flow.x + conditionSize + flow.right.lineHeight, conditionCenterY);
          
          // Check if this line is being dragged
          bool isHighlighted = controller.isDraggingLineHeight.value && 
                              controller.draggedFlowId.value >= 0 &&
                              controller.flows[controller.draggedFlowId.value].pid == flow.id &&
                              controller.flows[controller.draggedFlowId.value].direction == Direction.right;
          
          // Draw side line only if permanent (has child) or when showing add handles
          if (flow.right.hasChild || controller.showAddHandles.value) {
            canvas.drawLine(start, end, isHighlighted ? highlightPaint : paint);
          }
          if (controller.showAddHandles.value && !flow.right.hasChild) {
            myCanvas.drawCircle(end, 3, paint, onTapDown: (tapdetail) {
              print("Right dot tapped for flow ${flow.id}");
              controller.window.value = "add";
              controller.selectedId.value = flow.id;
              controller.selectedDirection.value = Direction.right;
              controller.refresh();
            });
          }
          
        }

        // left
        if (!hasLoopWithThis && flow.direction != Direction.right && !(flow.down.hasChild && flow.right.hasChild)) {
          start = Offset(flow.x, conditionCenterY);
          end = Offset(flow.x - flow.left.lineHeight, conditionCenterY);
          
          // Check if this line is being dragged
          bool isHighlighted = controller.isDraggingLineHeight.value && 
                              controller.draggedFlowId.value >= 0 &&
                              controller.flows[controller.draggedFlowId.value].pid == flow.id &&
                              controller.flows[controller.draggedFlowId.value].direction == Direction.left;
          
          // Draw side line only if permanent (has child) or when showing add handles
          if (flow.left.hasChild || controller.showAddHandles.value) {
            canvas.drawLine(start, end, isHighlighted ? highlightPaint : paint);
          }
          if (controller.showAddHandles.value && !flow.left.hasChild) {
            myCanvas.drawCircle(end, 3, paint, onTapDown: (tapdetail) {
              print("Left dot tapped for flow ${flow.id}");
              controller.window.value = "add";
              controller.selectedId.value = flow.id;
              controller.selectedDirection.value = Direction.left;
              controller.refresh();
            });
          }
          
        }
        Offset down = Offset((flow.x + conditionSize / 2) + 20, (flow.y + conditionSize + flow.down.lineHeight / 2) - 10);
        Offset left = Offset((flow.x - flow.left.lineHeight / 2) - 2, conditionCenterY - 20);
        Offset right = Offset((flow.x + conditionSize + flow.right.lineHeight / 2) - 10, conditionCenterY - 20);
        // yes
        if (flow.yes == Direction.down) {
          paintText('yes', down, true);
          // right
          if (flow.right.hasChild) {
            start = Offset((flow.x + conditionSize + flow.right.lineHeight / 2) - 10, conditionCenterY - 20);
            paintText('no', right, false);
          }
          // left
          if (flow.left.hasChild) {
            paintText('no', left, false);
          }
        } else if (flow.yes == Direction.right) {
          paintText('yes', right, false);
          // down
          if (flow.down.hasChild) {
            paintText('no', down, true);
          }
          // left
          if (flow.left.hasChild) {
            paintText('no', left, false);
          }
        } else if (flow.yes == Direction.left) {
          paintText('yes', left, false);
          // down
          if (flow.down.hasChild) {
            paintText('no', down, true);
          }
          // right
          if (flow.right.hasChild) {
            paintText('no', right, false);
          }
        }
      }
      
      // Process flow side dots (clickable) - only shown on hover
      if (flow.type == FlowType.process) {
        // Only draw dots when hovering over this specific flow
        bool isHovered = controller.showAddHandles.value && controller.hoveredProcessId.value == flow.id && controller.hoveredSide.value.isNotEmpty;
        
        if (isHovered) {
          // Right side dot
          if (flow.direction != Direction.left && !(flow.down.hasChild && flow.left.hasChild)) {
            if (controller.showAddHandles.value && !flow.right.hasChild && controller.hoveredSide.value == "right") {
              end = Offset(flow.x + flow.width + flow.right.lineHeight, flow.y + flow.height / 2);
              myCanvas.drawCircle(end, 3, paint, onTapDown: (tapdetail) {
                print("Process right dot tapped for flow ${flow.id}");
                controller.window.value = "add";
                controller.selectedId.value = flow.id;
                controller.selectedDirection.value = Direction.right;
                controller.refresh();
              });
            }
          }
          
          // Left side dot
          if (flow.direction != Direction.right && !(flow.down.hasChild && flow.right.hasChild)) {
            if (controller.showAddHandles.value && !flow.left.hasChild && controller.hoveredSide.value == "left") {
              end = Offset(flow.x - flow.left.lineHeight, flow.y + flow.height / 2);
              myCanvas.drawCircle(end, 3, paint, onTapDown: (tapdetail) {
                print("Process left dot tapped for flow ${flow.id}");
                controller.window.value = "add";
                controller.selectedId.value = flow.id;
                controller.selectedDirection.value = Direction.left;
                controller.refresh();
              });
            }
          }
        }
      }
      
      // Draw permanent lines for process flows with side children
      if (flow.type == FlowType.process) {
        // Right side line (if has right child)
        if (flow.right.hasChild) {
          start = Offset(flow.x + flow.width, flow.y + flow.height / 2);
          end = Offset(flow.x + flow.width + flow.right.lineHeight, flow.y + flow.height / 2);
          
          // Check if this line is being dragged
          bool isHighlighted = controller.isDraggingLineHeight.value && 
                              controller.draggedFlowId.value >= 0 &&
                              controller.flows[controller.draggedFlowId.value].pid == flow.id &&
                              controller.flows[controller.draggedFlowId.value].direction == Direction.right;
          
          canvas.drawLine(start, end, isHighlighted ? highlightPaint : paint);
        }
        
        // Left side line (if has left child)
        if (flow.left.hasChild) {
          start = Offset(flow.x, flow.y + flow.height / 2);
          end = Offset(flow.x - flow.left.lineHeight, flow.y + flow.height / 2);
          
          // Check if this line is being dragged
          bool isHighlighted = controller.isDraggingLineHeight.value && 
                              controller.draggedFlowId.value >= 0 &&
                              controller.flows[controller.draggedFlowId.value].pid == flow.id &&
                              controller.flows[controller.draggedFlowId.value].direction == Direction.left;
          
          canvas.drawLine(start, end, isHighlighted ? highlightPaint : paint);
        }
      }
    }
    
    // Draw hover lines for process flows (only when no children are attached) - using regular canvas, not TouchyCanvas
    if (controller.showAddHandles.value && controller.hoveredProcessId.value >= 0 && controller.hoveredProcessId.value < controller.flows.length) {
      final hoveredFlow = controller.flows[controller.hoveredProcessId.value];
      if (hoveredFlow.type == FlowType.process && controller.hoveredSide.value.isNotEmpty) {
        // Draw visible hover lines only if no children are attached to that side
        final hoverPaint = Paint()
          ..color = Pallet.font2.withOpacity(0.7) // More visible
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        
        // Draw only the hovered side (lines connect to the clickable dots) if no children attached
        if (controller.hoveredSide.value == "left" && !hoveredFlow.left.hasChild) {
          // Draw left line
          start = Offset(hoveredFlow.x, hoveredFlow.y + hoveredFlow.height / 2);
          end = Offset(hoveredFlow.x - hoveredFlow.left.lineHeight, hoveredFlow.y + hoveredFlow.height / 2);
          canvas.drawLine(start, end, hoverPaint);
        } else if (controller.hoveredSide.value == "right" && !hoveredFlow.right.hasChild) {
          // Draw right line
          start = Offset(hoveredFlow.x + hoveredFlow.width, hoveredFlow.y + hoveredFlow.height / 2);
          end = Offset(hoveredFlow.x + hoveredFlow.width + hoveredFlow.right.lineHeight, hoveredFlow.y + hoveredFlow.height / 2);
          canvas.drawLine(start, end, hoverPaint);
        }
      }
    }
    
    // Draw loop links routed via a top/bottom corridor outside all nodes to avoid crossing
    if (controller.flows.isNotEmpty) {
      double minY = controller.flows.map((f) => f.y).reduce((a, b) => a < b ? a : b);
      double maxY = controller.flows.map((f) => f.y + f.height).reduce((a, b) => a > b ? a : b);
      double minX = controller.flows.map((f) => f.x).reduce((a, b) => a < b ? a : b);
      double maxX = controller.flows.map((f) => f.x + f.width).reduce((a, b) => a > b ? a : b);
      double pad = controller.loopPad.value;
      double topCorridorY = minY - pad; // outside above
      double bottomCorridorY = maxY + pad; // outside below
      double leftLaneX = minX - pad; // outside left
      double rightLaneX = maxX + pad; // outside right
      
      Offset edgePointVertical(FlowClass f, double targetY) {
        final cx = f.x + f.width / 2;
        // For condition flows, use width for both dimensions since diamond is square
        final fHeight = (f.type == FlowType.condition) ? f.width : f.height;
        if (targetY < f.y + fHeight / 2) {
          return Offset(cx, f.y); // from top edge
        } else {
          return Offset(cx, f.y + fHeight); // from bottom edge
        }
      }
      
      Offset edgePointHorizontal(FlowClass f, double targetX) {
        // For condition flows, use width for both dimensions since diamond is square
        final fHeight = (f.type == FlowType.condition) ? f.width : f.height;
        final cy = f.y + fHeight / 2;
        if (targetX < f.x + f.width / 2) {
          return Offset(f.x, cy); // from left edge
        } else {
          return Offset(f.x + f.width, cy); // from right edge
        }
      }
      
      bool verticalBlocked(double x, double y1, double y2, int ignoreId) {
        final top = y1 < y2 ? y1 : y2;
        final bottom = y1 < y2 ? y2 : y1;
        for (var f in controller.flows) {
          if (f.id == ignoreId) continue;
          final fx1 = f.x;
          final fx2 = f.x + f.width;
          final fy1 = f.y;
          final fy2 = f.y + f.height;
          if (x >= fx1 && x <= fx2) {
            if (!(bottom < fy1 || top > fy2)) {
              return true;
            }
          }
        }
        return false;
      }
      
      // horizontalBlocked removed (unused)
      for (var link in controller.loopLinks) {
        final from = controller.flows.firstWhereOrNull((f) => f.id == link.fromId);
        final to = controller.flows.firstWhereOrNull((f) => f.id == link.toId);
        if (from == null || to == null) continue;
        final fromCenter = Offset(from.x + from.width / 2, from.y + from.height / 2);
        final toCenter = Offset(to.x + to.width / 2, to.y + to.height / 2);
        final bool goesLeft = toCenter.dx < fromCenter.dx;
        
        // Try top corridor first if verticals are clear
        bool useTop = !verticalBlocked(fromCenter.dx, fromCenter.dy, topCorridorY, from.id) &&
                      !verticalBlocked(toCenter.dx, toCenter.dy, topCorridorY, to.id);
        bool useBottom = !verticalBlocked(fromCenter.dx, fromCenter.dy, bottomCorridorY, from.id) &&
                         !verticalBlocked(toCenter.dx, toCenter.dy, bottomCorridorY, to.id);
        if (useTop || useBottom) {
          double corridorY = useTop ? topCorridorY : bottomCorridorY;
          final p1 = edgePointVertical(from, corridorY);
          final p2 = Offset(fromCenter.dx, corridorY);
          final p3 = Offset(toCenter.dx, corridorY);
          final p4 = edgePointVertical(to, corridorY);
          canvas.drawLine(p1, p2, paint);
          canvas.drawLine(p2, p3, paint);
          canvas.drawLine(p3, p4, paint);
          drawArrowhead(p3, p4, paint.color);
          final midH = Offset((p2.dx + p3.dx) / 2, corridorY);
          final double labelHX = goesLeft ? (midH.dx - 30) : (midH.dx + 4);
          loopp.paint(canvas, Offset(labelHX, midH.dy - 12));
          continue;
        }
        
        // Fallback: route via side lane (left or right) choosing the side with fewer flows
        final midX = (fromCenter.dx + toCenter.dx) / 2;
        int leftCount = 0;
        int rightCount = 0;
        for (var f in controller.flows) {
          final cx = f.x + f.width / 2;
          if (cx < midX) {
            leftCount++;
          } else {
            rightCount++;
          }
        }
        // Prefer the side with fewer nodes, but also ensure it's inside the canvas
        bool preferRight = rightCount < leftCount;
        double laneX = preferRight && rightLaneX + 10 < controller.stageWidth.value
            ? rightLaneX
            : leftLaneX;
        final p1 = edgePointHorizontal(from, laneX);
        final p2 = Offset(laneX, fromCenter.dy);
        final p3 = Offset(laneX, toCenter.dy);
        final p4 = edgePointHorizontal(to, laneX);
        canvas.drawLine(p1, p2, paint);
        canvas.drawLine(p2, p3, paint);
        canvas.drawLine(p3, p4, paint);
        drawArrowhead(p3, p4, paint.color);
        final midV = Offset(laneX, (p2.dy + p3.dy) / 2);
        final double labelVX = goesLeft ? (laneX - 30) : (laneX + 4);
        loopp.paint(canvas, Offset(labelVX, midV.dy - 6));
      }
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is LinePainter2) {
      return oldDelegate.controller.hoveredProcessId.value != controller.hoveredProcessId.value ||
             oldDelegate.controller.hoveredSide.value != controller.hoveredSide.value ||
             oldDelegate.controller.isDraggingLineHeight.value != controller.isDraggingLineHeight.value ||
             oldDelegate.controller.draggedFlowId.value != controller.draggedFlowId.value ||
             oldDelegate.controller.loopLinks.length != controller.loopLinks.length ||
             oldDelegate.controller.loopPad.value != controller.loopPad.value ||
             oldDelegate.controller.flowCanvasRefreshCounter.value != controller.flowCanvasRefreshCounter.value;
    }
    return true;
  }
}

bool hasChildren(int id) {
  final FlowsController controller = Get.find<FlowsController>();
  for (var flow in controller.flows) {
    if (flow.pid == id) {
      return true;
    }
  }
  return false;
}
