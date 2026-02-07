import 'package:freezed_annotation/freezed_annotation.dart';

enum Mood {
  happy('happy', '😊', '행복해요', '오늘은 행복한 하루야.'),
  sad('sad', '😢', '슬퍼요', '오늘은 조금 슬픈 하루였어.'),
  peaceful('peaceful', '😌', '평온해요', '오늘은 평온한 하루였어.'),
  angry('angry', '😤', '화나요', '오늘은 좀 화나는 일이 있었어.'),
  tired('tired', '😴', '피곤해요', '오늘은 정말 피곤한 하루였어.'),
  loved('loved', '🥰', '사랑해요', '오늘은 사랑이 넘치는 하루야.');

  const Mood(this.value, this.emoji, this.label, this.phrase);
  final String value;
  final String emoji;
  final String label;
  final String phrase;
}
