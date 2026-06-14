# Prompt 8 — Design System + UX/UI Pass

Paste Prompt 0 first if this is a new session, then paste everything below.

---

Do a full design-system and UX/UI pass on the app. This is a refactor-and-polish phase: no new features. Work in three stages, in this order, and show me the Theme file for approval before touching any views.

## Stage 1 — Design tokens (single source of truth)

Create one file, `Theme.swift`, containing every visual value in the app. After this pass, no view may contain a hardcoded color, font, spacing number, corner radius, or animation duration. Everything routes through Theme.

Implement Theme.swift as a 1:1 mapping of the token schema at the bottom of this prompt. Do not invent values; if the schema lacks something you need, ask before adding it.

Define:

**Colors (semantic names, not descriptive ones):**
- background (near-black, not pure #000 — use ~#0D0D0F so elevated surfaces can sit on it)
- surface (cards), surfaceElevated (sheets, the Now/Next bar)
- accent: #E53935
- textPrimary, textSecondary, textTertiary
- openSlot (muted gray for OPEN gap cards)
- warning (overlap indicator), success (confirmation/copy feedback)
- The eight category colors, kept as they are, exposed through Theme so they exist in exactly one place. Verify each category color passes 4.5:1 contrast as text on surface; where one fails, define a paired `onSurface` variant of it for text use and keep the raw color for stripes and fills only.

**Typography (SF Rounded everywhere, fixed scale):**
- displayCountdown — the Now-bar countdown, heavy, monospacedDigit. Every timer and time in the app must use monospaced digits so they don't jitter as seconds tick.
- titleLarge (screen headers, heavy), title (block titles, bold), body, caption (time ranges, metadata), codeHuge (confirmation codes — monospaced, very large)
- All styles defined relative to Dynamic Type text styles, not fixed point sizes, so the app scales with system text size.

**Spacing:** a 4-pt scale — 4, 8, 12, 16, 24, 32 — named xs/s/m/l/xl/xxl. No other spacing values allowed.

**Shape:** cornerRadius small (chips), medium (cards), large (sheets). One stroke width for dashed OPEN borders.

**Motion:** two named animations only — `Theme.snap` (quick spring, for state changes) and `Theme.gentle` (for scroll-to-now and layout shifts). Nothing animates outside these two. Respect Reduce Motion: when enabled, both resolve to near-instant.

## Stage 2 — Component extraction and refactor

Audit every view. Extract repeated UI into components, then refactor all screens to use them and Theme exclusively. Required components:

- **BlockCard** — variants: timeline (stripe + proportional height), compact (map bottom card, trip overview), list (widget). States: default, current (accent border glow + slightly elevated surface — the current block must be findable in one glance from across a room), past (40% opacity, never hidden), overlapWarning.
- **OpenSlotCard** — dashed border, "OPEN — Xh Ym", pressed state. Must look obviously different in kind from real blocks: no category stripe, no fill.
- **CategoryChip** — selected/unselected, used in editor and any filters.
- **NowNextBar** — the pinned bar as one component with three states: current block active, between blocks (counting down to next), day done ("Done for today" + first block of tomorrow — never an empty bar; an empty bar reads as "nothing exists," which violates design law 1).
- **DirectionsButtonRow**, **TimeRangeLabel** (always monospacedDigit), **DayPicker** (shared by Today and Map already — confirm it's one component, not two copies).

While refactoring, fix these UX rules everywhere:
- Tap targets minimum 44×44 pt. Check the 15-minute timeline blocks and the day-picker chevrons specifically.
- Every tappable element has a pressed state (scale 0.97 via Theme.snap). No dead-feeling taps.
- Haptics: light impact on block add/save, success notification haptic on copy-confirmation-code, none anywhere else.
- Destructive delete requires confirmation dialog.
- Empty states for every screen: Map day with no located blocks, Trip tab with no blocks, Today with zero blocks. Each empty state contains one action button that starts the fix (e.g., "Add a block"). No dead-end screens.

## Stage 3 — Accessibility + verification

- VoiceOver: every BlockCard reads as one element: "{title}, {category}, {start} to {end}, {location}". OPEN cards read "Open time, {duration}, double tap to fill". The Now bar announces updates politely, not every second.
- Dynamic Type: verify layouts at XXL. Timeline cards grow in height rather than truncating titles to one line.
- Color is never the only signal: current block has the border treatment, not just color; categories show icons everywhere the color appears small.
- Contrast: all text on its actual background passes 4.5:1.

Then output a short audit table: every screen, listing any remaining hardcoded values found and fixed, components now used, and accessibility status. If any view still contains a raw Color(...), font size number, or magic spacing value, the pass is not done.

Constraints: dark mode only stays. No gradients. No new features. Output whole files for everything you touch.

## Token Schema (authoritative — Theme.swift mirrors this exactly)

```json
{
  "color": {
    "background":      "#0D0D0F",
    "surface":         "#17171A",
    "surfaceElevated": "#1F1F24",
    "accent":          "#E53935",
    "textPrimary":     "#F5F5F7",
    "textSecondary":   "#A1A1AA",
    "textTertiary":    "#6B6B73",
    "openSlot":        "#3A3A41",
    "warning":         "#F5A623",
    "success":         "#34C759",
    "category": {
      "gig":     "#E53935",
      "travel":  "#F59E0A",
      "food":    "#4CAF50",
      "social":  "#ED5999",
      "work":    "#428AF5",
      "explore": "#8C5CF5",
      "rest":    "#738C99",
      "admin":   "#9E9E9E"
    }
  },
  "typography": {
    "note": "All styles: SF Rounded via .fontDesign(.rounded), based on Dynamic Type text styles, never fixed point sizes. monospacedDigit where flagged.",
    "displayCountdown": { "base": "largeTitle", "weight": "heavy",   "monospacedDigit": true },
    "titleLarge":       { "base": "title",      "weight": "heavy" },
    "title":            { "base": "headline",   "weight": "bold" },
    "body":             { "base": "body",       "weight": "medium" },
    "caption":          { "base": "caption",    "weight": "medium",  "monospacedDigit": true },
    "codeHuge":         { "base": "largeTitle", "weight": "bold",    "design": "monospaced" }
  },
  "spacing": { "xs": 4, "s": 8, "m": 12, "l": 16, "xl": 24, "xxl": 32 },
  "radius":  { "small": 8, "medium": 14, "large": 22 },
  "stroke":  { "openSlotDash": { "width": 1.5, "dash": [6, 5] }, "currentBlockBorder": 2 },
  "opacity": { "pastBlock": 0.4, "pressed": 0.97 },
  "size":    { "minTapTarget": 44, "categoryStripeWidth": 4 },
  "motion": {
    "snap":   { "type": "spring",    "response": 0.25, "dampingFraction": 0.85 },
    "gentle": { "type": "easeInOut", "duration": 0.35 },
    "reduceMotion": "both resolve to duration 0.01"
  },
  "haptics": { "blockSaved": "impactLight", "codeCopied": "notificationSuccess" }
}
```

Rules for the mapping:
- Category text-on-surface contrast: test each category hex at 4.5:1 against surface. Any that fail (expect rest and admin to be borderline) get a generated `onSurface` lightened variant in Theme; raw value remains for stripes and fills.
- Expose tokens as static members (`Theme.Color.surface`, `Theme.Spacing.l`, `Theme.Font.title`, `Theme.Motion.snap`), not strings or dictionaries.
- Include the JSON above as a comment block at the top of Theme.swift so the schema and the code never drift silently.
