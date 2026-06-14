# StayBusy

An ADHD-first solo-trip schedule app for iOS (SwiftUI + SwiftData).

Its design law: you can always answer **"what am I doing right now and what's
next"** in under one second, and **empty time is visible instead of invisible** —
rest and buffer are scheduled categories, never failures.

The app is **dark-mode only**, **flat** (no gradients), and built on a strict
token system: 44pt tap targets, monospaced timers that never jitter, color
always paired with iconography so color is never the only signal, and no
dead-end empty screens.

## App structure

Three tabs:

- **Today** — a proportional, hour-ruled timeline. The current block is ringed
  in accent so it's findable across a room; past blocks dim but never
  disappear; gaps render as dashed **OPEN** cards. A pinned **Now / Next** bar
  answers the core question and counts down live.
- **Map** — the day's located blocks as numbered pins (Apple MapKit), with a
  bottom card (Drive / Details) when you tap one.
- **Trip** — a multi-day overview: totals, the "thinnest day" callout, and a
  per-day density bar of scheduled-vs-open time.

Tapping a block opens a **detail** view (confirmation code to copy, notes,
links, map, Leave-by ETA); the **editor** is a bottom sheet with category chips
and a time range.

Key source files:

- `staybusy/Theme.swift` — the single source of truth for every visual value
  (colors, type, spacing, radius, strokes, motion, haptics).
- `staybusy/prompt-8-design-system.md` — the design-system spec `Theme.swift`
  implements.
- `staybusy/Components/` — reusable UI (`BlockCard`, `NowNextBar`,
  `OpenSlotCard`, `CategoryChip`, `PrimaryButton`, `TimeRangeLabel`,
  `EmptyStateView`, `DirectionsButtonRow`, `PressableScale`).
- `staybusy/TodayView.swift`, `MapTabView.swift`, `TripTabView.swift`,
  `BlockDetailView.swift`, `BlockEditorView.swift` — the screens.

## Design system

[`design-system/`](design-system/) is the exported StayBusy design system — a
compiler-indexed handoff bundle from [Claude Design](https://claude.ai/design),
reverse-engineered from this repo. It contains:

- **Tokens** (`design-system/project/tokens/`) — the dark-mode color system,
  type scale, spacing, and effects as CSS custom properties that mirror
  `Theme.swift` **1:1**.
- **Components** (`design-system/project/components/core/`) — React reference
  implementations of every primitive, each with a `.d.ts` contract and a
  `.prompt.md` usage note.
- **Foundations** (`design-system/project/guidelines/cards/`) — specimen cards
  for colors, type, spacing, and brand.
- **UI kit** (`design-system/project/ui_kits/staybusy/`) — a full interactive
  HTML/React recreation of the app (Today / Map / Trip, detail, editor).
- **`SKILL.md`** — an Agent Skill (`/staybusy-design`) for generating
  on-brand StayBusy interfaces and assets in Claude Code.

`Theme.swift` remains the authoritative source of truth; the design-system
tokens mirror it. When building new StayBusy surfaces, read
`design-system/project/readme.md` first — it documents the voice, visual
foundations, and iconography in full.

> **Substitutions (web only):** the app uses Apple **SF Pro Rounded** + **SF
> Mono** and **SF Symbols** / **MapKit**, which are the source of truth. The web
> bundle substitutes **Nunito**, **JetBrains Mono**, and **Phosphor** icons, and
> renders a stylized flat map — these are reference approximations, not changes
> to the app.
