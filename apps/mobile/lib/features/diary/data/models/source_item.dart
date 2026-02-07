import 'dart:io';
import 'package:mobile/features/diary/data/models/diary.dart';

class SourceItem {
  final DiarySource source;
  final DateTime dateTime;
  final File? imageFile;
  final String? imagePath;
  
  SourceItem(this.source, this.dateTime, {this.imageFile, this.imagePath});

  SourceItem copyWith({DiarySource? source, DateTime? dateTime, File? imageFile, String? imagePath}) {
    return SourceItem(
      source ?? this.source,
      dateTime ?? this.dateTime,
      imageFile: imageFile ?? this.imageFile,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
