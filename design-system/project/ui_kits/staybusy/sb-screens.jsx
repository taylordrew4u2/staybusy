// StayBusy UI kit — Today, Trip and Map screens.
// Composes the design-system primitives from the compiled bundle.
(function () {
  const DS = window.StayBusyDesignSystem_0220d6;
  const { NowNextBar, BlockCard, OpenSlotCard, DayPicker, EmptyState, BlockCardDummy } = DS;
  const { blocks: ALL, sameDay, fmtTime, durString } = window.SBData;

  const START_HOUR = 7, END_HOUR = 24, PPM = 1.25;
  const GUTTER = 48, RPAD = 16;

  function dayStartAt(date, hour) {
    const d = new Date(date); d.setHours(hour, 0, 0, 0); return d;
  }
  function hourLabel(h) {
    const x = h % 24;
    if (x === 0) return '12A';
    if (x === 12) return '12P';
    return x < 12 ? x + 'A' : (x - 12) + 'P';
  }

  // Build ordered list of timeline items (blocks + open gaps) for a day.
  function buildItems(dayBlocks, date) {
    const dayStart = dayStartAt(date, START_HOUR);
    const dayEnd = dayStartAt(date, 0); dayEnd.setDate(dayEnd.getDate() + 1);
    const sorted = [...dayBlocks].sort((a, b) => a.start - b.start);
    const items = [];
    let cursor = dayStart;
    for (const b of sorted) {
      const s = b.start < dayStart ? dayStart : b.start;
      if (s > cursor) {
        const gapMin = (s - cursor) / 60000;
        if (gapMin >= 10) items.push({ type: 'open', start: new Date(cursor), end: new Date(s) });
      }
      items.push({ type: 'block', block: b });
      const e = b.end > dayEnd ? dayEnd : b.end;
      if (e > cursor) cursor = e;
    }
    if (dayEnd > cursor) {
      const gapMin = (dayEnd - cursor) / 60000;
      if (gapMin >= 10) items.push({ type: 'open', start: new Date(cursor), end: new Date(dayEnd) });
    }
    return items;
  }

  function Timeline({ dayBlocks, date, onOpenBlock, onOpenSlot, ppm = PPM }) {
    const dayStart = dayStartAt(date, START_HOUR);
    const totalH = (END_HOUR - START_HOUR) * 60 * ppm;
    const isToday = sameDay(date, new Date());
    const now = new Date();
    const yFor = (t) => ((t - dayStart) / 60000) * ppm;
    const items = buildItems(dayBlocks, date);
    const scrollRef = React.useRef(null);

    React.useEffect(() => {
      if (isToday && scrollRef.current) {
        const y = Math.max(0, yFor(now) - 180);
        scrollRef.current.scrollTo({ top: y, behavior: 'smooth' });
      }
    }, [date]);

    const hours = [];
    for (let h = START_HOUR; h <= END_HOUR; h++) hours.push(h);

    return (
      <div ref={scrollRef} style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', position: 'relative' }}>
        <div style={{ position: 'relative', height: totalH + 40, margin: '8px 0 24px' }}>
          {/* hour ruler */}
          {hours.map((h) => (
            <div key={h} style={{ position: 'absolute', top: (h - START_HOUR) * 60 * ppm, left: 0, right: RPAD, display: 'flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: GUTTER - 10, textAlign: 'right', fontFamily: 'var(--sb-font-rounded)', fontSize: 'var(--sb-caption-size)', color: 'var(--sb-text-tertiary)' }}>{hourLabel(h)}</span>
              <span style={{ flex: 1, height: 1, background: 'var(--sb-hour-rule)' }} />
            </div>
          ))}

          {/* items */}
          {items.map((it, i) => {
            const start = it.type === 'block' ? it.block.start : it.start;
            const end = it.type === 'block' ? it.block.end : it.end;
            const top = yFor(start);
            const h = Math.max(44, ((end - start) / 60000) * ppm - 4);
            const isCurrent = isToday && it.type === 'block' && it.block.start <= now && now < it.block.end;
            const isPast = isToday && it.type === 'block' && it.block.end <= now;
            return (
              <div key={i} style={{ position: 'absolute', top, left: GUTTER, right: RPAD, height: h }}>
                {it.type === 'block'
                  ? <BlockCard block={it.block} variant="timeline" isCurrent={isCurrent} isPast={isPast} onClick={() => onOpenBlock(it.block)} />
                  : <OpenSlotCard start={it.start} end={it.end} onClick={() => onOpenSlot(it.start, it.end)} />}
              </div>
            );
          })}

          {/* now line */}
          {isToday && now >= dayStart && (
            <div style={{ position: 'absolute', top: yFor(now), left: 0, right: RPAD, display: 'flex', alignItems: 'center', height: 0, zIndex: 4 }}>
              <span style={{ width: GUTTER - 10, textAlign: 'right', marginRight: 4, fontFamily: 'var(--sb-font-rounded)', fontSize: 11, fontWeight: 700, letterSpacing: '1.2px', color: '#fff', background: 'var(--sb-accent)', borderRadius: 999, padding: '2px 6px', lineHeight: 1.2 }}>NOW</span>
              <span style={{ width: 9, height: 9, borderRadius: '50%', background: 'var(--sb-accent)' }} />
              <span style={{ flex: 1, height: 2, background: 'var(--sb-accent)' }} />
            </div>
          )}
        </div>
      </div>
    );
  }

  function TodayScreen({ date, onDate, onOpenBlock, onOpenSlot, onAdd, ppm }) {
    const dayBlocks = ALL.filter((b) => sameDay(b.start, date));
    return (
      <div style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }}>
        <DayPicker date={date} onChange={onDate} />
        <div style={{ padding: '0 16px 8px' }}>
          <NowNextBar blocks={ALL} />
        </div>
        {dayBlocks.length === 0
          ? <div style={{ flex: 1, display: 'flex', alignItems: 'center' }}>
              <EmptyState icon="calendar-plus" title="Nothing scheduled" message="Add a block to start mapping out your day." actionLabel="Add a block" onAction={onAdd} />
            </div>
          : <Timeline dayBlocks={dayBlocks} date={date} onOpenBlock={onOpenBlock} onOpenSlot={onOpenSlot} ppm={ppm} />}

        {/* floating add */}
        <button onClick={onAdd} aria-label="Add block" style={{
          position: 'absolute', right: 16, bottom: 16, width: 60, height: 60, borderRadius: '50%',
          border: 'none', background: 'var(--sb-accent)', color: '#fff', fontSize: 30,
          boxShadow: 'var(--sb-shadow-float)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <i className="ph-bold ph-plus" />
        </button>
      </div>
    );
  }

  // ---- Trip overview ----------------------------------------------------
  function dayWindow(date) {
    const s = dayStartAt(date, START_HOUR);
    const e = dayStartAt(date, 0); e.setDate(e.getDate() + 1);
    return { s, e, mins: (e - s) / 60000 };
  }
  function buildDays() {
    const byKey = {};
    for (const b of ALL) {
      const d = new Date(b.start); d.setHours(0, 0, 0, 0);
      const k = d.getTime();
      (byKey[k] = byKey[k] || { date: d, blocks: [] }).blocks.push(b);
    }
    const days = Object.values(byKey).sort((a, b) => a.date - b.date);
    for (const day of days) {
      const w = dayWindow(day.date);
      let scheduled = 0;
      for (const b of day.blocks) {
        const s = Math.max(b.start, w.s), e = Math.min(b.end, w.e);
        scheduled += Math.max(0, (e - s) / 60000);
      }
      day.openMin = Math.max(0, w.mins - scheduled);
      day.windowMin = w.mins;
    }
    return days;
  }

  function DensityBar({ day }) {
    const w = dayWindow(day.date);
    const segs = [];
    let cursor = w.s;
    for (const b of [...day.blocks].sort((a, b) => a.start - b.start)) {
      const bs = Math.max(b.start, w.s), be = Math.min(b.end, w.e);
      if (bs > cursor) segs.push({ open: true, frac: (bs - cursor) / 60000 / w.mins });
      if (be > bs) { segs.push({ cat: b.category, frac: (be - bs) / 60000 / w.mins }); cursor = be; }
    }
    if (w.e > cursor) segs.push({ open: true, frac: (w.e - cursor) / 60000 / w.mins });
    return (
      <div style={{ display: 'flex', height: 14, borderRadius: 4, overflow: 'hidden' }}>
        {segs.map((s, i) => (
          <span key={i} style={{ width: (s.frac * 100) + '%', background: s.open ? 'var(--sb-hour-rule)' : `var(--sb-cat-${s.cat})` }} />
        ))}
      </div>
    );
  }

  function TripScreen({ onSelectDay }) {
    const days = buildDays();
    const totalBlocks = days.reduce((n, d) => n + d.blocks.length, 0);
    const totalOpen = days.reduce((n, d) => n + d.openMin, 0);
    const thinnest = days.length > 1 ? [...days].sort((a, b) => a.openMin - b.openMin)[0] : null;
    const press = React.useRef(null);

    return (
      <div style={{ height: '100%', overflowY: 'auto', padding: 16, display: 'flex', flexDirection: 'column', gap: 12, fontFamily: 'var(--sb-font-rounded)' }}>
        {/* summary */}
        <div style={{ background: 'var(--sb-surface-elevated)', borderRadius: 'var(--sb-radius-medium)', padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>
          <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.4px', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>Trip overview</span>
          <div style={{ display: 'flex', gap: 32 }}>
            <Stat value={String(totalBlocks)} label="Blocks" />
            <Stat value={durString(totalOpen)} label="Open" />
          </div>
          {thinnest && (
            <div style={{ display: 'flex', gap: 5, alignItems: 'baseline' }}>
              <span style={{ fontSize: 'var(--sb-body-size)', color: 'var(--sb-text-secondary)' }}>Thinnest day:</span>
              <span style={{ fontSize: 'var(--sb-body-size)', color: 'var(--sb-accent)', fontWeight: 700 }}>{thinnest.date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}</span>
            </div>
          )}
        </div>

        {/* day rows */}
        {days.map((day) => (
          <button key={day.date.getTime()} onClick={() => onSelectDay(day.date)} style={{
            textAlign: 'left', border: 'none', cursor: 'pointer',
            background: 'var(--sb-surface)', borderRadius: 'var(--sb-radius-medium)', padding: 12,
            display: 'flex', flexDirection: 'column', gap: 8, fontFamily: 'var(--sb-font-rounded)',
          }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
              <span style={{ fontWeight: 800, fontSize: 'var(--sb-title-lg-size)', color: 'var(--sb-text-primary)' }}>{day.date.toLocaleDateString('en-US', { weekday: 'long' })}</span>
              <span style={{ fontSize: 'var(--sb-body-size)', color: 'var(--sb-text-secondary)' }}>{day.date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
              <span style={{ flex: 1 }} />
              <i className="ph-bold ph-caret-right" style={{ color: 'var(--sb-text-tertiary)', fontSize: 'var(--sb-caption-size)' }} />
            </div>
            <DensityBar day={day} />
            <span style={{ fontSize: 'var(--sb-caption-size)', color: 'var(--sb-text-secondary)' }}>{day.blocks.length} {day.blocks.length === 1 ? 'block' : 'blocks'} · {durString(day.openMin)} open</span>
          </button>
        ))}
      </div>
    );
  }

  function Stat({ value, label }) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <span style={{ fontWeight: 800, fontSize: 'var(--sb-title-lg-size)', color: 'var(--sb-text-primary)', fontVariantNumeric: 'tabular-nums' }}>{value}</span>
        <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.2px', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>{label}</span>
      </div>
    );
  }

  window.SBScreens = { TodayScreen, TripScreen, buildDays, dayWindow };
})();
