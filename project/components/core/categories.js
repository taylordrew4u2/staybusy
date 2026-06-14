// Shared category metadata for StayBusy components.
// Color values reference the design-system CSS custom properties so
// tokens remain the single source of truth. `icon` is a Phosphor glyph
// name (host page must load @phosphor-icons/web fill stylesheet).
export const CATEGORIES = {
  gig:     { label: 'Gig',     color: 'var(--sb-cat-gig)',     text: 'var(--sb-cat-gig-text)',     icon: 'microphone-stage' },
  travel:  { label: 'Travel',  color: 'var(--sb-cat-travel)',  text: 'var(--sb-cat-travel-text)',  icon: 'airplane-tilt' },
  food:    { label: 'Food',    color: 'var(--sb-cat-food)',    text: 'var(--sb-cat-food-text)',    icon: 'fork-knife' },
  social:  { label: 'Social',  color: 'var(--sb-cat-social)',  text: 'var(--sb-cat-social-text)',  icon: 'users' },
  work:    { label: 'Work',    color: 'var(--sb-cat-work)',    text: 'var(--sb-cat-work-text)',    icon: 'laptop' },
  explore: { label: 'Explore', color: 'var(--sb-cat-explore)', text: 'var(--sb-cat-explore-text)', icon: 'map-trifold' },
  rest:    { label: 'Rest',    color: 'var(--sb-cat-rest)',    text: 'var(--sb-cat-rest-text)',    icon: 'moon-stars' },
  admin:   { label: 'Admin',   color: 'var(--sb-cat-admin)',   text: 'var(--sb-cat-admin-text)',   icon: 'tray' },
};

export const CATEGORY_KEYS = Object.keys(CATEGORIES);

export function categoryMeta(key) {
  return CATEGORIES[key] || CATEGORIES.admin;
}
