import React from 'react';
import { categoryMeta } from './categories.js';
import { TimeRangeLabel } from './TimeRangeLabel.jsx';
import { Badge } from './Badge.jsx';

/**
 * The core schedule card. One block, three layout variants and a set of
 * composable states. Current blocks carry the accent border so they're
 * findable in one glance; past blocks dim to 40% but never disappear.
 */
export function BlockCard({
  block,
  variant = 'timeline',
  isCurrent = false,
  isPast = false,
  hasOverlap = false,
  onClick,
  style = {},
  ...rest
}) {
  const meta = categoryMeta(block.category);
  const [pressed, setPressed] = React.useState(false);
  const isList = variant === 'list';

  const surface = variant === 'compact' ? 'var(--sb-surface-elevated)' : 'var(--sb-surface)';

  const wrap = {
    position: 'relative',
    display: 'flex',
    alignItems: 'stretch',
    width: '100%',
    height: '100%',
    boxSizing: 'border-box',
    borderRadius: 'var(--sb-radius-medium)',
    background: surface,
    overflow: 'hidden',
    border: isCurrent ? 'var(--sb-stroke-current) solid var(--sb-accent)' : 'var(--sb-stroke-current) solid transparent',
    boxShadow: isCurrent ? 'var(--sb-glow-current)' : 'none',
    opacity: isPast ? 'var(--sb-opacity-past)' : 1,
    cursor: onClick ? 'pointer' : 'default',
    transform: pressed && onClick ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
    transition: 'transform var(--sb-motion-snap)',
    textAlign: 'left',
    fontFamily: 'var(--sb-font-rounded)',
    WebkitTapHighlightColor: 'transparent',
    ...style,
  };

  return (
    <button
      type="button"
      style={wrap}
      onClick={onClick}
      onPointerDown={() => onClick && setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      {...rest}
    >
      <span style={{
        width: 'var(--sb-stripe-width)',
        background: meta.color,
        borderRadius: '3px',
        margin: 'var(--sb-space-xs) 0',
        flexShrink: 0,
      }} aria-hidden="true" />

      <span style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--sb-space-xs)',
        padding: isList ? 'var(--sb-space-s) var(--sb-space-m)' : 'var(--sb-space-m)',
        flex: 1,
        minWidth: 0,
      }}>
        {/* header row */}
        <span style={{ display: 'flex', alignItems: 'center', gap: 'var(--sb-space-xs)', flexShrink: 0 }}>
          <i className={`ph-fill ph-${meta.icon}`} style={{ color: meta.text, fontSize: 'var(--sb-caption-size)' }} aria-hidden="true" />
          <span style={{
            fontSize: 'var(--sb-caption-size)',
            letterSpacing: 'var(--sb-tracking-label)',
            textTransform: 'uppercase',
            fontWeight: 'var(--sb-weight-body)',
            color: 'var(--sb-text-secondary)',
          }}>{meta.label}</span>
          <span style={{ flex: 1 }} />
          {isCurrent && <Badge tone="now">Now</Badge>}
          {hasOverlap && (
            <i className="ph-fill ph-warning" style={{ color: 'var(--sb-warning)', fontSize: 'var(--sb-caption-size)' }} aria-label="Overlaps another block" />
          )}
        </span>

        {/* title */}
        <span style={{
          fontWeight: 'var(--sb-weight-title)',
          fontSize: 'var(--sb-title-size)',
          lineHeight: 'var(--sb-title-line)',
          color: 'var(--sb-text-primary)',
          flexShrink: 0,
          display: '-webkit-box',
          WebkitLineClamp: isList ? 1 : 2,
          WebkitBoxOrient: 'vertical',
          overflow: 'hidden',
        }}>{block.title}</span>

        {/* meta */}
        {!isList && (
          <span style={{ display: 'flex', alignItems: 'center', gap: 'var(--sb-space-xs)', minWidth: 0 }}>
            <TimeRangeLabel start={block.start} end={block.end} />
            {block.locationName && (
              <>
                <span style={{ color: 'var(--sb-text-tertiary)' }}>·</span>
                <span style={{
                  fontSize: 'var(--sb-caption-size)',
                  color: 'var(--sb-text-secondary)',
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                }}>{block.locationName}</span>
              </>
            )}
          </span>
        )}
      </span>
    </button>
  );
}
