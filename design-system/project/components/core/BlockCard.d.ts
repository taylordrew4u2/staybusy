import * as React from 'react';

export interface Block {
  title: string;
  /** Start time — Date or value the Date constructor accepts. */
  start: Date | string | number;
  end: Date | string | number;
  category: 'gig' | 'travel' | 'food' | 'social' | 'work' | 'explore' | 'rest' | 'admin';
  locationName?: string;
}

/**
 * The core schedule card: one block with a category stripe, icon, title,
 * and time range. Current = accent border + glow; past = 40% opacity;
 * overlap shows a warning glyph. States compose.
 *
 * @startingPoint section="Schedule" subtitle="Block card — timeline / compact / list" viewport="700x260"
 */
export interface BlockCardProps {
  block: Block;
  /** Density. timeline = full cell, compact = map/overview, list = minimal. @default "timeline" */
  variant?: 'timeline' | 'compact' | 'list';
  /** Currently happening — accent border treatment. @default false */
  isCurrent?: boolean;
  /** Already finished — dims to 40%. @default false */
  isPast?: boolean;
  /** Overlaps another block — shows a warning glyph. @default false */
  hasOverlap?: boolean;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  style?: React.CSSProperties;
}

export function BlockCard(props: BlockCardProps): JSX.Element;
