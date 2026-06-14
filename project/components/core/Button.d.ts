import * as React from 'react';

/**
 * StayBusy action button — accent-fill primary or elevated-surface
 * secondary. Always meets the 44pt tap target with a press-scale state.
 *
 * @startingPoint section="Core" subtitle="Primary & secondary buttons" viewport="700x140"
 */
export interface ButtonProps {
  /** Button label / content. */
  children?: React.ReactNode;
  /** Visual weight. @default "primary" */
  variant?: 'primary' | 'secondary';
  /** Leading Phosphor icon name (without the ph- prefix), e.g. "car". */
  icon?: string | null;
  /** Stretch to fill the container width. @default false */
  fullWidth?: boolean;
  /** @default false */
  disabled?: boolean;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  style?: React.CSSProperties;
}

export function Button(props: ButtonProps): JSX.Element;
