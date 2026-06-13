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

  const blocks = [
    { id: 'b1', title: 'Hotel breakfast', start: at(0, 8, 0), end: at(0, 9, 0),
      category: 'food', locationName: 'The Standard', address: '25 Cooper Square, New York, NY',
      lat: 40.728, lng: -73.991 },
    { id: 'b2', title: 'Travel to venue', start: at(0, 11, 30), end: at(0, 12, 30),
      category: 'travel', locationName: 'Brooklyn Steel', lat: 40.722, lng: -73.933 },
    { id: 'b3', title: 'Soundcheck', start: at(0, 14, 0), end: at(0, 15, 30),
      category: 'gig', locationName: 'Brooklyn Steel', address: '319 Frost St, Brooklyn, NY',
      confirmationCode: 'BS-44721', notes: 'Backline ready. Talk to Mara about monitors.',
      links: ['brooklynsteel.com/advance'], lat: 40.722, lng: -73.933 },
    { id: 'b4', title: 'Green room rest', start: at(0, 16, 0), end: at(0, 18, 30),
      category: 'rest', locationName: 'Brooklyn Steel', lat: 40.722, lng: -73.933 },
    { id: 'b5', title: 'Show', start: at(0, 21, 0), end: at(0, 23, 0),
      category: 'gig', locationName: 'Brooklyn Steel', notes: 'Doors 8, openers 8:30, on stage 9.',
      lat: 40.722, lng: -73.933 },
    { id: 'b6', title: 'Flight LGA → ORD', start: at(1, 9, 30), end: at(1, 12, 0),
      category: 'travel', locationName: 'LaGuardia Airport', confirmationCode: 'DL-AB12CD',
      lat: 40.776, lng: -73.874 },
    { id: 'b7', title: 'Lunch w/ promoter', start: at(1, 13, 30), end: at(1, 14, 45),
      category: 'social', locationName: 'Au Cheval', address: '800 W Randolph St, Chicago, IL',
      lat: 41.884, lng: -87.648 },
    { id: 'b8', title: 'Radio interview', start: at(1, 16, 0), end: at(1, 16, 45),
      category: 'work', locationName: 'WBEZ Studios', lat: 41.866, lng: -87.617 },
  ];

  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }
  function fmtTime(d) {
    let h = d.getHours(); const m = d.getMinutes();
    const ap = h >= 12 ? 'PM' : 'AM'; h = h % 12; if (h === 0) h = 12;
    return `${h}:${m.toString().padStart(2, '0')} ${ap}`;
  }
  function durString(mins) {
    const h = Math.floor(mins / 60); const m = Math.round(mins % 60);
    if (h > 0 && m > 0) return `${h}h ${m}m`;
    if (h > 0) return `${h}h`;
    return `${m}m`;
  }

  window.SBData = { blocks, at, sameDay, fmtTime, durString };
})();
