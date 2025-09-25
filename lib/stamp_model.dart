import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stamp_model.g.dart';

@JsonSerializable()
class Stamp {
  String text;
  int colorValue;
  double fontSize;
  bool isBold;
  String shape; // 'rectangle' or 'circle'

  Stamp({
    required this.text,
    this.colorValue = 0xFF000000, // Negro por defecto
    this.fontSize = 24.0,
    this.isBold = true,
    this.shape = 'rectangle',
  });

  factory Stamp.fromJson(Map<String, dynamic> json) => _$StampFromJson(json);
  Map<String, dynamic> toJson() => _$StampToJson(this);
}
