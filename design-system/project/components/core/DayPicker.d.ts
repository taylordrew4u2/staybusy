import * as React from 'react';

/**
 * Day navigator shared by Today and Map. ±1 day chevrons with 44pt
 * targets and a TODAY marker / JUMP TO TODAY action.
 */
export interface DayPickerProps {
  /** Currently selected day. */
  date: Date | string | number;
  /** Called with a new midnight-aligned Date. */
  onChange?: (date: Date) => void;
  style?: React.CSSProperties;
}

export function DayPicker(props: DayPickerProps): JSX.Element;
