import React from 'react';

/**
 * StayBusy action button. Two variants map 1:1 to the app's
 * PrimaryButton (accent fill) and SecondaryButton (elevated surface).
 * Always meets the 44pt minimum tap target. Optional leading Phosphor
 * icon (host page must load @phosphor-icons/web fill stylesheet).
 */
export function Button({
  children,
  variant = 'primary',
  icon = null,
  fullWidth = false,
  disabled = false,
  onClick,
  style = {},
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);

  const palettes = {
    primary:   { bg: 'var(--sb-accent)',           fg: 'var(--sb-on-accent)' },
    secondary: { bg: 'var(--sb-surface-elevated)', fg: 'var(--sb-text-primary)' },
  };
  const p = palettes[variant] || palettes.primary;

  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 'var(--sb-space-s)',
    minHeight: 'var(--sb-tap-min)',
    width: fullWidth ? '100%' : 'auto',
    padding: '8px 18px',
    border: 'none',
    borderRadius: 'var(--sb-radius-medium)',
    background: p.bg,
    color: p.fg,
    fontFamily: 'var(--sb-font-rounded)',
    fontWeight: 'var(--sb-weight-title)',
    fontSize: 'var(--sb-title-size)',
    lineHeight: 1,
    cursor: disabled ? 'default' : 'pointer',
    opacity: disabled ? 0.4 : 1,
    transform: pressed && !disabled ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
    transition: 'transform var(--sb-motion-snap)',
    WebkitTapHighlightColor: 'transparent',
    ...style,
  };

  return (
    <button
      type="button"
      style={base}
      disabled={disabled}
      onClick={onClick}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      {...rest}
    >
      {icon && <i className={`ph-fill ph-${icon}`} style={{ fontSize: '1.15em' }} aria-hidden="true" />}
      {children}
    </button>
  );
}
