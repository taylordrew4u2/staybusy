import * as React from 'react';

/**
 * Category selector chip used in the block editor and any filter row.
 * Pairs color with a Phosphor glyph so it stays legible under
 * Differentiate Without Color.
 *
 * @startingPoint section="Core" subtitle="Category chips with icon + color" viewport="700x160"
 */
export interface CategoryChipProps {
  /** One of the eight StayBusy categories. @default "admin" */
  category?: 'gig' | 'travel' | 'food' | 'social' | 'work' | 'explore' | 'rest' | 'admin';
  /** Selected state — fills with the category color. @default false */
  selected?: boolean;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  style?: React.CSSProperties;
}

export function CategoryChip(props: CategoryChipProps): JSX.Element;
