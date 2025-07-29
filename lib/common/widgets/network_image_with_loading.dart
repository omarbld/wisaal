import 'package:flutter/material.dart';

class NetworkImageWithLoading extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const NetworkImageWithLoading({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          width: width,
          height: height,
          color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
          child: placeholder ?? Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
          child: errorWidget ?? Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: (width != null && height != null) 
                ? (width! < height! ? width! * 0.4 : height! * 0.4)
                : 40,
          ),
        );
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

class CircularNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const CircularNetworkImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: NetworkImageWithLoading(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: placeholder,
          errorWidget: errorWidget ?? Icon(
            Icons.person_outline,
            size: radius * 1.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class NetworkImageCard extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const NetworkImageCard({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            NetworkImageWithLoading(
              imageUrl: imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
            if (child != null)
              Positioned.fill(
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(178),
                      ],
                    ),
                  ),
                  child: child,
                ),
              ),
          ],
        ),
      ),
    );
  }
}