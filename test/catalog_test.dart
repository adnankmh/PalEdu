import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/models.dart';

void main() {
  test('student track selection covers grade 12', () {
    expect(LessonCatalog.tracksFor(1), ['عام']);
    expect(LessonCatalog.tracksFor(12), hasLength(7));
    expect(LessonCatalog.gradeName(12), contains('التوجيهي'));
  });
  test('catalog rejects unverified official label', () {
    expect(() => LessonCatalog.parse(
      '{"contentStatus":"official","lessons":[]}'), throwsFormatException);
    expect(() => LessonCatalog.parse(
      '{"contentStatus":"demonstration_only","lessons":[]}'), returnsNormally);
  });
  test('rejects invalid quiz answer indices', () {
    expect(() => QuizQuestion.fromJson({
      'prompt': 'سؤال', 'options': ['أ', 'ب'], 'answer': 4,
      'explanation': 'شرح',
    }), throwsFormatException);
  });
}
