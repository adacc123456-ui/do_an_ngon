// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsAnimesGen {
  const $AssetsAnimesGen();

  /// File path: assets/animes/loading.gif
  AssetGenImage get loading => const AssetGenImage('assets/animes/loading.gif');

  /// File path: assets/animes/pan_loading.gif
  AssetGenImage get panLoading =>
      const AssetGenImage('assets/animes/pan_loading.gif');

  /// File path: assets/animes/splash.gif
  AssetGenImage get splash => const AssetGenImage('assets/animes/splash.gif');

  /// List of all assets
  List<AssetGenImage> get values => [loading, panLoading, splash];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/backgroud_header.png
  AssetGenImage get backgroudHeader =>
      const AssetGenImage('assets/images/backgroud_header.png');

  /// File path: assets/images/banner.png
  AssetGenImage get banner => const AssetGenImage('assets/images/banner.png');

  /// File path: assets/images/monan.png
  AssetGenImage get monan => const AssetGenImage('assets/images/monan.png');

  /// List of all assets
  List<AssetGenImage> get values => [backgroudHeader, banner, monan];
}

class $AssetsSvgsGen {
  const $AssetsSvgsGen();

  /// File path: assets/svgs/icon_coffee.svg
  SvgGenImage get iconCoffee =>
      const SvgGenImage('assets/svgs/icon_coffee.svg');

  /// File path: assets/svgs/icon_fast_food.svg
  SvgGenImage get iconFastFood =>
      const SvgGenImage('assets/svgs/icon_fast_food.svg');

  /// File path: assets/svgs/icon_favorite.svg
  SvgGenImage get iconFavorite =>
      const SvgGenImage('assets/svgs/icon_favorite.svg');

  /// File path: assets/svgs/icon_favorite_enable.svg
  SvgGenImage get iconFavoriteEnable =>
      const SvgGenImage('assets/svgs/icon_favorite_enable.svg');

  /// File path: assets/svgs/icon_home.svg
  SvgGenImage get iconHome => const SvgGenImage('assets/svgs/icon_home.svg');

  /// File path: assets/svgs/icon_home_enable.svg
  SvgGenImage get iconHomeEnable =>
      const SvgGenImage('assets/svgs/icon_home_enable.svg');

  /// File path: assets/svgs/icon_noodles.svg
  SvgGenImage get iconNoodles =>
      const SvgGenImage('assets/svgs/icon_noodles.svg');

  /// File path: assets/svgs/icon_random.svg
  SvgGenImage get iconRandom =>
      const SvgGenImage('assets/svgs/icon_random.svg');

  /// File path: assets/svgs/icon_rice.svg
  SvgGenImage get iconRice => const SvgGenImage('assets/svgs/icon_rice.svg');

  /// File path: assets/svgs/icon_seafood.svg
  SvgGenImage get iconSeafood =>
      const SvgGenImage('assets/svgs/icon_seafood.svg');

  /// File path: assets/svgs/icon_snacks.svg
  SvgGenImage get iconSnacks =>
      const SvgGenImage('assets/svgs/icon_snacks.svg');

  /// File path: assets/svgs/icon_user.svg
  SvgGenImage get iconUser => const SvgGenImage('assets/svgs/icon_user.svg');

  /// List of all assets
  List<SvgGenImage> get values => [
    iconCoffee,
    iconFastFood,
    iconFavorite,
    iconFavoriteEnable,
    iconHome,
    iconHomeEnable,
    iconNoodles,
    iconRandom,
    iconRice,
    iconSeafood,
    iconSnacks,
    iconUser,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsAnimesGen animes = $AssetsAnimesGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $AssetsSvgsGen svgs = $AssetsSvgsGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}

class SvgGenImage {
  const SvgGenImage(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = false;

  const SvgGenImage.vec(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    _svg.ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
        colorMapper: colorMapper,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter:
          colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
