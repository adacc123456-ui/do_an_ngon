import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SvgIcon extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;
  final IconData? fallbackIcon;

  const SvgIcon({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.color,
    this.fallbackIcon,
  });

  @override
  State<SvgIcon> createState() => _SvgIconState();
}

class _SvgIconState extends State<SvgIcon> {
  bool _hasError = false;

  Widget _buildFallback() {
    if (widget.fallbackIcon != null) {
      return Icon(
        widget.fallbackIcon,
        size: widget.width?.w ?? widget.height?.h ?? 24.w,
        color: widget.color,
      );
    }
    return SizedBox(
      width: widget.width?.w ?? 24.w,
      height: widget.height?.h ?? 24.w,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallback();
    }

    return FutureBuilder<ByteData>(
      future: rootBundle.load(widget.assetPath),
      builder: (context, snapshot) {
        if (snapshot.hasError || _hasError) {
          if (!_hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                });
              }
            });
          }
          return _buildFallback();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildFallback();
        }

        if (snapshot.data == null) {
          return _buildFallback();
        }

        return SvgPicture.asset(
          widget.assetPath,
          width: widget.width?.w,
          height: widget.height?.h,
          colorFilter:
              widget.color != null
                  ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
                  : null,
          placeholderBuilder: (context) => _buildFallback(),
          fit: BoxFit.contain,
        );
      },
    );
  }
}
