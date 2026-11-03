import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/models/match_game.dart';
import 'package:ppyong/screens/matching_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

CardModel card(int i) => CardModel(
      id: 'c$i',
      korean: 'k$i',
      romanisation: '',
      translation: 't$i',
      notes: '',
      status: CardStatus.newCard,
    );

List<CardModel> deck(int n) => [for (var i = 0; i < n; i++) card(i)];

class _Harness {
  final recorded = <MatchGame>[];

  /// Opens MatchingScreen (pushed from a home page, so "Leave" can pop it)
  /// on the setup screen for a deck with [cards].
  Future<void> open(WidgetTester tester, List<CardModel> cards,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchingScreen(
                    deckId: 'd1',
                    deckName: 'Test deck',
                    loadCards: (_) async => cards,
                    recordGame: (_, game) => recorded.add(game),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Picks the settings and starts the game.
  Future<void> start(WidgetTester tester, {int seconds = 60, int pairs = 6}) async {
    await tester.tap(find.text('$seconds s'));
    await tester.tap(find.text('$pairs').first);
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapPair(WidgetTester tester, String a, String b) async {
    await tester.tap(find.text(a));
    await tester.pump();
    await tester.tap(find.text(b));
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// Unmounts the screen so its periodic timer is cancelled before the test ends.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }
}

double opacityOf(WidgetTester tester, String text) => tester
    .widget<AnimatedOpacity>(
        find.ancestor(of: find.text(text), matching: find.byType(AnimatedOpacity)))
    .opacity;

void main() {
  testWidgets('setup shows the deck and defaults, Start deals a board', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(8));

    expect(find.text('Test deck'), findsOneWidget);
    expect(find.text('Ready to match?'), findsOneWidget);
    expect(find.text('60 s'), findsOneWidget);

    await h.start(tester);
    expect(find.text('KOREAN'), findsOneWidget);
    expect(find.text('TRANSLATION'), findsOneWidget);
    // 6 of the 8 cards are on the board, each shown on both sides.
    final onBoard = [for (var i = 0; i < 8; i++) if (find.text('k$i').evaluate().isNotEmpty) i];
    expect(onBoard, hasLength(6));
    for (final i in onBoard) {
      expect(find.text('t$i'), findsOneWidget);
    }
    expect(find.text('60s'), findsOneWidget);
    await h.close(tester);
  });

  testWidgets('correct pair fades out and counts; wrong pair counts a mistake', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(3));
    await h.start(tester);

    await h.tapPair(tester, 'k0', 't1');
    expect(opacityOf(tester, 'k0'), 1.0);
    expect(find.text('1'), findsOneWidget, reason: 'mistakes chip');

    await h.tapPair(tester, 'k0', 't0');
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacityOf(tester, 'k0'), 0.0);
    expect(opacityOf(tester, 't0'), 0.0);
    expect(find.text('1'), findsNWidgets(2), reason: 'matched and mistakes chips');
    await h.close(tester);
  });

  testWidgets('time running out shows the end screen and records the game once', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(8));
    await h.start(tester, seconds: 30);

    final k = find.textContaining(RegExp(r'^k\d$')).evaluate().first.widget as Text;
    final i = k.data!.substring(1);
    await h.tapPair(tester, 'k$i', 't$i');

    await tester.pump(const Duration(seconds: 29));
    expect(find.text("Time's up!"), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text("Time's up!"), findsOneWidget);
    expect(find.text('MATCHED'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(h.recorded, hasLength(1));
    expect(h.recorded.single.matched, 1);
    await h.close(tester);
  });

  testWidgets('clearing the whole deck shows "Deck cleared!"', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(3));
    await h.start(tester);

    for (var i = 0; i < 3; i++) {
      await h.tapPair(tester, 'k$i', 't$i');
    }
    await tester.pump();

    expect(find.text('Deck cleared!'), findsOneWidget);
    expect(find.textContaining('All 3 words matched'), findsOneWidget);
    expect(h.recorded.single.deckFinished, isTrue);
    await h.close(tester);
  });

  testWidgets('next board is dealt after the first one is cleared', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(6));
    await h.start(tester, pairs: 4);

    final first = [for (var i = 0; i < 6; i++) if (find.text('k$i').evaluate().isNotEmpty) i];
    expect(first, hasLength(4));
    for (final i in first) {
      await h.tapPair(tester, 'k$i', 't$i');
    }
    await tester.pump(const Duration(milliseconds: 400));

    final second = [for (var i = 0; i < 6; i++) if (find.text('k$i').evaluate().isNotEmpty) i];
    expect(second, hasLength(2));
    expect(second.toSet().intersection(first.toSet()), isEmpty);
    expect(find.text("Time's up!"), findsNothing);
    await h.close(tester);
  });

  testWidgets('words in two wrong pairs are reported and mentioned', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(3));
    await h.start(tester);

    await h.tapPair(tester, 'k0', 't1');
    await tester.pump(const Duration(milliseconds: 500));
    await h.tapPair(tester, 'k0', 't2');
    await tester.pump(const Duration(milliseconds: 500));
    for (var i = 0; i < 3; i++) {
      await h.tapPair(tester, 'k$i', 't$i');
    }
    await tester.pump();

    expect(h.recorded.single.cardsToReview.map((c) => c.id), ['c0']);
    expect(find.text('1 tricky word will come back sooner in Flashcards'), findsOneWidget);
    await h.close(tester);
  });

  testWidgets('beating the stored best shows "New best!" and saves it', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(3), prefs: {'match_best_d1_60s': 2});
    await h.start(tester);
    for (var i = 0; i < 3; i++) {
      await h.tapPair(tester, 'k$i', 't$i');
    }
    await tester.pump();
    await tester.pump();

    expect(find.text('New best!'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('match_best_d1_60s'), 3);
    await h.close(tester);
  });

  testWidgets('leave dialog pauses the clock; Leave records nothing', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(8));
    await h.start(tester, seconds: 30);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    expect(find.text('Leave the game?'), findsOneWidget);

    // Far past the time limit while the dialog is open: the game must not end.
    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.text('Keep playing'));
    await tester.pump(); // pop starts the dialog's exit animation
    await tester.pump(const Duration(milliseconds: 300)); // ...which then finishes
    expect(find.text('Leave the game?'), findsNothing);
    expect(find.text("Time's up!"), findsNothing);
    expect(find.text('KOREAN'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(h.recorded, isEmpty);
    await h.close(tester);
  });

  testWidgets('a deck with fewer than 2 cards stays on setup', (tester) async {
    final h = _Harness();
    await h.open(tester, deck(1));
    await h.start(tester);

    expect(find.text('Not enough cards'), findsOneWidget);
    expect(find.text('Ready to match?'), findsOneWidget);
    await h.close(tester);
  });
}
