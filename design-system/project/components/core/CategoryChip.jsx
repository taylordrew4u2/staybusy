import React from 'react';
import { categoryMeta } from './categories.js';

/**
 * Category selector chip. Color is never the only signal — the Phosphor
 * glyph always rides alongside it. Selected = filled with the category
 * color; unselected = surface with a tinted outline.
 */
export function CategoryChip({ category = 'admin', selected = false, onClick, style = {}, ...rest }) {
  const meta = categoryMeta(category);
  const [pressed, setPressed] = React.useState(false);

  const wrap = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 'var(--sb-space-xs)',
    minHeight: 'var(--sb-tap-min)',
    padding: '8px 14px',
    borderRadius: '999px',
    border: selected ? '1.2px solid transparent' : '1.2px solid color-mix(in srgb, ' + meta.color + ' 55%, transparent)',
    background: selected ? meta.color : 'var(--sb-surface)',
    color: selected ? 'var(--sb-on-accent)' : 'var(--sb-text-primary)',
    fontFamily: 'var(--sb-font-rounded)',
    fontWeight: 'var(--sb-weight-body)',
    fontSize: 'var(--sb-body-size)',
    lineHeight: 1,
    cursor: 'pointer',
    transform: pressed ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
    transition: 'transform var(--sb-motion-snap)',
    WebkitTapHighlightColor: 'transparent',
    ...style,
  };

  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={selected}
      aria-label={meta.label}
      style={wrap}
      onClick={onClick}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      {...rest}
    >
      <i className={`ph-fill ph-${meta.icon}`} style={{ fontSize: '1.05em' }} aria-hidden="true" />
      {meta.label}
    </button>
  );
}
