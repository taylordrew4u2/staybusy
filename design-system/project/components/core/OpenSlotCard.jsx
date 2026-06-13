import React from 'react';
import { TimeRangeLabel } from './TimeRangeLabel.jsx';

function durationString(start, end) {
  const total = Math.round((end - start) / 60000);
  const h = Math.floor(total / 60);
  const m = total % 60;
  if (h > 0 && m > 0) return `${h}h ${m}m`;
  if (h > 0) return `${h}h`;
  return `${m}m`;
}

/**
 * Dashed-border card for free time on the timeline. Deliberately a
 * different KIND of object than a real block — no category stripe, no
 * fill — so a glance can never confuse "open" with "scheduled". Rest
 * and buffer are visible here, not invisible.
 */
export function OpenSlotCard({ start, end, onClick, style = {}, ...rest }) {
  const s = start instanceof Date ? start : new Date(start);
  const e = end instanceof Date ? end : new Date(end);
  const [pressed, setPressed] = React.useState(false);

  return (
    <button
      type="button"
      onClick={onClick}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      aria-label={`Open time, ${durationString(s, e)}`}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 'var(--sb-space-s)',
        width: '100%',
        height: '100%',
        minHeight: 'var(--sb-tap-min)',
        boxSizing: 'border-box',
        padding: 'var(--sb-space-m)',
        background: 'transparent',
        border: 'var(--sb-stroke-open-width) dashed var(--sb-open-slot)',
        borderRadius: 'var(--sb-radius-medium)',
        cursor: 'pointer',
        textAlign: 'left',
        fontFamily: 'var(--sb-font-rounded)',
        transform: pressed ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
        transition: 'transform var(--sb-motion-snap)',
        WebkitTapHighlightColor: 'transparent',
        ...style,
      }}
      {...rest}
    >
      <span style={{ display: 'flex', flexDirection: 'column', gap: 'var(--sb-space-xs)', flex: 1, minWidth: 0 }}>
        <span style={{
          fontSize: 'var(--sb-body-size)',
          fontWeight: 'var(--sb-weight-body)',
          letterSpacing: '0.8px',
          color: 'var(--sb-text-tertiary)',
        }}>OPEN — {durationString(s, e)}</span>
        <TimeRangeLabel start={s} end={e} />
      </span>
      <i className="ph ph-plus-circle" style={{ fontSize: 'var(--sb-title-size)', color: 'var(--sb-text-tertiary)' }} aria-hidden="true" />
    </button>
  );
}
