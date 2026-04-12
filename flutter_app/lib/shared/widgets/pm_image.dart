import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// 统一网络图片组件，磁盘缓存 + 占位符。
/// 替代 Image.network，解决每次重启重新下载的问题。
class PmImage extends StatelessWidget {
  const PmImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final Widget image = (url == null || url!.isEmpty)
        ? _buildPlaceholder()
        : CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, _) => _buildPlaceholder(),
            errorWidget: (_, _, _) => _buildError(),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: AppColors.primaryLight,
        );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryLight,
      child: const Icon(Icons.broken_image_outlined,
          color: AppColors.textSecondary, size: 20),
    );
  }
}

/// 用于 CircleAvatar / BoxDecoration backgroundImage 场景的 ImageProvider。
/// 替代 NetworkImage。
class PmImageProvider extends CachedNetworkImageProvider {
  const PmImageProvider(super.url);
}
