import 'dart:io';
import 'package:flutter/material.dart';

class DiaryImageSlider extends StatefulWidget {
  const DiaryImageSlider({
    super.key,
    required this.images,
    required this.onImageTap,
  });

  final List<String> images;
  final Function(int index) onImageTap;

  @override
  State<DiaryImageSlider> createState() => _DiaryImageSliderState();
}

class _DiaryImageSliderState extends State<DiaryImageSlider> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final path = widget.images[index];
                  final isNetwork = path.startsWith('http');
                  return GestureDetector(
                    onTap: () => widget.onImageTap(index),
                    child: isNetwork
                        ? Image.network(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                            ),
                          )
                        : Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            ),
                          ),
                  );
                },
              ),
            ),
            
            // Left Arrow
            if (widget.images.length > 1)
              Positioned(
                left: 8,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                       _pageController.animateToPage(
                        widget.images.length - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
              
            // Right Arrow
            if (widget.images.length > 1)
              Positioned(
                right: 8,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () {
                    if (_currentPage < widget.images.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
              
            // Current index badge (optional, but dots are standard)
          ],
        ),
        
        // Dots Indicator
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
