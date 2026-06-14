import * as React from 'react';
import type { Block } from './BlockCard';

/**
 * The pinned Now/Next bar. Answers "what now, what next" at a glance and
 * never renders empty — current block, free-until-next, or done-for-today
 * with tomorrow's first block. Counts down live unless `now` is fixed.
 *
 * @startingPoint section="Schedule" subtitle="Pinned Now / Next status bar" viewport="700x200"
 */
export interface NowNextBarProps {
  /** All blocks across days; the bar finds the relevant one. */
  blocks: Block[];
  /** Fix the clock for static rendering (cards, tests). Live if omitted. */
  now?: Date | string | number | null;
  style?: React.CSSProperties;
}

export function NowNextBar(props: NowNextBarProps): JSX.Element;
