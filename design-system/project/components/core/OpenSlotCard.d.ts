import * as React from 'react';

/**
 * Dashed-border free-time card. Visually a different kind of object than
 * a real block (no stripe, no fill) so empty time stays visible.
 */
export interface OpenSlotCardProps {
  start: Date | string | number;
  end: Date | string | number;
  /** Fired when the user taps to fill the gap. */
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  style?: React.CSSProperties;
}

export function OpenSlotCard(props: OpenSlotCardProps): JSX.Element;
