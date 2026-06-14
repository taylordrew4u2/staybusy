import React from 'react';
import { categoryMeta } from './categories.js';
import { Badge } from './Badge.jsx';

function fmtTime(d) {
  let h = d.getHours(); const m = d.getMinutes();
  const ap = h >= 12 ? 'PM' : 'AM'; h = h % 12; if (h === 0) h = 12;
  return `${h}:${m.toString().padStart(2, '0')} ${ap}`;
}
function countdown(from, to) {
  const total = Math.max(0, Math.floor((to - from) / 1000));
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  if (h > 0) return `${h}h ${m.toString().padStart(2, '0')}m`;
  return `${m}m ${s.toString().padStart(2, '0')}s`;
}
function sameDay(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function deriveState(now, blocks) {
  const list = blocks
    .map((b) => ({ ...b, _s: new Date(b.start), _e: new Date(b.end) }))
    .sort((a, b) => a._s - b._s);
  const current = list.find((b) => b._s <= now && now < b._e);
  if (current) {
    const next = list.find((b) => b._s > now && sameDay(b._s, now));
    return { kind: 'current', current, next };
  }
  const nextToday = list.find((b) => b._s > now && sameDay(b._s, now));
  if (nextToday) return { kind: 'between', next: nextToday };
  const tmw = new Date(now); tmw.setDate(tmw.getDate() + 1); tmw.setHours(0, 0, 0, 0);
  const firstTmw = list.find((b) => sameDay(b._s, tmw));
  return { kind: 'done', tomorrow: firstTmw || null };
}

function NextLine({ label, block }) {
  const meta = categoryMeta(block.category);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--sb-space-s)', minWidth: 0 }}>
      <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: meta.color, flexShrink: 0 }} />
      <i className={`ph-fill ph-${meta.icon}`} style={{ color: meta.text, fontSize: 'var(--sb-caption-size)' }} aria-hidden="true" />
      <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: 'var(--sb-tracking-eyebrow)', color: 'var(--sb-text-secondary)' }}>{label}</span>
      <span style={{ fontSize: 'var(--sb-body-size)', color: 'var(--sb-text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{block.title}</span>
      <span style={{ flex: 1 }} />
      <span style={{ fontSize: 'var(--sb-caption-size)', color: 'var(--sb-text-secondary)', fontVariantNumeric: 'tabular-nums' }}>{fmtTime(new Date(block.start))}</span>
    </div>
  );
}

function Divider() {
  return <div style={{ height: '1px', background: 'var(--sb-divider)' }} />;
}

function PrimaryRow({ color, text, icon, eyebrow, title, trailingLabel, trailing, trailingColor }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--sb-space-m)' }}>
      <div style={{
        width: 'var(--sb-tap-min)', height: 'var(--sb-tap-min)', flexShrink: 0,
        borderRadius: 'var(--sb-radius-small)',
        background: `color-mix(in srgb, ${color} 18%, transparent)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <i className={`ph-fill ph-${icon}`} style={{ color: text, fontSize: 'var(--sb-title-size)' }} aria-hidden="true" />
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', minWidth: 0, flex: 1 }}>
        <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: 'var(--sb-tracking-eyebrow)', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>{eyebrow}</span>
        <span style={{ fontWeight: 'var(--sb-weight-heavy)', fontSize: 'var(--sb-title-lg-size)', color: 'var(--sb-text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</span>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '2px', flexShrink: 0 }}>
        <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: 'var(--sb-tracking-eyebrow)', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>{trailingLabel}</span>
        <span style={{ fontWeight: 'var(--sb-weight-heavy)', fontSize: 'var(--sb-display-size)', lineHeight: 1, color: trailingColor, fontVariantNumeric: 'tabular-nums', whiteSpace: 'nowrap' }}>{trailing}</span>
      </div>
    </div>
  );
}

/**
 * The pinned Now/Next bar — the answer to "what am I doing now and
 * what's next" in under a second. Three states, and it NEVER goes empty:
 * current block, free-until-next, or done-for-today (with tomorrow's
 * first block). Ticks live unless a fixed `now` is supplied.
 */
export function NowNextBar({ blocks = [], now = null, style = {}, ...rest }) {
  const [tick, setTick] = React.useState(() => now ? new Date(now) : new Date());
  React.useEffect(() => {
    if (now) { setTick(new Date(now)); return; }
    const id = setInterval(() => setTick(new Date()), 1000);
    return () => clearInterval(id);
  }, [now]);

  const state = deriveState(tick, blocks);

  const shell = {
    padding: 'var(--sb-space-m)',
    borderRadius: 'var(--sb-radius-medium)',
    background: 'var(--sb-surface-elevated)',
    fontFamily: 'var(--sb-font-rounded)',
    display: 'flex',
    flexDirection: 'column',
    gap: 'var(--sb-space-m)',
    ...style,
  };

  return (
    <div style={shell} {...rest}>
      {state.kind === 'current' && (
        <>
          <PrimaryRow
            color={categoryMeta(state.current.category).color}
            text={categoryMeta(state.current.category).text}
            icon={categoryMeta(state.current.category).icon}
            eyebrow="Now"
            title={state.current.title}
            trailingLabel="Ends in"
            trailing={countdown(tick, state.current._e)}
            trailingColor="var(--sb-text-primary)"
          />
          {state.next && <><Divider /><NextLine label="Next" block={state.next} /></>}
        </>
      )}

      {state.kind === 'between' && (
        <>
          <PrimaryRow
            color="var(--sb-text-tertiary)"
            text="var(--sb-text-tertiary)"
            icon="clock"
            eyebrow="Free until"
            title={state.next.title}
            trailingLabel="Starts in"
            trailing={countdown(tick, state.next._s)}
            trailingColor="var(--sb-accent)"
          />
          <Divider />
          <NextLine label="Next" block={state.next} />
        </>
      )}

      {state.kind === 'done' && (
        <>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--sb-space-s)' }}>
            <i className="ph-fill ph-check-circle" style={{ color: 'var(--sb-success)', fontSize: 'var(--sb-title-size)' }} aria-hidden="true" />
            <span style={{ fontWeight: 'var(--sb-weight-title)', fontSize: 'var(--sb-title-size)', color: 'var(--sb-text-primary)' }}>Done for today</span>
          </div>
          {state.tomorrow ? (
            <><Divider /><NextLine label="Tomorrow" block={state.tomorrow} /></>
          ) : (
            <span style={{ fontSize: 'var(--sb-body-size)', color: 'var(--sb-text-secondary)' }}>Nothing scheduled yet</span>
          )}
        </>
      )}
    </div>
  );
}
