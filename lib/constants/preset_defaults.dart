import '../models/sentence_template.dart';

const List<String> defaultPresetTags = [
  '开放世界',
  '剧情驱动',
  '肉鸽',
  'PVP',
  'PVE',
  '合作联机',
  '认真推进',
  '悠闲探索',
  '挂机休闲',
  '社交为主',
  '竞技冲分',
  '收集养成',
  '音画优秀',
  '情怀加成',
  '肝',
  '养老',
];

List<SentenceTemplate> get defaultSentenceTemplates => [
      SentenceTemplate(key: 'suitable_for', format: '适合 {tag}'),
      SentenceTemplate(key: 'not_suitable_for', format: '不适合 {tag}'),
      SentenceTemplate(key: 'if_you_like', format: '如果你喜欢 {tag}，值得一试'),
      SentenceTemplate(key: 'watch_out', format: '注意 {tag} 的玩家慎入'),
      SentenceTemplate(key: 'ideal_for', format: '{tag} 玩家的理想选择'),
    ];
