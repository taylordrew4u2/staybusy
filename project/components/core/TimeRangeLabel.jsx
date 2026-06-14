import React from 'react';

function fmt(d) {
  let h = d.getHours();
  const m = d.getMinutes();
  const ap = h >= 12 ? 'PM' : 'AM';
  h = h % 12; if (h === 0) h = 12;
  return `${h}:${m.toString().padStart(2, '0')} ${ap}`;
}

/**
 * Monospaced-digit start–end time range, used everywhere a block's
 * window is shown so the digits never jitter or shift width.
 * Accepts Date objects or anything the Date constructor parses.
 */
export function TimeRangeLabel({ start, end, size = 'caption', style = {}, ...rest }) {
  const s = start instanceof Date ? start : new Date(start);
  const e = end instanceof Date ? end : new Date(end);

  const sizes = {
    caption: { fontSize: 'var(--sb-caption-size)', lineHeight: 'var(--sb-caption-line)' },
    title:   { fontSize: 'var(--sb-title-size)',   lineHeight: 'var(--sb-title-line)', color: 'var(--sb-text-primary)' },
  };

  return (
    <span
      style={{
        fontFamily: 'var(--sb-font-rounded)',
        fontWeight: 'var(--sb-weight-body)',
        fontVariantNumeric: 'tabular-nums',
        whiteSpace: 'nowrap',
        color: 'var(--sb-text-secondary)',
        ...(sizes[size] || sizes.caption),
        ...style,
      }}
      aria-label={`${fmt(s)} to ${fmt(e)}`}
      {...rest}
    >
      {fmt(s)} – {fmt(e)}
    </span>
  );
}
