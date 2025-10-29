import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/globals.dart';

import '../../widgets/button.dart';
import 'types.dart';
import '../../widgets/textbox.dart';
import 'flows_controller.dart';

class EditFlow extends StatefulWidget {
  const EditFlow({super.key});

  @override
  State<EditFlow> createState() => _EditFlowState();
}

class _EditFlowState extends State<EditFlow> {
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _downController = TextEditingController();
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();

  int? _lastSelectedId;
  Timer? _saveDebounce;

  void _recalculateSizeForFlow(FlowClass flow, String text, FlowsController controller) {
    if (controller.selectedType.value != FlowType.condition) {
      final double contentMaxWidth = (flow.width - 40).clamp(0, double.infinity);
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: 13)),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );
      textPainter.layout(minWidth: 0, maxWidth: contentMaxWidth);
      final double computedHeight = textPainter.size.height.ceilToDouble() + 40;
      flow.height = computedHeight < 40.0 ? 40.0 : computedHeight;
    } else {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: 13)),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );
      final double contentMaxWidth = (flow.width - 40).clamp(0, double.infinity);
      textPainter.layout(minWidth: 0, maxWidth: contentMaxWidth);
      final double contentW = textPainter.size.width;
      final double contentH = textPainter.size.height;
      const double padding = 42;
      double requiredSide = max(contentW, contentH) + padding;
      if (requiredSide < Defaults.flowWidth) {
        requiredSide = Defaults.flowWidth;
      }
      if (flow.width < requiredSide) {
        flow.width = requiredSide.ceilToDouble();
        controller.widthText.value = flow.width.toString();
        _widthController.text = flow.width.toString();
      }
      flow.height = flow.width; // keep diamond square
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _valueController.dispose();
    _downController.dispose();
    _leftController.dispose();
    _rightController.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FlowsController controller = Get.find<FlowsController>();

    return Obx(() {
      if (controller.selectedId.value < 0 ||
          controller.selectedId.value >= controller.flows.length) {
        return SizedBox.shrink();
      }

      final selectedFlow = controller.flows[controller.selectedId.value];
      if (_lastSelectedId != controller.selectedId.value) {
        // Update controllers only when selection changes to avoid cursor jumps during typing
        _widthController.text = selectedFlow.width.toString();
        _valueController.text = selectedFlow.value;
        _downController.text = selectedFlow.down.lineHeight.toString();
        _leftController.text = selectedFlow.left.lineHeight.toString();
        _rightController.text = selectedFlow.right.lineHeight.toString();
        _lastSelectedId = controller.selectedId.value;
      }

      return Container(
        margin: EdgeInsets.only(top: 10, right: 10),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        width: 200,
        decoration: BoxDecoration(
          color: Pallet.inside2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Obx(() {
          final bool showLoopControls = controller.isSelectingLoop.value || controller.loopFrom.value >= 0 || controller.loopTo.value >= 0;
          if (showLoopControls) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("loop", style: TextStyle(fontSize: 12)),
                SizedBox(height: 8),
                Row(
                  children: [
                    SmallButton(
                      label: controller.isPickingLoopFrom.value ? "pick from (active)" : (controller.loopFrom.value >= 0 ? "change from" : "pick from"),
                      onPress: () {
                        controller.isPickingLoopFrom.value = true;
                        controller.isPickingLoopTo.value = false;
                      },
                    ),
                  ],
                ),
                if (controller.loopFrom.value >= 0)
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: _FlowPreview(flow: controller.flows[controller.loopFrom.value]),
                  ),
                SizedBox(height: 6),
                Row(
                  children: [
                    SmallButton(
                      label: controller.isPickingLoopTo.value ? "pick to (active)" : (controller.loopTo.value >= 0 ? "change to" : "pick to"),
                      onPress: () {
                        controller.isPickingLoopTo.value = true;
                        controller.isPickingLoopFrom.value = false;
                      },
                    ),
                  ],
                ),
                if (controller.loopTo.value >= 0)
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: _FlowPreview(flow: controller.flows[controller.loopTo.value]),
                  ),
                SizedBox(height: 6),
                // Styled flip action (like delete) with icon
                InkWell(
                  onTap: () {
                    controller.flipPendingLoop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Pallet.inside1,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("flip", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                        Icon(Icons.swap_horiz, size: 18),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Existing styled delete row, visible in loop mode as well
                InkWell(
                  onTap: () {
                    if ((controller.isSelectingLoop.value || (controller.loopFrom.value >= 0 && controller.loopTo.value >= 0))
                        && controller.loopFrom.value >= 0 && controller.loopTo.value >= 0) {
                      controller.deleteLoop(controller.loopFrom.value, controller.loopTo.value);
                      controller.loopFrom.value = -1;
                      controller.loopTo.value = -1;
                      controller.isPickingLoopFrom.value = false;
                      controller.isPickingLoopTo.value = false;
                      controller.window.value = "none";
                      controller.refresh();
                    } else {
                      controller.deleteFlow(controller.selectedId.value);
                      controller.window.value = "none";
                      controller.refresh();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Pallet.inside1,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("delete", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                        Icon(Icons.delete, size: 18),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SmallButton(
                      label: "close",
                      onPress: () {
                        controller.isSelectingLoop.value = false;
                        controller.loopFrom.value = -1;
                        controller.loopTo.value = -1;
                        controller.isPickingLoopFrom.value = false;
                        controller.isPickingLoopTo.value = false;
                        controller.window.value = "none";
                        controller.refresh();
                      },
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text("width", style: TextStyle(fontSize: 12)),
            SizedBox(height: 10),
            SmallTextBox(
              controller: _widthController,
              onType: (value) async {
                if (double.tryParse(value) != null &&
                    double.parse(value) >= Defaults.flowWidth) {
                  selectedFlow.width = double.parse(value);
                  controller.widthText.value = value;
                  _recalculateSizeForFlow(selectedFlow, _valueController.text, controller);
                  controller.updateFlowsReactive();
                  _saveDebounce?.cancel();
                  _saveDebounce = Timer(Duration(milliseconds: 500), () {
                    controller.save();
                  });
                }
              },
            ),
            SizedBox(height: 15),
            Text("value", style: TextStyle(fontSize: 12)),
            SizedBox(height: 10),
            SmallTextBox(
              controller: _valueController,
              maxLines: 5,
              onType: (value) {
                selectedFlow.value = value;
                controller.valueText.value = value;
                _recalculateSizeForFlow(selectedFlow, value, controller);
                controller.updateFlowsReactive();
                _saveDebounce?.cancel();
                _saveDebounce = Timer(Duration(milliseconds: 500), () {
                  controller.save();
                });
              },
            ),
            // SizedBox(
            //   height: 10,
            // ),
            if (selectedFlow.down.hasChild ||
                selectedFlow.right.hasChild ||
                selectedFlow.left.hasChild)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text("line heights", style: TextStyle(fontSize: 12)),
              ),
            SizedBox(height: 10),
            if (selectedFlow.down.hasChild)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Text("down", style: TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: SmallTextBox(
                        controller: _downController,
                        onType: (value) {
                          if (value.isNotEmpty &&
                              double.tryParse(value) != null) {
                            selectedFlow.down.lineHeight = double.parse(value);
                            controller.downText.value = value;
                            print(selectedFlow.down.lineHeight);
                            controller.forceRepositionAllFlows();
                            controller.save();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedFlow.left.hasChild)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Text("left", style: TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: SmallTextBox(
                        controller: _leftController,
                        onType: (value) {
                          if (value.isNotEmpty &&
                              double.tryParse(value) != null) {
                            selectedFlow.left.lineHeight = double.parse(value);
                            controller.leftText.value = value;
                            controller.forceRepositionAllFlows();
                            controller.save();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedFlow.right.hasChild)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Text("right", style: TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: SmallTextBox(
                        controller: _rightController,
                        onType: (value) {
                          if (value.isNotEmpty &&
                              double.tryParse(value) != null) {
                            selectedFlow.right.lineHeight = double.parse(value);
                            controller.rightText.value = value;
                            controller.forceRepositionAllFlows();
                            controller.save();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            // Toggle yes direction for condition flows with two children
            if (selectedFlow.type == FlowType.condition)
              Obx(() {
                final childDirections = <Direction>[];
                for (var flow in controller.flows) {
                  if (flow.pid == selectedFlow.id) {
                    if (flow.direction != null) {
                      childDirections.add(flow.direction!);
                    }
                  }
                }
                // Only show toggle if exactly two children with different directions
                if (childDirections.length == 2 && childDirections[0] != childDirections[1]) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: InkWell(
                      onTap: () {
                        // Toggle between the two directions
                        final currentYes = selectedFlow.yes;
                        final newYes = currentYes == childDirections[0] ? childDirections[1] : childDirections[0];
                        selectedFlow.yes = newYes;
                        controller.updateFlowsReactive();
                        controller.save();
                        // Force canvas repaint
                        controller.flowCanvasRefreshCounter.value++;
                        // Force UI update
                        setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Pallet.inside1,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("yes: ${selectedFlow.yes?.name ?? 'none'}", style: TextStyle(fontSize: 12)),
                            SizedBox(width: 10),
                            Icon(Icons.swap_horiz, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
            InkWell(
              onTap: () {
                // Use existing delete to remove loop when in loop selection mode with both endpoints chosen
                if ((controller.isSelectingLoop.value || (controller.loopFrom.value >= 0 && controller.loopTo.value >= 0))
                    && controller.loopFrom.value >= 0 && controller.loopTo.value >= 0) {
                  controller.deleteLoop(controller.loopFrom.value, controller.loopTo.value);
                  // Reset loop selection UI state
                  controller.loopFrom.value = -1;
                  controller.loopTo.value = -1;
                  controller.isPickingLoopFrom.value = false;
                  controller.isPickingLoopTo.value = false;
                  controller.window.value = "none";
                  controller.refresh();
                } else {
                  controller.deleteFlow(controller.selectedId.value);
                  controller.window.value = "none";
                  controller.refresh();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Pallet.inside1,
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("delete", style: TextStyle(fontSize: 12)),
                    SizedBox(width: 10),
                    Icon(Icons.delete, size: 18),
                  ],
                ),
              ),
            ),
            // Check if selected flow is linked to any loops
            if (controller.loopLinks.any((link) => link.fromId == selectedFlow.id || link.toId == selectedFlow.id))
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: InkWell(
                  onTap: () {
                    controller.deleteAllLoopsForFlow(selectedFlow.id);
                    controller.window.value = "none";
                    controller.refresh();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Pallet.inside1,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("delete loops", style: TextStyle(fontSize: 12)),
                        SizedBox(width: 10),
                        Icon(Icons.delete, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SmallButton(
                  label: "done",
                  onPress: () {
                    controller.save();
                    controller.window.value = "none";
                    controller.refresh();
                  },
                ),
                SizedBox(width: 5),
                SmallButton(
                  label: "close",
                  onPress: () {
                    controller.window.value = "none";
                    controller.refresh();
                  },
                ),
              ],
            ),
          ],
          );
        }),
      );
    });
  }
}

class _FlowPreview extends StatelessWidget {
  const _FlowPreview({required this.flow});
  final FlowClass flow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Pallet.inside1,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("#${flow.id} • ${flow.type.name}", style: TextStyle(fontSize: 11, color: Pallet.font2)),
          SizedBox(height: 4),
          Text(flow.value, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
