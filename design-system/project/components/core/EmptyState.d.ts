import * as React from 'react';

/**
 * Empty state with a single recovery action — no dead-end screens.
 */
export interface EmptyStateProps {
  /** Phosphor glyph name. @default "calendar-blank" */
  icon?: string;
  title: string;
  message?: string;
  /** Label for the single recovery action button. */
  actionLabel?: string;
  onAction?: () => void;
  style?: React.CSSProperties;
}

export function EmptyState(props: EmptyStateProps): JSX.Element;
