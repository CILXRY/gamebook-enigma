class TagFill {
  String sentenceKey;
  String tag;

  TagFill({
    required this.sentenceKey,
    required this.tag,
  });

  Map<String, dynamic> toJson() => {
        'sentenceKey': sentenceKey,
        'tag': tag,
      };

  factory TagFill.fromJson(Map<String, dynamic> json) {
    return TagFill(
      sentenceKey: json['sentenceKey'] as String,
      tag: json['tag'] as String,
    );
  }
}
