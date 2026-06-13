Dashed "OPEN — Xh Ym" card that makes free time visible on the timeline; deliberately unlike a real block so it's never mistaken for scheduled.

```jsx
<OpenSlotCard start={gapStart} end={gapEnd} onClick={() => createBlock(gapStart, gapEnd)} />
```

- No category stripe, no fill — only a dashed outline + plus affordance.
- Tapping it opens the editor to fill that gap.
