---
name: staybusy-design
description: Use this skill to generate well-branded interfaces and assets for StayBusy, the ADHD-first trip-schedule app — for production or throwaway prototypes/mocks. Contains essential design guidelines, colors, type, fonts, iconography, and a full UI kit of components for prototyping.
user-invocable: true
---

Read the `readme.md` file within this skill, and explore the other available files.

StayBusy is a **dark-mode-only, flat (no gradients) ADHD-first trip-schedule
app**. Its design law: you can always answer "what am I doing now and what's
next" in under a second, and empty time is visible, not invisible. Rest and
buffer are scheduled categories, never failures.

Key foundations (full detail in `readme.md`):

- **Color:** near-black `#0D0D0F` canvas, `#17171A` cards, `#1F1F24` sheets, a
  single red accent `#E53935`, and eight category colors. No gradients.
- **Type:** SF Rounded (web: **Nunito**) on a small fixed scale; SF Mono (web:
  **JetBrains Mono**) for timers and confirmation codes. Monospaced digits
  everywhere numbers tick or align.
- **Spacing:** strict 4-pt scale. **Radius:** 8 / 14 / 22.
- **Icons:** SF Symbols (web: **Phosphor**, fill weight); color is never the
  only signal — every category color is paired with its glyph.
- **Motion:** only two animations — `snap` (state/press) and `gentle`
  (layout). 0.97 press-scale on everything tappable. 44pt tap targets.
- **Voice:** calm, second-person, present-tense; reassuring; uppercase tracked
  eyebrows (NOW, NEXT, FREE UNTIL); no emoji.

Files:
- `styles.css` + `tokens/` — design tokens (link `styles.css` to get them).
- `components/core/` — React components (Button, BlockCard, NowNextBar,
  OpenSlotCard, CategoryChip, DayPicker, EmptyState, Badge, TimeRangeLabel).
- `guidelines/cards/` — foundation specimen cards.
- `ui_kits/staybusy/` — the full interactive app recreation.

If creating visual artifacts (slides, mocks, throwaway prototypes), copy assets
out and create static HTML files for the user to view. If working on production
code, copy assets and read the rules here to become an expert in designing with
this brand.

If the user invokes this skill without other guidance, ask them what they want
to build or design, ask a few questions, and act as an expert designer who
outputs HTML artifacts *or* production code, depending on the need.
