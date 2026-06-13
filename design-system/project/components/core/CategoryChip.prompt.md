Pill chip for choosing a block category; pairs the category color with its Phosphor icon so color is never the only signal.

```jsx
<CategoryChip category="gig" selected onClick={() => setCat('gig')} />
<CategoryChip category="food" />
```

- Selected fills with the category color and white text; unselected is dark surface with a tinted outline.
- One of: gig, travel, food, social, work, explore, rest, admin.
