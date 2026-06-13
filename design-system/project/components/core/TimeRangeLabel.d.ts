import * as React from 'react';

/**
 * Monospaced start–end time range. Tabular digits keep widths stable
 * as times change.
 */
export interface TimeRangeLabelProps {
  /** Range start — Date or a value the Date constructor accepts. */
  start: Date | string | number;
  /** Range end. */
  end: Date | string | number;
  /** caption (metadata) or title (emphasised). @default "caption" */
  size?: 'caption' | 'title';
  style?: React.CSSProperties;
}

export function TimeRangeLabel(props: TimeRangeLabelProps): JSX.Element;
