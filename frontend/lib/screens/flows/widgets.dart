import 'package:flutter/material.dart';
import 'package:frontend/globals.dart';

import '../../widgets/button.dart';
import '../../widgets/textbox.dart';

class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 0;

    Offset start = Offset(size.width / 2, 0);
    Offset end = Offset(size.width, size.height / 2);

    canvas.drawLine(start, end, paint);

    start = Offset(size.width, size.height / 2);
    end = Offset(size.width / 2, size.height);

    canvas.drawLine(start, end, paint);

    start = Offset(size.width / 2, size.height);
    end = Offset(0, size.height / 2);

    canvas.drawLine(start, end, paint);

    start = Offset(0, size.height / 2);
    end = Offset(size.width / 2, 0);

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class DiamondHighlightPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DiamondHighlightPainter({this.color = Colors.yellowAccent, this.strokeWidth = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Condition extends StatelessWidget {
  const Condition({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    this.highlight = false,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.mouseCursor,
  });
  final String label;
  final double width;
  final double height;
  final bool highlight;
  final Function(DragStartDetails)? onPanStart;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;
  final MouseCursor? mouseCursor;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: mouseCursor ?? SystemMouseCursors.basic,
      child: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: CustomPaint(
          painter: LinePainter(),
          foregroundPainter: highlight ? DiamondHighlightPainter() : null,
          child: Container(
            padding: EdgeInsets.all(width / 4),
            width: width,
            height: width,
            child: Center(child: Text(label, style: TextStyle(fontSize: 13))),
          ),
        ),
      ),
    );
  }
}

class Terminal extends StatelessWidget {
  const Terminal({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    this.highlight = false,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.mouseCursor,
  });
  final String label;
  final double width;
  final double height;
  final bool highlight;
  final Function(DragStartDetails)? onPanStart;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;
  final MouseCursor? mouseCursor;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: mouseCursor ?? SystemMouseCursors.basic,
      child: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: highlight ? 3 : 1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 13))),
        ),
      ),
    );
  }
}

class Process extends StatelessWidget {
  const Process({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    this.highlight = false,
    this.onHover,
    this.onUnhover,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.mouseCursor,
  });
  final String label;
  final double width;
  final double height;
  final bool highlight;
  final VoidCallback? onHover;
  final VoidCallback? onUnhover;
  final Function(DragStartDetails)? onPanStart;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;
  final MouseCursor? mouseCursor;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover?.call(),
      onExit: (_) => onUnhover?.call(),
      cursor: mouseCursor ?? SystemMouseCursors.basic,
      child: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: highlight ? 3 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 13))),
        ),
      ),
    );
  }
}

class Expandable extends StatefulWidget {
  const Expandable({
    super.key,
    required this.name,
    required this.children,
    required this.onTap,
    required this.selected,
    required this.indent,
    required this.data,
  });
  final String name;
  final Function? onTap;
  final List<Widget> children;
  final bool selected;
  final Map data;

  final double indent;
  @override
  State<Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<Expandable> {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (isOpen) {
              isOpen = false;
            } else if (widget.children.isNotEmpty) {
              isOpen = true;
            }
            if (widget.onTap != null) {
              widget.onTap!();
            }
            setState(() {});
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? Pallet.inside2.withOpacity(0.5)
                  : Colors.transparent,
              border: Border(
                top: BorderSide(
                  color: (widget.indent == 0)
                      ? Colors.transparent
                      : Pallet.font3.withOpacity(0.2),
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 10 * widget.indent),
              child: Row(
                children: [
                  if (widget.children.isNotEmpty)
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: Pallet.font3,
                      size: 18,
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.transparent,
                      size: 18,
                    ),
                  Expanded(
                    child: Text(widget.name, style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isOpen)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.children,
          ),
      ],
    );
  }
}

class AddController extends StatefulWidget {
  const AddController({super.key, required this.onSave});
  final Function onSave;
  @override
  State<AddController> createState() => _AddControllerState();
}

class _AddControllerState extends State<AddController> {
  TextEditingController name = TextEditingController();

  double height = 0, width = 0, initX = 0, initY = 0;
  GlobalKey actionKey = GlobalKey();
  OverlayEntry? dropdown;
  bool isOpen = false;
  @override
  void initState() {
    super.initState();
  }

  close() {
    if (isOpen) {
      dropdown!.remove();
      isOpen = false;
      setState(() {});
    }
  }

  void findDropDownData() {
    RenderBox renderBox =
        actionKey.currentContext!.findRenderObject() as RenderBox;
    height = renderBox.size.height;
    width = renderBox.size.width;
    // Offset offset = renderBox.localToGlobal(Offset.zero);
    Offset offset = renderBox.localToGlobal(Offset.zero);
    initX = offset.dx;
    initY = offset.dy;
    print(initX);
  }

  OverlayEntry _createDropDown() {
    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            // Close overlay when tapping outside the menu
            close();
          },
          child: Container(
            color: Colors.black.withOpacity(0.1),
            child: Stack(
              children: [
                Positioned(
                  left: initX,
                  top: initY + height + 5,
                  child: GestureDetector(
                    onTap: () {
                      // Prevent closing when tapping inside the menu
                    },
                    child: Material(
                      shadowColor: Colors.transparent,
                      elevation: 1,
                      color: Colors.transparent,
                      child: Container(
                        width: 220,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Pallet.inside2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Text("Name", style: TextStyle(fontSize: 12)),
                            SizedBox(height: 10),
                            SmallTextBox(
                              controller: name,
                              onEnter: (value) {
                                widget.onSave(value);
                                close(); // Close overlay after saving
                              },
                            ),
                            SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SmallButton(
                                  label: "close",
                                  onPress: () {
                                    close();
                                  },
                                ),
                                SizedBox(width: 10),
                                SmallButton(
                                  label: "done",
                                  onPress: () async {
                                    // save();
                                    widget.onSave(name.text);
                                    close(); // Close overlay after saving
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isOpen) {
          dropdown!.remove();
        } else {
          findDropDownData();
          dropdown = _createDropDown();
          Overlay.of(context).insert(dropdown!);
        }

        isOpen = !isOpen;
        setState(() {});
      },
      child: Container(
        key: actionKey,
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.grey),
        ),
        child: Icon(Icons.add, color: Colors.grey, size: 10),
      ),
    );
  }
}
