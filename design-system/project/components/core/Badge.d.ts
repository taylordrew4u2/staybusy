import * as React from 'react';

/**
 * Small uppercase status pill — the NOW marker, TAP TO COPY, counts.
 */
export interface BadgeProps {
  children?: React.ReactNode;
  /** Color tone. @default "now" */
  tone?: 'now' | 'soft' | 'neutral' | 'success';
  /** Optional leading Phosphor icon name. */
  icon?: string | null;
  style?: React.CSSProperties;
}

export function Badge(props: BadgeProps): JSX.Element;
