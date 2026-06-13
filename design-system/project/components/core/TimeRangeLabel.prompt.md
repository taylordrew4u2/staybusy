Monospaced-digit "h:mm AM – h:mm PM" range; use anywhere a block's start/end is shown so digits don't jitter.

```jsx
<TimeRangeLabel start={block.start} end={block.end} />
<TimeRangeLabel start={s} end={e} size="title" />
```

- `size="caption"` for metadata rows, `"title"` when the range is the emphasis.
