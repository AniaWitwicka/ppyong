import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ppyong/screens/collection_detail_screen.dart';

final _decks = MockClient((req) async => http.Response(
    jsonEncode([
      {
        'id': 'd1',
        'name': 'Jedzenie',
        'card_count': 10,
        'mastered_count': 2,
        'learning_count': 3,
        'new_count': 5,
      }
    ]),
    200));

Future<void> openCollection(WidgetTester tester, {required bool canEdit}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await http.runWithClient(() async {
    await tester.pumpWidget(MaterialApp(
      home: CollectionDetailScreen(
        collectionId: 'c1',
        collectionName: '한국어 Chikas',
        accentColor: Colors.blue,
        canEdit: canEdit,
      ),
    ));
    await tester.pumpAndSettle();
  }, () => _decks);
}

void main() {
  testWidgets('someone the collection is shared with gets no Share or + buttons',
      (tester) async {
    await openCollection(tester, canEdit: false);
    expect(find.text('Jedzenie'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('the owner gets Share on the collection and each deck, and +',
      (tester) async {
    await openCollection(tester, canEdit: true);
    expect(find.text('Jedzenie'), findsOneWidget);
    expect(find.text('Share'), findsNWidgets(2));
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
