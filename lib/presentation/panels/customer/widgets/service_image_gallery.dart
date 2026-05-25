import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image carousel for service detail (Task 6.3.2).
class ServiceImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final String fallbackTitle;

  const ServiceImageGallery({
    super.key,
    required this.imageUrls,
    required this.fallbackTitle,
  });

  @override
  State<ServiceImageGallery> createState() => _ServiceImageGalleryState();
}

class _ServiceImageGalleryState extends State<ServiceImageGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    if (urls.isEmpty) {
      return Container(
        height: 220,
        color: Colors.blue.shade50,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_not_supported, size: 64, color: Colors.blue),
              const SizedBox(height: 8),
              Text(widget.fallbackTitle),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: urls[i],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
        if (urls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? Colors.blue : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
