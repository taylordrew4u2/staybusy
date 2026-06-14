# StayBusy Design System

A complete, compiler-indexed design system for **StayBusy** — an ADHD-first
trip-schedule app. This project contains the design tokens, foundation
specimens, reusable React components, and a full interactive UI-kit
recreation of the product, all derived from the app's real source.

---

## What StayBusy is

StayBusy is a solo-trip planner built around one idea:

> **The job is not to pack every minute.** The job is that you can always
> answer *"what am I doing right now and what's next"* in under one second,
> and that **empty time is visible instead of invisible.** Rest and buffer
> are scheduled categories, not failures.

It is **dark-mode only**, **flat** (no gradients, anywhere), built on a
strict token system, and tuned for accessibility: 44pt tap targets,
monospaced timers that never jitter, color paired with iconography so color
is never the only signal, and no dead-end empty screens.

The product is one iOS app with three tabs:

- **Today** — a proportional, hour-ruled timeline of the day. The current
  block is ringed in accent so it's findable across a room; past blocks dim
  but never disappear; gaps render as dashed **OPEN** cards. A pinned
  **Now / Next** bar answers the core question at a glance and counts down
  live. A floating **+** adds a block.
- **Map** — the day's located blocks as numbered pins, with a bottom card
  (Drive / Details) when you tap one.
- **Trip** — a multi-day overview: totals, the "thinnest day" callout, and a
  per-day density bar showing scheduled-vs-open at a glance.

Tapping a block opens a **detail** view (confirmation code to copy, notes,
links, map, "Leave by" ETA); the **editor** is a bottom sheet with category
chips and a time range.

### Source

This system was reverse-engineered from the app's own codebase:

- **GitHub:** https://github.com/taylordrew4u2/staybusy (SwiftUI / SwiftData,
  iOS). The authoritative token schema lives in `staybusy/Theme.swift` and
  `staybusy/prompt-8-design-system.md`. Components and screens were lifted
  from `Components/*.swift`, `TodayView.swift`, `TripTabView.swift`,
  `MapTabView.swift`, `BlockDetailView.swift`, and `BlockEditorView.swift`.

Explore that repository for deeper fidelity when building new StayBusy work —
`Theme.swift` is the single source of truth the tokens here mirror 1:1.

---

## Content fundamentals

How StayBusy talks. Match this voice in any new copy.

- **Voice: calm, plain, second-person, present-tense.** The app speaks *to*
  you about *your* day. "Add a block to start mapping out your day." Never
  "we", never marketing language, never motivational filler.
- **Reassurance over pressure.** Empty and finished states are framed as
  fine, not as failure: **"Done for today"**, **"Nothing scheduled yet"**,
  **"Free until …"**. Open time is named and valued, never scolded.
- **Eyebrows are short, uppercase, tracked.** `NOW`, `NEXT`, `FREE UNTIL`,
  `STARTS IN`, `ENDS IN`, `TOMORROW`, `TRIP OVERVIEW`, `LEAVE BY`,
  `CONFIRMATION CODE`. These letter-spaced caps label everything.
- **Titles are sentence case, concise, literal.** "Soundcheck", "Travel to
  venue", "Green room rest", "Lunch w/ promoter". Real nouns, no emoji.
- **Time and duration are terse and human.** `1h 24m`, `2h`, `45m`,
  `OPEN — 2h 30m`, `9:30 AM – 12:00 PM`. Always monospaced digits.
- **Every dead end offers one way out.** Empty-state copy always pairs with a
  single action button ("Add a block"). No screen leaves you stuck.
- **No emoji.** Iconography carries meaning instead (see Iconography).
- **Microcopy for state, not chrome.** `TAP TO COPY` → `COPIED`,
  `JUMP TO TODAY`. Tells you what just happened or what you can do.

---

## Visual foundations

- **Mode:** dark only. Canvas is a near-black `#0D0D0F` (deliberately *not*
  pure black) so the two elevated surfaces — `#17171A` cards and `#1F1F24`
  sheets / the Now-bar — read as lifted.
- **Brand color:** a single red, `#E53935`. It is scarce on purpose — the
  current-block ring, the `NOW` marker, primary buttons, the now-line, and
  active states. Nothing else competes with it.
- **Category palette:** eight activity colors (gig, travel, food, social,
  work, explore, rest, admin). Used as 4-pt stripes, fills, dots and icons.
  Two (gig, explore) fail 4.5:1 as text on `surface`, so they ship lightened
  `*-text` variants used *only* for text; raw values stay for stripes/fills.
- **Status color:** amber `#F5A623` for overlap warnings, green `#34C759` for
  confirmation/copy feedback. Used sparingly, only for state.
- **Type:** SF Rounded everywhere in the app — **substituted on web with
  Nunito** (see Caveats). A small fixed scale tied to iOS Dynamic Type
  roles: displayCountdown (heavy, mono), titleLarge (heavy), title (bold),
  body (medium), caption (medium, mono), and codeHuge (bold **monospaced**,
  for confirmation codes). **Every number that ticks or aligns uses
  monospaced digits** so timers and times never jitter.
- **Spacing:** a strict **4-pt scale** — 4 / 8 / 12 / 16 / 24 / 32
  (xs…xxl). No off-scale spacing is permitted.
- **Radius:** 8 (chips, icon tiles), 14 (cards), 22 (sheets).
- **Borders & strokes:** 4-pt category stripe on blocks; 2-pt solid accent
  border for the current block; **1.5-pt dashed** outline (6/5 dash) for
  OPEN gap cards — a deliberately different *kind* of object than a block
  (no stripe, no fill) so free time is never mistaken for scheduled.
- **Backgrounds:** flat fills only. **No gradients** — a hard rule from the
  design pass. No photographic or illustrated backgrounds; the Map tab uses
  a flat dark surface with faint street lines.
- **Elevation / shadows:** the app is mostly shadowless. Shadow appears only
  on genuinely floating elements — the round **+** button
  (`0 4px 10px rgba(0,0,0,.5)`), map pins, and the map bottom card (which
  casts *upward*). No inner shadows, no glow except a faint accent halo on
  the current block (the border does the real work).
- **Corner treatment / cards:** cards are solid `surface` fills, 14-radius,
  no border by default; the only borders are the current-block accent ring
  and the dashed OPEN outline. Compact cards (map / overview) sit on the
  lighter `surfaceElevated`.
- **Transparency & blur:** minimal. A scrim behind the editor sheet; the map
  controls and empty-state card use a ~92% opacity surface so the map peeks
  through. No frosted-glass chrome inside the app itself.
- **Motion:** exactly **two** named animations and nothing else.
  `snap` — a quick spring (~250ms) for state changes and the 0.97 press
  scale on every tappable surface. `gentle` — a 350ms ease for
  scroll-to-now and layout shifts. Both collapse to ~instant under Reduce
  Motion. No bounces, no decorative looping, no parallax.
- **Press / hover states:** there is no hover (touch app); **every** tappable
  element scales to **0.97** via `snap` on press — no dead-feeling taps.
  Active toggles fill with accent; the copy button flips to green.
- **Imagery vibe:** there is essentially no decorative imagery — the content
  *is* the schedule. Attachments (boarding passes, etc.) display on black.

---

## Iconography

- **Source system:** Apple **SF Symbols**, filled/rounded weight, used
  pervasively — one glyph per category plus UI affordances (chevrons, plus,
  car, tram, checkmark, map pin, warning triangle, camera/photos/files…).
- **Web substitution:** SF Symbols are proprietary and can't ship, so this
  system uses **[Phosphor Icons](https://phosphor-icons.com/)** (`fill`
  weight primarily, `bold` for chevrons/plus) via CDN — the closest free
  match for SF's filled-rounded look. Loaded from
  `@phosphor-icons/web` jsDelivr CSS; render as `<i class="ph-fill ph-…">`.
- **Category → glyph map:** gig → `microphone-stage`, travel →
  `airplane-tilt`, food → `fork-knife`, social → `users`, work → `laptop`,
  explore → `map-trifold`, rest → `moon-stars`, admin → `tray`.
- **Color is never the only signal.** Every place a category color appears at
  small size, its glyph rides alongside it (chips, block headers, Now-bar,
  category dots) so the UI survives Differentiate-Without-Color.
- **No emoji, no Unicode-glyph icons, no hand-drawn SVG icons.** Pins use
  monospaced numerals; the density bar and stripes are pure color blocks.

---

## Index / manifest

**Root**
- `styles.css` — the single entry point consumers link. `@import`s only.
- `tokens/` — `colors.css`, `typography.css`, `spacing.css`, `effects.css`,
  `fonts.css` (webfont import), `base.css` (type utility classes).
- `readme.md` — this guide.
- `SKILL.md` — Agent-Skills front matter for use in Claude Code.

**Foundations** — `guidelines/cards/` (specimen cards on the Design System tab)
- Colors: surfaces, brand & status, text, category palette.
- Type: display & countdown, heading scale, body & caption, confirmation code.
- Spacing: scale, corner radius, strokes & stripe.
- Brand: category icons, motion, elevation.

**Components** — `components/core/` (namespace `window.StayBusyDesignSystem_0220d6`)
- `Button` — primary / secondary action button (44pt, press-scale).
- `CategoryChip` — category selector (color + glyph).
- `BlockCard` — the core schedule card (timeline / compact / list; current /
  past / overlap states).
- `OpenSlotCard` — dashed free-time card.
- `NowNextBar` — the pinned Now/Next status bar (3 states, live countdown).
- `TimeRangeLabel` — monospaced start–end range.
- `Badge` — small status pill (now / soft / neutral / success).
- `EmptyState` — empty screen with one recovery action.
- `DayPicker` — shared ±1-day navigator with Jump-to-Today.
- `categories.js` — shared category metadata (color / text-color / glyph).

**UI kit** — `ui_kits/staybusy/`
- `index.html` — the full interactive app (Today / Map / Trip, detail, editor)
  inside an iPhone frame. See its `README.md`.

---

## Caveats / substitutions

- **Fonts:** the app uses **SF Pro Rounded** (and SF Mono); both are Apple
  proprietary. Web ships **Nunito** (rounded sans) and **JetBrains Mono**.
  Swap the `@import` in `tokens/fonts.css` for self-hosted SF faces in a
  real Apple-platform build.
- **Icons:** **SF Symbols → Phosphor** (see Iconography). Glyph shapes are
  close but not identical.
- **No logo asset** exists in the source repo (the app-icon set is empty), so
  there is no wordmark/logomark here. If you have a StayBusy logo, drop it in
  `assets/` and reference it from cards/screens.
- **Map** is a stylized flat recreation (the real app uses Apple MapKit).
