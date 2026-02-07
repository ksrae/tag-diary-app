import 'dart:io';
import 'package:flutter/material.dart';

class DiaryGalleryScreen extends StatefulWidget {
  const DiaryGalleryScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<DiaryGalleryScreen> createState() => _DiaryGalleryScreenState();
}

class _DiaryGalleryScreenState extends State<DiaryGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isGridView = false; // Toggle between full screen (pageview) and grid view

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_carousel : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _isGridView 
          ? _buildGridView() 
          : _buildFullScreenView(),
    );
  }

  Widget _buildFullScreenView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.images.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
      },
      itemBuilder: (context, index) {
        final path = widget.images[index];
        final isNetwork = path.startsWith('http');
        
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: isNetwork
                ? Image.network(
                    path,
                    fit: BoxFit.contain,
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.contain,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        final path = widget.images[index];
        final isNetwork = path.startsWith('http');
        final isSelected = index == _currentIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              _isGridView = false;
              _currentIndex = index;
              _pageController = PageController(initialPage: index);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              isNetwork
                  ? Image.network(path, fit: BoxFit.cover)
                  : Image.file(File(path), fit: BoxFit.cover),
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 3),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
