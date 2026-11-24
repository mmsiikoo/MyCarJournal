import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class Base64Image extends StatefulWidget {
  const Base64Image(
    this.data, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String data;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _decode();
    }
  }

  void _decode() {
    try {
      _bytes = base64Decode(widget.data);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined),
      );
    }
    return Image.memory(
      bytes,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}
