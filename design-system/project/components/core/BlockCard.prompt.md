The core StayBusy schedule card — one block with category stripe, icon, title and time range; the current block gets an accent border so it's findable in one glance.

```jsx
<BlockCard block={{title:'Soundcheck', start, end, category:'gig', locationName:'Brooklyn Steel'}} isCurrent onClick={open} />
<BlockCard block={pastBlock} isPast />
<BlockCard block={b} variant="compact" />
```

- `variant`: `timeline` (full cell) | `compact` (map bottom card / overview) | `list` (minimal, one-line title, no meta).
- States compose: `isCurrent`, `isPast`, `hasOverlap`. Past dims to 40% but is never hidden.
- Pass `onClick` to make it pressable (adds the 0.97 press scale).
