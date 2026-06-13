import React from 'react';

function isSameDay(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}
function headline(d) {
  return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
}

function Chevron({ dir, onClick, label }) {
  const [pressed, setPressed] = React.useState(false);
  return (
    <button
      type="button"
      aria-label={label}
      onClick={onClick}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      style={{
        width: 'var(--sb-tap-min)',
        height: 'var(--sb-tap-min)',
        flexShrink: 0,
        borderRadius: '50%',
        border: 'none',
        background: 'var(--sb-surface)',
        color: 'var(--sb-text-primary)',
        fontSize: 'var(--sb-title-size)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        transform: pressed ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
        transition: 'transform var(--sb-motion-snap)',
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      <i className={`ph-bold ph-caret-${dir}`} aria-hidden="true" />
    </button>
  );
}

/**
 * Shared day navigator used by Today and Map. Chevrons step ±1 day
 * (44pt targets); the center shows the date and either a TODAY marker
 * or a JUMP TO TODAY action so you're never stranded on another day.
 */
export function DayPicker({ date, onChange, style = {}, ...rest }) {
  const d = date instanceof Date ? date : new Date(date);
  const today = new Date();
  const isToday = isSameDay(d, today);

  const step = (days) => {
    const next = new Date(d);
    next.setDate(next.getDate() + days);
    next.setHours(0, 0, 0, 0);
    onChange && onChange(next);
  };
  const jumpToday = () => {
    const t = new Date(); t.setHours(0, 0, 0, 0);
    onChange && onChange(t);
  };

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 'var(--sb-space-l)',
        padding: 'var(--sb-space-m) var(--sb-space-l) var(--sb-space-s)',
        fontFamily: 'var(--sb-font-rounded)',
        ...style,
      }}
      {...rest}
    >
      <Chevron dir="left" label="Previous day" onClick={() => step(-1)} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '2px' }}>
        <span style={{ fontWeight: 'var(--sb-weight-title)', fontSize: 'var(--sb-title-size)', color: 'var(--sb-text-primary)' }}>
          {headline(d)}
        </span>
        {isToday ? (
          <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.6px', color: 'var(--sb-accent)', fontWeight: 'var(--sb-weight-body)' }}>TODAY</span>
        ) : (
          <button
            type="button"
            onClick={jumpToday}
            style={{
              border: 'none', background: 'transparent', cursor: 'pointer',
              fontFamily: 'var(--sb-font-rounded)', fontWeight: 'var(--sb-weight-body)',
              fontSize: 'var(--sb-caption-size)', letterSpacing: '1.4px',
              color: 'var(--sb-accent)', padding: '2px 6px',
            }}
          >JUMP TO TODAY</button>
        )}
      </div>
      <Chevron dir="right" label="Next day" onClick={() => step(1)} />
    </div>
  );
}
