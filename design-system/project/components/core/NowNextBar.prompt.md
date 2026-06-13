The pinned bar that answers "what am I doing now and what's next" in under a second; it never goes empty.

```jsx
I<NowNextBar blocks={allBlocks} />            {/* live, ticks each second */}
<NowNextBar blocks={allBlocks} now={fixed} /> {/* static, for cards */}
```

- Three states, chosen automatically: **current** (NOW + ends-in countdown + NEXT line), **between** (FREE UNTIL + starts-in), **done** (Done for today + tomorrow's first block).
- Pass a fixed `now` to freeze it for a specimen; omit for a live countdown.
- All timers use monospaced digits so nothing jitters.
