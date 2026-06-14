Centered empty state with one recovery action; every empty screen in StayBusy uses it so there are no dead ends.

```jsx
<EmptyState icon="calendar-plus" title="Nothing scheduled"
  message="Add a block to start mapping out your day."
  actionLabel="Add a block" onAction={create} />
```

- Always pass an `actionLabel` + `onAction` for screens the user can fix.
