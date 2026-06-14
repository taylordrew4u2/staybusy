Brand-defaulted icon over Phosphor (the web stand-in for SF Symbols); use for any glyph so weight/size/color defaults stay consistent.

```jsx
<Icon name="car" />                         {/* fill weight, decorative */}
<Icon name="caret-right" weight="bold" />   {/* chevrons / plus use bold */}
<Icon name="map-pin" label="Location" color="var(--sb-accent)" size={20} />
```

- `weight` defaults to `fill` (the app's filled-rounded look); use `bold` for chevrons and the plus.
- Decorative by default; pass `label` to expose it to screen readers.
- Host page must load the matching `@phosphor-icons/web` weight stylesheet (fill + bold are the two the app uses).
