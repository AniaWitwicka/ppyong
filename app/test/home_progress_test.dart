import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ppyong/models/collection.dart';
import 'package:ppyong/navigation.dart';
import 'package:ppyong/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> collectionJson({int mastered = 0, int learning = 0}) => {
      'id': 'c1',
      'name': '한국어 Chikas',
      'emoji': '🇰🇷',
      'color': '#F296BD',
      'deck_count': 6,
      'word_count': 263,
      'due_count': 0,
      'progress': mastered / 263,
      'mastered_count': mastered,
      'learning_count': learning,
      'can_edit': false,
    };

void main() {
  test('collection counts come from the API, and default to 0 if missing', () {
    final c = Collection.fromJson(collectionJson(mastered: 3, learning: 14));
    expect(c.masteredCount, 3);
    expect(c.learningCount, 14);
    final old = Collection.fromJson(collectionJson()
      ..remove('mastered_count')
      ..remove('learning_count'));
    expect(old.masteredCount, 0);
    expect(old.learningCount, 0);
  });

  Future<double> segmentWidth(WidgetTester tester, String key) async =>
      tester.getSize(find.byKey(ValueKey(key))).width;

  testWidgets('the bar moves as soon as words are being learned', (tester) async {
    Future<void> pumpBar(Collection c) => tester.pumpWidget(MaterialApp(
          home: Center(
            child: SizedBox(width: 263, child: CollectionProgressBar(collection: c)),
          ),
        ));

    await pumpBar(Collection.fromJson(collectionJson()));
    expect(find.byKey(const ValueKey('learning')), findsNothing);
    expect(find.byKey(const ValueKey('mastered')), findsNothing);

    await pumpBar(Collection.fromJson(collectionJson(learning: 14)));
    expect(await segmentWidth(tester, 'learning'), closeTo(14, 0.5),
        reason: '14 of 263 words studied, none mastered yet');
    expect(find.byKey(const ValueKey('mastered')), findsNothing);

    await pumpBar(Collection.fromJson(collectionJson(mastered: 30, learning: 100)));
    expect(await segmentWidth(tester, 'mastered'), closeTo(30, 0.5));
    expect(await segmentWidth(tester, 'learning'), closeTo(100, 0.5));
  });

  testWidgets('Home reloads its progress after a screen on top of it closes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Wide: the test font draws every letter as a full square.
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var learning = 0;
    var collectionLoads = 0;
    final api = MockClient((req) async {
      final path = req.url.path;
      if (path.endsWith('/collections')) {
        collectionLoads++;
        return http.Response(jsonEncode([collectionJson(learning: learning)]), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
      if (path.endsWith('/me/stats')) {
        return http.Response(
            jsonEncode({'mastered_count': 0, 'learning_count': learning, 'due_count': 0,
                'session_count': 0, 'accuracy_percent': 0, 'weekly_activity': List.filled(7, false)}),
            200);
      }
      if (path.endsWith('/me')) {
        return http.Response(
            jsonEncode({'id': 'u1', 'name': 'Lucy L', 'email': 'l@x.test', 'role': 'learner',
                'streak': 2, 'initials': 'LL'}),
            200);
      }
      return http.Response(path.contains('invite') || path.contains('group') ? '[]' : '{}', 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [appRouteObserver],
        home: const HomeScreen(),
      ));
      await tester.pumpAndSettle();
      final loadsBefore = collectionLoads;
      expect(find.byKey(const ValueKey('learning')), findsNothing);

      // Study somewhere on top of Home…
      tester.state<NavigatorState>(find.byType(Navigator).first).push(
          MaterialPageRoute(builder: (_) => const Scaffold(body: Text('studying'))));
      await tester.pumpAndSettle();
      learning = 14;

      // …and come back.
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(collectionLoads, greaterThan(loadsBefore), reason: 'reloaded on the way back');
    }, () => api);

    expect(find.byKey(const ValueKey('learning')), findsOneWidget);
  });
}
