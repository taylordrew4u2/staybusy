// StayBusy UI kit — Map, Block detail, Editor, tab bar, and app shell.
(function () {
  const DS = window.StayBusyDesignSystem_0220d6;
  const { BlockCard, Button, Badge, DayPicker, TimeRangeLabel, EmptyState, CategoryChip, CATEGORIES } = DS;
  const { blocks: ALL, sameDay, fmtTime, durString } = window.SBData;

  function catMeta(k) { return CATEGORIES[k] || CATEGORIES.admin; }

  // ---- Map --------------------------------------------------------------
  function MapScreen({ date, onDate, onOpenBlock }) {
    const [selected, setSelected] = React.useState(null);
    const dayBlocks = ALL.filter((b) => sameDay(b.start, date) && b.lat != null);

    // normalize coords into the map rectangle
    const lats = dayBlocks.map((b) => b.lat), lngs = dayBlocks.map((b) => b.lng);
    const minLat = Math.min(...lats), maxLat = Math.max(...lats);
    const minLng = Math.min(...lngs), maxLng = Math.max(...lngs);
    const pos = (b) => {
      const padX = 18, padY = 16;
      const fx = maxLng === minLng ? 0.5 : (b.lng - minLng) / (maxLng - minLng);
      const fy = maxLat === minLat ? 0.5 : (maxLat - b.lat) / (maxLat - minLat);
      return { left: `calc(${padX}% + ${fx * (100 - padX * 2)}%)`, top: `calc(${padY}% + ${fy * (100 - padY * 2)}%)` };
    };

    return (
      <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
        <DayPicker date={date} onChange={(d) => { setSelected(null); onDate(d); }} />
        <div style={{ flex: 1, position: 'relative', margin: '0 0 0', overflow: 'hidden', background: '#101216' }}>
          {/* faux street grid — flat, no gradient */}
          <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0 }} preserveAspectRatio="none">
            <defs>
              <pattern id="streets" width="46" height="46" patternUnits="userSpaceOnUse">
                <path d="M0 0H46M0 0V46" stroke="#1b1e24" strokeWidth="1.5" fill="none" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#streets)" />
            <path d="M-20 120 Q 200 60 460 200" stroke="#23262e" strokeWidth="10" fill="none" />
            <path d="M120 -20 Q 180 300 320 700" stroke="#23262e" strokeWidth="14" fill="none" />
          </svg>

          {dayBlocks.length === 0 && (
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24 }}>
              <div style={{ background: 'color-mix(in srgb, var(--sb-surface) 92%, transparent)', borderRadius: 'var(--sb-radius-medium)' }}>
                <EmptyState icon="map-pin" title="No locations yet" message="Add a location to one of today's blocks to see it here." />
              </div>
            </div>
          )}

          {/* numbered pins */}
          {dayBlocks.map((b, i) => {
            const p = pos(b); const isSel = selected && selected.id === b.id;
            return (
              <button key={b.id} onClick={() => setSelected(b)} aria-label={`Block ${i + 1}`} style={{
                position: 'absolute', left: p.left, top: p.top, transform: 'translate(-50%,-50%)',
                width: isSel ? 44 : 32, height: isSel ? 44 : 32, borderRadius: '50%', cursor: 'pointer',
                background: `var(--sb-cat-${b.category})`, border: '2px solid #fff', boxShadow: 'var(--sb-shadow-pin)',
                color: '#fff', fontFamily: 'var(--sb-font-mono)', fontWeight: 700, fontSize: 14,
                display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all var(--sb-motion-snap)',
              }}>{i + 1}</button>
            );
          })}

          {/* polyline toggle (decorative) */}
          <div style={{ position: 'absolute', top: 12, right: 16, width: 44, height: 44, borderRadius: '50%', background: 'color-mix(in srgb, var(--sb-surface-elevated) 92%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--sb-shadow-pin)' }}>
            <i className="ph-bold ph-path" style={{ color: 'var(--sb-text-primary)', fontSize: 18 }} />
          </div>

          {/* bottom card */}
          {selected && (
            <div style={{ position: 'absolute', left: 16, right: 16, bottom: 16, background: 'var(--sb-surface)', borderRadius: 'var(--sb-radius-medium)', padding: 12, boxShadow: 'var(--sb-shadow-sheet)', display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
                <div style={{ flex: 1 }}><BlockCard block={selected} variant="compact" /></div>
                <button onClick={() => setSelected(null)} aria-label="Dismiss" style={{ border: 'none', background: 'transparent', color: 'var(--sb-text-tertiary)', fontSize: 24, cursor: 'pointer', width: 36, height: 36 }}>
                  <i className="ph-fill ph-x-circle" />
                </button>
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <Button icon="car" fullWidth>Drive</Button>
                <Button variant="secondary" icon="arrow-up-right" fullWidth onClick={() => onOpenBlock(selected)}>Details</Button>
              </div>
            </div>
          )}
        </div>
      </div>
    );
  }

  // ---- Block detail -----------------------------------------------------
  function DetailScreen({ block, onBack, onEdit }) {
    const meta = catMeta(block.category);
    const [copied, setCopied] = React.useState(false);
    const copy = () => { setCopied(true); setTimeout(() => setCopied(false), 1500); };
    const dayStr = block.start.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });

    return (
      <div style={{ position: 'absolute', inset: 0, background: 'var(--sb-background)', display: 'flex', flexDirection: 'column', zIndex: 30 }}>
        {/* nav */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '52px 12px 8px' }}>
          <button onClick={onBack} aria-label="Back" style={{ border: 'none', background: 'transparent', color: 'var(--sb-accent)', display: 'flex', alignItems: 'center', gap: 2, fontFamily: 'var(--sb-font-rounded)', fontWeight: 700, fontSize: 'var(--sb-title-size)', cursor: 'pointer', minHeight: 44 }}>
            <i className="ph-bold ph-caret-left" /> Today
          </button>
          <button onClick={onEdit} style={{ border: 'none', background: 'transparent', color: 'var(--sb-accent)', fontFamily: 'var(--sb-font-rounded)', fontWeight: 700, fontSize: 'var(--sb-title-size)', cursor: 'pointer', minHeight: 44, padding: '0 8px' }}>Edit</button>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', padding: '0 16px 24px', display: 'flex', flexDirection: 'column', gap: 16, fontFamily: 'var(--sb-font-rounded)' }}>
          <h1 style={{ margin: '4px 0 0', fontWeight: 800, fontSize: 28, color: 'var(--sb-text-primary)' }}>{block.title}</h1>

          {/* ingestion buttons */}
          <div style={{ display: 'flex', gap: 8 }}>
            {[['camera', 'Camera'], ['images', 'Photos'], ['file', 'Files']].map(([ic, lb]) => (
              <div key={lb} style={{ flex: 1, minHeight: 44, padding: '12px 0', borderRadius: 'var(--sb-radius-medium)', background: 'var(--sb-surface)', color: 'var(--sb-text-primary)', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <i className={`ph-fill ph-${ic}`} style={{ fontSize: 'var(--sb-title-size)' }} />
                <span style={{ fontSize: 'var(--sb-caption-size)' }}>{lb}</span>
              </div>
            ))}
          </div>

          {/* confirmation code */}
          {block.confirmationCode && (
            <button onClick={copy} style={{ textAlign: 'left', border: 'none', cursor: 'pointer', background: 'var(--sb-surface)', borderRadius: 'var(--sb-radius-medium)', padding: 16, display: 'flex', flexDirection: 'column', gap: 8 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.4px', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>Confirmation code</span>
                <Badge tone={copied ? 'success' : 'soft'} icon={copied ? 'check' : null}>{copied ? 'Copied' : 'Tap to copy'}</Badge>
              </div>
              <span style={{ fontFamily: 'var(--sb-font-mono)', fontWeight: 700, fontSize: 34, color: 'var(--sb-text-primary)', letterSpacing: '1px' }}>{block.confirmationCode}</span>
            </button>
          )}

          {/* links */}
          {block.links && block.links.map((l) => (
            <div key={l} style={{ display: 'flex', alignItems: 'center', gap: 8, minHeight: 44, padding: '12px', borderRadius: 'var(--sb-radius-medium)', background: 'var(--sb-surface)' }}>
              <i className="ph-fill ph-compass" style={{ color: 'var(--sb-accent)', fontSize: 'var(--sb-title-size)' }} />
              <span style={{ flex: 1, color: 'var(--sb-text-primary)', fontSize: 'var(--sb-body-size)' }}>{l}</span>
              <i className="ph-bold ph-arrow-up-right" style={{ color: 'var(--sb-text-secondary)', fontSize: 'var(--sb-caption-size)' }} />
            </div>
          ))}

          {/* info card */}
          <div style={{ background: 'var(--sb-surface)', borderRadius: 'var(--sb-radius-medium)', padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ width: 30, height: 30, borderRadius: 'var(--sb-radius-small)', background: `color-mix(in srgb, ${meta.color} 18%, transparent)`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <i className={`ph-fill ph-${meta.icon}`} style={{ color: meta.text, fontSize: 'var(--sb-caption-size)' }} />
              </span>
              <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.3px', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>{meta.label}</span>
            </div>
            <span style={{ fontWeight: 700, fontSize: 'var(--sb-title-size)', color: 'var(--sb-text-primary)', fontVariantNumeric: 'tabular-nums' }}>{dayStr} · {fmtTime(block.start)} – {fmtTime(block.end)}</span>
            {block.locationName && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <i className="ph-fill ph-map-pin" style={{ color: 'var(--sb-text-secondary)' }} />
                <span style={{ color: 'var(--sb-text-secondary)', fontSize: 'var(--sb-body-size)' }}>{block.locationName}</span>
              </div>
            )}
            {block.address && <span style={{ color: 'var(--sb-text-tertiary)', fontSize: 'var(--sb-caption-size)' }}>{block.address}</span>}
            {block.notes && <span style={{ color: 'var(--sb-text-primary)', fontSize: 'var(--sb-body-size)', marginTop: 4 }}>{block.notes}</span>}
          </div>

          {/* leave by */}
          {block.lat != null && (
            <>
              <span style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.4px', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>Leave by</span>
              <div style={{ background: 'var(--sb-surface)', borderRadius: 'var(--sb-radius-medium)', padding: 16, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <span style={{ fontWeight: 800, fontSize: 'var(--sb-title-lg-size)', color: 'var(--sb-text-primary)', fontVariantNumeric: 'tabular-nums' }}>Leave by {fmtTime(new Date(block.start.getTime() - 35 * 60000))}</span>
                  <span style={{ fontSize: 'var(--sb-caption-size)', color: 'var(--sb-text-secondary)' }}>25m drive · 10 min buffer</span>
                </div>
                <i className="ph-fill ph-car" style={{ color: 'var(--sb-accent)', fontSize: 'var(--sb-title-size)' }} />
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <Button icon="car" fullWidth>Drive</Button>
                <Button icon="tram" fullWidth>Transit</Button>
              </div>
            </>
          )}
        </div>
      </div>
    );
  }

  // ---- Editor sheet -----------------------------------------------------
  function EditorScreen({ suggested, editing, onClose }) {
    const [cat, setCat] = React.useState(editing ? editing.category : 'gig');
    const [title, setTitle] = React.useState(editing ? editing.title : '');
    const start = editing ? editing.start : (suggested ? suggested.start : new Date());
    const end = editing ? editing.end : (suggested ? suggested.end : new Date());

    return (
      <div style={{ position: 'absolute', inset: 0, zIndex: 40, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
        <div onClick={onClose} style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.5)' }} />
        <div style={{ position: 'relative', background: 'var(--sb-surface)', borderRadius: 'var(--sb-radius-large) var(--sb-radius-large) 0 0', padding: '12px 16px 32px', maxHeight: '88%', overflowY: 'auto', fontFamily: 'var(--sb-font-rounded)' }}>
          <div style={{ width: 40, height: 5, borderRadius: 999, background: 'var(--sb-hour-rule)', margin: '0 auto 16px' }} />
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
            <button onClick={onClose} style={{ border: 'none', background: 'transparent', color: 'var(--sb-text-secondary)', fontSize: 'var(--sb-body-size)', fontFamily: 'var(--sb-font-rounded)', cursor: 'pointer', minHeight: 44 }}>Cancel</button>
            <span style={{ fontWeight: 800, fontSize: 'var(--sb-title-size)', color: 'var(--sb-text-primary)' }}>{editing ? 'Edit block' : 'New block'}</span>
            <span style={{ width: 60 }} />
          </div>

          <label style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.2px', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>Title</label>
          <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="What's happening?" style={{
            width: '100%', boxSizing: 'border-box', marginTop: 6, marginBottom: 16, padding: '12px 14px', minHeight: 44,
            background: 'var(--sb-surface-elevated)', border: 'none', borderRadius: 'var(--sb-radius-medium)',
            color: 'var(--sb-text-primary)', fontFamily: 'var(--sb-font-rounded)', fontSize: 'var(--sb-body-size)', outline: 'none',
          }} />

          <label style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.2px', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>Category</label>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, margin: '8px 0 16px' }}>
            {Object.keys(CATEGORIES).map((c) => (
              <CategoryChip key={c} category={c} selected={cat === c} onClick={() => setCat(c)} />
            ))}
          </div>

          <label style={{ fontSize: 'var(--sb-caption-size)', letterSpacing: '1.2px', textTransform: 'uppercase', color: 'var(--sb-text-secondary)' }}>When</label>
          <div style={{ display: 'flex', gap: 8, margin: '8px 0 24px' }}>
            <div style={{ flex: 1, padding: '12px 14px', minHeight: 44, boxSizing: 'border-box', background: 'var(--sb-surface-elevated)', borderRadius: 'var(--sb-radius-medium)', color: 'var(--sb-text-primary)', fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>{fmtTime(start)}</div>
            <span style={{ alignSelf: 'center', color: 'var(--sb-text-tertiary)' }}>→</span>
            <div style={{ flex: 1, padding: '12px 14px', minHeight: 44, boxSizing: 'border-box', background: 'var(--sb-surface-elevated)', borderRadius: 'var(--sb-radius-medium)', color: 'var(--sb-text-primary)', fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>{fmtTime(end)}</div>
          </div>

          <Button fullWidth icon="check" onClick={onClose}>{editing ? 'Save changes' : 'Add block'}</Button>
        </div>
      </div>
    );
  }

  // ---- Tab bar ----------------------------------------------------------
  function TabBar({ tab, onTab }) {
    const tabs = [['today', 'calendar-blank', 'Today'], ['map', 'map-trifold', 'Map'], ['trip', 'suitcase', 'Trip']];
    return (
      <div style={{ display: 'flex', borderTop: '0.5px solid var(--sb-hour-rule)', background: 'var(--sb-background)', paddingBottom: 4 }}>
        {tabs.map(([id, ic, lb]) => {
          const active = tab === id;
          return (
            <button key={id} onClick={() => onTab(id)} style={{ flex: 1, border: 'none', background: 'transparent', cursor: 'pointer', padding: '8px 0', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, color: active ? 'var(--sb-accent)' : 'var(--sb-text-tertiary)' }}>
              <i className={`ph-fill ph-${ic}`} style={{ fontSize: 24 }} />
              <span style={{ fontFamily: 'var(--sb-font-rounded)', fontSize: 11, fontWeight: 700 }}>{lb}</span>
            </button>
          );
        })}
      </div>
    );
  }

  // ---- App shell --------------------------------------------------------
  const { TodayScreen, TripScreen } = window.SBScreens;

  function App({ tweaks }) {
    const [tab, setTab] = React.useState('today');
    const [date, setDate] = React.useState(() => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; });
    const [detail, setDetail] = React.useState(null);
    const [editor, setEditor] = React.useState(null); // {suggested, editing}

    const openBlock = (b) => setDetail(b);
    const openSlot = (s, e) => setEditor({ suggested: { start: s, end: e } });
    const add = () => setEditor({ suggested: { start: new Date(), end: new Date(Date.now() + 3600000) } });

    return (
      <div style={{ height: '100%', display: 'flex', flexDirection: 'column', paddingTop: 50, background: 'var(--sb-background)', position: 'relative' }}>
        <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
          {tab === 'today' && <TodayScreen date={date} onDate={setDate} onOpenBlock={openBlock} onOpenSlot={openSlot} onAdd={add} ppm={tweaks ? tweaks.density : undefined} />}
          {tab === 'map' && <MapScreen date={date} onDate={setDate} onOpenBlock={openBlock} />}
          {tab === 'trip' && <TripScreen onSelectDay={(d) => { setDate(d); setTab('today'); }} />}
        </div>
        <TabBar tab={tab} onTab={setTab} />
        <div style={{ height: 22, background: 'var(--sb-background)' }} />

        {detail && <DetailScreen block={detail} onBack={() => setDetail(null)} onEdit={() => { setEditor({ editing: detail }); }} />}
        {editor && <EditorScreen suggested={editor.suggested} editing={editor.editing} onClose={() => setEditor(null)} />}
      </div>
    );
  }

  window.SBApp = App;
})();
