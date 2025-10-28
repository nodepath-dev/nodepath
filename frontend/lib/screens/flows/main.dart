import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'flows.dart';
import 'flows_controller.dart';
import 'package:frontend/globals.dart';
import '../../widgets/user_profile.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:image/image.dart' as img;

import 'widgets.dart';

class FlowEditor extends StatefulWidget {
  const FlowEditor({super.key});

  @override
  State<FlowEditor> createState() => _FlowEditorState();
}

class _FlowEditorState extends State<FlowEditor> {
  final FlowsController controller = Get.put(FlowsController());
  bool _isSidebarVisible = true;
  final GlobalKey _canvasKey = GlobalKey();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    // Initialize window dimensions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.stageWidth.value =
          MediaQuery.of(context).size.width - (_isSidebarVisible ? 250 : 0);
      controller.windowHeight.value = MediaQuery.of(context).size.height;
    });
  }

  Future<void> _exportAsPng() async {
    if (controller.selectedFlowId.value.isEmpty) {
      _showSnack('Please select a flow to export');
      return;
    }
    setState(() {
      _exporting = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    String oldWindow = controller.window.value;
    bool oldShowHandles = controller.showAddHandles.value;
    try {
      controller.window.value = "";
      controller.showAddHandles.value = false;
      controller.refresh();

      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _showSnack('Unable to capture canvas');
        return;
      }
      const double pixelRatio = 3.0;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showSnack('Failed to create image bytes');
        return;
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();
      final cropped = _cropToFlowsBounds(pngBytes, pixelRatio: pixelRatio);
      if (cropped != null) {
        pngBytes = cropped;
      }
      // Pad to square with white background for PNG export
      final squared = _padPngToSquareWhite(pngBytes);
      if (squared != null) {
        pngBytes = squared;
      }
      final String fileName = _sanitizedFlowName();
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: pngBytes,
        mimeType: MimeType.png,
        ext: 'png',
      );
      _showSnack('PNG exported');
    } catch (e) {
      _showSnack('Export failed: $e');
    } finally {
      controller.window.value = oldWindow;
      controller.showAddHandles.value = oldShowHandles;
      controller.refresh();
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  Future<void> _exportAsPdf() async {
    if (controller.selectedFlowId.value.isEmpty) {
      _showSnack('Please select a flow to export');
      return;
    }
    setState(() {
      _exporting = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    String oldWindow = controller.window.value;
    bool oldShowHandles = controller.showAddHandles.value;
    try {
      controller.window.value = "";
      controller.showAddHandles.value = false;
      controller.refresh();

      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _showSnack('Unable to capture canvas');
        return;
      }
      const double pixelRatio = 3.0;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showSnack('Failed to create image bytes');
        return;
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();
      final cropped = _cropToFlowsBounds(pngBytes, pixelRatio: pixelRatio);
      if (cropped != null) {
        pngBytes = cropped;
      }

      final doc = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.FittedBox(
                child: pw.Image(imageProvider),
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      final String fileName = _sanitizedFlowName();
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: pdfBytes,
        mimeType: MimeType.pdf,
        ext: 'pdf',
      );
      _showSnack('PDF exported');
    } catch (e) {
      _showSnack('Export failed: $e');
    } finally {
      controller.window.value = oldWindow;
      controller.showAddHandles.value = oldShowHandles;
      controller.refresh();
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  String _sanitizedFlowName() {
    try {
      String? rawName;
      final selectedId = controller.selectedFlowId.value;
      if (selectedId.isNotEmpty) {
        final match = controller.savedFlows.firstWhereOrNull(
          (f) => f.id == selectedId,
        );
        if (match != null) rawName = match.flowName;
      }
      rawName ??= 'flow_canvas';
      // Replace illegal filename characters and trim
      final sanitized = rawName
          .replaceAll(RegExp(r'[<>:"/\\|?*]+'), '-')
          .trim();
      if (sanitized.isEmpty) return 'flow_canvas';
      return sanitized;
    } catch (_) {
      return 'flow_canvas';
    }
  }

  Uint8List? _cropToFlowsBounds(
    Uint8List pngBytes, {
    required double pixelRatio,
  }) {
    try {
      if (controller.flows.isEmpty) return pngBytes;

      double minX = controller.flows
          .map((f) => f.x)
          .reduce((a, b) => a < b ? a : b);
      double minY = controller.flows
          .map((f) => f.y)
          .reduce((a, b) => a < b ? a : b);
      double maxX = controller.flows
          .map((f) => f.x + f.width)
          .reduce((a, b) => a > b ? a : b);
      double maxY = controller.flows
          .map((f) => f.y + f.height)
          .reduce((a, b) => a > b ? a : b);

      const double pad = 16.0;
      final double stageW = controller.stageWidth.value;
      final double stageH = controller.windowHeight.value;

      double leftF = (minX - pad).clamp(0.0, stageW);
      double topF = (minY - pad).clamp(0.0, stageH);
      double rightF = (maxX + pad).clamp(0.0, stageW);
      double bottomF = (maxY + pad).clamp(0.0, stageH);

      int left = (leftF * pixelRatio).floor();
      int top = (topF * pixelRatio).floor();
      int right = (rightF * pixelRatio).ceil();
      int bottom = (bottomF * pixelRatio).ceil();

      final img.Image? decoded = img.decodePng(pngBytes);
      if (decoded == null) return pngBytes;
      final int width = decoded.width;
      final int height = decoded.height;

      if (right <= 0 || bottom <= 0 || left >= width || top >= height) {
        return pngBytes;
      }
      left = left.clamp(0, width - 1);
      top = top.clamp(0, height - 1);
      right = right.clamp(left + 1, width);
      bottom = bottom.clamp(top + 1, height);
      final int cropWidth = right - left;
      final int cropHeight = bottom - top;
      if (cropWidth <= 1 || cropHeight <= 1) return pngBytes;

      final img.Image cropped = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: cropWidth,
        height: cropHeight,
      );
      return Uint8List.fromList(img.encodePng(cropped));
    } catch (_) {
      return pngBytes;
    }
  }

  Uint8List? _padPngToSquareWhite(Uint8List pngBytes) {
    try {
      final img.Image? decoded = img.decodePng(pngBytes);
      if (decoded == null) return pngBytes;

      final int width = decoded.width;
      final int height = decoded.height;
      if (width == height) return pngBytes;

      final int size = width > height ? width : height;
      final img.Image canvas = img.Image(width: size, height: size);
      // Fill canvas with white
      img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));

      final int offsetX = ((size - width) / 2).floor();
      final int offsetY = ((size - height) / 2).floor();

      // Draw original in center
      img.compositeImage(canvas, decoded, dstX: offsetX, dstY: offsetY);

      return Uint8List.fromList(img.encodePng(canvas));
    } catch (_) {
      return pngBytes;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
      controller.stageWidth.value =
          MediaQuery.of(context).size.width - (_isSidebarVisible ? 250 : 0);
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                // Sidebar for flow creation
                if (_isSidebarVisible)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    width: 250,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Pallet.inside1,
                      border: Border(
                        right: BorderSide(color: Pallet.inside2, width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("add flow"),
                            AddController(
                              onSave: (value) {
                                controller.createFlow(value);
                              },
                            ),
                          ],
                        ),
                        // Flow creation buttons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Expanded(
                                child: Obx(() {
                                  if (controller.isLoadingFlows.value) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (controller.savedFlows.isEmpty) {
                                    return Center(
                                      child: Text(
                                        "No saved flows",
                                        style: TextStyle(
                                          color: Pallet.font3,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }
                                  SizedBox(height: 8);

                                  return ListView.builder(
                                    itemCount: controller.savedFlows.length,
                                    itemBuilder: (context, index) {
                                      final flow = controller.savedFlows[index];
                                      return Obx(() {
                                        final bool isSelected =
                                            controller.selectedFlowId.value ==
                                            flow.id;
                                        return InkWell(
                                          onTap: () {
                                            controller.selectedFlowId.value =
                                                flow.id;
                                            controller.loadFlow(flow.id);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Pallet.inside2
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Pallet.inside3
                                                    : Colors.transparent,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  flow.flowName,
                                                  style: TextStyle(
                                                    color: Pallet.font2,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Pallet.font3,
                                                  size: 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Main flow editor area
                Expanded(
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Container(
                      color: _exporting ? Colors.white : Pallet.background,
                      child: Stack(
                        children: [
                          // Flow canvas
                          const Flows(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Pallet.inside1,
        border: Border(bottom: BorderSide(color: Pallet.inside3, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/logo.png', width: 30, height: 30),
              ),
              const SizedBox(width: 12),
              Text(
                'Node Path',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Pallet.font2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Pallet.inside2,
                  popupMenuTheme: Theme.of(context).popupMenuTheme.copyWith(
                    elevation: 10,
                    shadowColor: Colors.black54,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Pallet.inside1,
                  ),
                ),
                child: PopupMenuButton<String>(
                  tooltip: _exporting ? 'Exporting…' : 'Export',
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 8),
                  color: Pallet.inside1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (value) {
                    if (value == 'png') {
                      _exportAsPng();
                    } else if (value == 'pdf') {
                      _exportAsPdf();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'png',
                      child: Row(
                        children: [
                          Icon(Icons.image, size: 18),
                          SizedBox(width: 8),
                          Text('Export as PNG'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 18),
                          SizedBox(width: 8),
                          Text('Export as PDF'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Pallet.inside2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Pallet.inside3, width: 1),
                    ),
                    child: Row(
                      children: [
                        Text('Export', style: TextStyle(color: Pallet.font2)),
                        const SizedBox(width: 6),
                        _exporting
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Pallet.font2,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.download,
                                size: 18,
                                color: Pallet.font2,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const UserProfileWidget(),
            ],
          ),
        ],
      ),
    );
  }
}
