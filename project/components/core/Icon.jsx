import React from 'react';

/**
 * StayBusy icon. A thin, brand-defaulted wrapper over Phosphor Icons —
 * the web stand-in for SF Symbols. Defaults to the `fill` weight (the
 * app's filled-rounded look); pass weight="bold" for chevrons / plus.
 * Host page must load the matching @phosphor-icons/web weight stylesheet.
 *
 * Decorative by default (aria-hidden). Pass `label` to make it a
 * standalone meaningful icon (adds role="img" + aria-label).
 */
export function Icon({
  name,
  weight = 'fill',
  size = '1.15em',
  color = 'currentColor',
  label = null,
  style = {},
  ...rest
}) {
  const px = typeof size === 'number' ? `${size}px` : size;
  const a11y = label
    ? { role: 'img', 'aria-label': label }
    : { 'aria-hidden': 'true' };
  return (
    <i
      className={`ph-${weight} ph-${name}`}
      style={{
        fontSize: px,
        lineHeight: 1,
        color,
        display: 'inline-flex',
        flexShrink: 0,
        ...style,
      }}
      {...a11y}
      {...rest}
    />
  );
}
