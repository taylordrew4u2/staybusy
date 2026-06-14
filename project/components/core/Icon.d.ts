import * as React from 'react';

/**
 * StayBusy icon — a brand-defaulted wrapper over Phosphor Icons (the web
 * stand-in for SF Symbols). Defaults to the filled weight; decorative
 * unless you pass a `label`.
 *
 * @startingPoint section="Core" subtitle="Icon — Phosphor with brand defaults" viewport="700x180"
 */
export interface IconProps {
  /** Phosphor glyph name without the `ph-` prefix, e.g. "car", "microphone-stage". */
  name: string;
  /** Phosphor weight. @default "fill" */
  weight?: 'thin' | 'light' | 'regular' | 'bold' | 'fill' | 'duotone';
  /** Size — number (px) or any CSS length. @default "1.15em" */
  size?: number | string;
  /** Icon color. @default "currentColor" */
  color?: string;
  /** Accessible label. Omit for decorative icons (renders aria-hidden). */
  label?: string | null;
  style?: React.CSSProperties;
}

export function Icon(props: IconProps): JSX.Element;
