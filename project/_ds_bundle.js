/* @ds-bundle: {"format":3,"namespace":"StayBusyDesignSystem_0220d6","components":[{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"BlockCard","sourcePath":"components/core/BlockCard.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"CategoryChip","sourcePath":"components/core/CategoryChip.jsx"},{"name":"DayPicker","sourcePath":"components/core/DayPicker.jsx"},{"name":"EmptyState","sourcePath":"components/core/EmptyState.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"NowNextBar","sourcePath":"components/core/NowNextBar.jsx"},{"name":"OpenSlotCard","sourcePath":"components/core/OpenSlotCard.jsx"},{"name":"TimeRangeLabel","sourcePath":"components/core/TimeRangeLabel.jsx"},{"name":"CATEGORIES","sourcePath":"components/core/categories.js"},{"name":"CATEGORY_KEYS","sourcePath":"components/core/categories.js"}],"sourceHashes":{"components/core/Badge.jsx":"528d657e780f","components/core/BlockCard.jsx":"54bb73fd9e17","components/core/Button.jsx":"e0f64b8f135b","components/core/CategoryChip.jsx":"1471c8415525","components/core/DayPicker.jsx":"5092a6e53b6d","components/core/EmptyState.jsx":"465a41929602","components/core/Icon.jsx":"c37bd1fc9db7","components/core/NowNextBar.jsx":"1c91bfc7c2e2","components/core/OpenSlotCard.jsx":"e37c486bed0f","components/core/TimeRangeLabel.jsx":"50b57ec775a9","components/core/categories.js":"9741f2fc507d","ui_kits/staybusy/ios-frame.jsx":"be3343be4b51","ui_kits/staybusy/sb-data.js":"c3dc9fc38a63","ui_kits/staybusy/sb-detail.jsx":"640aba54dfc3","ui_kits/staybusy/sb-screens.jsx":"83e08e5ec26c","ui_kits/staybusy/tweaks-panel.jsx":"6591467622ed"},"inlinedExternals":[],"unexposedExports":[{"name":"categoryMeta","sourcePath":"components/core/categories.js"}]} */

(() => {

const __ds_ns = (window.StayBusyDesignSystem_0220d6 = window.StayBusyDesignSystem_0220d6 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Small status pill. Default "now" tone = solid accent (the NOW badge);
 * "soft" = tinted accent wash; "neutral" = elevated surface. Used for
 * the NOW marker, TAP TO COPY, and small counts.
 */
function Badge({
  children,
  tone = 'now',
  icon = null,
  style = {},
  ...rest
}) {
  const tones = {
    now: {
      bg: 'var(--sb-accent)',
      fg: 'var(--sb-on-accent)'
    },
    soft: {
      bg: 'var(--sb-accent-wash)',
      fg: 'var(--sb-accent)'
    },
    neutral: {
      bg: 'var(--sb-surface-elevated)',
      fg: 'var(--sb-text-secondary)'
    },
    success: {
      bg: 'var(--sb-success)',
      fg: '#05210d'
    }
  };
  const t = tones[tone] || tones.now;
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: '5px',
      padding: '3px 9px',
      borderRadius: '999px',
      background: t.bg,
      color: t.fg,
      fontFamily: 'var(--sb-font-rounded)',
      fontWeight: 'var(--sb-weight-body)',
      fontSize: '11px',
      letterSpacing: 'var(--sb-tracking-label)',
      textTransform: 'uppercase',
      lineHeight: 1.4,
      ...style
    }
  }, rest), icon && /*#__PURE__*/React.createElement("i", {
    className: `ph-fill ph-${icon}`,
    "aria-hidden": "true"
  }), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * StayBusy action button. Two variants map 1:1 to the app's
 * PrimaryButton (accent fill) and SecondaryButton (elevated surface).
 * Always meets the 44pt minimum tap target. Optional leading Phosphor
 * icon (host page must load @phosphor-icons/web fill stylesheet).
 */
function Button({
  children,
  variant = 'primary',
  icon = null,
  fullWidth = false,
  disabled = false,
  onClick,
  style = {},
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  const palettes = {
    primary: {
      bg: 'var(--sb-accent)',
      fg: 'var(--sb-on-accent)'
    },
    secondary: {
      bg: 'var(--sb-surface-elevated)',
      fg: 'var(--sb-text-primary)'
    }
  };
  const p = palettes[variant] || palettes.primary;
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 'var(--sb-space-s)',
    minHeight: 'var(--sb-tap-min)',
    width: fullWidth ? '100%' : 'auto',
    padding: '8px 18px',
    border: 'none',
    borderRadius: 'var(--sb-radius-medium)',
    background: p.bg,
    color: p.fg,
    fontFamily: 'var(--sb-font-rounded)',
    fontWeight: 'var(--sb-weight-title)',
    fontSize: 'var(--sb-title-size)',
    lineHeight: 1,
    cursor: disabled ? 'default' : 'pointer',
    opacity: disabled ? 0.4 : 1,
    transform: pressed && !disabled ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
    transition: 'transform var(--sb-motion-snap)',
    WebkitTapHighlightColor: 'transparent',
    ...style
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    style: base,
    disabled: disabled,
    onClick: onClick,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false)
  }, rest), icon && /*#__PURE__*/React.createElement("i", {
    className: `ph-fill ph-${icon}`,
    style: {
      fontSize: '1.15em'
    },
    "aria-hidden": "true"
  }), children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/DayPicker.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function isSameDay(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}
function headline(d) {
  return d.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric'
  });
}
function Chevron({
  dir,
  onClick,
  label
}) {
  const [pressed, setPressed] = React.useState(false);
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": label,
    onClick: onClick,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    style: {
      width: 'var(--sb-tap-min)',
      height: 'var(--sb-tap-min)',
      flexShrink: 0,
      borderRadius: '50%',
      border: 'none',
      background: 'var(--sb-surface)',
      color: 'var(--sb-text-primary)',
      fontSize: 'var(--sb-title-size)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer',
      transform: pressed ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
      transition: 'transform var(--sb-motion-snap)',
      WebkitTapHighlightColor: 'transparent'
    }
  }, /*#__PURE__*/React.createElement("i", {
    className: `ph-bold ph-caret-${dir}`,
    "aria-hidden": "true"
  }));
}

/**
 * Shared day navigator used by Today and Map. Chevrons step ±1 day
 * (44pt targets); the center shows the date and either a TODAY marker
 * or a JUMP TO TODAY action so you're never stranded on another day.
 */
function DayPicker({
  date,
  onChange,
  style = {},
  ...rest
}) {
  const d = date instanceof Date ? date : new Date(date);
  const today = new Date();
  const isToday = isSameDay(d, today);
  const step = days => {
    const next = new Date(d);
    next.setDate(next.getDate() + days);
    next.setHours(0, 0, 0, 0);
    onChange && onChange(next);
  };
  const jumpToday = () => {
    const t = new Date();
    t.setHours(0, 0, 0, 0);
    onChange && onChange(t);
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--sb-space-l)',
      padding: 'var(--sb-space-m) var(--sb-space-l) var(--sb-space-s)',
      fontFamily: 'var(--sb-font-rounded)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(Chevron, {
    dir: "left",
    label: "Previous day",
    onClick: () => step(-1)
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: '2px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 'var(--sb-weight-title)',
      fontSize: 'var(--sb-title-size)',
      color: 'var(--sb-text-primary)'
    }
  }, headline(d)), isToday ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-caption-size)',
      letterSpacing: '1.6px',
      color: 'var(--sb-accent)',
      fontWeight: 'var(--sb-weight-body)'
    }
  }, "TODAY") : /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: jumpToday,
    style: {
      border: 'none',
      background: 'transparent',
      cursor: 'pointer',
      fontFamily: 'var(--sb-font-rounded)',
      fontWeight: 'var(--sb-weight-body)',
      fontSize: 'var(--sb-caption-size)',
      letterSpacing: '1.4px',
      color: 'var(--sb-accent)',
      padding: '2px 6px'
    }
  }, "JUMP TO TODAY")), /*#__PURE__*/React.createElement(Chevron, {
    dir: "right",
    label: "Next day",
    onClick: () => step(1)
  }));
}
Object.assign(__ds_scope, { DayPicker });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/DayPicker.jsx", error: String((e && e.message) || e) }); }

// components/core/EmptyState.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Reusable empty state. Enforces design law 1 — no dead-end screen:
 * every empty state offers one button that starts the user toward
 * filling it. Centered Phosphor glyph, title, optional message + action.
 */
function EmptyState({
  icon = 'calendar-blank',
  title,
  message,
  actionLabel,
  onAction,
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      textAlign: 'center',
      gap: 'var(--sb-space-m)',
      padding: 'var(--sb-space-xl)',
      fontFamily: 'var(--sb-font-rounded)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("i", {
    className: `ph-fill ph-${icon}`,
    style: {
      fontSize: '44px',
      color: 'var(--sb-text-secondary)'
    },
    "aria-hidden": "true"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 'var(--sb-weight-heavy)',
      fontSize: 'var(--sb-title-lg-size)',
      lineHeight: 'var(--sb-title-lg-line)',
      color: 'var(--sb-text-primary)'
    }
  }, title), message && /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 'var(--sb-weight-body)',
      fontSize: 'var(--sb-body-size)',
      lineHeight: 'var(--sb-body-line)',
      color: 'var(--sb-text-secondary)',
      maxWidth: '320px'
    }
  }, message), actionLabel && onAction && /*#__PURE__*/React.createElement(__ds_scope.Button, {
    icon: "plus",
    onClick: onAction,
    style: {
      marginTop: 'var(--sb-space-s)',
      minWidth: '180px'
    }
  }, actionLabel));
}
Object.assign(__ds_scope, { EmptyState });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/EmptyState.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * StayBusy icon. A thin, brand-defaulted wrapper over Phosphor Icons —
 * the web stand-in for SF Symbols. Defaults to the `fill` weight (the
 * app's filled-rounded look); pass weight="bold" for chevrons / plus.
 * Host page must load the matching @phosphor-icons/web weight stylesheet.
 *
 * Decorative by default (aria-hidden). Pass `label` to make it a
 * standalone meaningful icon (adds role="img" + aria-label).
 */
function Icon({
  name,
  weight = 'fill',
  size = '1.15em',
  color = 'currentColor',
  label = null,
  style = {},
  ...rest
}) {
  const px = typeof size === 'number' ? `${size}px` : size;
  const a11y = label ? {
    role: 'img',
    'aria-label': label
  } : {
    'aria-hidden': 'true'
  };
  return /*#__PURE__*/React.createElement("i", _extends({
    className: `ph-${weight} ph-${name}`,
    style: {
      fontSize: px,
      lineHeight: 1,
      color,
      display: 'inline-flex',
      flexShrink: 0,
      ...style
    }
  }, a11y, rest));
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/core/TimeRangeLabel.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function fmt(d) {
  let h = d.getHours();
  const m = d.getMinutes();
  const ap = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h === 0) h = 12;
  return `${h}:${m.toString().padStart(2, '0')} ${ap}`;
}

/**
 * Monospaced-digit start–end time range, used everywhere a block's
 * window is shown so the digits never jitter or shift width.
 * Accepts Date objects or anything the Date constructor parses.
 */
function TimeRangeLabel({
  start,
  end,
  size = 'caption',
  style = {},
  ...rest
}) {
  const s = start instanceof Date ? start : new Date(start);
  const e = end instanceof Date ? end : new Date(end);
  const sizes = {
    caption: {
      fontSize: 'var(--sb-caption-size)',
      lineHeight: 'var(--sb-caption-line)'
    },
    title: {
      fontSize: 'var(--sb-title-size)',
      lineHeight: 'var(--sb-title-line)',
      color: 'var(--sb-text-primary)'
    }
  };
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      fontFamily: 'var(--sb-font-rounded)',
      fontWeight: 'var(--sb-weight-body)',
      fontVariantNumeric: 'tabular-nums',
      whiteSpace: 'nowrap',
      color: 'var(--sb-text-secondary)',
      ...(sizes[size] || sizes.caption),
      ...style
    },
    "aria-label": `${fmt(s)} to ${fmt(e)}`
  }, rest), fmt(s), " \u2013 ", fmt(e));
}
Object.assign(__ds_scope, { TimeRangeLabel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/TimeRangeLabel.jsx", error: String((e && e.message) || e) }); }

// components/core/OpenSlotCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function durationString(start, end) {
  const total = Math.round((end - start) / 60000);
  const h = Math.floor(total / 60);
  const m = total % 60;
  if (h > 0 && m > 0) return `${h}h ${m}m`;
  if (h > 0) return `${h}h`;
  return `${m}m`;
}

/**
 * Dashed-border card for free time on the timeline. Deliberately a
 * different KIND of object than a real block — no category stripe, no
 * fill — so a glance can never confuse "open" with "scheduled". Rest
 * and buffer are visible here, not invisible.
 */
function OpenSlotCard({
  start,
  end,
  onClick,
  style = {},
  ...rest
}) {
  const s = start instanceof Date ? start : new Date(start);
  const e = end instanceof Date ? end : new Date(end);
  const [pressed, setPressed] = React.useState(false);
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    onClick: onClick,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    "aria-label": `Open time, ${durationString(s, e)}`,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--sb-space-s)',
      width: '100%',
      height: '100%',
      minHeight: 'var(--sb-tap-min)',
      boxSizing: 'border-box',
      padding: 'var(--sb-space-m)',
      background: 'transparent',
      border: 'var(--sb-stroke-open-width) dashed var(--sb-open-slot)',
      borderRadius: 'var(--sb-radius-medium)',
      cursor: 'pointer',
      textAlign: 'left',
      fontFamily: 'var(--sb-font-rounded)',
      transform: pressed ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
      transition: 'transform var(--sb-motion-snap)',
      WebkitTapHighlightColor: 'transparent',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 'var(--sb-space-xs)',
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-body-size)',
      fontWeight: 'var(--sb-weight-body)',
      letterSpacing: '0.8px',
      color: 'var(--sb-text-tertiary)'
    }
  }, "OPEN \u2014 ", durationString(s, e)), /*#__PURE__*/React.createElement(__ds_scope.TimeRangeLabel, {
    start: s,
    end: e
  })), /*#__PURE__*/React.createElement("i", {
    className: "ph ph-plus-circle",
    style: {
      fontSize: 'var(--sb-title-size)',
      color: 'var(--sb-text-tertiary)'
    },
    "aria-hidden": "true"
  }));
}
Object.assign(__ds_scope, { OpenSlotCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/OpenSlotCard.jsx", error: String((e && e.message) || e) }); }

// components/core/categories.js
try { (() => {
// Shared category metadata for StayBusy components.
// Color values reference the design-system CSS custom properties so
// tokens remain the single source of truth. `icon` is a Phosphor glyph
// name (host page must load @phosphor-icons/web fill stylesheet).
const CATEGORIES = {
  gig: {
    label: 'Gig',
    color: 'var(--sb-cat-gig)',
    text: 'var(--sb-cat-gig-text)',
    icon: 'microphone-stage'
  },
  travel: {
    label: 'Travel',
    color: 'var(--sb-cat-travel)',
    text: 'var(--sb-cat-travel-text)',
    icon: 'airplane-tilt'
  },
  food: {
    label: 'Food',
    color: 'var(--sb-cat-food)',
    text: 'var(--sb-cat-food-text)',
    icon: 'fork-knife'
  },
  social: {
    label: 'Social',
    color: 'var(--sb-cat-social)',
    text: 'var(--sb-cat-social-text)',
    icon: 'users'
  },
  work: {
    label: 'Work',
    color: 'var(--sb-cat-work)',
    text: 'var(--sb-cat-work-text)',
    icon: 'laptop'
  },
  explore: {
    label: 'Explore',
    color: 'var(--sb-cat-explore)',
    text: 'var(--sb-cat-explore-text)',
    icon: 'map-trifold'
  },
  rest: {
    label: 'Rest',
    color: 'var(--sb-cat-rest)',
    text: 'var(--sb-cat-rest-text)',
    icon: 'moon-stars'
  },
  admin: {
    label: 'Admin',
    color: 'var(--sb-cat-admin)',
    text: 'var(--sb-cat-admin-text)',
    icon: 'tray'
  }
};
const CATEGORY_KEYS = Object.keys(CATEGORIES);
function categoryMeta(key) {
  return CATEGORIES[key] || CATEGORIES.admin;
}
Object.assign(__ds_scope, { CATEGORIES, CATEGORY_KEYS, categoryMeta });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/categories.js", error: String((e && e.message) || e) }); }

// components/core/BlockCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * The core schedule card. One block, three layout variants and a set of
 * composable states. Current blocks carry the accent border so they're
 * findable in one glance; past blocks dim to 40% but never disappear.
 */
function BlockCard({
  block,
  variant = 'timeline',
  isCurrent = false,
  isPast = false,
  hasOverlap = false,
  onClick,
  style = {},
  ...rest
}) {
  const meta = __ds_scope.categoryMeta(block.category);
  const [pressed, setPressed] = React.useState(false);
  const isList = variant === 'list';
  const surface = variant === 'compact' ? 'var(--sb-surface-elevated)' : 'var(--sb-surface)';
  const wrap = {
    position: 'relative',
    display: 'flex',
    alignItems: 'stretch',
    width: '100%',
    height: '100%',
    boxSizing: 'border-box',
    borderRadius: 'var(--sb-radius-medium)',
    background: surface,
    overflow: 'hidden',
    border: isCurrent ? 'var(--sb-stroke-current) solid var(--sb-accent)' : 'var(--sb-stroke-current) solid transparent',
    boxShadow: isCurrent ? 'var(--sb-glow-current)' : 'none',
    opacity: isPast ? 'var(--sb-opacity-past)' : 1,
    cursor: onClick ? 'pointer' : 'default',
    transform: pressed && onClick ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
    transition: 'transform var(--sb-motion-snap)',
    textAlign: 'left',
    fontFamily: 'var(--sb-font-rounded)',
    WebkitTapHighlightColor: 'transparent',
    ...style
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    style: wrap,
    onClick: onClick,
    onPointerDown: () => onClick && setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false)
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 'var(--sb-stripe-width)',
      background: meta.color,
      borderRadius: '3px',
      margin: 'var(--sb-space-xs) 0',
      flexShrink: 0
    },
    "aria-hidden": "true"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 'var(--sb-space-xs)',
      padding: isList ? 'var(--sb-space-s) var(--sb-space-m)' : 'var(--sb-space-m)',
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--sb-space-xs)',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("i", {
    className: `ph-fill ph-${meta.icon}`,
    style: {
      color: meta.text,
      fontSize: 'var(--sb-caption-size)'
    },
    "aria-hidden": "true"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-caption-size)',
      letterSpacing: 'var(--sb-tracking-label)',
      textTransform: 'uppercase',
      fontWeight: 'var(--sb-weight-body)',
      color: 'var(--sb-text-secondary)'
    }
  }, meta.label), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1
    }
  }), isCurrent && /*#__PURE__*/React.createElement(__ds_scope.Badge, {
    tone: "now"
  }, "Now"), hasOverlap && /*#__PURE__*/React.createElement("i", {
    className: "ph-fill ph-warning",
    style: {
      color: 'var(--sb-warning)',
      fontSize: 'var(--sb-caption-size)'
    },
    "aria-label": "Overlaps another block"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 'var(--sb-weight-title)',
      fontSize: 'var(--sb-title-size)',
      lineHeight: 'var(--sb-title-line)',
      color: 'var(--sb-text-primary)',
      flexShrink: 0,
      display: '-webkit-box',
      WebkitLineClamp: isList ? 1 : 2,
      WebkitBoxOrient: 'vertical',
      overflow: 'hidden'
    }
  }, block.title), !isList && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--sb-space-xs)',
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.TimeRangeLabel, {
    start: block.start,
    end: block.end
  }), block.locationName && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--sb-text-tertiary)'
    }
  }, "\xB7"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-caption-size)',
      color: 'var(--sb-text-secondary)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, block.locationName)))));
}
Object.assign(__ds_scope, { BlockCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/BlockCard.jsx", error: String((e && e.message) || e) }); }

// components/core/CategoryChip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Category selector chip. Color is never the only signal — the Phosphor
 * glyph always rides alongside it. Selected = filled with the category
 * color; unselected = surface with a tinted outline.
 */
function CategoryChip({
  category = 'admin',
  selected = false,
  onClick,
  style = {},
  ...rest
}) {
  const meta = __ds_scope.categoryMeta(category);
  const [pressed, setPressed] = React.useState(false);
  const wrap = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 'var(--sb-space-xs)',
    minHeight: 'var(--sb-tap-min)',
    padding: '8px 14px',
    borderRadius: '999px',
    border: selected ? '1.2px solid transparent' : '1.2px solid color-mix(in srgb, ' + meta.color + ' 55%, transparent)',
    background: selected ? meta.color : 'var(--sb-surface)',
    color: selected ? 'var(--sb-on-accent)' : 'var(--sb-text-primary)',
    fontFamily: 'var(--sb-font-rounded)',
    fontWeight: 'var(--sb-weight-body)',
    fontSize: 'var(--sb-body-size)',
    lineHeight: 1,
    cursor: 'pointer',
    transform: pressed ? 'scale(var(--sb-scale-pressed))' : 'scale(1)',
    transition: 'transform var(--sb-motion-snap)',
    WebkitTapHighlightColor: 'transparent',
    ...style
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "checkbox",
    "aria-checked": selected,
    "aria-label": meta.label,
    style: wrap,
    onClick: onClick,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false)
  }, rest), /*#__PURE__*/React.createElement("i", {
    className: `ph-fill ph-${meta.icon}`,
    style: {
      fontSize: '1.05em'
    },
    "aria-hidden": "true"
  }), meta.label);
}
Object.assign(__ds_scope, { CategoryChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/CategoryChip.jsx", error: String((e && e.message) || e) }); }

// components/core/NowNextBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function fmtTime(d) {
  let h = d.getHours();
  const m = d.getMinutes();
  const ap = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h === 0) h = 12;
  return `${h}:${m.toString().padStart(2, '0')} ${ap}`;
}
function countdown(from, to) {
  const total = Math.max(0, Math.floor((to - from) / 1000));
  const h = Math.floor(total / 3600);
  const m = Math.floor(total % 3600 / 60);
  const s = total % 60;
  if (h > 0) return `${h}h ${m.toString().padStart(2, '0')}m`;
  return `${m}m ${s.toString().padStart(2, '0')}s`;
}
function sameDay(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}
function deriveState(now, blocks) {
  const list = blocks.map(b => ({
    ...b,
    _s: new Date(b.start),
    _e: new Date(b.end)
  })).sort((a, b) => a._s - b._s);
  const current = list.find(b => b._s <= now && now < b._e);
  if (current) {
    const next = list.find(b => b._s > now && sameDay(b._s, now));
    return {
      kind: 'current',
      current,
      next
    };
  }
  const nextToday = list.find(b => b._s > now && sameDay(b._s, now));
  if (nextToday) return {
    kind: 'between',
    next: nextToday
  };
  const tmw = new Date(now);
  tmw.setDate(tmw.getDate() + 1);
  tmw.setHours(0, 0, 0, 0);
  const firstTmw = list.find(b => sameDay(b._s, tmw));
  return {
    kind: 'done',
    tomorrow: firstTmw || null
  };
}
function NextLine({
  label,
  block
}) {
  const meta = __ds_scope.categoryMeta(block.category);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--sb-space-s)',
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: '8px',
      height: '8px',
      borderRadius: '50%',
      background: meta.color,
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("i", {
    className: `ph-fill ph-${meta.icon}`,
    style: {
      color: meta.text,
      fontSize: 'var(--sb-caption-size)'
    },
    "aria-hidden": "true"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-caption-size)',
      letterSpacing: 'var(--sb-tracking-eyebrow)',
      color: 'var(--sb-text-secondary)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-body-size)',
      color: 'var(--sb-text-primary)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, block.title), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-caption-size)',
      color: 'var(--sb-text-secondary)',
      fontVariantNumeric: 'tabular-nums'
    }
  }, fmtTime(new Date(block.start))));
}
function Divider() {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '1px',
      background: 'var(--sb-divider)'
    }
  });
}
function PrimaryRow({
  color,
  text,
  icon,
  eyebrow,
  title,
  trailingLabel,
  trailing,
  trailingColor
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--sb-space-m)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 'var(--sb-tap-min)',
      height: 'var(--sb-tap-min)',
      flexShrink: 0,
      borderRadius: 'var(--sb-radius-small)',
      background: `color-mix(in srgb, ${color} 18%, transparent)`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("i", {
    className: `ph-fill ph-${icon}`,
    style: {
      color: text,
      fontSize: 'var(--sb-title-size)'
    },
    "aria-hidden": "true"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: '2px',
      minWidth: 0,
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-caption-size)',
      letterSpacing: 'var(--sb-tracking-eyebrow)',
      textTransform: 'uppercase',
      color: 'var(--sb-text-secondary)'
    }
  }, eyebrow), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 'var(--sb-weight-heavy)',
      fontSize: 'var(--sb-title-lg-size)',
      color: 'var(--sb-text-primary)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, title)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'flex-end',
      gap: '2px',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-caption-size)',
      letterSpacing: 'var(--sb-tracking-eyebrow)',
      textTransform: 'uppercase',
      color: 'var(--sb-text-secondary)'
    }
  }, trailingLabel), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 'var(--sb-weight-heavy)',
      fontSize: 'var(--sb-display-size)',
      lineHeight: 1,
      color: trailingColor,
      fontVariantNumeric: 'tabular-nums',
      whiteSpace: 'nowrap'
    }
  }, trailing)));
}

/**
 * The pinned Now/Next bar — the answer to "what am I doing now and
 * what's next" in under a second. Three states, and it NEVER goes empty:
 * current block, free-until-next, or done-for-today (with tomorrow's
 * first block). Ticks live unless a fixed `now` is supplied.
 */
function NowNextBar({
  blocks = [],
  now = null,
  style = {},
  ...rest
}) {
  const [tick, setTick] = React.useState(() => now ? new Date(now) : new Date());
  React.useEffect(() => {
    if (now) {
      setTick(new Date(now));
      return;
    }
    const id = setInterval(() => setTick(new Date()), 1000);
    return () => clearInterval(id);
  }, [now]);
  const state = deriveState(tick, blocks);
  const shell = {
    padding: 'var(--sb-space-m)',
    borderRadius: 'var(--sb-radius-medium)',
    background: 'var(--sb-surface-elevated)',
    fontFamily: 'var(--sb-font-rounded)',
    display: 'flex',
    flexDirection: 'column',
    gap: 'var(--sb-space-m)',
    ...style
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: shell
  }, rest), state.kind === 'current' && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PrimaryRow, {
    color: __ds_scope.categoryMeta(state.current.category).color,
    text: __ds_scope.categoryMeta(state.current.category).text,
    icon: __ds_scope.categoryMeta(state.current.category).icon,
    eyebrow: "Now",
    title: state.current.title,
    trailingLabel: "Ends in",
    trailing: countdown(tick, state.current._e),
    trailingColor: "var(--sb-text-primary)"
  }), state.next && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Divider, null), /*#__PURE__*/React.createElement(NextLine, {
    label: "Next",
    block: state.next
  }))), state.kind === 'between' && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(PrimaryRow, {
    color: "var(--sb-text-tertiary)",
    text: "var(--sb-text-tertiary)",
    icon: "clock",
    eyebrow: "Free until",
    title: state.next.title,
    trailingLabel: "Starts in",
    trailing: countdown(tick, state.next._s),
    trailingColor: "var(--sb-accent)"
  }), /*#__PURE__*/React.createElement(Divider, null), /*#__PURE__*/React.createElement(NextLine, {
    label: "Next",
    block: state.next
  })), state.kind === 'done' && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--sb-space-s)'
    }
  }, /*#__PURE__*/React.createElement("i", {
    className: "ph-fill ph-check-circle",
    style: {
      color: 'var(--sb-success)',
      fontSize: 'var(--sb-title-size)'
    },
    "aria-hidden": "true"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 'var(--sb-weight-title)',
      fontSize: 'var(--sb-title-size)',
      color: 'var(--sb-text-primary)'
    }
  }, "Done for today")), state.tomorrow ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Divider, null), /*#__PURE__*/React.createElement(NextLine, {
    label: "Tomorrow",
    block: state.tomorrow
  })) : /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--sb-body-size)',
      color: 'var(--sb-text-secondary)'
    }
  }, "Nothing scheduled yet")));
}
Object.assign(__ds_scope, { NowNextBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/NowNextBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/staybusy/ios-frame.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)

/* BEGIN USAGE */
// iOS.jsx — Simplified iOS 26 (Liquid Glass) device frame
// Based on the iOS 26 UI Kit + Figma status bar spec. No assets, no deps.
// Exports (to window): IOSDevice, IOSStatusBar, IOSNavBar, IOSGlassPill, IOSList, IOSListRow, IOSKeyboard
//
// Usage — wrap your screen content in <IOSDevice> to get the bezel, status bar
// and home indicator (props: title, dark, keyboard):
//
//   <IOSDevice title="Settings">
//     ...your screen content...
//   </IOSDevice>
//   <IOSDevice dark title="Search" keyboard>…</IOSDevice>
/* END USAGE */

// ─────────────────────────────────────────────────────────────
// Status bar
// ─────────────────────────────────────────────────────────────
function IOSStatusBar({
  dark = false,
  time = '9:41'
}) {
  const c = dark ? '#fff' : '#000';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 154,
      alignItems: 'center',
      justifyContent: 'center',
      padding: '21px 24px 19px',
      boxSizing: 'border-box',
      position: 'relative',
      zIndex: 20,
      width: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      paddingTop: 1.5
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 590,
      fontSize: 17,
      lineHeight: '22px',
      color: c
    }
  }, time)), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 7,
      paddingTop: 1,
      paddingRight: 1
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "19",
    height: "12",
    viewBox: "0 0 19 12"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "7.5",
    width: "3.2",
    height: "4.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "4.8",
    y: "5",
    width: "3.2",
    height: "7",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "9.6",
    y: "2.5",
    width: "3.2",
    height: "9.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "14.4",
    y: "0",
    width: "3.2",
    height: "12",
    rx: "0.7",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "17",
    height: "12",
    viewBox: "0 0 17 12"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M8.5 3.2C10.8 3.2 12.9 4.1 14.4 5.6L15.5 4.5C13.7 2.7 11.2 1.5 8.5 1.5C5.8 1.5 3.3 2.7 1.5 4.5L2.6 5.6C4.1 4.1 6.2 3.2 8.5 3.2Z",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M8.5 6.8C9.9 6.8 11.1 7.3 12 8.2L13.1 7.1C11.8 5.9 10.2 5.1 8.5 5.1C6.8 5.1 5.2 5.9 3.9 7.1L5 8.2C5.9 7.3 7.1 6.8 8.5 6.8Z",
    fill: c
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "8.5",
    cy: "10.5",
    r: "1.5",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "27",
    height: "13",
    viewBox: "0 0 27 13"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0.5",
    y: "0.5",
    width: "23",
    height: "12",
    rx: "3.5",
    stroke: c,
    strokeOpacity: "0.35",
    fill: "none"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "2",
    y: "2",
    width: "20",
    height: "9",
    rx: "2",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M25 4.5V8.5C25.8 8.2 26.5 7.2 26.5 6.5C26.5 5.8 25.8 4.8 25 4.5Z",
    fill: c,
    fillOpacity: "0.4"
  }))));
}

// ─────────────────────────────────────────────────────────────
// Liquid glass pill — blur + tint + shine
// ─────────────────────────────────────────────────────────────
function IOSGlassPill({
  children,
  dark = false,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44,
      minWidth: 44,
      borderRadius: 9999,
      position: 'relative',
      overflow: 'hidden',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: dark ? '0 2px 6px rgba(0,0,0,0.35), 0 6px 16px rgba(0,0,0,0.2)' : '0 1px 3px rgba(0,0,0,0.07), 0 3px 10px rgba(0,0,0,0.06)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.28)' : 'rgba(255,255,255,0.5)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15), inset -1px -1px 1px rgba(255,255,255,0.08)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 1,
      display: 'flex',
      alignItems: 'center',
      padding: '0 4px'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Navigation bar — glass pills + large title
// ─────────────────────────────────────────────────────────────
function IOSNavBar({
  title = 'Title',
  dark = false,
  trailingIcon = true
}) {
  const muted = dark ? 'rgba(255,255,255,0.6)' : '#404040';
  const text = dark ? '#fff' : '#000';
  const pillIcon = content => /*#__PURE__*/React.createElement(IOSGlassPill, {
    dark: dark
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, content));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      paddingTop: 62,
      paddingBottom: 10,
      position: 'relative',
      zIndex: 5
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 16px'
    }
  }, pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "12",
    height: "20",
    viewBox: "0 0 12 20",
    fill: "none",
    style: {
      marginLeft: -1
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M10 2L2 10l8 8",
    stroke: muted,
    strokeWidth: "2.5",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }))), trailingIcon && pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "22",
    height: "6",
    viewBox: "0 0 22 6"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "3",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "11",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "19",
    cy: "3",
    r: "2.5",
    fill: muted
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 16px',
      fontFamily: '-apple-system, system-ui',
      fontSize: 34,
      fontWeight: 700,
      lineHeight: '41px',
      color: text,
      letterSpacing: 0.4
    }
  }, title));
}

// ─────────────────────────────────────────────────────────────
// Grouped list (inset card, r:26) + row (52px)
// ─────────────────────────────────────────────────────────────
function IOSListRow({
  title,
  detail,
  icon,
  chevron = true,
  isLast = false,
  dark = false
}) {
  const text = dark ? '#fff' : '#000';
  const sec = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const ter = dark ? 'rgba(235,235,245,0.3)' : 'rgba(60,60,67,0.3)';
  const sep = dark ? 'rgba(84,84,88,0.65)' : 'rgba(60,60,67,0.12)';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 52,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      letterSpacing: -0.43
    }
  }, icon && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 30,
      height: 30,
      borderRadius: 7,
      background: icon,
      marginRight: 12,
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      color: text
    }
  }, title), detail && /*#__PURE__*/React.createElement("span", {
    style: {
      color: sec,
      marginRight: 6
    }
  }, detail), chevron && /*#__PURE__*/React.createElement("svg", {
    width: "8",
    height: "14",
    viewBox: "0 0 8 14",
    style: {
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M1 1l6 6-6 6",
    stroke: ter,
    strokeWidth: "2",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), !isLast && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      right: 0,
      left: icon ? 58 : 16,
      height: 0.5,
      background: sep
    }
  }));
}
function IOSList({
  header,
  children,
  dark = false
}) {
  const hc = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const bg = dark ? '#1C1C1E' : '#fff';
  return /*#__PURE__*/React.createElement("div", null, header && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: '-apple-system, system-ui',
      fontSize: 13,
      color: hc,
      textTransform: 'uppercase',
      padding: '8px 36px 6px',
      letterSpacing: -0.08
    }
  }, header), /*#__PURE__*/React.createElement("div", {
    style: {
      background: bg,
      borderRadius: 26,
      margin: '0 16px',
      overflow: 'hidden'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Device frame
// ─────────────────────────────────────────────────────────────
function IOSDevice({
  children,
  width = 402,
  height = 874,
  dark = false,
  title,
  keyboard = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width,
      height,
      borderRadius: 48,
      overflow: 'hidden',
      position: 'relative',
      background: dark ? '#000' : '#F2F2F7',
      boxShadow: '0 40px 80px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.12)',
      fontFamily: '-apple-system, system-ui, sans-serif',
      WebkitFontSmoothing: 'antialiased'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 11,
      left: '50%',
      transform: 'translateX(-50%)',
      width: 126,
      height: 37,
      borderRadius: 24,
      background: '#000',
      zIndex: 50
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      zIndex: 10
    }
  }, /*#__PURE__*/React.createElement(IOSStatusBar, {
    dark: dark
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      display: 'flex',
      flexDirection: 'column'
    }
  }, title !== undefined && /*#__PURE__*/React.createElement(IOSNavBar, {
    title: title,
    dark: dark
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflow: 'auto'
    }
  }, children), keyboard && /*#__PURE__*/React.createElement(IOSKeyboard, {
    dark: dark
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      zIndex: 60,
      height: 34,
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'flex-end',
      paddingBottom: 8,
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 139,
      height: 5,
      borderRadius: 100,
      background: dark ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.25)'
    }
  })));
}

// ─────────────────────────────────────────────────────────────
// Keyboard — iOS 26 liquid glass
// ─────────────────────────────────────────────────────────────
function IOSKeyboard({
  dark = false
}) {
  const glyph = dark ? 'rgba(255,255,255,0.7)' : '#595959';
  const sugg = dark ? 'rgba(255,255,255,0.6)' : '#333';
  const keyBg = dark ? 'rgba(255,255,255,0.22)' : 'rgba(255,255,255,0.85)';

  // special-key icons
  const icons = {
    shift: /*#__PURE__*/React.createElement("svg", {
      width: "19",
      height: "17",
      viewBox: "0 0 19 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M9.5 1L1 9.5h4.5V16h8V9.5H18L9.5 1z",
      fill: glyph
    })),
    del: /*#__PURE__*/React.createElement("svg", {
      width: "23",
      height: "17",
      viewBox: "0 0 23 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M7 1h13a2 2 0 012 2v11a2 2 0 01-2 2H7l-6-7.5L7 1z",
      fill: "none",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinejoin: "round"
    }), /*#__PURE__*/React.createElement("path", {
      d: "M10 5l7 7M17 5l-7 7",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinecap: "round"
    })),
    ret: /*#__PURE__*/React.createElement("svg", {
      width: "20",
      height: "14",
      viewBox: "0 0 20 14"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M18 1v6H4m0 0l4-4M4 7l4 4",
      fill: "none",
      stroke: "#fff",
      strokeWidth: "1.8",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    }))
  };
  const key = (content, {
    w,
    flex,
    ret,
    fs = 25,
    k
  } = {}) => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      height: 42,
      borderRadius: 8.5,
      flex: flex ? 1 : undefined,
      width: w,
      minWidth: 0,
      background: ret ? '#08f' : keyBg,
      boxShadow: '0 1px 0 rgba(0,0,0,0.075)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: '-apple-system, "SF Compact", system-ui',
      fontSize: fs,
      fontWeight: 458,
      color: ret ? '#fff' : glyph
    }
  }, content);
  const row = (keys, pad = 0) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      justifyContent: 'center',
      padding: `0 ${pad}px`
    }
  }, keys.map(l => key(l, {
    flex: true,
    k: l
  })));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 15,
      borderRadius: 27,
      overflow: 'hidden',
      padding: '11px 0 2px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      boxShadow: dark ? '0 -2px 20px rgba(0,0,0,0.09)' : '0 -1px 6px rgba(0,0,0,0.018), 0 -3px 20px rgba(0,0,0,0.012)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.14)' : 'rgba(255,255,255,0.25)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 20,
      alignItems: 'center',
      padding: '8px 22px 13px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, ['"The"', 'the', 'to'].map((w, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: i
  }, i > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 1,
      height: 25,
      background: '#ccc',
      opacity: 0.3
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      color: sugg,
      letterSpacing: -0.43,
      lineHeight: '22px'
    }
  }, w)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 13,
      padding: '0 6.5px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, row(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']), row(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'], 20), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14.25,
      alignItems: 'center'
    }
  }, key(icons.shift, {
    w: 45,
    k: 'shift'
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      flex: 1
    }
  }, ['z', 'x', 'c', 'v', 'b', 'n', 'm'].map(l => key(l, {
    flex: true,
    k: l
  }))), key(icons.del, {
    w: 45,
    k: 'del'
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      alignItems: 'center'
    }
  }, key('ABC', {
    w: 92.25,
    fs: 18,
    k: 'abc'
  }), key('', {
    flex: true,
    k: 'space'
  }), key(icons.ret, {
    w: 92.25,
    ret: true,
    k: 'ret'
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 56,
      width: '100%',
      position: 'relative'
    }
  }));
}
Object.assign(window, {
  IOSDevice,
  IOSStatusBar,
  IOSNavBar,
  IOSGlassPill,
  IOSList,
  IOSListRow,
  IOSKeyboard
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/staybusy/ios-frame.jsx", error: String((e && e.message) || e) }); }

// ui_kits/staybusy/sb-data.js
try { (() => {
// Sample schedule data for the StayBusy UI kit — modeled on the app's
// SampleData.swift (a touring musician's two days). Times are built
// relative to "today" so the Now/Next bar and now-line stay live.
(function () {
  function at(dayOffset, h, m) {
    const d = new Date();
    d.setDate(d.getDate() + dayOffset);
    d.setHours(h, m || 0, 0, 0);
    return d;
  }
  const blocks = [{
    id: 'b1',
    title: 'Hotel breakfast',
    start: at(0, 8, 0),
    end: at(0, 9, 0),
    category: 'food',
    locationName: 'The Standard',
    address: '25 Cooper Square, New York, NY',
    lat: 40.728,
    lng: -73.991
  }, {
    id: 'b2',
    title: 'Travel to venue',
    start: at(0, 11, 30),
    end: at(0, 12, 30),
    category: 'travel',
    locationName: 'Brooklyn Steel',
    lat: 40.722,
    lng: -73.933
  }, {
    id: 'b3',
    title: 'Soundcheck',
    start: at(0, 14, 0),
    end: at(0, 15, 30),
    category: 'gig',
    locationName: 'Brooklyn Steel',
    address: '319 Frost St, Brooklyn, NY',
    confirmationCode: 'BS-44721',
    notes: 'Backline ready. Talk to Mara about monitors.',
    links: ['brooklynsteel.com/advance'],
    lat: 40.722,
    lng: -73.933
  }, {
    id: 'b4',
    title: 'Green room rest',
    start: at(0, 16, 0),
    end: at(0, 18, 30),
    category: 'rest',
    locationName: 'Brooklyn Steel',
    lat: 40.722,
    lng: -73.933
  }, {
    id: 'b5',
    title: 'Show',
    start: at(0, 21, 0),
    end: at(0, 23, 0),
    category: 'gig',
    locationName: 'Brooklyn Steel',
    notes: 'Doors 8, openers 8:30, on stage 9.',
    lat: 40.722,
    lng: -73.933
  }, {
    id: 'b6',
    title: 'Flight LGA → ORD',
    start: at(1, 9, 30),
    end: at(1, 12, 0),
    category: 'travel',
    locationName: 'LaGuardia Airport',
    confirmationCode: 'DL-AB12CD',
    lat: 40.776,
    lng: -73.874
  }, {
    id: 'b7',
    title: 'Lunch w/ promoter',
    start: at(1, 13, 30),
    end: at(1, 14, 45),
    category: 'social',
    locationName: 'Au Cheval',
    address: '800 W Randolph St, Chicago, IL',
    lat: 41.884,
    lng: -87.648
  }, {
    id: 'b8',
    title: 'Radio interview',
    start: at(1, 16, 0),
    end: at(1, 16, 45),
    category: 'work',
    locationName: 'WBEZ Studios',
    lat: 41.866,
    lng: -87.617
  }];
  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }
  function fmtTime(d) {
    let h = d.getHours();
    const m = d.getMinutes();
    const ap = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h === 0) h = 12;
    return `${h}:${m.toString().padStart(2, '0')} ${ap}`;
  }
  function durString(mins) {
    const h = Math.floor(mins / 60);
    const m = Math.round(mins % 60);
    if (h > 0 && m > 0) return `${h}h ${m}m`;
    if (h > 0) return `${h}h`;
    return `${m}m`;
  }
  window.SBData = {
    blocks,
    at,
    sameDay,
    fmtTime,
    durString
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/staybusy/sb-data.js", error: String((e && e.message) || e) }); }

// ui_kits/staybusy/sb-detail.jsx
try { (() => {
// StayBusy UI kit — Map, Block detail, Editor, tab bar, and app shell.
(function () {
  const DS = window.StayBusyDesignSystem_0220d6;
  const {
    BlockCard,
    Button,
    Badge,
    DayPicker,
    TimeRangeLabel,
    EmptyState,
    CategoryChip,
    CATEGORIES
  } = DS;
  const {
    blocks: ALL,
    sameDay,
    fmtTime,
    durString
  } = window.SBData;
  function catMeta(k) {
    return CATEGORIES[k] || CATEGORIES.admin;
  }

  // ---- Map --------------------------------------------------------------
  function MapScreen({
    date,
    onDate,
    onOpenBlock
  }) {
    const [selected, setSelected] = React.useState(null);
    const dayBlocks = ALL.filter(b => sameDay(b.start, date) && b.lat != null);

    // normalize coords into the map rectangle
    const lats = dayBlocks.map(b => b.lat),
      lngs = dayBlocks.map(b => b.lng);
    const minLat = Math.min(...lats),
      maxLat = Math.max(...lats);
    const minLng = Math.min(...lngs),
      maxLng = Math.max(...lngs);
    const pos = b => {
      const padX = 18,
        padY = 16;
      const fx = maxLng === minLng ? 0.5 : (b.lng - minLng) / (maxLng - minLng);
      const fy = maxLat === minLat ? 0.5 : (maxLat - b.lat) / (maxLat - minLat);
      return {
        left: `calc(${padX}% + ${fx * (100 - padX * 2)}%)`,
        top: `calc(${padY}% + ${fy * (100 - padY * 2)}%)`
      };
    };
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        height: '100%'
      }
    }, /*#__PURE__*/React.createElement(DayPicker, {
      date: date,
      onChange: d => {
        setSelected(null);
        onDate(d);
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        position: 'relative',
        margin: '0 0 0',
        overflow: 'hidden',
        background: '#101216'
      }
    }, /*#__PURE__*/React.createElement("svg", {
      width: "100%",
      height: "100%",
      style: {
        position: 'absolute',
        inset: 0
      },
      preserveAspectRatio: "none"
    }, /*#__PURE__*/React.createElement("defs", null, /*#__PURE__*/React.createElement("pattern", {
      id: "streets",
      width: "46",
      height: "46",
      patternUnits: "userSpaceOnUse"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M0 0H46M0 0V46",
      stroke: "#1b1e24",
      strokeWidth: "1.5",
      fill: "none"
    }))), /*#__PURE__*/React.createElement("rect", {
      width: "100%",
      height: "100%",
      fill: "url(#streets)"
    }), /*#__PURE__*/React.createElement("path", {
      d: "M-20 120 Q 200 60 460 200",
      stroke: "#23262e",
      strokeWidth: "10",
      fill: "none"
    }), /*#__PURE__*/React.createElement("path", {
      d: "M120 -20 Q 180 300 320 700",
      stroke: "#23262e",
      strokeWidth: "14",
      fill: "none"
    })), dayBlocks.length === 0 && /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        inset: 0,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'color-mix(in srgb, var(--sb-surface) 92%, transparent)',
        borderRadius: 'var(--sb-radius-medium)'
      }
    }, /*#__PURE__*/React.createElement(EmptyState, {
      icon: "map-pin",
      title: "No locations yet",
      message: "Add a location to one of today's blocks to see it here."
    }))), dayBlocks.map((b, i) => {
      const p = pos(b);
      const isSel = selected && selected.id === b.id;
      return /*#__PURE__*/React.createElement("button", {
        key: b.id,
        onClick: () => setSelected(b),
        "aria-label": `Block ${i + 1}`,
        style: {
          position: 'absolute',
          left: p.left,
          top: p.top,
          transform: 'translate(-50%,-50%)',
          width: isSel ? 44 : 32,
          height: isSel ? 44 : 32,
          borderRadius: '50%',
          cursor: 'pointer',
          background: `var(--sb-cat-${b.category})`,
          border: '2px solid #fff',
          boxShadow: 'var(--sb-shadow-pin)',
          color: '#fff',
          fontFamily: 'var(--sb-font-mono)',
          fontWeight: 700,
          fontSize: 14,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          transition: 'all var(--sb-motion-snap)'
        }
      }, i + 1);
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        top: 12,
        right: 16,
        width: 44,
        height: 44,
        borderRadius: '50%',
        background: 'color-mix(in srgb, var(--sb-surface-elevated) 92%, transparent)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: 'var(--sb-shadow-pin)'
      }
    }, /*#__PURE__*/React.createElement("i", {
      className: "ph-bold ph-path",
      style: {
        color: 'var(--sb-text-primary)',
        fontSize: 18
      }
    })), selected && /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        left: 16,
        right: 16,
        bottom: 16,
        background: 'var(--sb-surface)',
        borderRadius: 'var(--sb-radius-medium)',
        padding: 12,
        boxShadow: 'var(--sb-shadow-sheet)',
        display: 'flex',
        flexDirection: 'column',
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8,
        alignItems: 'flex-start'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement(BlockCard, {
      block: selected,
      variant: "compact"
    })), /*#__PURE__*/React.createElement("button", {
      onClick: () => setSelected(null),
      "aria-label": "Dismiss",
      style: {
        border: 'none',
        background: 'transparent',
        color: 'var(--sb-text-tertiary)',
        fontSize: 24,
        cursor: 'pointer',
        width: 36,
        height: 36
      }
    }, /*#__PURE__*/React.createElement("i", {
      className: "ph-fill ph-x-circle"
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(Button, {
      icon: "car",
      fullWidth: true
    }, "Drive"), /*#__PURE__*/React.createElement(Button, {
      variant: "secondary",
      icon: "arrow-up-right",
      fullWidth: true,
      onClick: () => onOpenBlock(selected)
    }, "Details")))));
  }

  // ---- Block detail -----------------------------------------------------
  function DetailScreen({
    block,
    onBack,
    onEdit
  }) {
    const meta = catMeta(block.category);
    const [copied, setCopied] = React.useState(false);
    const copy = () => {
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    };
    const dayStr = block.start.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric'
    });
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        inset: 0,
        background: 'var(--sb-background)',
        display: 'flex',
        flexDirection: 'column',
        zIndex: 30
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '52px 12px 8px'
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: onBack,
      "aria-label": "Back",
      style: {
        border: 'none',
        background: 'transparent',
        color: 'var(--sb-accent)',
        display: 'flex',
        alignItems: 'center',
        gap: 2,
        fontFamily: 'var(--sb-font-rounded)',
        fontWeight: 700,
        fontSize: 'var(--sb-title-size)',
        cursor: 'pointer',
        minHeight: 44
      }
    }, /*#__PURE__*/React.createElement("i", {
      className: "ph-bold ph-caret-left"
    }), " Today"), /*#__PURE__*/React.createElement("button", {
      onClick: onEdit,
      style: {
        border: 'none',
        background: 'transparent',
        color: 'var(--sb-accent)',
        fontFamily: 'var(--sb-font-rounded)',
        fontWeight: 700,
        fontSize: 'var(--sb-title-size)',
        cursor: 'pointer',
        minHeight: 44,
        padding: '0 8px'
      }
    }, "Edit")), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflowY: 'auto',
        padding: '0 16px 24px',
        display: 'flex',
        flexDirection: 'column',
        gap: 16,
        fontFamily: 'var(--sb-font-rounded)'
      }
    }, /*#__PURE__*/React.createElement("h1", {
      style: {
        margin: '4px 0 0',
        fontWeight: 800,
        fontSize: 28,
        color: 'var(--sb-text-primary)'
      }
    }, block.title), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8
      }
    }, [['camera', 'Camera'], ['images', 'Photos'], ['file', 'Files']].map(([ic, lb]) => /*#__PURE__*/React.createElement("div", {
      key: lb,
      style: {
        flex: 1,
        minHeight: 44,
        padding: '12px 0',
        borderRadius: 'var(--sb-radius-medium)',
        background: 'var(--sb-surface)',
        color: 'var(--sb-text-primary)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 4
      }
    }, /*#__PURE__*/React.createElement("i", {
      className: `ph-fill ph-${ic}`,
      style: {
        fontSize: 'var(--sb-title-size)'
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-caption-size)'
      }
    }, lb)))), block.confirmationCode && /*#__PURE__*/React.createElement("button", {
      onClick: copy,
      style: {
        textAlign: 'left',
        border: 'none',
        cursor: 'pointer',
        background: 'var(--sb-surface)',
        borderRadius: 'var(--sb-radius-medium)',
        padding: 16,
        display: 'flex',
        flexDirection: 'column',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        letterSpacing: '1.4px',
        textTransform: 'uppercase',
        color: 'var(--sb-text-secondary)'
      }
    }, "Confirmation code"), /*#__PURE__*/React.createElement(Badge, {
      tone: copied ? 'success' : 'soft',
      icon: copied ? 'check' : null
    }, copied ? 'Copied' : 'Tap to copy')), /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: 'var(--sb-font-mono)',
        fontWeight: 700,
        fontSize: 34,
        color: 'var(--sb-text-primary)',
        letterSpacing: '1px'
      }
    }, block.confirmationCode)), block.links && block.links.map(l => /*#__PURE__*/React.createElement("div", {
      key: l,
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        minHeight: 44,
        padding: '12px',
        borderRadius: 'var(--sb-radius-medium)',
        background: 'var(--sb-surface)'
      }
    }, /*#__PURE__*/React.createElement("i", {
      className: "ph-fill ph-compass",
      style: {
        color: 'var(--sb-accent)',
        fontSize: 'var(--sb-title-size)'
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        color: 'var(--sb-text-primary)',
        fontSize: 'var(--sb-body-size)'
      }
    }, l), /*#__PURE__*/React.createElement("i", {
      className: "ph-bold ph-arrow-up-right",
      style: {
        color: 'var(--sb-text-secondary)',
        fontSize: 'var(--sb-caption-size)'
      }
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--sb-surface)',
        borderRadius: 'var(--sb-radius-medium)',
        padding: 16,
        display: 'flex',
        flexDirection: 'column',
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 30,
        height: 30,
        borderRadius: 'var(--sb-radius-small)',
        background: `color-mix(in srgb, ${meta.color} 18%, transparent)`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement("i", {
      className: `ph-fill ph-${meta.icon}`,
      style: {
        color: meta.text,
        fontSize: 'var(--sb-caption-size)'
      }
    })), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        letterSpacing: '1.3px',
        textTransform: 'uppercase',
        color: 'var(--sb-text-secondary)'
      }
    }, meta.label)), /*#__PURE__*/React.createElement("span", {
      style: {
        fontWeight: 700,
        fontSize: 'var(--sb-title-size)',
        color: 'var(--sb-text-primary)',
        fontVariantNumeric: 'tabular-nums'
      }
    }, dayStr, " \xB7 ", fmtTime(block.start), " \u2013 ", fmtTime(block.end)), block.locationName && /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 4
      }
    }, /*#__PURE__*/React.createElement("i", {
      className: "ph-fill ph-map-pin",
      style: {
        color: 'var(--sb-text-secondary)'
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--sb-text-secondary)',
        fontSize: 'var(--sb-body-size)'
      }
    }, block.locationName)), block.address && /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--sb-text-tertiary)',
        fontSize: 'var(--sb-caption-size)'
      }
    }, block.address), block.notes && /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--sb-text-primary)',
        fontSize: 'var(--sb-body-size)',
        marginTop: 4
      }
    }, block.notes)), block.lat != null && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        letterSpacing: '1.4px',
        textTransform: 'uppercase',
        color: 'var(--sb-text-secondary)'
      }
    }, "Leave by"), /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--sb-surface)',
        borderRadius: 'var(--sb-radius-medium)',
        padding: 16,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 2
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontWeight: 800,
        fontSize: 'var(--sb-title-lg-size)',
        color: 'var(--sb-text-primary)',
        fontVariantNumeric: 'tabular-nums'
      }
    }, "Leave by ", fmtTime(new Date(block.start.getTime() - 35 * 60000))), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        color: 'var(--sb-text-secondary)'
      }
    }, "25m drive \xB7 10 min buffer")), /*#__PURE__*/React.createElement("i", {
      className: "ph-fill ph-car",
      style: {
        color: 'var(--sb-accent)',
        fontSize: 'var(--sb-title-size)'
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(Button, {
      icon: "car",
      fullWidth: true
    }, "Drive"), /*#__PURE__*/React.createElement(Button, {
      icon: "tram",
      fullWidth: true
    }, "Transit")))));
  }

  // ---- Editor sheet -----------------------------------------------------
  function EditorScreen({
    suggested,
    editing,
    onClose
  }) {
    const [cat, setCat] = React.useState(editing ? editing.category : 'gig');
    const [title, setTitle] = React.useState(editing ? editing.title : '');
    const start = editing ? editing.start : suggested ? suggested.start : new Date();
    const end = editing ? editing.end : suggested ? suggested.end : new Date();
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        inset: 0,
        zIndex: 40,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'flex-end'
      }
    }, /*#__PURE__*/React.createElement("div", {
      onClick: onClose,
      style: {
        position: 'absolute',
        inset: 0,
        background: 'rgba(0,0,0,0.5)'
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'relative',
        background: 'var(--sb-surface)',
        borderRadius: 'var(--sb-radius-large) var(--sb-radius-large) 0 0',
        padding: '12px 16px 32px',
        maxHeight: '88%',
        overflowY: 'auto',
        fontFamily: 'var(--sb-font-rounded)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 40,
        height: 5,
        borderRadius: 999,
        background: 'var(--sb-hour-rule)',
        margin: '0 auto 16px'
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: 16
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: onClose,
      style: {
        border: 'none',
        background: 'transparent',
        color: 'var(--sb-text-secondary)',
        fontSize: 'var(--sb-body-size)',
        fontFamily: 'var(--sb-font-rounded)',
        cursor: 'pointer',
        minHeight: 44
      }
    }, "Cancel"), /*#__PURE__*/React.createElement("span", {
      style: {
        fontWeight: 800,
        fontSize: 'var(--sb-title-size)',
        color: 'var(--sb-text-primary)'
      }
    }, editing ? 'Edit block' : 'New block'), /*#__PURE__*/React.createElement("span", {
      style: {
        width: 60
      }
    })), /*#__PURE__*/React.createElement("label", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        letterSpacing: '1.2px',
        textTransform: 'uppercase',
        color: 'var(--sb-text-secondary)'
      }
    }, "Title"), /*#__PURE__*/React.createElement("input", {
      value: title,
      onChange: e => setTitle(e.target.value),
      placeholder: "What's happening?",
      style: {
        width: '100%',
        boxSizing: 'border-box',
        marginTop: 6,
        marginBottom: 16,
        padding: '12px 14px',
        minHeight: 44,
        background: 'var(--sb-surface-elevated)',
        border: 'none',
        borderRadius: 'var(--sb-radius-medium)',
        color: 'var(--sb-text-primary)',
        fontFamily: 'var(--sb-font-rounded)',
        fontSize: 'var(--sb-body-size)',
        outline: 'none'
      }
    }), /*#__PURE__*/React.createElement("label", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        letterSpacing: '1.2px',
        textTransform: 'uppercase',
        color: 'var(--sb-text-secondary)'
      }
    }, "Category"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexWrap: 'wrap',
        gap: 8,
        margin: '8px 0 16px'
      }
    }, Object.keys(CATEGORIES).map(c => /*#__PURE__*/React.createElement(CategoryChip, {
      key: c,
      category: c,
      selected: cat === c,
      onClick: () => setCat(c)
    }))), /*#__PURE__*/React.createElement("label", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        letterSpacing: '1.2px',
        textTransform: 'uppercase',
        color: 'var(--sb-text-secondary)'
      }
    }, "When"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8,
        margin: '8px 0 24px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        padding: '12px 14px',
        minHeight: 44,
        boxSizing: 'border-box',
        background: 'var(--sb-surface-elevated)',
        borderRadius: 'var(--sb-radius-medium)',
        color: 'var(--sb-text-primary)',
        fontVariantNumeric: 'tabular-nums',
        fontWeight: 600
      }
    }, fmtTime(start)), /*#__PURE__*/React.createElement("span", {
      style: {
        alignSelf: 'center',
        color: 'var(--sb-text-tertiary)'
      }
    }, "\u2192"), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        padding: '12px 14px',
        minHeight: 44,
        boxSizing: 'border-box',
        background: 'var(--sb-surface-elevated)',
        borderRadius: 'var(--sb-radius-medium)',
        color: 'var(--sb-text-primary)',
        fontVariantNumeric: 'tabular-nums',
        fontWeight: 600
      }
    }, fmtTime(end))), /*#__PURE__*/React.createElement(Button, {
      fullWidth: true,
      icon: "check",
      onClick: onClose
    }, editing ? 'Save changes' : 'Add block')));
  }

  // ---- Tab bar ----------------------------------------------------------
  function TabBar({
    tab,
    onTab
  }) {
    const tabs = [['today', 'calendar-blank', 'Today'], ['map', 'map-trifold', 'Map'], ['trip', 'suitcase', 'Trip']];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        borderTop: '0.5px solid var(--sb-hour-rule)',
        background: 'var(--sb-background)',
        paddingBottom: 4
      }
    }, tabs.map(([id, ic, lb]) => {
      const active = tab === id;
      return /*#__PURE__*/React.createElement("button", {
        key: id,
        onClick: () => onTab(id),
        style: {
          flex: 1,
          border: 'none',
          background: 'transparent',
          cursor: 'pointer',
          padding: '8px 0',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 3,
          color: active ? 'var(--sb-accent)' : 'var(--sb-text-tertiary)'
        }
      }, /*#__PURE__*/React.createElement("i", {
        className: `ph-fill ph-${ic}`,
        style: {
          fontSize: 24
        }
      }), /*#__PURE__*/React.createElement("span", {
        style: {
          fontFamily: 'var(--sb-font-rounded)',
          fontSize: 11,
          fontWeight: 700
        }
      }, lb));
    }));
  }

  // ---- App shell --------------------------------------------------------
  const {
    TodayScreen,
    TripScreen
  } = window.SBScreens;
  function App({
    tweaks
  }) {
    const [tab, setTab] = React.useState('today');
    const [date, setDate] = React.useState(() => {
      const d = new Date();
      d.setHours(0, 0, 0, 0);
      return d;
    });
    const [detail, setDetail] = React.useState(null);
    const [editor, setEditor] = React.useState(null); // {suggested, editing}

    const openBlock = b => setDetail(b);
    const openSlot = (s, e) => setEditor({
      suggested: {
        start: s,
        end: e
      }
    });
    const add = () => setEditor({
      suggested: {
        start: new Date(),
        end: new Date(Date.now() + 3600000)
      }
    });
    return /*#__PURE__*/React.createElement("div", {
      style: {
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        paddingTop: 50,
        background: 'var(--sb-background)',
        position: 'relative'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        position: 'relative',
        overflow: 'hidden'
      }
    }, tab === 'today' && /*#__PURE__*/React.createElement(TodayScreen, {
      date: date,
      onDate: setDate,
      onOpenBlock: openBlock,
      onOpenSlot: openSlot,
      onAdd: add,
      ppm: tweaks ? tweaks.density : undefined
    }), tab === 'map' && /*#__PURE__*/React.createElement(MapScreen, {
      date: date,
      onDate: setDate,
      onOpenBlock: openBlock
    }), tab === 'trip' && /*#__PURE__*/React.createElement(TripScreen, {
      onSelectDay: d => {
        setDate(d);
        setTab('today');
      }
    })), /*#__PURE__*/React.createElement(TabBar, {
      tab: tab,
      onTab: setTab
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        height: 22,
        background: 'var(--sb-background)'
      }
    }), detail && /*#__PURE__*/React.createElement(DetailScreen, {
      block: detail,
      onBack: () => setDetail(null),
      onEdit: () => {
        setEditor({
          editing: detail
        });
      }
    }), editor && /*#__PURE__*/React.createElement(EditorScreen, {
      suggested: editor.suggested,
      editing: editor.editing,
      onClose: () => setEditor(null)
    }));
  }
  window.SBApp = App;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/staybusy/sb-detail.jsx", error: String((e && e.message) || e) }); }

// ui_kits/staybusy/sb-screens.jsx
try { (() => {
// StayBusy UI kit — Today, Trip and Map screens.
// Composes the design-system primitives from the compiled bundle.
(function () {
  const DS = window.StayBusyDesignSystem_0220d6;
  const {
    NowNextBar,
    BlockCard,
    OpenSlotCard,
    DayPicker,
    EmptyState,
    BlockCardDummy
  } = DS;
  const {
    blocks: ALL,
    sameDay,
    fmtTime,
    durString
  } = window.SBData;
  const START_HOUR = 7,
    END_HOUR = 24,
    PPM = 1.25;
  const GUTTER = 48,
    RPAD = 16;
  function dayStartAt(date, hour) {
    const d = new Date(date);
    d.setHours(hour, 0, 0, 0);
    return d;
  }
  function hourLabel(h) {
    const x = h % 24;
    if (x === 0) return '12A';
    if (x === 12) return '12P';
    return x < 12 ? x + 'A' : x - 12 + 'P';
  }

  // Build ordered list of timeline items (blocks + open gaps) for a day.
  function buildItems(dayBlocks, date) {
    const dayStart = dayStartAt(date, START_HOUR);
    const dayEnd = dayStartAt(date, 0);
    dayEnd.setDate(dayEnd.getDate() + 1);
    const sorted = [...dayBlocks].sort((a, b) => a.start - b.start);
    const items = [];
    let cursor = dayStart;
    for (const b of sorted) {
      const s = b.start < dayStart ? dayStart : b.start;
      if (s > cursor) {
        const gapMin = (s - cursor) / 60000;
        if (gapMin >= 10) items.push({
          type: 'open',
          start: new Date(cursor),
          end: new Date(s)
        });
      }
      items.push({
        type: 'block',
        block: b
      });
      const e = b.end > dayEnd ? dayEnd : b.end;
      if (e > cursor) cursor = e;
    }
    if (dayEnd > cursor) {
      const gapMin = (dayEnd - cursor) / 60000;
      if (gapMin >= 10) items.push({
        type: 'open',
        start: new Date(cursor),
        end: new Date(dayEnd)
      });
    }
    return items;
  }
  function Timeline({
    dayBlocks,
    date,
    onOpenBlock,
    onOpenSlot,
    ppm = PPM
  }) {
    const dayStart = dayStartAt(date, START_HOUR);
    const totalH = (END_HOUR - START_HOUR) * 60 * ppm;
    const isToday = sameDay(date, new Date());
    const now = new Date();
    const yFor = t => (t - dayStart) / 60000 * ppm;
    const items = buildItems(dayBlocks, date);
    const scrollRef = React.useRef(null);
    React.useEffect(() => {
      if (isToday && scrollRef.current) {
        const y = Math.max(0, yFor(now) - 180);
        scrollRef.current.scrollTo({
          top: y,
          behavior: 'smooth'
        });
      }
    }, [date]);
    const hours = [];
    for (let h = START_HOUR; h <= END_HOUR; h++) hours.push(h);
    return /*#__PURE__*/React.createElement("div", {
      ref: scrollRef,
      style: {
        flex: 1,
        overflowY: 'auto',
        overflowX: 'hidden',
        position: 'relative'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'relative',
        height: totalH + 40,
        margin: '8px 0 24px'
      }
    }, hours.map(h => /*#__PURE__*/React.createElement("div", {
      key: h,
      style: {
        position: 'absolute',
        top: (h - START_HOUR) * 60 * ppm,
        left: 0,
        right: RPAD,
        display: 'flex',
        alignItems: 'center',
        gap: 4
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: GUTTER - 10,
        textAlign: 'right',
        fontFamily: 'var(--sb-font-rounded)',
        fontSize: 'var(--sb-caption-size)',
        color: 'var(--sb-text-tertiary)'
      }
    }, hourLabel(h)), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        height: 1,
        background: 'var(--sb-hour-rule)'
      }
    }))), items.map((it, i) => {
      const start = it.type === 'block' ? it.block.start : it.start;
      const end = it.type === 'block' ? it.block.end : it.end;
      const top = yFor(start);
      const h = Math.max(44, (end - start) / 60000 * ppm - 4);
      const isCurrent = isToday && it.type === 'block' && it.block.start <= now && now < it.block.end;
      const isPast = isToday && it.type === 'block' && it.block.end <= now;
      return /*#__PURE__*/React.createElement("div", {
        key: i,
        style: {
          position: 'absolute',
          top,
          left: GUTTER,
          right: RPAD,
          height: h
        }
      }, it.type === 'block' ? /*#__PURE__*/React.createElement(BlockCard, {
        block: it.block,
        variant: "timeline",
        isCurrent: isCurrent,
        isPast: isPast,
        onClick: () => onOpenBlock(it.block)
      }) : /*#__PURE__*/React.createElement(OpenSlotCard, {
        start: it.start,
        end: it.end,
        onClick: () => onOpenSlot(it.start, it.end)
      }));
    }), isToday && now >= dayStart && /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        top: yFor(now),
        left: 0,
        right: RPAD,
        display: 'flex',
        alignItems: 'center',
        height: 0,
        zIndex: 4
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: GUTTER - 10,
        textAlign: 'right',
        marginRight: 4,
        fontFamily: 'var(--sb-font-rounded)',
        fontSize: 11,
        fontWeight: 700,
        letterSpacing: '1.2px',
        color: '#fff',
        background: 'var(--sb-accent)',
        borderRadius: 999,
        padding: '2px 6px',
        lineHeight: 1.2
      }
    }, "NOW"), /*#__PURE__*/React.createElement("span", {
      style: {
        width: 9,
        height: 9,
        borderRadius: '50%',
        background: 'var(--sb-accent)'
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        height: 2,
        background: 'var(--sb-accent)'
      }
    }))));
  }
  function TodayScreen({
    date,
    onDate,
    onOpenBlock,
    onOpenSlot,
    onAdd,
    ppm
  }) {
    const dayBlocks = ALL.filter(b => sameDay(b.start, date));
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        position: 'relative'
      }
    }, /*#__PURE__*/React.createElement(DayPicker, {
      date: date,
      onChange: onDate
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: '0 16px 8px'
      }
    }, /*#__PURE__*/React.createElement(NowNextBar, {
      blocks: ALL
    })), dayBlocks.length === 0 ? /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: 'flex',
        alignItems: 'center'
      }
    }, /*#__PURE__*/React.createElement(EmptyState, {
      icon: "calendar-plus",
      title: "Nothing scheduled",
      message: "Add a block to start mapping out your day.",
      actionLabel: "Add a block",
      onAction: onAdd
    })) : /*#__PURE__*/React.createElement(Timeline, {
      dayBlocks: dayBlocks,
      date: date,
      onOpenBlock: onOpenBlock,
      onOpenSlot: onOpenSlot,
      ppm: ppm
    }), /*#__PURE__*/React.createElement("button", {
      onClick: onAdd,
      "aria-label": "Add block",
      style: {
        position: 'absolute',
        right: 16,
        bottom: 16,
        width: 60,
        height: 60,
        borderRadius: '50%',
        border: 'none',
        background: 'var(--sb-accent)',
        color: '#fff',
        fontSize: 30,
        boxShadow: 'var(--sb-shadow-float)',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement("i", {
      className: "ph-bold ph-plus"
    })));
  }

  // ---- Trip overview ----------------------------------------------------
  function dayWindow(date) {
    const s = dayStartAt(date, START_HOUR);
    const e = dayStartAt(date, 0);
    e.setDate(e.getDate() + 1);
    return {
      s,
      e,
      mins: (e - s) / 60000
    };
  }
  function buildDays() {
    const byKey = {};
    for (const b of ALL) {
      const d = new Date(b.start);
      d.setHours(0, 0, 0, 0);
      const k = d.getTime();
      (byKey[k] = byKey[k] || {
        date: d,
        blocks: []
      }).blocks.push(b);
    }
    const days = Object.values(byKey).sort((a, b) => a.date - b.date);
    for (const day of days) {
      const w = dayWindow(day.date);
      let scheduled = 0;
      for (const b of day.blocks) {
        const s = Math.max(b.start, w.s),
          e = Math.min(b.end, w.e);
        scheduled += Math.max(0, (e - s) / 60000);
      }
      day.openMin = Math.max(0, w.mins - scheduled);
      day.windowMin = w.mins;
    }
    return days;
  }
  function DensityBar({
    day
  }) {
    const w = dayWindow(day.date);
    const segs = [];
    let cursor = w.s;
    for (const b of [...day.blocks].sort((a, b) => a.start - b.start)) {
      const bs = Math.max(b.start, w.s),
        be = Math.min(b.end, w.e);
      if (bs > cursor) segs.push({
        open: true,
        frac: (bs - cursor) / 60000 / w.mins
      });
      if (be > bs) {
        segs.push({
          cat: b.category,
          frac: (be - bs) / 60000 / w.mins
        });
        cursor = be;
      }
    }
    if (w.e > cursor) segs.push({
      open: true,
      frac: (w.e - cursor) / 60000 / w.mins
    });
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        height: 14,
        borderRadius: 4,
        overflow: 'hidden'
      }
    }, segs.map((s, i) => /*#__PURE__*/React.createElement("span", {
      key: i,
      style: {
        width: s.frac * 100 + '%',
        background: s.open ? 'var(--sb-hour-rule)' : `var(--sb-cat-${s.cat})`
      }
    })));
  }
  function TripScreen({
    onSelectDay
  }) {
    const days = buildDays();
    const totalBlocks = days.reduce((n, d) => n + d.blocks.length, 0);
    const totalOpen = days.reduce((n, d) => n + d.openMin, 0);
    const thinnest = days.length > 1 ? [...days].sort((a, b) => a.openMin - b.openMin)[0] : null;
    const press = React.useRef(null);
    return /*#__PURE__*/React.createElement("div", {
      style: {
        height: '100%',
        overflowY: 'auto',
        padding: 16,
        display: 'flex',
        flexDirection: 'column',
        gap: 12,
        fontFamily: 'var(--sb-font-rounded)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--sb-surface-elevated)',
        borderRadius: 'var(--sb-radius-medium)',
        padding: 16,
        display: 'flex',
        flexDirection: 'column',
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        letterSpacing: '1.4px',
        textTransform: 'uppercase',
        color: 'var(--sb-text-secondary)'
      }
    }, "Trip overview"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 32
      }
    }, /*#__PURE__*/React.createElement(Stat, {
      value: String(totalBlocks),
      label: "Blocks"
    }), /*#__PURE__*/React.createElement(Stat, {
      value: durString(totalOpen),
      label: "Open"
    })), thinnest && /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 5,
        alignItems: 'baseline'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-body-size)',
        color: 'var(--sb-text-secondary)'
      }
    }, "Thinnest day:"), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-body-size)',
        color: 'var(--sb-accent)',
        fontWeight: 700
      }
    }, thinnest.date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric'
    })))), days.map(day => /*#__PURE__*/React.createElement("button", {
      key: day.date.getTime(),
      onClick: () => onSelectDay(day.date),
      style: {
        textAlign: 'left',
        border: 'none',
        cursor: 'pointer',
        background: 'var(--sb-surface)',
        borderRadius: 'var(--sb-radius-medium)',
        padding: 12,
        display: 'flex',
        flexDirection: 'column',
        gap: 8,
        fontFamily: 'var(--sb-font-rounded)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'baseline',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontWeight: 800,
        fontSize: 'var(--sb-title-lg-size)',
        color: 'var(--sb-text-primary)'
      }
    }, day.date.toLocaleDateString('en-US', {
      weekday: 'long'
    })), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-body-size)',
        color: 'var(--sb-text-secondary)'
      }
    }, day.date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric'
    })), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("i", {
      className: "ph-bold ph-caret-right",
      style: {
        color: 'var(--sb-text-tertiary)',
        fontSize: 'var(--sb-caption-size)'
      }
    })), /*#__PURE__*/React.createElement(DensityBar, {
      day: day
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        color: 'var(--sb-text-secondary)'
      }
    }, day.blocks.length, " ", day.blocks.length === 1 ? 'block' : 'blocks', " \xB7 ", durString(day.openMin), " open"))));
  }
  function Stat({
    value,
    label
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 2
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontWeight: 800,
        fontSize: 'var(--sb-title-lg-size)',
        color: 'var(--sb-text-primary)',
        fontVariantNumeric: 'tabular-nums'
      }
    }, value), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 'var(--sb-caption-size)',
        letterSpacing: '1.2px',
        textTransform: 'uppercase',
        color: 'var(--sb-text-secondary)'
      }
    }, label));
  }
  window.SBScreens = {
    TodayScreen,
    TripScreen,
    buildDays,
    dayWindow
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/staybusy/sb-screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/staybusy/tweaks-panel.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)

/* BEGIN USAGE */
// tweaks-panel.jsx
// Reusable Tweaks shell + form-control helpers.
// Exports (to window): useTweaks, TweaksPanel, TweakSection, TweakRow, TweakSlider,
//   TweakToggle, TweakRadio, TweakSelect, TweakText, TweakNumber, TweakColor, TweakButton.
//
// Owns the host protocol (listens for __activate_edit_mode / __deactivate_edit_mode,
// posts __edit_mode_available / __edit_mode_set_keys / __edit_mode_dismissed) so
// individual prototypes don't re-roll it. Ships a consistent set of controls so you
// don't hand-draw <input type="range">, segmented radios, steppers, etc.
//
// Usage (in an HTML file that loads React + Babel):
//
//   const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
//     "primaryColor": "#D97757",
//     "palette": ["#D97757", "#29261b", "#f6f4ef"],
//     "fontSize": 16,
//     "density": "regular",
//     "dark": false
//   }/*EDITMODE-END*/;
//
//   function App() {
//     const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
//     return (
//       <div style={{ fontSize: t.fontSize, color: t.primaryColor }}>
//         Hello
//         <TweaksPanel>
//           <TweakSection label="Typography" />
//           <TweakSlider label="Font size" value={t.fontSize} min={10} max={32} unit="px"
//                        onChange={(v) => setTweak('fontSize', v)} />
//           <TweakRadio  label="Density" value={t.density}
//                        options={['compact', 'regular', 'comfy']}
//                        onChange={(v) => setTweak('density', v)} />
//           <TweakSection label="Theme" />
//           <TweakColor  label="Primary" value={t.primaryColor}
//                        options={['#D97757', '#2A6FDB', '#1F8A5B', '#7A5AE0']}
//                        onChange={(v) => setTweak('primaryColor', v)} />
//           <TweakColor  label="Palette" value={t.palette}
//                        options={[['#D97757', '#29261b', '#f6f4ef'],
//                                  ['#475569', '#0f172a', '#f1f5f9']]}
//                        onChange={(v) => setTweak('palette', v)} />
//           <TweakToggle label="Dark mode" value={t.dark}
//                        onChange={(v) => setTweak('dark', v)} />
//         </TweaksPanel>
//       </div>
//     );
//   }
//
// TweakRadio is the segmented control for 2–3 short options (auto-falls-back to
// TweakSelect past ~16/~10 chars per label); reach for TweakSelect directly when
// options are many or long. For color tweaks always curate 3-4 options rather than
// a free picker; an option can also be a whole 2–5 color palette (the stored value
// is the array). The Tweak* controls are a floor, not a ceiling — build custom
// controls inside the panel if a tweak calls for UI they don't cover.
/* END USAGE */
// ─────────────────────────────────────────────────────────────────────────────

const __TWEAKS_STYLE = `
  .twk-panel{position:fixed;right:16px;bottom:16px;z-index:2147483646;width:280px;
    max-height:calc(100vh - 32px);display:flex;flex-direction:column;
    transform:scale(var(--dc-inv-zoom,1));transform-origin:bottom right;
    background:rgba(250,249,247,.78);color:#29261b;
    -webkit-backdrop-filter:blur(24px) saturate(160%);backdrop-filter:blur(24px) saturate(160%);
    border:.5px solid rgba(255,255,255,.6);border-radius:14px;
    box-shadow:0 1px 0 rgba(255,255,255,.5) inset,0 12px 40px rgba(0,0,0,.18);
    font:11.5px/1.4 ui-sans-serif,system-ui,-apple-system,sans-serif;overflow:hidden}
  .twk-hd{display:flex;align-items:center;justify-content:space-between;
    padding:10px 8px 10px 14px;cursor:move;user-select:none}
  .twk-hd b{font-size:12px;font-weight:600;letter-spacing:.01em}
  .twk-x{appearance:none;border:0;background:transparent;color:rgba(41,38,27,.55);
    width:22px;height:22px;border-radius:6px;cursor:default;font-size:13px;line-height:1}
  .twk-x:hover{background:rgba(0,0,0,.06);color:#29261b}
  .twk-body{padding:2px 14px 14px;display:flex;flex-direction:column;gap:10px;
    overflow-y:auto;overflow-x:hidden;min-height:0;
    scrollbar-width:thin;scrollbar-color:rgba(0,0,0,.15) transparent}
  .twk-body::-webkit-scrollbar{width:8px}
  .twk-body::-webkit-scrollbar-track{background:transparent;margin:2px}
  .twk-body::-webkit-scrollbar-thumb{background:rgba(0,0,0,.15);border-radius:4px;
    border:2px solid transparent;background-clip:content-box}
  .twk-body::-webkit-scrollbar-thumb:hover{background:rgba(0,0,0,.25);
    border:2px solid transparent;background-clip:content-box}
  .twk-row{display:flex;flex-direction:column;gap:5px}
  .twk-row-h{flex-direction:row;align-items:center;justify-content:space-between;gap:10px}
  .twk-lbl{display:flex;justify-content:space-between;align-items:baseline;
    color:rgba(41,38,27,.72)}
  .twk-lbl>span:first-child{font-weight:500}
  .twk-val{color:rgba(41,38,27,.5);font-variant-numeric:tabular-nums}

  .twk-sect{font-size:10px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;
    color:rgba(41,38,27,.45);padding:10px 0 0}
  .twk-sect:first-child{padding-top:0}

  .twk-field{appearance:none;box-sizing:border-box;width:100%;min-width:0;height:26px;padding:0 8px;
    border:.5px solid rgba(0,0,0,.1);border-radius:7px;
    background:rgba(255,255,255,.6);color:inherit;font:inherit;outline:none}
  .twk-field:focus{border-color:rgba(0,0,0,.25);background:rgba(255,255,255,.85)}
  select.twk-field{padding-right:22px;
    background-image:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='rgba(0,0,0,.5)' d='M0 0h10L5 6z'/></svg>");
    background-repeat:no-repeat;background-position:right 8px center}

  .twk-slider{appearance:none;-webkit-appearance:none;width:100%;height:4px;margin:6px 0;
    border-radius:999px;background:rgba(0,0,0,.12);outline:none}
  .twk-slider::-webkit-slider-thumb{-webkit-appearance:none;appearance:none;
    width:14px;height:14px;border-radius:50%;background:#fff;
    border:.5px solid rgba(0,0,0,.12);box-shadow:0 1px 3px rgba(0,0,0,.2);cursor:default}
  .twk-slider::-moz-range-thumb{width:14px;height:14px;border-radius:50%;
    background:#fff;border:.5px solid rgba(0,0,0,.12);box-shadow:0 1px 3px rgba(0,0,0,.2);cursor:default}

  .twk-seg{position:relative;display:flex;padding:2px;border-radius:8px;
    background:rgba(0,0,0,.06);user-select:none}
  .twk-seg-thumb{position:absolute;top:2px;bottom:2px;border-radius:6px;
    background:rgba(255,255,255,.9);box-shadow:0 1px 2px rgba(0,0,0,.12);
    transition:left .15s cubic-bezier(.3,.7,.4,1),width .15s}
  .twk-seg.dragging .twk-seg-thumb{transition:none}
  .twk-seg button{appearance:none;position:relative;z-index:1;flex:1;border:0;
    background:transparent;color:inherit;font:inherit;font-weight:500;min-height:22px;
    border-radius:6px;cursor:default;padding:4px 6px;line-height:1.2;
    overflow-wrap:anywhere}

  .twk-toggle{position:relative;width:32px;height:18px;border:0;border-radius:999px;
    background:rgba(0,0,0,.15);transition:background .15s;cursor:default;padding:0}
  .twk-toggle[data-on="1"]{background:#34c759}
  .twk-toggle i{position:absolute;top:2px;left:2px;width:14px;height:14px;border-radius:50%;
    background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25);transition:transform .15s}
  .twk-toggle[data-on="1"] i{transform:translateX(14px)}

  .twk-num{display:flex;align-items:center;box-sizing:border-box;min-width:0;height:26px;padding:0 0 0 8px;
    border:.5px solid rgba(0,0,0,.1);border-radius:7px;background:rgba(255,255,255,.6)}
  .twk-num-lbl{font-weight:500;color:rgba(41,38,27,.6);cursor:ew-resize;
    user-select:none;padding-right:8px}
  .twk-num input{flex:1;min-width:0;height:100%;border:0;background:transparent;
    font:inherit;font-variant-numeric:tabular-nums;text-align:right;padding:0 8px 0 0;
    outline:none;color:inherit;-moz-appearance:textfield}
  .twk-num input::-webkit-inner-spin-button,.twk-num input::-webkit-outer-spin-button{
    -webkit-appearance:none;margin:0}
  .twk-num-unit{padding-right:8px;color:rgba(41,38,27,.45)}

  .twk-btn{appearance:none;height:26px;padding:0 12px;border:0;border-radius:7px;
    background:rgba(0,0,0,.78);color:#fff;font:inherit;font-weight:500;cursor:default}
  .twk-btn:hover{background:rgba(0,0,0,.88)}
  .twk-btn.secondary{background:rgba(0,0,0,.06);color:inherit}
  .twk-btn.secondary:hover{background:rgba(0,0,0,.1)}

  .twk-swatch{appearance:none;-webkit-appearance:none;width:56px;height:22px;
    border:.5px solid rgba(0,0,0,.1);border-radius:6px;padding:0;cursor:default;
    background:transparent;flex-shrink:0}
  .twk-swatch::-webkit-color-swatch-wrapper{padding:0}
  .twk-swatch::-webkit-color-swatch{border:0;border-radius:5.5px}
  .twk-swatch::-moz-color-swatch{border:0;border-radius:5.5px}

  .twk-chips{display:flex;gap:6px}
  .twk-chip{position:relative;appearance:none;flex:1;min-width:0;height:46px;
    padding:0;border:0;border-radius:6px;overflow:hidden;cursor:default;
    box-shadow:0 0 0 .5px rgba(0,0,0,.12),0 1px 2px rgba(0,0,0,.06);
    transition:transform .12s cubic-bezier(.3,.7,.4,1),box-shadow .12s}
  .twk-chip:hover{transform:translateY(-1px);
    box-shadow:0 0 0 .5px rgba(0,0,0,.18),0 4px 10px rgba(0,0,0,.12)}
  .twk-chip[data-on="1"]{box-shadow:0 0 0 1.5px rgba(0,0,0,.85),
    0 2px 6px rgba(0,0,0,.15)}
  .twk-chip>span{position:absolute;top:0;bottom:0;right:0;width:34%;
    display:flex;flex-direction:column;box-shadow:-1px 0 0 rgba(0,0,0,.1)}
  .twk-chip>span>i{flex:1;box-shadow:0 -1px 0 rgba(0,0,0,.1)}
  .twk-chip>span>i:first-child{box-shadow:none}
  .twk-chip svg{position:absolute;top:6px;left:6px;width:13px;height:13px;
    filter:drop-shadow(0 1px 1px rgba(0,0,0,.3))}
`;

// ── useTweaks ───────────────────────────────────────────────────────────────
// Single source of truth for tweak values. setTweak persists via the host
// (__edit_mode_set_keys → host rewrites the EDITMODE block on disk).
function useTweaks(defaults) {
  const [values, setValues] = React.useState(defaults);
  // Accepts either setTweak('key', value) or setTweak({ key: value, ... }) so a
  // useState-style call doesn't write a "[object Object]" key into the persisted
  // JSON block.
  const setTweak = React.useCallback((keyOrEdits, val) => {
    const edits = typeof keyOrEdits === 'object' && keyOrEdits !== null ? keyOrEdits : {
      [keyOrEdits]: val
    };
    setValues(prev => ({
      ...prev,
      ...edits
    }));
    window.parent.postMessage({
      type: '__edit_mode_set_keys',
      edits
    }, '*');
    // Same-window signal so in-page listeners (deck-stage rail thumbnails)
    // can react — the parent message only reaches the host, not peers.
    window.dispatchEvent(new CustomEvent('tweakchange', {
      detail: edits
    }));
  }, []);
  return [values, setTweak];
}

// ── TweaksPanel ─────────────────────────────────────────────────────────────
// Floating shell. Registers the protocol listener BEFORE announcing
// availability — if the announce ran first, the host's activate could land
// before our handler exists and the toolbar toggle would silently no-op.
// The close button posts __edit_mode_dismissed so the host's toolbar toggle
// flips off in lockstep; the host echoes __deactivate_edit_mode back which
// is what actually hides the panel.
function TweaksPanel({
  title = 'Tweaks',
  children
}) {
  const [open, setOpen] = React.useState(false);
  const dragRef = React.useRef(null);
  const offsetRef = React.useRef({
    x: 16,
    y: 16
  });
  const PAD = 16;
  const clampToViewport = React.useCallback(() => {
    const panel = dragRef.current;
    if (!panel) return;
    const w = panel.offsetWidth,
      h = panel.offsetHeight;
    const maxRight = Math.max(PAD, window.innerWidth - w - PAD);
    const maxBottom = Math.max(PAD, window.innerHeight - h - PAD);
    offsetRef.current = {
      x: Math.min(maxRight, Math.max(PAD, offsetRef.current.x)),
      y: Math.min(maxBottom, Math.max(PAD, offsetRef.current.y))
    };
    panel.style.right = offsetRef.current.x + 'px';
    panel.style.bottom = offsetRef.current.y + 'px';
  }, []);
  React.useEffect(() => {
    if (!open) return;
    clampToViewport();
    if (typeof ResizeObserver === 'undefined') {
      window.addEventListener('resize', clampToViewport);
      return () => window.removeEventListener('resize', clampToViewport);
    }
    const ro = new ResizeObserver(clampToViewport);
    ro.observe(document.documentElement);
    return () => ro.disconnect();
  }, [open, clampToViewport]);
  React.useEffect(() => {
    const onMsg = e => {
      const t = e?.data?.type;
      if (t === '__activate_edit_mode') setOpen(true);else if (t === '__deactivate_edit_mode') setOpen(false);
    };
    window.addEventListener('message', onMsg);
    window.parent.postMessage({
      type: '__edit_mode_available'
    }, '*');
    return () => window.removeEventListener('message', onMsg);
  }, []);
  const dismiss = () => {
    setOpen(false);
    window.parent.postMessage({
      type: '__edit_mode_dismissed'
    }, '*');
  };
  const onDragStart = e => {
    const panel = dragRef.current;
    if (!panel) return;
    const r = panel.getBoundingClientRect();
    const sx = e.clientX,
      sy = e.clientY;
    const startRight = window.innerWidth - r.right;
    const startBottom = window.innerHeight - r.bottom;
    const move = ev => {
      offsetRef.current = {
        x: startRight - (ev.clientX - sx),
        y: startBottom - (ev.clientY - sy)
      };
      clampToViewport();
    };
    const up = () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
  };
  if (!open) return null;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("style", null, __TWEAKS_STYLE), /*#__PURE__*/React.createElement("div", {
    ref: dragRef,
    className: "twk-panel",
    "data-omelette-chrome": "",
    style: {
      right: offsetRef.current.x,
      bottom: offsetRef.current.y
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-hd",
    onMouseDown: onDragStart
  }, /*#__PURE__*/React.createElement("b", null, title), /*#__PURE__*/React.createElement("button", {
    className: "twk-x",
    "aria-label": "Close tweaks",
    onMouseDown: e => e.stopPropagation(),
    onClick: dismiss
  }, "\u2715")), /*#__PURE__*/React.createElement("div", {
    className: "twk-body"
  }, children)));
}

// ── Layout helpers ──────────────────────────────────────────────────────────

function TweakSection({
  label,
  children
}) {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "twk-sect"
  }, label), children);
}
function TweakRow({
  label,
  value,
  children,
  inline = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: inline ? 'twk-row twk-row-h' : 'twk-row'
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-lbl"
  }, /*#__PURE__*/React.createElement("span", null, label), value != null && /*#__PURE__*/React.createElement("span", {
    className: "twk-val"
  }, value)), children);
}

// ── Controls ────────────────────────────────────────────────────────────────

function TweakSlider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  unit = '',
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label,
    value: `${value}${unit}`
  }, /*#__PURE__*/React.createElement("input", {
    type: "range",
    className: "twk-slider",
    min: min,
    max: max,
    step: step,
    value: value,
    onChange: e => onChange(Number(e.target.value))
  }));
}
function TweakToggle({
  label,
  value,
  onChange
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "twk-row twk-row-h"
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-lbl"
  }, /*#__PURE__*/React.createElement("span", null, label)), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "twk-toggle",
    "data-on": value ? '1' : '0',
    role: "switch",
    "aria-checked": !!value,
    onClick: () => onChange(!value)
  }, /*#__PURE__*/React.createElement("i", null)));
}
function TweakRadio({
  label,
  value,
  options,
  onChange
}) {
  const trackRef = React.useRef(null);
  const [dragging, setDragging] = React.useState(false);
  // The active value is read by pointer-move handlers attached for the lifetime
  // of a drag — ref it so a stale closure doesn't fire onChange for every move.
  const valueRef = React.useRef(value);
  valueRef.current = value;

  // Segments wrap mid-word once per-segment width runs out. The track is
  // ~248px (280 panel − 28 body pad − 4 seg pad), each button loses 12px
  // to its own padding, and 11.5px system-ui averages ~6.3px/char — so 2
  // options fit ~16 chars each, 3 fit ~10. Past that (or >3 options), fall
  // back to a dropdown rather than wrap.
  const labelLen = o => String(typeof o === 'object' ? o.label : o).length;
  const maxLen = options.reduce((m, o) => Math.max(m, labelLen(o)), 0);
  const fitsAsSegments = maxLen <= ({
    2: 16,
    3: 10
  }[options.length] ?? 0);
  if (!fitsAsSegments) {
    // <select> emits strings — map back to the original option value so the
    // fallback stays type-preserving (numbers, booleans) like the segment path.
    const resolve = s => {
      const m = options.find(o => String(typeof o === 'object' ? o.value : o) === s);
      return m === undefined ? s : typeof m === 'object' ? m.value : m;
    };
    return /*#__PURE__*/React.createElement(TweakSelect, {
      label: label,
      value: value,
      options: options,
      onChange: s => onChange(resolve(s))
    });
  }
  const opts = options.map(o => typeof o === 'object' ? o : {
    value: o,
    label: o
  });
  const idx = Math.max(0, opts.findIndex(o => o.value === value));
  const n = opts.length;
  const segAt = clientX => {
    const r = trackRef.current.getBoundingClientRect();
    const inner = r.width - 4;
    const i = Math.floor((clientX - r.left - 2) / inner * n);
    return opts[Math.max(0, Math.min(n - 1, i))].value;
  };
  const onPointerDown = e => {
    setDragging(true);
    const v0 = segAt(e.clientX);
    if (v0 !== valueRef.current) onChange(v0);
    const move = ev => {
      if (!trackRef.current) return;
      const v = segAt(ev.clientX);
      if (v !== valueRef.current) onChange(v);
    };
    const up = () => {
      setDragging(false);
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("div", {
    ref: trackRef,
    role: "radiogroup",
    onPointerDown: onPointerDown,
    className: dragging ? 'twk-seg dragging' : 'twk-seg'
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-seg-thumb",
    style: {
      left: `calc(2px + ${idx} * (100% - 4px) / ${n})`,
      width: `calc((100% - 4px) / ${n})`
    }
  }), opts.map(o => /*#__PURE__*/React.createElement("button", {
    key: o.value,
    type: "button",
    role: "radio",
    "aria-checked": o.value === value
  }, o.label))));
}
function TweakSelect({
  label,
  value,
  options,
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("select", {
    className: "twk-field",
    value: value,
    onChange: e => onChange(e.target.value)
  }, options.map(o => {
    const v = typeof o === 'object' ? o.value : o;
    const l = typeof o === 'object' ? o.label : o;
    return /*#__PURE__*/React.createElement("option", {
      key: v,
      value: v
    }, l);
  })));
}
function TweakText({
  label,
  value,
  placeholder,
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("input", {
    className: "twk-field",
    type: "text",
    value: value,
    placeholder: placeholder,
    onChange: e => onChange(e.target.value)
  }));
}
function TweakNumber({
  label,
  value,
  min,
  max,
  step = 1,
  unit = '',
  onChange
}) {
  const clamp = n => {
    if (min != null && n < min) return min;
    if (max != null && n > max) return max;
    return n;
  };
  const startRef = React.useRef({
    x: 0,
    val: 0
  });
  const onScrubStart = e => {
    e.preventDefault();
    startRef.current = {
      x: e.clientX,
      val: value
    };
    const decimals = (String(step).split('.')[1] || '').length;
    const move = ev => {
      const dx = ev.clientX - startRef.current.x;
      const raw = startRef.current.val + dx * step;
      const snapped = Math.round(raw / step) * step;
      onChange(clamp(Number(snapped.toFixed(decimals))));
    };
    const up = () => {
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "twk-num"
  }, /*#__PURE__*/React.createElement("span", {
    className: "twk-num-lbl",
    onPointerDown: onScrubStart
  }, label), /*#__PURE__*/React.createElement("input", {
    type: "number",
    value: value,
    min: min,
    max: max,
    step: step,
    onChange: e => onChange(clamp(Number(e.target.value)))
  }), unit && /*#__PURE__*/React.createElement("span", {
    className: "twk-num-unit"
  }, unit));
}

// Relative-luminance contrast pick — checkmarks drawn over a swatch need to
// read on both #111 and #fafafa without per-option configuration. Hex input
// only (#rgb / #rrggbb); named or rgb()/hsl() colors fall through to "light".
function __twkIsLight(hex) {
  const h = String(hex).replace('#', '');
  const x = h.length === 3 ? h.replace(/./g, c => c + c) : h.padEnd(6, '0');
  const n = parseInt(x.slice(0, 6), 16);
  if (Number.isNaN(n)) return true;
  const r = n >> 16 & 255,
    g = n >> 8 & 255,
    b = n & 255;
  return r * 299 + g * 587 + b * 114 > 148000;
}
const __TwkCheck = ({
  light
}) => /*#__PURE__*/React.createElement("svg", {
  viewBox: "0 0 14 14",
  "aria-hidden": "true"
}, /*#__PURE__*/React.createElement("path", {
  d: "M3 7.2 5.8 10 11 4.2",
  fill: "none",
  strokeWidth: "2.2",
  strokeLinecap: "round",
  strokeLinejoin: "round",
  stroke: light ? 'rgba(0,0,0,.78)' : '#fff'
}));

// TweakColor — curated color/palette picker. Each option is either a single
// hex string or an array of 1-5 hex strings; the card adapts — a lone color
// renders solid, a palette renders colors[0] as the hero (left ~2/3) with the
// rest stacked in a sharp column on the right. onChange emits the
// option in the shape it was passed (string stays string, array stays array).
// Without options it falls back to the native color input for back-compat.
function TweakColor({
  label,
  value,
  options,
  onChange
}) {
  if (!options || !options.length) {
    return /*#__PURE__*/React.createElement("div", {
      className: "twk-row twk-row-h"
    }, /*#__PURE__*/React.createElement("div", {
      className: "twk-lbl"
    }, /*#__PURE__*/React.createElement("span", null, label)), /*#__PURE__*/React.createElement("input", {
      type: "color",
      className: "twk-swatch",
      value: value,
      onChange: e => onChange(e.target.value)
    }));
  }
  // Native <input type=color> emits lowercase hex per the HTML spec, so
  // compare case-insensitively. String() guards JSON.stringify(undefined),
  // which returns the primitive undefined (no .toLowerCase).
  const key = o => String(JSON.stringify(o)).toLowerCase();
  const cur = key(value);
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-chips",
    role: "radiogroup"
  }, options.map((o, i) => {
    const colors = Array.isArray(o) ? o : [o];
    const [hero, ...rest] = colors;
    const sup = rest.slice(0, 4);
    const on = key(o) === cur;
    return /*#__PURE__*/React.createElement("button", {
      key: i,
      type: "button",
      className: "twk-chip",
      role: "radio",
      "aria-checked": on,
      "data-on": on ? '1' : '0',
      "aria-label": colors.join(', '),
      title: colors.join(' · '),
      style: {
        background: hero
      },
      onClick: () => onChange(o)
    }, sup.length > 0 && /*#__PURE__*/React.createElement("span", null, sup.map((c, j) => /*#__PURE__*/React.createElement("i", {
      key: j,
      style: {
        background: c
      }
    }))), on && /*#__PURE__*/React.createElement(__TwkCheck, {
      light: __twkIsLight(hero)
    }));
  })));
}
function TweakButton({
  label,
  onClick,
  secondary = false
}) {
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: secondary ? 'twk-btn secondary' : 'twk-btn',
    onClick: onClick
  }, label);
}
Object.assign(window, {
  useTweaks,
  TweaksPanel,
  TweakSection,
  TweakRow,
  TweakSlider,
  TweakToggle,
  TweakRadio,
  TweakSelect,
  TweakText,
  TweakNumber,
  TweakColor,
  TweakButton
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/staybusy/tweaks-panel.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.BlockCard = __ds_scope.BlockCard;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.CategoryChip = __ds_scope.CategoryChip;

__ds_ns.DayPicker = __ds_scope.DayPicker;

__ds_ns.EmptyState = __ds_scope.EmptyState;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.NowNextBar = __ds_scope.NowNextBar;

__ds_ns.OpenSlotCard = __ds_scope.OpenSlotCard;

__ds_ns.TimeRangeLabel = __ds_scope.TimeRangeLabel;

__ds_ns.CATEGORIES = __ds_scope.CATEGORIES;

__ds_ns.CATEGORY_KEYS = __ds_scope.CATEGORY_KEYS;

})();
