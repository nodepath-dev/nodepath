import 'package:get/get.dart';
import 'dart:async';
import 'types.dart';
import '../../backend/server.dart';
import '../../services/local_storage_service.dart';
import '../../services/arri_client.rpc.dart';

class FlowsController extends GetxController {
  // Observable flows list
  final RxList<FlowClass> flows = <FlowClass>[].obs;
  
  // Observable saved flows list (from API)
  final RxList<FlowItem> savedFlows = <FlowItem>[].obs;
  
  // Observable loading state
  final RxBool isLoadingFlows = false.obs;
  
  // Observable window mode
  final RxString window = "add".obs;
  
  // Observable selected flow properties
  final Rx<FlowType?> selectedType = Rx<FlowType?>(null);
  final Rx<Direction?> selectedDirection = Rx<Direction?>(null);
  final RxInt selectedId = (-1).obs;
  
  // Observable flow properties for editing
  final RxString widthText = "".obs;
  final RxString valueText = "".obs;
  final RxString downText = "".obs;
  final RxString leftText = "".obs;
  final RxString rightText = "".obs;
  
  // Observable window dimensions
  final RxDouble stageWidth = 0.0.obs;
  final RxDouble windowHeight = 0.0.obs;
  
  // Observable widget key for positioning
  final RxString widgetKey = "".obs;
  
  // Observable flow ID
  final RxString flowId = "".obs;
  
  // Observable selected flow from sidebar
  final RxString selectedFlowId = "".obs;
  
  // Observable palette settings
  final RxBool isLightMode = false.obs;
  
  // Observable hover state for process flows
  final RxInt hoveredProcessId = (-1).obs;
  
  // Observable hovered side for process flows
  final RxString hoveredSide = "".obs; // "left", "right", or ""
  
  // Observable mouse over dot state
  final RxBool isMouseOverDot = false.obs;
  
  // Toggle to show/hide add handles (dots and hover lines)
  final RxBool showAddHandles = true.obs;
  
  // Observable refresh counter to force UI updates
  final RxInt refreshCounter = 0.obs;
  
  // Observable refresh counter specifically for flow canvas positioning
  final RxInt flowCanvasRefreshCounter = 0.obs;
  
  // Observable drag state for line height adjustment
  final RxBool isDraggingLineHeight = false.obs;
  final RxInt draggedFlowId = (-1).obs;
  final RxDouble initialDragX = 0.0.obs;
  final RxDouble initialDragY = 0.0.obs;
  final RxDouble initialLineHeight = 0.0.obs;

  // Observable panning state for InteractiveViewer
  final RxBool isPanning = false.obs;
  
  // Loop selection state
  final RxBool isSelectingLoop = false.obs;
  final RxInt loopFirstSelection = (-1).obs;
  final RxList<LoopLink> loopLinks = <LoopLink>[].obs;
  // Panel-based pending loop endpoints
  final RxInt loopFrom = (-1).obs;
  final RxInt loopTo = (-1).obs;
  // Loop picking state and hover
  final RxBool isPickingLoopFrom = false.obs;
  final RxBool isPickingLoopTo = false.obs;
  final RxInt loopHoverId = (-1).obs;
  
  // Loop routing offset (used by painter to place outer corridors/lanes)
  final RxDouble loopPad = 40.0.obs;
  // Hover/drag state for loop pad
  final RxString hoveredLoopPadAxis = "".obs; // "vertical" or "horizontal"
  final RxBool isDraggingLoopPad = false.obs;
  final RxDouble initialLoopPadDragPos = 0.0.obs;
  final RxDouble initialLoopPadValue = 40.0.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize with empty flows
    if (flows.isEmpty) {
      window.value = "add";
    }
    // Load saved flows from API
    loadSavedFlows();
  }
  
  // Method to refresh the UI (replaces refreshSink.add(""))
  void refresh() {
    // No need to call update() here as it's already called where needed
    // This method can be used for any additional refresh logic if needed
  }
  
  // Method to load saved flows from API
  Future<void> loadSavedFlows() async {
    try {
      isLoadingFlows.value = true;
      
      // Get user ID from local storage
      final userId = await LocalStorageService.getUserId();
      if (userId == null) {
        print('No user ID found in local storage');
        return;
      }
      
      // Call listFlows API using centralized server client
      final response = await server.flows.listFlows(
        ListFlowsParams(userId: userId),
      );
      
      if (response.success) {
        savedFlows.value = response.flows;
        print('Loaded ${response.flows.length} flows from API');
      } else {
        print('Failed to load flows: ${response.message}');
      }
    } catch (e) {
      print('Error loading flows: $e');
    } finally {
      isLoadingFlows.value = false;
    }
  }
  
  // Method to load a specific flow
  Future<void> loadFlow(String flowId) async {
    try {
      // Set the flow ID for future updates
      this.flowId.value = flowId;
      
      // Call getFlow API to fetch the flow data using centralized server client
      final response = await server.flows.getFlow(
        GetFlowParams(flowId: flowId),
      );
      
      if (response.success && response.flow != null) {
        print('Loading flow: ${response.flowName}');
        
        // Clear current flows
        flows.clear();
        
        // Load the flow data from JSON
        fromJson(response.flow as List);
        
        // Set window to add mode
        window.value = "add";
        
        refresh();
      } else {
        print('Failed to load flow: ${response.message}');
      }
    } catch (e) {
      print('Error loading flow: $e');
    }
  }
  
  // Method to set flow ID for updates
  void setFlowId(String id) {
    flowId.value = id;
  }
  
  // Method to clear selected flow
  void clearSelectedFlow() {
    selectedFlowId.value = "";
    refresh();
  }
  
  // Method to handle process flow hover
  void onProcessHover(int processId, String side) {
    hoveredProcessId.value = processId;
    hoveredSide.value = side;
  }
  
  // Method to handle process flow unhover
  void onProcessUnhover() {
    hoveredProcessId.value = -1;
    hoveredSide.value = "";
  }
  
  // Method to update mouse over dot state
  void updateMouseOverDot(bool isOverDot) {
    isMouseOverDot.value = isOverDot;
  }
  
  // Hover setter for loop pad axis
  void setHoveredLoopPadAxis(String axis) {
    hoveredLoopPadAxis.value = axis;
  }
  
  // Begin dragging the loop pad offset (global)
  void startLoopPadDrag(double pointerX, double pointerY) {
    if (hoveredLoopPadAxis.value.isEmpty) return;
    isDraggingLoopPad.value = true;
    initialLoopPadValue.value = loopPad.value;
    initialLoopPadDragPos.value = hoveredLoopPadAxis.value == "vertical" ? pointerY : pointerX;
  }
  
  // Update loop pad while dragging
  void updateLoopPadDrag(double pointerX, double pointerY) {
    if (!isDraggingLoopPad.value) return;
    const double minPad = 10.0;
    const double maxPad = 300.0;
    final currentPos = hoveredLoopPadAxis.value == "vertical" ? pointerY : pointerX;
    final delta = currentPos - initialLoopPadDragPos.value;
    final newValue = (initialLoopPadValue.value + delta).clamp(minPad, maxPad);
    loopPad.value = newValue;
    // Trigger repaint
    flowCanvasRefreshCounter.value++;
    update();
  }
  
  // End loop pad drag
  void endLoopPadDrag() {
    if (!isDraggingLoopPad.value) return;
    isDraggingLoopPad.value = false;
    // Persist loop corridor/lanes offset changes
    save();
  }
  
  // Method to start line height drag
  void startLineHeightDrag(int flowId, double startX, double startY) {
    if (flowId < 0 || flowId >= flows.length) return;
    
    final flow = flows[flowId];
    if (flow.pid == null) return; // Can't drag root flow
    
    final parentFlow = flows.firstWhere((f) => f.id == flow.pid);
    
    // Determine which line height to adjust based on flow direction
    double currentLineHeight = 0.0;
    if (flow.direction == Direction.down) {
      currentLineHeight = parentFlow.down.lineHeight;
    } else if (flow.direction == Direction.left) {
      currentLineHeight = parentFlow.left.lineHeight;
    } else if (flow.direction == Direction.right) {
      currentLineHeight = parentFlow.right.lineHeight;
    }
    
    isDraggingLineHeight.value = true;
    draggedFlowId.value = flowId;
    initialDragX.value = startX;
    initialDragY.value = startY;
    initialLineHeight.value = currentLineHeight;
  }
  
  // Method to update line height during drag
  void updateLineHeightDrag(double currentX, double currentY) {
    if (!isDraggingLineHeight.value || draggedFlowId.value < 0) return;
    
    final flowId = draggedFlowId.value;
    if (flowId >= flows.length) return;
    
    final flow = flows[flowId];
    if (flow.pid == null) return;
    
    final parentFlow = flows.firstWhere((f) => f.id == flow.pid);
    final deltaY = currentY - initialDragY.value;
    final deltaX = currentX - initialDragX.value;
    
    // Apply drag sensitivity (reduce sensitivity for smoother control)
    final adjustedDeltaY = deltaY * 0.5;
    final adjustedDeltaX = deltaX * 0.5;
    
    // Calculate new line height (minimum 10px, maximum 500px)
    double newLineHeight = initialLineHeight.value;
    if (flow.direction == Direction.down) {
      newLineHeight = (initialLineHeight.value + adjustedDeltaY).clamp(10.0, 500.0);
      parentFlow.down.lineHeight = newLineHeight;
    } else if (flow.direction == Direction.left) {
      // Moving left (decreasing X) should increase line height
      newLineHeight = (initialLineHeight.value + (-adjustedDeltaX)).clamp(10.0, 500.0);
      parentFlow.left.lineHeight = newLineHeight;
    } else if (flow.direction == Direction.right) {
      // Moving right (increasing X) should increase line height
      newLineHeight = (initialLineHeight.value + adjustedDeltaX).clamp(10.0, 500.0);
      parentFlow.right.lineHeight = newLineHeight;
    }
    
    // Reposition all flows to reflect the new line height
    forceRepositionAllFlows();
  }
  
  // Method to end line height drag
  void endLineHeightDrag() {
    if (isDraggingLineHeight.value) {
      isDraggingLineHeight.value = false;
      draggedFlowId.value = -1;
      initialDragY.value = 0.0;
      initialLineHeight.value = 0.0;
      
      // Save the changes
      save();
    }
  }
  
  // Method to add a new flow
  void addFlow(FlowType type) {
    double y = 20;
    
    FlowClass flow = FlowClass(
      id: flows.length,
      width: Defaults.flowWidth,
      height: (type == FlowType.condition) ? Defaults.flowWidth : 40,
      x: stageWidth.value / 2 - Defaults.flowWidth / 2,
      y: y,
      type: type,
      value: "start",
      down: Line(),
      left: Line(),
      right: Line(),
      pid: selectedId.value >= 0 ? selectedId.value : null,
      direction: selectedDirection.value,
    );
    
    if (selectedId.value >= 0 && selectedId.value < flows.length) {
      if (flows[selectedId.value].type == FlowType.condition && 
          flows[selectedId.value].yes == null) {
        flows[selectedId.value].yes = selectedDirection.value;
      }
    }
    
    selectedId.value = flows.length;
    selectedType.value = type;
    flows.add(flow);
    
    // Update positions after adding the flow
    updateFlowsReactive();
    
    // Clear hover state after adding flow
    onProcessUnhover();
    
    // Save the flow after adding and updating relationships
    save();
    
    window.value = "edit";
    update();
  }
  
  // Method to select a flow
  void selectFlow(int id, Direction direction, FlowType type) {
    // Handle loop selection mode
    if (isSelectingLoop.value) {
      if (isPickingLoopFrom.value) {
        loopFrom.value = id;
        isPickingLoopFrom.value = false;
        // After a short delay, switch to picking 'to' automatically if still in loop mode
        Future.delayed(Duration(milliseconds: 500), () {
          if (isSelectingLoop.value && loopFrom.value >= 0 && loopTo.value < 0) {
            isPickingLoopTo.value = true;
          }
        });
      } else if (isPickingLoopTo.value) {
        if (loopFrom.value != id) {
          loopTo.value = id;
          // Auto-create loop when "to" is selected
          commitPendingLoop();
        }
        isPickingLoopTo.value = false;
      } else {
        // Fallback: sequential pick
        if (loopFrom.value < 0) {
          loopFrom.value = id;
          // Move to picking 'to' after delay
          Future.delayed(Duration(milliseconds: 500), () {
            if (isSelectingLoop.value && loopFrom.value >= 0 && loopTo.value < 0) {
              isPickingLoopTo.value = true;
            }
          });
        } else if (loopTo.value < 0 && loopFrom.value != id) {
          loopTo.value = id;
          // Auto-create loop when "to" is selected
          commitPendingLoop();
        }
      }
      return;
    }

    window.value = "edit";
    selectedId.value = id;
    selectedDirection.value = direction;
    selectedType.value = type;
    
    // Clear hover state when selecting a flow
    onProcessUnhover();
    
    if (id >= 0 && id < flows.length) {
      widthText.value = flows[id].width.toString();
      valueText.value = flows[id].value;
      downText.value = flows[id].down.lineHeight.toString();
      leftText.value = flows[id].left.lineHeight.toString();
      rightText.value = flows[id].right.lineHeight.toString();
    }
    
    refresh();
  }

  // Start loop selection mode
  void startLoopSelection() {
    isSelectingLoop.value = true;
    loopFirstSelection.value = -1;
    loopFrom.value = -1;
    loopTo.value = -1;
    isPickingLoopFrom.value = true; // auto-start picking from
    isPickingLoopTo.value = false;
    loopHoverId.value = -1;
    // Make sure edit panel is shown for loop controls
    window.value = "edit";
  }

  // Cancel loop selection mode and reset related state
  void cancelLoopSelection() {
    if (!isSelectingLoop.value && !isPickingLoopFrom.value && !isPickingLoopTo.value) {
      return;
    }
    isSelectingLoop.value = false;
    isPickingLoopFrom.value = false;
    isPickingLoopTo.value = false;
    loopFrom.value = -1;
    loopTo.value = -1;
    loopHoverId.value = -1;
    update();
  }

  // Set pending loop endpoints via panel
  void setLoopFrom(int id) {
    if (id >= 0 && id < flows.length) {
      loopFrom.value = id;
    }
  }

  void setLoopTo(int id) {
    if (id >= 0 && id < flows.length) {
      loopTo.value = id;
    }
  }

  // Flip pending loop direction (swap arrow)
  void flipPendingLoop() {
    // If a committed link exists for current selection, flip it in place
    if (loopFrom.value >= 0 && loopTo.value >= 0) {
      final int from = loopFrom.value;
      final int to = loopTo.value;
      final int existingIndex = loopLinks.indexWhere((l) => l.fromId == from && l.toId == to);
      if (existingIndex >= 0) {
        loopLinks[existingIndex] = LoopLink(fromId: to, toId: from);
        update();
        save();
      }
    }
    // Always swap the pending endpoints for the UI
    final int tmp = loopFrom.value;
    loopFrom.value = loopTo.value;
    loopTo.value = tmp;
  }

  // Hover update when in loop selection mode
  void setLoopHover(int id) {
    if (isSelectingLoop.value) {
      loopHoverId.value = id;
    }
  }

  // Commit pending loop and persist
  void commitPendingLoop() {
    if (loopFrom.value >= 0 && loopTo.value >= 0 && loopFrom.value != loopTo.value) {
      loopLinks.add(LoopLink(fromId: loopFrom.value, toId: loopTo.value));
      isSelectingLoop.value = false;
      loopFirstSelection.value = -1;
      update();
      save();
    }
  }

  // Delete a specific loop link
  void deleteLoop(int fromId, int toId) {
    loopLinks.removeWhere((link) => link.fromId == fromId && link.toId == toId);
    update();
    save();
  }

  // Delete all loops involving a specific flow
  void deleteAllLoopsForFlow(int flowId) {
    loopLinks.removeWhere((link) => link.fromId == flowId || link.toId == flowId);
    update();
    save();
  }
  
  // Method to delete a flow
  void deleteFlow(int id) {
    if (id < 0 || id >= flows.length) return;
    
    FlowClass selectedFlow = flows[id];
    for (var flow in flows) {
      if (flow.id == selectedFlow.pid) {
        if (selectedFlow.direction == Direction.down) {
          flow.down.hasChild = false;
        }
        if (selectedFlow.direction == Direction.left) {
          flow.left.hasChild = false;
        }
        if (selectedFlow.direction == Direction.right) {
          flow.right.hasChild = false;
        }
      }
    }
    
    flows.removeAt(id);
    
    List<int> children = getChildIds(id);
    for (var child in children) {
      for (var i = 0; i < flows.length; i++) {
        if (flows[i].id == child) {
          flows.removeAt(i);
        }
      }
    }
    
    // Fix IDs
    for (var i = 0; i < flows.length; i++) {
      if (flows[i].id != i) {
        int oldId = flows[i].id;
        flows[i].id = i;
        for (var flow in flows) {
          if (flow.pid == oldId) {
            flow.pid = i;
          }
        }
      }
    }
    
    update();
    save();
  }
  
  // Helper method to get child IDs
  List<int> getChildIds(int id) {
    List<int> flowIds = [];
    for (var flow in flows) {
      if (flow.pid == id) {
        flowIds.add(flow.id);
        flowIds.addAll(getChildIds(flow.id));
      }
    }
    return flowIds;
  }
  
  // Method to update flow positions (for paint method - doesn't modify reactive list)
  void updateFlows() {
    // Create a copy to avoid modifying the reactive list during paint
    final flowsCopy = List<FlowClass>.from(flows);
    
    for (var flow in flowsCopy) {
      for (var child in flowsCopy) {
        if (child.pid == flow.id) {
          if (child.direction == Direction.down) {
            flow.down.hasChild = true;
          } else if (child.direction == Direction.right) {
            flow.right.hasChild = true;
          } else if (child.direction == Direction.left) {
            flow.left.hasChild = true;
          }
        }
      }
    }
    
    if (flowsCopy.isNotEmpty) {
      flowsCopy[0].x = (stageWidth.value / 2) - flowsCopy[0].width / 2;
    }
    downLines(flowsCopy, 0, stageWidth.value / 2);
    
    // Also handle side positioning for all flows that have side children
    for (var flow in flowsCopy) {
      if (flow.left.hasChild || flow.right.hasChild) {
        sideLines(flowsCopy, flow.id);
      }
    }
  }
  
  // Method to update flow positions and trigger reactive updates
  void updateFlowsReactive() {
    // First, reset all hasChild flags
    for (var flow in flows) {
      flow.down.hasChild = false;
      flow.left.hasChild = false;
      flow.right.hasChild = false;
    }
    
    // Then, set hasChild flags based on actual children
    for (var flow in flows) {
      for (var child in flows) {
        if (child.pid == flow.id) {
          if (child.direction == Direction.down) {
            flow.down.hasChild = true;
          } else if (child.direction == Direction.right) {
            flow.right.hasChild = true;
          } else if (child.direction == Direction.left) {
            flow.left.hasChild = true;
          }
        }
      }
    }
    
    if (flows.isNotEmpty) {
      flows[0].x = (stageWidth.value / 2) - flows[0].width / 2;
    }
    
    // Recalculate all positions starting from the root
    downLinesReactive(0, stageWidth.value / 2);
    
    // Also handle side positioning for all flows that have side children
    for (var flow in flows) {
      if (flow.left.hasChild || flow.right.hasChild) {
        sideLinesReactive(flow.id);
      }
    }
    
    // Force flow canvas refresh by incrementing counter
    flowCanvasRefreshCounter.value++;
    update();
  }
  
  // Method to force a complete repositioning of all flows
  void forceRepositionAllFlows() {
    if (flows.isEmpty) return;
    
    // Reset all hasChild flags
    for (var flow in flows) {
      flow.down.hasChild = false;
      flow.left.hasChild = false;
      flow.right.hasChild = false;
    }
    
    // Set hasChild flags based on actual children
    for (var flow in flows) {
      for (var child in flows) {
        if (child.pid == flow.id) {
          if (child.direction == Direction.down) {
            flow.down.hasChild = true;
          } else if (child.direction == Direction.right) {
            flow.right.hasChild = true;
          } else if (child.direction == Direction.left) {
            flow.left.hasChild = true;
          }
        }
      }
    }
    
    // Position root flow
    flows[0].x = (stageWidth.value / 2) - flows[0].width / 2;
    
    // Recursively position all flows
    _repositionFlowTree(0, stageWidth.value / 2);
    
    // Force flow canvas refresh by incrementing counter
    flowCanvasRefreshCounter.value++;
    update();
  }
  
  // Helper method to recursively reposition flows
  void _repositionFlowTree(int parentId, double parentX) {
    // Handle down children
    for (var flow in flows) {
      if (flow.pid == parentId && flow.direction == Direction.down) {
        flow.y = flows[parentId].y + flows[parentId].height + flows[parentId].down.lineHeight;
        flow.x = parentX - flow.width / 2;
        _repositionFlowTree(flow.id, flow.x + flow.width / 2);
      }
    }
    
    // Handle left children
    for (var flow in flows) {
      if (flow.pid == parentId && flow.direction == Direction.left) {
        flow.y = flows[parentId].y + flows[parentId].height / 2 - flow.height / 2;
        flow.x = flows[parentId].x - flows[parentId].left.lineHeight - flow.width;
        _repositionFlowTree(flow.id, flow.x + flow.width / 2);
      }
    }
    
    // Handle right children
    for (var flow in flows) {
      if (flow.pid == parentId && flow.direction == Direction.right) {
        flow.y = flows[parentId].y + flows[parentId].height / 2 - flow.height / 2;
        flow.x = flows[parentId].x + flows[parentId].right.lineHeight + flows[parentId].width;
        _repositionFlowTree(flow.id, flow.x + flow.width / 2);
      }
    }
  }
  
  // Method to calculate down lines
  void downLines(List<FlowClass> flowsList, int id, double x) {
    for (var flow in flowsList) {
      if (flow.pid == id && flow.direction == Direction.down) {
        // Position the flow so its top edge is just below the line
        flow.y = flowsList[id].y + flowsList[id].height + flowsList[id].down.lineHeight;
        flow.x = x - flow.width / 2;
        // Handle side lines for both condition and process flows
        sideLines(flowsList, flow.id);
        downLines(flowsList, flow.id, x);
      }
    }
  }
  
  // Method to calculate side lines
  void sideLines(List<FlowClass> flowsList, int id) {
    // Left
    for (var flow in flowsList) {
      if (flow.pid == id && flow.direction == Direction.left) {
        // Position the flow so its right edge is just after the line
        flow.y = flowsList[id].y + flowsList[id].height / 2 - flow.height / 2;
        flow.x = flowsList[id].x - flowsList[id].left.lineHeight - flow.width;
        // Handle side lines for both condition and process flows
        sideLines(flowsList, flow.id);
        downLines(flowsList, flow.id, flow.x + flow.width / 2);
      }
    }
    
    // Right
    for (var flow in flowsList) {
      if (flow.pid == id && flow.direction == Direction.right) {
        // Position the flow so its left edge is just after the line
        flow.y = flowsList[id].y + flowsList[id].height / 2 - flow.height / 2;
        flow.x = flowsList[id].x + flowsList[id].right.lineHeight + flowsList[id].width;
        // Handle side lines for both condition and process flows
        sideLines(flowsList, flow.id);
        downLines(flowsList, flow.id, flow.x + flow.width / 2);
      }
    }
  }
  
  // Reactive version of downLines for updating the actual flows list
  void downLinesReactive(int id, double x) {
    for (var flow in flows) {
      if (flow.pid == id && flow.direction == Direction.down) {
        // Position the flow so its top edge is just below the line
        flow.y = flows[id].y + flows[id].height + flows[id].down.lineHeight;
        flow.x = x - flow.width / 2;
        // Handle side lines for both condition and process flows
        sideLinesReactive(flow.id);
        downLinesReactive(flow.id, x);
      }
    }
  }
  
  // Reactive version of sideLines for updating the actual flows list
  void sideLinesReactive(int id) {
    // Left
    for (var flow in flows) {
      if (flow.pid == id && flow.direction == Direction.left) {
        // Position the flow so its right edge is just after the line
        flow.y = flows[id].y + flows[id].height / 2 - flow.height / 2;
        flow.x = flows[id].x - flows[id].left.lineHeight - flow.width;
        // Handle side lines for both condition and process flows
        sideLinesReactive(flow.id);
        downLinesReactive(flow.id, flow.x + flow.width / 2);
      }
    }
    
    // Right
    for (var flow in flows) {
      if (flow.pid == id && flow.direction == Direction.right) {
        // Position the flow so its left edge is just after the line
        flow.y = flows[id].y + flows[id].height / 2 - flow.height / 2;
        flow.x = flows[id].x + flows[id].right.lineHeight + flows[id].width;
        // Handle side lines for both condition and process flows
        sideLinesReactive(flow.id);
        downLinesReactive(flow.id, flow.x + flow.width / 2);
      }
    }
  }
  
  // Method to save flows
  Future<void> save() async {
    try {
      // Check if we have a flow ID to update
      if (flowId.value.isEmpty) {
        print('No flow ID available for update. Use createFlow() to create a new flow.');
        return;
      }
      
      // Convert flows to JSON
      final flowData = toJson();
      
      // Call updateFlow API using centralized server client
      final response = await server.flows.updateFlow(
        UpdateFlowParams(
          flowId: flowId.value,
          flow: flowData,
        ),
      );
      
      if (response.success) {
        print('Flow updated successfully: ${response.flowId}');
        // Reload saved flows to show the updated flow
        await loadSavedFlows();
      } else {
        print('Failed to update flow: ${response.message}');
      }
    } catch (e) {
      print('Error updating flow: $e');
    }
  }
  
  // Method to create a new flow via API
  Future<void> createFlow(String flowName) async {
    try {
      // Validate flow name
      if (flowName.trim().isEmpty) {
        print('Flow name cannot be empty');
        return;
      }
      
      // Get user ID from local storage
      final userId = await LocalStorageService.getUserId();
      if (userId == null) {
        print('No user ID found in local storage');
        return;
      }
      
      // Convert flows to JSON
      final flowData = toJson();
      
      // Call createFlow API using centralized server client
      final response = await server.flows.createFlow(
        CreateFlowParams(
          userId: userId,
          flowName: flowName.trim(),
          flow: flowData,
        ),
      );
      
      if (response.success) {
        print('Flow created successfully: ${response.flowId}');
        // Set the flow ID for future updates
        if (response.flowId != null) {
          flowId.value = response.flowId!;
        }
        // Reload saved flows to show the new flow
        await loadSavedFlows();
      } else {
        print('Failed to create flow: ${response.message}');
      }
    } catch (e) {
      print('Error creating flow: $e');
    }
  }
  
  // Method to load flows from JSON
  void fromJson(List flowsData) {
    flows.clear();
    loopLinks.clear();
    Direction direction = Direction.down;
    FlowType type = FlowType.terminal;
    Direction? yes;
    
    for (var flowData in flowsData) {
      // Handle special loops payload
      if (flowData is Map && flowData.containsKey("_loops")) {
        final loops = flowData["_loops"] as List?;
        if (loops != null) {
          for (var l in loops) {
            if (l is Map && l.containsKey("fromId") && l.containsKey("toId")) {
              final fromId = l["fromId"];
              final toId = l["toId"];
              if (fromId is int && toId is int) {
                loopLinks.add(LoopLink(fromId: fromId, toId: toId));
              }
            }
          }
        }
        continue; // skip creating a FlowClass for this entry
      }
      // Handle loop pad value payload
      if (flowData is Map && flowData.containsKey("_loopPad")) {
        final pad = flowData["_loopPad"];
        if (pad is num) {
          loopPad.value = pad.toDouble();
        }
        continue;
      }
      if (flowData["direction"] == "down") {
        direction = Direction.down;
      } else if (flowData["direction"] == "left") {
        direction = Direction.left;
      } else if (flowData["direction"] == "right") {
        direction = Direction.right;
      }

      if (flowData["type"] == "terminal") {
        type = FlowType.terminal;
      } else if (flowData["type"] == "condition") {
        type = FlowType.condition;
      } else if (flowData["type"] == "process") {
        type = FlowType.process;
      }
      
      if (flowData["yes"] != "none") {
        if (flowData["yes"] == "down") {
          yes = Direction.down;
        } else if (flowData["yes"] == "left") {
          yes = Direction.left;
        } else if (flowData["yes"] == "right") {
          yes = Direction.right;
        }
      }
      
      FlowClass flow = FlowClass(
        id: flowData["id"],
        width: flowData["width"],
        height: flowData["height"],
        x: flowData["x"],
        y: flowData["y"],
        type: type,
        value: flowData["value"],
        down: Line(
          lineHeight: flowData["down"]["lineHeight"], 
          hasChild: flowData["down"]["hasChild"]
        ),
        left: Line(
          lineHeight: flowData["left"]["lineHeight"], 
          hasChild: flowData["left"]["hasChild"]
        ),
        right: Line(
          lineHeight: flowData["right"]["lineHeight"], 
          hasChild: flowData["right"]["hasChild"]
        ),
        pid: flowData["pid"],
        direction: direction,
        yes: yes,
      );
      
      flows.add(flow);
    }
    
    if (flows.isEmpty) {
      window.value = "add";
    }
  }
  
  // Method to convert flows to JSON
  List toJson() {
    List flowsData = [];
    
    for (var flow in flows) {
      String direction = "down";
      String yes = "none";
      String type = "terminal";
      
      if (flow.direction == Direction.down) {
        direction = "down";
      } else if (flow.direction == Direction.right) {
        direction = "right";
      } else if (flow.direction == Direction.left) {
        direction = "left";
      }

      if (flow.type == FlowType.terminal) {
        type = "terminal";
      } else if (flow.type == FlowType.process) {
        type = "process";
      } else if (flow.type == FlowType.condition) {
        type = "condition";
      }

      if (flow.yes == Direction.down) {
        yes = "down";
      } else if (flow.yes == Direction.right) {
        yes = "right";
      } else if (flow.yes == Direction.left) {
        yes = "left";
      }
      
      Map flowData = {
        "id": flow.id,
        "width": flow.width,
        "height": flow.height,
        "x": flow.x,
        "y": flow.y,
        "type": type,
        "value": flow.value,
        "down": {
          "lineHeight": flow.down.lineHeight, 
          "hasChild": flow.down.hasChild
        },
        "left": {
          "lineHeight": flow.left.lineHeight, 
          "hasChild": flow.left.hasChild
        },
        "right": {
          "lineHeight": flow.right.lineHeight, 
          "hasChild": flow.right.hasChild
        },
        "pid": flow.pid,
        "direction": direction,
        "yes": yes
      };
      
      flowsData.add(flowData);
    }
    // Append loops payload at the end of the list so backend can store alongside nodes
    if (loopLinks.isNotEmpty) {
      final List<Map<String, int>> loops = loopLinks
          .map((e) => {"fromId": e.fromId, "toId": e.toId})
          .toList();
      flowsData.add({"_loops": loops});
    }
    // Append loop pad value so routing offset persists
    flowsData.add({"_loopPad": loopPad.value});
    
    return flowsData;
  }
}
