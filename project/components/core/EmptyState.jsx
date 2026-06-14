import React from 'react';
import { Button } from './Button.jsx';

/**
 * Reusable empty state. Enforces design law 1 — no dead-end screen:
 * every empty state offers one button that starts the user toward
 * filling it. Centered Phosphor glyph, title, optional message + action.
 */
export function EmptyState({ icon = 'calendar-blank', title, message, actionLabel, onAction, style = {}, ...rest }) {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        gap: 'var(--sb-space-m)',
        padding: 'var(--sb-space-xl)',
        fontFamily: 'var(--sb-font-rounded)',
        ...style,
      }}
      {...rest}
    >
      <i className={`ph-fill ph-${icon}`} style={{ fontSize: '44px', color: 'var(--sb-text-secondary)' }} aria-hidden="true" />
      <div style={{
        fontWeight: 'var(--sb-weight-heavy)',
        fontSize: 'var(--sb-title-lg-size)',
        lineHeight: 'var(--sb-title-lg-line)',
        color: 'var(--sb-text-primary)',
      }}>{title}</div>
      {message && (
        <div style={{
          fontWeight: 'var(--sb-weight-body)',
          fontSize: 'var(--sb-body-size)',
          lineHeight: 'var(--sb-body-line)',
          color: 'var(--sb-text-secondary)',
          maxWidth: '320px',
        }}>{message}</div>
      )}
      {actionLabel && onAction && (
        <Button icon="plus" onClick={onAction} style={{ marginTop: 'var(--sb-space-s)', minWidth: '180px' }}>
          {actionLabel}
        </Button>
      )}
    </div>
  );
}
