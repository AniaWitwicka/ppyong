# Matching game — implementation plan

Status: plan, not started. Replaces the "Matching — coming soon" card on the Learn tab.

## The game

- Two columns on one board: **Korean** tiles on the left, **translation** tiles on the right, each column shuffled on its own.
- Tap a tile on one side, then a tile on the other side (either order). Tapping a second tile on the same side just moves the selection.
  - **Right pair** → both tiles turn green, pop, then fade out and stop being tappable.
  - **Wrong pair** → both tiles flash pink and shake; mistakes +1; selection clears.
- A **countdown** runs for the whole game. When a board is cleared, the next board is dealt straight away with new words from the deck.
- The game ends when **time runs out** or **every card in the deck has been matched** (whichever is first). Finishing the deck early is a "perfect run" and shows the time left.
- Score = pairs matched. End screen shows pairs matched, mistakes, accuracy and the best score for that deck.

### Settings (picked before starting, defaults in bold)

| Setting | Options |
|---|---|
| Time limit | 30 s · **60 s** · 90 s |
| Pairs per board | 4 · 5 · **6** |

Wrong matches cost no time in v1 — mistakes only lower accuracy. (Easy to add a −2 s penalty later if it feels too forgiving.)

## Rules for dealing boards

- Draw cards from the deck in random order without repeats; deal `min(pairsPerBoard, cardsLeft)` per board.
- **Duplicate translations:** two cards can share a translation — the live deck *Codzienne sprawy* has 고치다 and 수리하다, both "naprawiać". Never put two cards with the same translation on one board, and treat a pair as correct when the translation **text** matches, not only the card id.
- Decks with fewer than 2 cards → the same "Not enough cards" toast the multiple-choice quiz uses.
- Long text (translations up to 40 characters, e.g. "zakaz wnoszenia jedzenia"): tiles wrap to max 3 lines and shrink the font a step instead of overflowing.

## Study progress (SRS)

Decided 2026-11-03: **only mistakes count, and games count toward the streak.**

- Correct matches never change word progress — recognising a word among 6 options is a weak signal.
- A card that is part of **2 or more wrong pairs in one game** is sent as "didn't know" (`POST /cards/{id}/review` with `knew_it: false`) when the game ends, so it comes back sooner in Flashcards. Both cards of a wrong pair count, since either word may be the unknown one. The end screen says "N tricky words will come back sooner in Flashcards".
- Every finished game with at least one match calls `POST /practice`, which updates the streak exactly like a review does and writes a `match` activity entry ("Alicja matched 18 words in Dom i mieszkanie") to each of the player's groups.
- Leaving mid-game sends nothing. All calls are fire-and-forget: a network error never blocks the end screen.
- **Release order:** backend first (it adds `POST /practice`), then the app. The old app shows unknown activity kinds as "is struggling with…", but only the new app creates `match` entries, so this order is safe.

## Screens

Identity colour: **Bubblegum `#F296BD`** (already used for the Matching card on the Learn tab), corner tint `#FEF0F6`.

1. **Deck picker** — the same collection → deck list the multiple-choice quiz uses.
2. **Setup** — deck name, time limit chips, pairs-per-board chips, "Start" orange pill.
3. **Board**
   - Top bar: back button · countdown bar (bubblegum fill on fog track, turns orange under 10 s) · seconds left · score chip (pairs matched) · mistakes chip.
   - Two columns of tiles: white, 2 px `#E8E4DE` border, 18 px radius. Korean tiles use the Korean font fallback (Noto Sans KR), translations DM Sans.
   - Selected: periwinkle border + tint. Correct: green `#267F53` border, `#E8F5EE` bg, scale pop. Wrong: pink `#C45A8A` border, `#FEF0F6` bg, shake (same animations as multiple choice §16).
   - Back mid-game → "Leave the game?" confirm; the timer pauses while the dialog is open and while the browser tab/app is in the background.
4. **End screen** — 🎉 (perfect run) or ⏱️ (time's up) squircle, three stat cards (Matched · Mistakes · Accuracy), "New best!" badge when beaten, "Play again" orange pill (same deck and settings), "Back to study modes" ghost button.

## Implementation steps

### Phase 1 — game in the app (Flutter only, no backend changes)

1. **Share the deck picker.** Move `_DeckPickerScreen`, `_CollectionSection` and `_DeckRow` out of `app/lib/screens/multiple_choice_screen.dart` into `app/lib/widgets/deck_picker.dart` (public `DeckPicker(onDeckSelected:)`), and use it from the quiz. No behaviour change. (The flashcard screen has its own copy; leave it for a separate cleanup.)
2. **Game logic as plain Dart** — `app/lib/models/match_game.dart`, no widgets, so it can be unit-tested:
   - `MatchGame(cards, pairsPerBoard, rng)` → `dealBoard()`, `select(tile)`, `result` (matched / mistakes / done), duplicate-translation rule above.
3. **Screen** — `app/lib/screens/matching_screen.dart`, same shape as `MultipleChoiceScreen`: `enum _Phase { pick, setup, loading, playing, complete }`, optional `deckId`/`deckName` to skip the picker. Countdown with `Timer.periodic` (100 ms) driving the bar; `WidgetsBindingObserver` to pause in the background.
4. **Best score** — `shared_preferences` key `match_best_<deckId>_<seconds>s`, stored locally per device.
5. **Wire up**
   - `app/lib/screens/learn_screen.dart`: replace the Matching `_ComingSoonCard` with an active `_ModeCard` (bubblegum, tags "Timed" · "Pairs", opens `MatchingScreen`).
   - `app/lib/screens/deck_detail_screen.dart`: add a "Match" button next to "Multiple choice".
6. **Docs** — add the screen spec as §21 in `DESIGN_SCREENS.md`, and the checklist to `TASKS.md`.

### Phase 2 — tests and release

7. **Unit tests** — `app/test/match_game_test.dart`: dealing never repeats a card; never two equal translations on one board; correct/wrong pair handling; last board smaller than `pairsPerBoard`; game ends when the deck runs out.
8. **Widget test** — `app/test/matching_screen_test.dart`: board renders, a correct pair disappears, a wrong pair increments mistakes, timer reaching 0 shows the end screen (fake async clock). Replaces the empty placeholder in `widget_test.dart`.
9. **Test locally — required before any deploy** (the app has real users). Local backend + web build against the real database, phone-size window:
   - `flutter analyze` has no errors, `flutter test` passes, `build/web` has its fonts and icons.
   - **New game:** play full games on *Dom i mieszkanie* (60 s and 30 s), run out the clock, clear a whole small deck for the perfect-run screen, check *Codzienne sprawy* for the duplicate-translation case, leave mid-game via back, play again, best score saved.
   - **Nothing else broke:** log in · home + collections · Learn → Flashcards both directions (card flips to the other language) · Multiple choice · deck detail (all three study buttons) · Groups · teacher view switch.
   - Don't rate flashcards during the smoke test — it's the real database.
10. **Release** — only after step 9 passes: Vercel preview → check the preview → promote with your OK, as with the flashcard fix.

### Phase 3 — streak + tricky words (done in the same branch)

11. Backend `POST /practice` (`{ deck_id, mode: "match", matched, mistakes }`) → streak + `match` activity per group; `SRSRepository.touchStreak` now shared with reviews.
12. App: `CardService.logPractice`, `MatchGame.cardsToReview`, game end sends both; teacher dashboard + group teacher view show `match` events with their own icon and wording.

## Open questions

- Should wrong taps cost time (e.g. −2 s)? Default: no.
- Grammar deck: its "words" are patterns like `-(으)ㄹ지 모르겠다` — playable, but maybe hide it from the picker for this mode?
