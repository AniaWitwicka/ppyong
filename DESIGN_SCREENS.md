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

---

## 13. Groups tab

### Overview
A dedicated 5th tab in the bottom nav — the social hub of the app. Houses group management, friend list, and invites. Uses bubblegum pink `#F296BD` as its identity color.

### Updated bottom nav
```
Home · Learn · Library · Groups · Profile
```
- Groups icon: two overlapping people circles, filled `#F296BD` when active
- Badge: orange circle with white count number, top-right of icon — shows pending invite count
- Active label color: `#C45A8A`

### Tab structure
Three views inside the Groups tab, switched via a segmented control in the header:
```
My groups | Friends | Invites (badge)
```
- Segmented control sits inside the pink header band
- Active segment: white pill, ink text, subtle shadow
- Inactive: transparent, fog text
- Invites segment shows pending count badge when > 0

---

### 13a. My groups view

#### Layout
- **Header band** — bubblegum pink `#F296BD`
  - Title "Groups" (24px, 800)
  - Segmented control below
- **Group cards** — white bg, colored border (2px), emoji icon (46px rounded square), name + member/deck count, overlapping member avatars (28px, -8px overlap), last active timestamp
- **Create group card** — dashed pink border `#F296BD`, pink bg tint `#FEF0F6`, + icon circle, "Create a new group" label
- **FAB** — orange, bottom-right, opens create group sheet

#### Group card colors
Each group gets one of the 5 palette colors as its identity (same as collections).

---

### 13b. Friends view

#### Layout
- Search bar at top (`#F0EDE8` bg, rounded 12px)
- **Friend rows** — white bg, `#E8E4DE` border, 38px avatar, name + group membership label, stat badge on right
  - Stat badge examples: "7 day streak 🔥" (green), "34 words" (periwinkle), "12 words due" (pink)
  - Teacher friends show yellow "Teacher" badge
- **"Add a friend" row** — orange border `#F5793B`, orange bg tint, orange + icon, orange text — always pinned at bottom of list

---

### 13c. Invites view

#### Layout
Two sections with uppercase fog labels: "Incoming" and "Sent"

**Incoming invite row:**
- Sender avatar + "X invited you to" + group name (colored) + member/deck count
- Two buttons stacked right: "Accept" (green filled) + "Decline" (ghost)
- Row border: `#267F53`, bg: `#F0FBF5`

**Sent invite row:**
- Gray avatar (?) for unregistered invitee, email address, "Invited to [group]" label
- "Pending" badge: yellow tint bg, dark yellow text
- Row opacity: 70%

**Info chip** at bottom: periwinkle tint, "Invites expire after 7 days"

---

### 13d. Create group — bottom sheet

#### Trigger
FAB on My groups view, or dashed "Create a new group" card

#### Content
- Title "New group"
- Group name input
- Emoji picker row (🇰🇷 📚 ✏️ 🎯 💬) — selected gets colored bg
- "Create group" orange button + "Cancel" ghost button

---

### 13e. Add friend — bottom sheet

#### Trigger
"Add a friend" row in Friends view

#### Content
- Title "Add a friend"
- Segmented control: "Search name" | "Invite by email"

**Search name tab:**
- Search input (`#F0EDE8` bg)
- "Type to search Ppyong users" hint when empty
- Results appear below as friend rows (tap to send friend request)

**Invite by email tab:**
- Email input field
- "Invite to group" dropdown — shows current group with emoji + name, periwinkle border when selected
- "Send invite" orange button

---

## 14. Group detail screen

### Trigger
Tapping a group card in My groups view

### Layout
- **Header band** — bubblegum pink `#F296BD`
  - Back button (semi-transparent white square)
  - Emoji + group name (18px, 800) + member/deck count
  - Three-dot menu button (semi-transparent circle) — edit group, leave group
  - **Member avatars row** — horizontal scroll
    - Each member: 44px avatar circle + name label below
    - Last item: dashed white circle with + icon + "Invite" label — opens add friend sheet

### Body sections

**Group progress card** — white bg, `#E8E4DE` border
- Title "Group progress"
- One row per member: avatar (20px) + name + progress bar (100px wide) + percentage
- Bar colors vary per member for easy visual distinction

**Shared decks section**
- "SHARED DECKS" uppercase fog label
- Deck cards: colored border + emoji icon (36px rounded square) + deck name + card count + who added it
- Right side: "Study" button (filled, matching deck color)

### Bottom nav
Groups tab active (`#F296BD`)

---

## Navigation update — 5 tab bottom nav

The bottom nav now has 5 tabs. Icon sizes reduced slightly to 20px to fit:

| Tab | Icon | Active color | Label color |
|-----|------|-------------|-------------|
| Home | House | `#99B7F5` filled | `#1A3A7A` |
| Learn | Grid 2×2 | `#99B7F5` filled | `#1A3A7A` |
| Library | Grid asymmetric | `#99B7F5` filled | `#1A3A7A` |
| Groups | Two people | `#F296BD` filled | `#C45A8A` |
| Profile | Person circle | `#FCCA59` filled | `#7A5500` |

Badge: orange `#F5793B` circle, white text, positioned top-right of icon — used on Groups tab for pending invites.

---

## 15. Learn tab — study type picker

### Overview
The Learn tab's main screen. Shows all available study modes as selectable cards. Replaces the placeholder "feature selector" from the original screen map.

### Layout
- **Header band** — periwinkle `#99B7F5`
  - Title "Learn" (24px, 800)
  - Subtitle "Pick a study mode" (13px, dark periwinkle)
- **Mode cards** — scrollable list, gap 12px

### Mode card structure
Each card: white bg, 2px colored border, 22px radius, 18px padding, flex row
- **Decorative corner** — colored tint quarter-circle top-right (80×80px)
- **Icon container** — 52px rounded square (18px radius), solid color bg, white icon
- **Content** — title (17px, 800) + description (13px, ash) + tag chips row
- **Chevron** — right side, colored to match card

### Active modes

**Flashcards**
- Border + icon bg: periwinkle `#99B7F5`
- Corner tint: `#EEF3FE`
- Tags: "Both directions" · "SRS"
- Description: "Flip cards to reveal translations. Swipe to rate yourself."

**Multiple choice**
- Border + icon bg: orange `#F5793B`
- Corner tint: `#FFF8F4`
- Tags: "4 options" · "Instant feedback"
- Description: "Pick the correct translation from 4 options."

### Coming soon modes (greyed out, 60% opacity)
- "Coming soon" badge: fog bg, fog text, top-right of card
- No chevron, non-interactive

**Matching**
- Description: "Match Korean words to their translations."

**Type the answer**
- Description: "Type the Korean or translation from memory."

### Bottom nav
Learn tab active (`#99B7F5` filled icons, `#1A3A7A` label)

---

## 16. Multiple choice quiz screen

### Overview
An interactive 4-option quiz. One correct answer + 3 randomly pulled wrong answers from other cards in the deck. Instant visual feedback on every answer.

### Layout — top bar
- Back button (white card, chevron)
- Progress bar — orange `#F5793B` fill on fog track, 7px height, updates per question
- Score chips — right side:
  - Correct: `#E8F5EE` bg, green `#267F53` count, ✓ icon
  - Wrong: `#FEF0F6` bg, pink `#C45A8A` count, ✗ icon

### Layout — question card
Full-width orange `#F5793B` rounded card (24px radius):
- Label: "What does this mean?" (11px, uppercase, white 70% opacity)
- Korean word: 36px, 800, white
- Romanisation: 14px, white 75% opacity
- Question counter: "Question X of Y" (11px, white 60% opacity)

### Layout — answer options
4 buttons stacked vertically, gap 8px:
- Default state: white bg, `#E8E4DE` border (2px), 18px radius
- Each button: letter badge (A/B/C/D) in fog square (26px, 8px radius) + answer text

### Answer feedback states

**Correct answer selected:**
- Selected button: `#E8F5EE` bg, `#267F53` border, dark green text
- Letter badge: green bg, white letter
- Question card: subtle scale pop animation (1→1.03→1, 300ms)

**Wrong answer selected:**
- Selected button: `#FEF0F6` bg, `#C45A8A` border, dark pink text, shake animation
- Correct button: simultaneously revealed in green (`#E8F5EE` bg, `#267F53` border)
- All other buttons: 55% opacity, non-interactive

**After answering:**
- All buttons disabled
- "Next →" button appears below (orange pill, full width), 400ms delay

### Answer generation logic
```
correctAnswer = current card translation
wrongAnswers  = 3 random translations from other cards in deck (shuffled)
options       = shuffle([correctAnswer, ...wrongAnswers])
correctIndex  = options.indexOf(correctAnswer)
```

### Animations
- Question card slide in: `translateX(30px) → 0`, opacity 0→1, 200ms ease-out
- Wrong answer shake: `translateX(-6px, 6px, -4px, 4px, 0)`, 400ms
- Correct pop: `scale(1 → 1.03 → 1)`, 300ms

### Completion screen
Shown after all questions answered:
- Yellow squircle with 🎉 emoji (72px, 24px radius)
- "Quiz complete!" (24px, 800)
- "You answered X questions" subtitle
- Three stat cards side by side:
  - Correct: `#E8F5EE` bg, green count + "CORRECT" label
  - Wrong: `#FEF0F6` bg, pink count + "WRONG" label
  - Score: `#FEF9E8` bg, yellow percentage + "SCORE" label
- "Try again" orange pill button
- "Back to study modes" ghost button

### Flutter implementation notes
- Wrong answers: query 3 random cards from same deck excluding current card
- Shuffle options array before rendering
- Disable all option buttons immediately on tap (before animation completes) to prevent double-tap
- Use `AnimatedContainer` or `TweenAnimationBuilder` for color transitions
- Progress bar: `LinearProgressIndicator` with orange color

# Ppyong — DESIGN_SCREENS.md additions

Append the following sections to `/docs/DESIGN_SCREENS.md`.

Also update the **Screens overview** table:

| Screen | Status | Tab |
|--------|--------|-----|
| Teacher dashboard | ✅ Designed | Home (role=teacher) |
| Group detail — Teacher view | ✅ Designed | Home (role=teacher) |
| Import deck (3-step) | ✅ Designed | Home (role=teacher) |
| Role view switcher | ✅ Designed | Header chip |
| Student home (role=teacher → toggled) | ↪️ Reuses Home screen |

---

## 17. Teacher dashboard

### Overview
The Home tab content when `role === teacher`. Same 5-tab bottom nav as the student app — only the Home content swaps. Uses forest green `#267F53` as the teacher identity color (matches the logo and signals authority/mastery; the only saturated palette color not yet claimed by a tab).

### Layout
- **Header band** — forest green `#267F53`
  - Greeting: "안녕하세요," (13px, Nunito 600, 85% opacity) + name "김 선생님" (22px, Nunito 800)
  - **Role switcher chip** — semi-transparent white pill below name, "TEACHER VIEW ›" (10px, 600 + chevron). Tappable — flips Home to the student view. Yellow dot prefix `#FCCA59`.
  - Right side: notification bell icon button (36px, semi-transparent white square, 12px radius) with orange `#F5793B` dot (top-right, 8px, green border to match header) + teacher avatar (38px, yellow `#FCCA59` bg, dark yellow `#7A5500` initial).
  - Decorative: large white circle at 12% opacity, top-right corner (140px), pulled outside frame.

- **Stats row** — 3 tiles overlapping header (margin-top: -22px, padding: 0 16px, gap 8px)
  1. **Active today** — yellow `#FCCA59` bg, `#E6B547` border, dark yellow text, flame corner icon. Format: `8/12` (active over total).
  2. **Avg accuracy** — green tint `#E8F5EE` bg, green `#267F53` border, dark green text, trend-up corner icon. Format: `84%`.
  3. **Decks live** — periwinkle `#99B7F5` bg, `#7B9CE5` border, dark periwinkle text, stack corner icon. Format: `14`.
  - Tile structure: 18px radius, 2px border, 12px padding, big number (22px, Nunito 800) with optional `/total` suffix (11px, 700, 70% opacity), label below (10px, DM Sans 500).
  - Corner icon container: 18px rounded square, white 55% opacity bg, top-right.

- **Needs attention** section
  - Section title "Needs attention" + count chip (pink `#F296BD` bg, white text)
  - "See all" right link (ash, 12px)
  - Attention card structure:
    - 40px avatar (member's identity color, white initials)
    - Name (14px, Nunito 700) + group tag chip (9px, fog tint, 1×6 padding)
    - Reason line (12px, ash) with **bold detail** (ink)
    - Right chevron (fog)
  - **Severity variants:**
    - **Urgent** (pink): pink `#F296BD` border, pink tint `#FEF0F6` bg — e.g. "Streak ended yesterday — after 12 days"
    - **Warn** (yellow): yellow `#FCCA59` border, yellow tint `#FEF9E8` bg — e.g. "Stuck on 5 weak words for 3 days", "No study for 2 days"
  - Tappable → opens student detail panel

- **My groups** section
  - Section title + "Manage" link
  - Group card structure (cursor: pointer, scale 0.99 on press):
    - 22px radius, 2px colored border (matches group's identity color), 14px padding, white bg
    - Top row: 44px emoji container (14px radius, identity tint bg) + name (15px, Nunito 800) + meta line ("4 students · 6 decks · last active 2h ago", 11px ash with bold values) + chevron
    - Overlapping member avatars (22px circle, 2px white border, -6px overlap, identity color bg, first-letter initials), with "class avg" label after
    - Dashed-top progress section: 3-segment progress bar showing mastered / learning / new + class average percent (Nunito 800, ink)
  - Identity colors: TOPIK 2 = periwinkle, Beginners = green, K-drama club = pink

- **Recent activity** feed
  - Section title + "Today" filter chip
  - Container: white card, 2px `#E8E4DE` border, 22px radius, padding 4px 14px
  - Item rows divided by dashed `#E8E4DE` line, 12px vertical padding
  - Structure: 30px icon square (10px radius, tinted bg, colored icon) + text block (12px DM Sans, ink, **bold subject + target**) + time (10px, fog)
  - **Icon variants** (one per `kind`):
    - `mastered` → green tint bg, green check icon
    - `streak` → yellow tint bg, dark yellow flame icon
    - `quiz` → periwinkle tint bg, dark periwinkle target icon
    - `weak` → pink tint bg, dark pink sparkle icon

- **Two stacked FABs** — bottom-right, above bottom nav
  - **Import deck** (white, secondary) — at `bottom: 142px`, 52px height, white bg, ink text, inset 1.5px `#E8E4DE` border, soft shadow, upload icon in green. Opens Import deck screen.
  - **Assign deck** (orange, primary) — at `bottom: 84px`, orange `#F5793B`, white text, inset 2px shadow `#D85F22`, plus icon. Opens Assign sheet.

### Mock data shape
```dart
class TeacherDashboardState {
  String name;            // "Kim"
  String nameKo;          // "김 선생님"
  int activeToday;        // 8
  int totalStudents;      // 12
  int avgAccuracy;        // 84
  int decksAssigned;      // 14
  List<AttentionItem> attention;
  List<GroupSummary> groups;
  List<ActivityEvent> recentActivity;
}
```

### Bottom nav
Home tab active — `#99B7F5` filled icon, `#1A3A7A` label (unchanged).

---

## 18. Group detail — Teacher view

### Trigger
Tapping any group card on the teacher dashboard.

### Layout
- **Header band** — forest green `#267F53` (matches teacher identity)
  - Back chevron button (36px, semi-transparent white square) + small "Group · Teacher view" label + three-dot menu (right)
  - Group identity row: 50px emoji square (16px radius, white 20% bg) + group name (20px, Nunito 800) + meta line ("4 students · 4 decks · class avg **78%**")
  - **Segmented control** — three segments: Students · Decks · Activity. White pill active (dark green text `#16563A`), transparent inactive (75% white text). 4px inner padding, 999px radius, white 20% bg, backdrop blur.

- **Class roster section** (Students tab — default)
  - Title + "Sort" link
  - Student row structure:
    - 40px avatar (identity color, 13px Nunito 800 white initial)
    - Name (14px Nunito 700)
    - Sub-line (11px ash): flame icon (orange when active, fog when 0) + "X day streak" · dot · "Y due"
    - Inline progress bar (5px height, 999px radius) + percent (Nunito 800, 11px, 28px min width right-aligned)
    - **Progress fill color rules:**
      - `progress > 80` → green `#267F53`
      - `progress > 60` → periwinkle `#99B7F5`
      - else → pink `#F296BD`
    - **Warn variant** (streak = 0 or stale): yellow `#FCCA59` border, yellow tint `#FEF9E8` bg

- **Shared decks section**
  - Title only
  - Deck chips (pill 999px, 1.5px `#E8E4DE` border, white bg, padding 6×10, 11px DM Sans 500): emoji + name
  - Action row at bottom: **Message group** (ghost) + **Assign deck** (orange primary, full width split 50/50)

### Bottom nav
Home tab active (this is still under the Home tab in teacher mode).

---

## 19. Import deck flow

### Overview
3-step stepper for bulk-adding cards into a new deck. Reached via the white **Import deck** FAB on the teacher dashboard. Could also be reachable from Library FAB for non-teacher members (TBD).

### Header (shared across all 3 steps)
- Forest green `#267F53` band
- Back chevron (top-left) + title "Import deck" (Nunito 800, 18px) + subtitle "Bulk add cards from text or a file"
- **Step indicator** — 3 dots connected by 1.5px white lines (30% opacity)
  - Inactive: 22px circle, white 25% bg, white number
  - Active: 22px circle, white bg, 2px white border, dark green number `#16563A`
  - Done: 22px circle, green `#267F53` bg, white check
  - Labels next to each: Source · Preview · Save (11px DM Sans 600 white)

### Step 1 — Source

- **Source tabs** — 4 evenly-spaced tab buttons, vertical icon+label layout, 14px radius
  - Selected: 2px green border, green tint `#E8F5EE` bg, dark green `#16563A` label
  - Unselected: 1.5px `#E8E4DE` border, white bg, ash label
  - Options: **Paste** (clipboard icon) · **CSV** (file-up icon) · **Sheet** (link icon) · **Anki** (sparkle icon)

- **Paste tab (default)**
  - Label "Paste cards" + monospace format hint right-aligned: `KO | EN | ROMAJA`
  - Textarea field — 180px min height, JetBrains Mono 12px, 1.5 line-height, no resize
  - Default placeholder content (6 example cards, one per line, `|` separated)
  - Yellow tip card below — yellow tint `#FEF9E8` bg, yellow `#FCCA59` 1.5px border, 12px radius, sparkle icon: "One card per line. Separate fields with **|**, **tab**, or **comma**. We'll auto-detect."

- **CSV tab**
  - Dashed dropzone — 2px dashed periwinkle `#99B7F5`, periwinkle tint `#EEF3FE` bg, 18px radius, 32×16px padding, centered
  - 48px white square (14px radius) with periwinkle file-up icon
  - "Drop a CSV file here" (Nunito 700, 14px, dark periwinkle) + "or tap to browse · max 5 MB" (11px ash)
  - "Choose file" ghost button (36px height, auto width)

- **Sheet tab**
  - Label "Google Sheet URL"
  - Standard input with placeholder `https://docs.google.com/spreadsheets/d/...`
  - Hint (11px ash): "Sheet must be shared as 'Anyone with link'. We read the first three columns."

- **Anki tab**
  - Dashed dropzone — pink `#F296BD` dashed border, pink tint `#FEF0F6` bg
  - "Drop an .apkg here" (Nunito 700, dark pink `#C45A8A`) + "Notes → cards. Decks become collections."

- **Footer buttons:** Cancel (ghost) · **Preview** (orange primary, chevron right icon)

### Step 2 — Preview

- Section title "Preview" + count chip (green `#267F53` bg, white text) + format reminder `KO → EN → ROMAJA`
- **Auto-detect banner** — green tint `#E8F5EE` bg, green 1.5px border, 12px radius, green check icon: "Auto-detected format: **Korean | English | Romaja**"
- **Card preview list** (max 6 visible, "+ N more cards…" footer)
  - White bg, 1.5px `#E8E4DE` border, 14px radius, 10×12 padding
  - 22px row number square (8px radius, periwinkle tint bg, mono 10px) + KO (Nunito 800 14px, ink) + EN · romaja sub-line (DM Sans 11px ash + JetBrains Mono 10px)
  - Pencil edit button (fog, top-right)
- **Footer:** Back (ghost, chevron-left) · **Continue** (orange primary, chevron-right)

### Step 3 — Save (destination)

- **Deck name** — text input, default "Greetings & basics"
- **Collection** — pill chip row (TOPIK 2, Beginners, K-drama club, + New)
  - Selected: 2px green border, green tint bg, dark green text
  - Unselected: 1.5px `#E8E4DE` border, white bg
- **Auto-assign to group (optional)** — radio row list
  - First option always: "Don't assign — save to library only" with em-dash emoji
  - Then one row per teacher's groups (emoji + name)
  - Selected row: 2px green border, green tint `#E8F5EE` bg, filled green circle check (20px)
- **Summary chip** — periwinkle tint `#EEF3FE` bg, periwinkle `#99B7F5` 1.5px border, 12px radius, stack icon: "**N cards** → '[deck name]' in **[collection]**"
- **Footer:** Back (ghost) · **Save deck** (orange primary, sparkle icon)

### On save
- Returns to dashboard
- Success toast (green variant): `Imported N cards into "[deck name]"`
- If auto-assign was chosen, also push notification to that group's students

### State shape
```dart
class ImportDeckState {
  ImportSource source;            // paste | csv | sheet | anki
  String rawText;                 // for paste
  String? sheetUrl;
  File? csvFile, apkgFile;
  String detectedFormat;          // 'ko|en|romaja' etc
  List<ParsedCard> parsedCards;
  String deckName;
  String collection;
  String? autoAssignGroupId;      // null = library only
}
```

---

## 20. Role view switcher

### Overview
A small chip in the header that lets users with `role === teacher` flip the Home tab between **Teacher view** (dashboard at §17) and **Student view** (existing Home at §1). Same account, same nav — only Home content swaps.

### Visibility rules
- Chip only renders when `user.role === 'teacher'` (or `'admin'`)
- Members never see it; their Home is always the student view

### State
- `activeRole` — `'teacher' | 'student'`, persisted per user in localStorage (or shared prefs)
- Defaults to `'teacher'` for teachers on first login
- All other tabs (Learn, Library, Groups, Profile) are unaffected — they render the same regardless of `activeRole`

### Visual
- Pill: semi-transparent white `rgba(255,255,255,0.18)`, 999px radius, 3×10×3×8 padding, backdrop blur, sits inside header
- Yellow dot `#FCCA59` (5×5) + label (10px DM Sans 600, white, letter-spacing 0.06em) + chevron-right (10px)
- Teacher view: "TEACHER VIEW ›" on green header
- Student view: "STUDENT VIEW ›" on periwinkle header (same chip styling, just different label)

### Interaction
- Tap → toggle role, swap Home content, persist
- Optional: subtle slide-cross-fade transition (200ms) when flipping
- Bottom nav stays put — no remount of the tab bar

### Flutter implementation note
```dart
final activeRoleProvider = StateProvider<String>((ref) {
  final user = ref.watch(userProvider);
  final saved = ref.read(prefsProvider).getString('activeRole_${user.id}');
  return saved ?? (user.role == 'teacher' ? 'teacher' : 'student');
});

// In HomeTab
Widget build(BuildContext context, WidgetRef ref) {
  final role = ref.watch(activeRoleProvider);
  return role == 'teacher' ? TeacherDashboard() : StudentHome();
}
```

---

## Teacher identity color

Forest green `#267F53` is now reserved as the **teacher view identity color**, used for:
- Teacher dashboard header band
- Group detail header (teacher view)
- Import deck header
- Selected state in teacher-only pickers (e.g. import source tabs, collection chips, auto-assign rows)

This keeps a clear visual separation: periwinkle = student home, pink = groups, yellow = profile, green = teacher tools.
