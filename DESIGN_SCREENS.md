# Ppyong — Screen Design Reference

This file documents all designed screens and UI patterns.
Add to your repo under `/docs/DESIGN_SCREENS.md`.
Reference this when implementing Flutter screens.

---

## Screens overview

| Screen | Status | Tab |
|--------|--------|-----|
| Home | ✅ Designed | Home |
| Library | ✅ Designed | Library |
| Deck detail | ✅ Designed | Library |
| Flashcard study (picker + session) | ✅ Designed | Learn |
| Profile | ✅ Designed | Profile |
| Add collection (bottom sheet) | ✅ Designed | Library |
| Add deck (bottom sheet) | ✅ Designed | Library |
| Add flashcard (bottom sheet) | ✅ Designed | Library |
| Learn tab / feature selector | ⏳ Not yet designed | Learn |
| Onboarding / login | ⏳ Not yet designed | — |

---

## 1. Home screen

### Layout
- **Header band** — full-width periwinkle `#99B7F5` background
  - Left: Ppyong logo (36px) + greeting "안녕하세요," + user name (22px, Nunito 800)
  - Right: avatar circle (40px, ink `#1A1A2E` bg, periwinkle initials)
- **Stats row** — 3 cards, pulled up overlapping the header (margin-top: -14px)
  - Streak card: yellow `#FCCA59` bg, "7 days 🔥"
  - Due card: bubblegum `#F296BD` bg, "12 words today"
  - Mastered card: forest green `#267F53` bg, white text
- **Resume card** — full-width orange `#F5793B`, white text, "Go" button (white bg, orange text, pill shape)
- **Collections section** — "My collections" heading + "See all" link (periwinkle)
- **Collection cards** — white bg, colored border (2px, matches collection color), emoji icon, title, deck count, progress bar, mini avatars (each friend gets their own palette color), due badge
- **Companion** — floating overlay bottom-right, above nav bar (see companion section below)

### Collection card colors
Each collection gets one of the 5 palette colors as its identity:
- Border color = collection color
- Icon container bg = collection color
- Progress bar fill = collection color
- Progress bar bg = pale tint of collection color

### Bottom nav
Active: Home icon filled `#99B7F5`, label `#1A3A7A`

---

## 2. Library screen

### Layout
- **Header band** — periwinkle `#99B7F5`
  - Title "Library" (24px, Nunito 800, ink)
  - Search bar below (white bg, rounded 14px, placeholder "Search collections...")
- **Filter pills** — horizontal scroll row below header
  - Active: `#99B7F5` bg, ink text
  - Inactive: white bg, `#E8E4DE` border, ash text
  - Options: All · In progress · Mastered · New
- **Collection rows** — list (not cards grid), each row:
  - 48px emoji icon container (colored, rounded 16px)
  - Title (15px, 800) + subtitle "X decks · Y words"
  - Progress bar (5px height)
  - Right side: due badge + chevron arrow
- **FAB** — orange `#F5793B`, bottom-right, 52px circle, white + icon, shadow
  - Tapping FAB opens "Add collection" bottom sheet

### Bottom nav
Active: Library icon filled `#99B7F5`, label `#1A3A7A`

---

## 3. Deck detail screen

### Layout
- **Top bar** — back button (white card, 36px, chevron), breadcrumb text (collection name), "Edit deck" button (periwinkle tint bg `#EEF3FE`, ink text)
- **Hero section**
  - Deck title (22px, 800)
  - Meta pills: word count (periwinkle tint), week tag (pink tint), "Added by teacher" (fog)
  - Progress bar — 3 segments: green (mastered) + periwinkle (learning) + gray (new)
  - Legend row below bar
  - SRS chips row (3 chips): Mastered (green bg), Learning (periwinkle bg), New (fog bg)
  - Action buttons: "Study now" (orange, full) + "Preview cards" (white, bordered) side by side
- **Divider**
- **Cards list header** — "All cards" + "Sort by status" ghost button
- **Card rows** — expandable on tap
  - Left: 8px status dot (green = mastered, periwinkle = learning, gray = new)
  - Korean text (16px, 800) + romanisation (12px, fog) + translation (13px, ash)
  - Right: chevron (periwinkle when expanded, fog when collapsed)
  - Expanded: notes text appears below translation, card gets periwinkle border + pale blue bg `#F8FAFF`

### Bottom nav
Active: Library tab

---

## 4. Flashcard study screen

### Sub-screen A — Direction picker
- Back button + deck name breadcrumb
- "Ready to study?" heading + card count subtitle
- **Direction selector** (two options, radio-style):
  - Selected: periwinkle border (2px), periwinkle check circle
  - Unselected: fog border (0.5px), empty gray circle
  - Options: "Korean → Translation" / "Translation → Korean"
- **Scope selector** (3 pills):
  - Selected: periwinkle `#99B7F5` bg
  - Unselected: white + fog border
  - Options: All cards (12) · Due today (5) · Weak words (3)
- "Start studying" CTA — full-width orange pill button

### Sub-screen B — Study session
- **Top bar**: back button + progress bar (periwinkle fill on fog track) + card counter + score chips (green knew / pink again)
- **Swipe hints** — "← Didn't know" (pink) and "Knew it →" (green), low opacity until card is flipped
- **Flashcard** — white card, 28px radius, 240px height
  - Front: language tag pill + main text (32px, 800) + romanisation + "Tap to reveal" hint (periwinkle)
  - Back (after tap flip animation): translation in orange `#F5793B` (22px, 800) + notes in ash
  - Flipped state: periwinkle border
- **Overlay feedback**: green `#E8F5EE` slides in from right ("Knew it!"), pink `#FEF0F6` from left ("Keep trying")
- **Action buttons** (appear after flip):
  - "Again" — pink tint bg `#FEF0F6`, pink text, left arrow icon
  - "Knew it" — green tint bg `#E8F5EE`, green text, right arrow icon

### Sub-screen C — Session complete
- Yellow star icon in yellow squircle `#FCCA59`
- "Session complete!" heading
- Knew / Again score cards (green + pink)
- "Study again" orange button

### Animations
- Card flip: `perspective(600px) rotateY()` — out 180ms, in 180ms
- Swipe right: `translateX(120%) rotate(12deg)` 320ms
- Swipe left: `translateX(-120%) rotate(-12deg)` 320ms
- Card load: slide in from right 250ms

---

## 5. Profile screen

### Layout
- **Header band** — sunny yellow `#FCCA59`
  - Avatar (72px circle, ink bg, yellow initials, white border 4px)
  - Name (20px, 800) + email (13px, dark yellow)
  - Role badge — ink bg, yellow text pill ("Learner" or "Teacher")
- **Streak banner** — orange `#F5793B`, full width card
  - Left: "Current streak" label + "7 days 🔥" (32px, 800, white) + "Best: X days"
  - Right: mini weekly calendar (7 day dots — white = studied, 30% opacity = missed) + day labels
- **Stats grid** — 2×2 grid
  - Mastered: green bg `#E8F5EE`
  - Learning: periwinkle bg `#EEF3FE`
  - Sessions: yellow bg `#FEF9E8`
  - Accuracy: pink bg `#FEF0F6`
- **Settings section**
  - Section label: "SETTINGS" (uppercase, fog, 11px)
  - Each row: white bg, rounded 16px, icon container (32px, colored) + label + right element
  - Edit profile → chevron
  - Notifications → green toggle (on by default)
  - Study reminder → time string + chevron
  - Weak words → pink badge with count + chevron
- **Account section**
  - Sign out row: pink border (1.5px `#F296BD`), pink icon + text

### Bottom nav
Active: Profile icon filled `#FCCA59`, label `#7A5500`

---

## 6. Add collection — bottom sheet

### Trigger
FAB (+ button) on Library screen

### Content
- Sheet handle (36px wide, 4px tall, fog)
- Title "New collection" (18px, 800)
- **Name** input field
- **Description** input field (optional)
- **Color picker** — 5 dots (32px circles), one per palette color, selected state: 3px ink border
  - Colors: `#99B7F5` · `#267F53` · `#F5793B` · `#F296BD` · `#FCCA59`
- **Emoji picker** — row of emoji options (📚 🏠 🍜 🚇 💬 ⭐), selected gets colored bg
- Buttons: "Create collection" (orange primary) + "Cancel" (ghost)

### Behavior
- Tapping outside / Cancel dismisses sheet
- Color selected becomes the collection's identity color (border, icon, progress bar)

---

## 7. Add deck — bottom sheet

### Trigger
FAB on Library screen (after selecting "New deck" from a picker, or from within a collection)

### Content
- Title "New deck"
- **Deck name** input
- **Description** input (optional)
- **Add to collection** — styled dropdown showing currently selected collection (colored icon + name)
- Buttons: "Create deck" (orange) + "Cancel" (ghost)

---

## 8. Add flashcard — bottom sheet

### Trigger
From within a deck detail screen — FAB or "Add card" button

### Content
- Title "New flashcard" + card counter badge ("Card 13 of deck") — periwinkle tint
- **Korean (한국어)** — larger input (18px, 700) — primary field
- **Romanisation** — standard input
- **Translation** — standard input
- **Notes / example sentence** — optional, standard input
- Two buttons side by side:
  - "Save & close" — ghost button (for adding a single card)
  - "Save & add next" — orange button (for batch adding, clears form and keeps sheet open)

### Key UX note
"Save & add next" is critical for the teacher workflow — adding 15–20 words in one session without reopening the sheet each time.

---

## Companion overlay

### Present on: Home screen (and potentially all screens in future)

### Structure
- Floating `Stack` + `Positioned` widget, bottom-right corner
- Above bottom nav (bottom: 84px, right: 16px)
- **Speech bubble** — white bg, periwinkle border, rounded 18px 18px 4px 18px
  - Dismiss × button: fog circle, top-right of bubble
  - Message text (13px, 700) + subtitle (11px, ash)
  - Appears with scale + translateY animation
- **Character button** — 58px circle, orange `#F5793B` bg, white border (3px)
  - Toggles bubble on tap
  - Floats with `translateY` animation (3s loop)
  - Character SVG inside (placeholder blob — real character TBD)

### Future character moods (map from app state)
```dart
enum CompanionMood { happy, celebrating, sleepy, encouraging, sad }

// Logic
CompanionMood resolveMood(AppState state) {
  if (state.justCompletedSession) return CompanionMood.celebrating;
  if (state.streakDays == 0)      return CompanionMood.sad;
  if (state.dueCards > 10)        return CompanionMood.encouraging;
  if (state.hoursSinceStudy > 20) return CompanionMood.sleepy;
  return CompanionMood.happy;
}
```

---

## Input field style (reusable)

```
bg:           #ffffff
border:       1.5px solid #E8E4DE
border-focus: 1.5px solid #99B7F5
border-radius: 14px
padding:      12px 14px
font-size:    14px
font-weight:  600
color:        #1A1A2E
placeholder:  #B8B4C0
```

---

## Bottom sheet style (reusable)

```
background:    #FFFDF9
border-radius: 28px 28px 0 0
padding:       8px 20px 32px
gap between elements: 14px
handle: 36×4px, #E8E4DE, centered, margin-bottom 4px
overlay bg: rgba(26, 26, 46, 0.4)
animation: slide up 250ms ease-out
```

---

## Screens not yet designed

### Login / onboarding
- Needs: welcome screen, email input, role selection (learner vs teacher)
- Suggestion: single page with Ppyong logo large, email + password, Google SSO

### Learn tab — feature selector
- Grid of learning mode cards
- For now: just "Flashcards" card (active) + placeholder cards for future modes
- Each mode card: colored bg, icon, name, description, "coming soon" badge for unbuilt ones

### Game modes
- Not yet scoped — future sprint
- Possible modes: word match, multiple choice quiz, typing challenge

---

## 9. Login / Register screen

### Structure
Single screen with a toggle between Log in and Register — no separate screens.

### Layout
- **Hero band** — full-width periwinkle `#99B7F5`
  - Ppyong logo (72px) centered
  - App name "Ppyong" (26px, 800) + tagline "Korean learning, together" (14px, periwinkle dark)
- **Toggle** — pill-shaped track (`#F0EDE8` bg), two buttons: "Log in" and "Register"
  - Active: white card, ink text, subtle shadow
  - Inactive: transparent, fog text
- **Forms** — switch on toggle tap, no page navigation

### Log in form
- Email input
- Password input (with show/hide eye icon)
- "Forgot password?" link — right aligned, periwinkle
- "Log in" CTA — full-width orange pill button
- "Don't have an account? Register" link at bottom

### Register form
- Name input
- Email input
- Password input (with show/hide)
- Confirm password input
- Info note (periwinkle tint bg `#EEF3FE`): "You'll join as a Member. Your study group admin can update your role after you join."
- "Create account" CTA — full-width orange pill button
- "Already have an account? Log in" link at bottom

### Role assignment
- Everyone registers as **Member** by default
- **Teacher** role assigned manually by Admin (flag in Supabase)
- **Admin** role assigned manually in DB — not exposed in UI

---

## 10. Forgot password screen

### Structure
Separate screen, accessed from "Forgot password?" link on login.

### Layout
- **Header band** — periwinkle `#99B7F5`
  - Back button (semi-transparent white square, chevron icon)
  - Title "Reset password"
- **Body**
  - Heading "Forgot your password?" (18px, 800)
  - Subtitle explaining a reset link will be sent (14px, ash)
  - Email input field
  - "Send reset link" CTA — orange pill
  - "Back to login" ghost button

### Success state
After sending — green confirmation card appears:
- Green circle check icon + "Email sent!" + "Check your inbox for the reset link"
- Background `#E8F5EE`, text `#1A5C3A` / `#267F53`

---

## 11. Deck sharing popup

### Trigger
"Share" button on deck detail screen (or from deck options menu)

### Structure
Centered popup/dialog — `showDialog` in Flutter.
Overlay: `rgba(26, 26, 46, 0.5)`, popup border-radius 24px.

### Layout
- **Header** — title "Share deck with" + deck name subtitle + × close button (fog circle)
- **Selected chips row** — appears when at least one person is selected
  - Each chip: avatar dot + name + × to deselect
  - Color: periwinkle `#99B7F5` bg, dark blue text
  - Hidden when no one selected
- **Search bar** — `#F0EDE8` bg, rounded 12px, search icon + text input
  - Filters member list in real time
  - "No one found" empty state if no matches
- **Member list** — scrollable, max-height 280px
  - Unselected row: `#E8E4DE` border, white bg
  - Selected row: `#99B7F5` border (2px), `#EEF3FE` bg, blue filled checkbox
  - Teacher row: `#FCCA59` border, always checked, non-interactive, "Always included" label
- **Footer CTA button**
  - 0 selected: disabled gray "Select people to share with"
  - 1 selected: "Share with [Name]"
  - 2+ selected: "Share with X people"

### Behavior
- Tapping a row toggles selection
- Tapping × on a chip deselects that person
- Search filters all rows including teacher
- Teacher always pre-selected and cannot be deselected
- On save: selected members get Viewer access by default

---

## Role & permission model

### Account roles (app-wide)
| Role    | Access |
|---------|--------|
| Admin   | Full access — all groups, all users, all decks, user management |
| Teacher | Manages their group's collections and decks, sees group progress |
| Member  | Studies shared decks, can create and share their own decks |

### Per-deck access
| Level  | Can do |
|--------|--------|
| Owner  | Full control — edit, delete, share |
| Viewer | Study only, read-only |

### Role assignment rules
- All new registrations → Member
- Teacher → assigned manually by Admin in Supabase
- Admin → assigned directly in DB, not in UI
- Teachers always have Editor access to all decks in their group

---

## 12. Toast notifications

### Overview
Toasts are temporary feedback messages that slide in from the top of the screen, auto-dismiss after 3.5 seconds, and can be tapped to dismiss early. Used for any action result — success, error, info, or warning.

### Position
Top of screen, below status bar — `top: 70px`, left/right margin `16px`.

### Structure
```
[icon circle] [title + subtitle]  [× close]
```
- Border radius: 16px
- Padding: 12px 14px
- Gap between elements: 10px
- Icon: 32px circle with semi-transparent or colored bg
- Title: 13px, 800, colored per variant
- Subtitle: 11px, 600, 80% opacity
- Close ×: 14px, 800, 50% opacity, tappable

### Variants

| Variant | Bg | Shadow | Use case |
|---------|-----|--------|----------|
| Success | `#267F53` | `rgba(38,127,83,0.3)` | Deck shared, card saved, session complete |
| Error | `#1A1A2E` | `rgba(26,26,46,0.3)` | Failed action, network error |
| Info | `#99B7F5` | `rgba(153,183,245,0.35)` | Auto-save, neutral confirmation |
| Warning | `#FCCA59` | `rgba(252,202,89,0.35)` | Streak at risk, incomplete form |

### Success toast
- Bg: `#267F53`, icon bg: `rgba(255,255,255,0.2)`, checkmark icon
- Title: white, subtitle: `#A8D9C0`
- Examples: "Deck shared!", "Card saved", "Session complete!"

### Error toast
- Bg: `#1A1A2E`, icon bg: `#F296BD`, exclamation icon
- Title: white, subtitle: `#B8B4C0`
- Examples: "Something went wrong", "Couldn't save. Try again."

### Info toast
- Bg: `#99B7F5`, icon bg: `rgba(255,255,255,0.25)`, info circle icon
- Title: `#1A1A2E`, subtitle: `#1A3A7A`
- Examples: "Deck saved", "Changes applied"

### Warning toast
- Bg: `#FCCA59`, icon bg: `rgba(255,255,255,0.3)`, triangle warning icon
- Title: `#1A1A2E`, subtitle: `#7A5500`
- Examples: "Streak at risk!", "You have 12 words due"

### Animation
- Slide in: `translateY(-20px) → translateY(0)`, opacity 0→1, 250ms ease-out
- Auto-dismiss: after 3500ms
- Slide out: `translateY(-8px)`, opacity 1→0, 300ms ease-out
- Tap to dismiss early

### Flutter implementation note
Use `fluttertoast` or `awesome_snackbar_content` package, or build a custom overlay widget with `OverlayEntry`. Avoid the default Flutter `SnackBar` — it appears at the bottom and doesn't match this design.

### When to use each variant
- **Shared deck** → Success: "Deck shared! [Names] can now study this deck"
- **Failed share** → Error: "Couldn't share the deck. Try again."
- **Saved card/deck** → Info: "Changes saved"
- **Deleted card** → Success: "Card removed" (with optional undo action)
- **Streak warning** → Warning: "Study today to keep your X day streak"
- **Network offline** → Error: "No connection. Changes will sync when you're back online."