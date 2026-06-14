import React from 'react';

/**
 * Small status pill. Default "now" tone = solid accent (the NOW badge);
 * "soft" = tinted accent wash; "neutral" = elevated surface. Used for
 * the NOW marker, TAP TO COPY, and small counts.
 */
export function Badge({ children, tone = 'now', icon = null, style = {}, ...rest }) {
  const tones = {
    now:     { bg: 'var(--sb-accent)',           fg: 'var(--sb-on-accent)' },
    soft:    { bg: 'var(--sb-accent-wash)',      fg: 'var(--sb-accent)' },
    neutral: { bg: 'var(--sb-surface-elevated)', fg: 'var(--sb-text-secondary)' },
    success: { bg: 'var(--sb-success)',          fg: '#05210d' },
  };
  const t = tones[tone] || tones.now;

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '5px',
        padding: '3px 9px',
        borderRadius: '999px',
        background: t.bg,
        color: t.fg,
        fontFamily: 'var(--sb-font-rounded)',
        fontWeight: 'var(--sb-weight-body)',
        fontSize: '11px',
        letterSpacing: 'var(--sb-tracking-label)',
        textTransform: 'uppercase',
        lineHeight: 1.4,
        ...style,
      }}
      {...rest}
    >
      {icon && <i className={`ph-fill ph-${icon}`} aria-hidden="true" />}
      {children}
    </span>
  );
}
