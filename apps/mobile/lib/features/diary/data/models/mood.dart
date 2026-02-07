import 'package:freezed_annotation/freezed_annotation.dart';

enum Mood {
  happy('happy', '😊', '행복해요'),
  sad('sad', '😢', '슬퍼요'),
  peaceful('peaceful', '😌', '평온해요'),
  angry('angry', '😤', '화나요'),
  tired('tired', '😴', '피곤해요'),
  loved('loved', '🥰', '사랑해요');

  const Mood(this.value, this.emoji, this.label);
  final String value;
  final String emoji;
  final String label;
}
