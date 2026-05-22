class SentenceTemplate {
  String key;
  String format;

  SentenceTemplate({
    required this.key,
    required this.format,
  });

  String render(String tag) => format.replaceAll('{tag}', tag);

  Map<String, dynamic> toJson() => {
        'key': key,
        'format': format,
      };

  factory SentenceTemplate.fromJson(Map<String, dynamic> json) {
    return SentenceTemplate(
      key: json['key'] as String,
      format: json['format'] as String,
    );
  }
}
