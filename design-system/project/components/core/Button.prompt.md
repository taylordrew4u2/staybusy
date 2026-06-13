Accent-fill primary or elevated-surface secondary action button; use for any tap action, always ≥44pt with a press-scale.

```jsx
<Button variant="primary" icon="car" onClick={go}>Drive</Button>
<Button variant="secondary" icon="arrow-up-right">Details</Button>
```

- `variant`: `primary` (red CTA) | `secondary` (dark surface).
- `icon`: leading Phosphor glyph name (host loads `@phosphor-icons/web` fill CSS).
- `fullWidth`, `disabled` supported. Press gives a 0.97 scale via the `snap` motion token.
