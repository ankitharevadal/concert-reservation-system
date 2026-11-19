'use client';

import React, { useState, useEffect } from 'react';
import { 
  Ticket, Calendar, MapPin, Shield, Zap, Sparkles, 
  RefreshCw, CheckCircle2, AlertTriangle, Trash2, Plus, 
  Search, Code, Flame, User, Table, FileText, Check, 
  ChevronRight, LogIn, LogOut, Music, Edit3, X,
  CreditCard, ChevronDown, Eye, Filter, ArrowRight, Star,
  LayoutDashboard
} from 'lucide-react';

export default function Home() {
  // Navigation & Role State
  const [activeTab, setActiveTab] = useState<'concerts' | 'my_tickets' | 'organizer_console'>('concerts');

  // Authentication State
  const [user, setUser] = useState<any>({
    user_id: 3,
    full_name: 'Rohan Verma',
    email: 'rohan.verma@gmail.com',
    role: 'CUSTOMER',
  });
  const [showAuthModal, setShowAuthModal] = useState(false);

  // Concert & Booking State
  const [events, setEvents] = useState<any[]>([]);
  const [filteredEvents, setFilteredEvents] = useState<any[]>([]);
  const [selectedEvent, setSelectedEvent] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCity, setSelectedCity] = useState('All');

  // Realistic Arena Seat Grid (120+ seats)
  const [seats, setSeats] = useState<any[]>([]);
  const [selectedSeats, setSelectedSeats] = useState<any[]>([]);
  const [dynamicPricing, setDynamicPricing] = useState<any>(null);
  const [bookingLoading, setBookingLoading] = useState(false);
  const [bookingSuccess, setBookingSuccess] = useState<any>(null);
  const [myBookings, setMyBookings] = useState<any[]>([]);
  const [paymentMethod, setPaymentMethod] = useState<'UPI' | 'CREDIT_CARD' | 'NET_BANKING'>('UPI');

  // Organizer Management State
  const [newConcert, setNewConcert] = useState({
    event_title: '',
    artist_id: 1,
    venue_id: 1,
    base_ticket_price: 2500,
    duration_minutes: 180,
    event_date_time: '2026-11-20T19:00:00Z',
    event_description: 'Arena live headline performance with full orchestra & stage lighting.',
  });
  const [crudMsg, setCrudMsg] = useState('');

  // Load Initial Data
  useEffect(() => {
    fetchEvents();
    fetchMyBookings(3);
  }, []);

  // Filter events when search or city changes
  useEffect(() => {
    let result = [...events];
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        (e) =>
          e.event_title.toLowerCase().includes(q) ||
          e.artist_name.toLowerCase().includes(q) ||
          e.venue_name.toLowerCase().includes(q) ||
          e.city.toLowerCase().includes(q)
      );
    }
    if (selectedCity !== 'All') {
      result = result.filter(
        (e) =>
          e.city.toLowerCase().includes(selectedCity.toLowerCase()) ||
          selectedCity.toLowerCase().includes(e.city.toLowerCase())
      );
    }
    setFilteredEvents(result);
  }, [events, searchQuery, selectedCity]);

  const fetchEvents = async () => {
    try {
      const res = await fetch('/api/events');
      const data = await res.json();
      if (data.success && data.events) {
        setEvents(data.events);
        setFilteredEvents(data.events);
        if (data.events.length > 0 && !selectedEvent) {
          selectEvent(data.events[0]);
        }
      }
    } catch (err) {
      console.error('Fetch events error:', err);
    }
  };

  const selectEvent = async (event: any) => {
    setSelectedEvent(event);
    setSelectedSeats([]);
    setDynamicPricing(null);
    setBookingSuccess(null);
    try {
      const res = await fetch(`/api/seats?eventId=${event.event_id}`);
      const data = await res.json();
      if (data.success) {
        setSeats(data.seats || []);
      }
    } catch (err) {
      console.error('Fetch seats error:', err);
    }
  };

  const toggleSeatSelection = async (seat: any) => {
    if (seat.current_status === 'BOOKED') return;
    setBookingSuccess(null);

    const isAlreadySelected = selectedSeats.some((s) => s.seat_id === seat.seat_id);
    let newSelected: any[] = [];
    if (isAlreadySelected) {
      newSelected = selectedSeats.filter((s) => s.seat_id !== seat.seat_id);
    } else {
      newSelected = [...selectedSeats, seat];
    }
    setSelectedSeats(newSelected);

    if (newSelected.length > 0 && selectedEvent) {
      const lastSeat = newSelected[newSelected.length - 1];
      try {
        const res = await fetch(
          `/api/pricing?eventId=${selectedEvent.event_id}&seatId=${lastSeat.seat_id}`
        );
        const data = await res.json();
        if (data.success) {
          setDynamicPricing(data.data);
        }
      } catch (err) {
        console.error('Dynamic pricing error:', err);
      }
    } else {
      setDynamicPricing(null);
    }
  };

  const handleBookTickets = async () => {
    if (!user) {
      setShowAuthModal(true);
      return;
    }
    if (!selectedEvent || selectedSeats.length === 0) return;

    setBookingLoading(true);
    try {
      const res = await fetch('/api/bookings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_id: user.user_id,
          event_id: selectedEvent.event_id,
          seat_ids: selectedSeats.map((s) => s.seat_id),
          payment_method: paymentMethod,
        }),
      });
      const data = await res.json();
      if (data.success) {
        setBookingSuccess(data);
        setSelectedSeats([]);
        selectEvent(selectedEvent);
        fetchMyBookings(user.user_id);
      } else {
        alert(data.error || 'Failed to complete booking');
      }
    } catch (err: any) {
      alert('Error during booking: ' + err.message);
    } finally {
      setBookingLoading(false);
    }
  };

  const fetchMyBookings = async (userId: number) => {
    try {
      const res = await fetch(`/api/bookings?userId=${userId}`);
      const data = await res.json();
      if (data.success) {
        setMyBookings(data.bookings || []);
      }
    } catch (err) {
      console.error('Fetch bookings error:', err);
    }
  };

  const handleQuickLogin = (role: 'CUSTOMER' | 'ADMIN') => {
    if (role === 'ADMIN') {
      setUser({
        user_id: 1,
        full_name: 'Aarav Sharma',
        email: 'aarav.admin@pesevents.edu',
        role: 'ADMIN',
      });
      fetchMyBookings(1);
    } else {
      setUser({
        user_id: 3,
        full_name: 'Rohan Verma',
        email: 'rohan.verma@gmail.com',
        role: 'CUSTOMER',
      });
      fetchMyBookings(3);
    }
    setShowAuthModal(false);
  };

  // Organizer Event Management Handlers
  const handleCreateConcert = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch('/api/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newConcert),
      });
      const data = await res.json();
      if (data.success) {
        setCrudMsg(`Successfully created event "${newConcert.event_title}"!`);
        fetchEvents();
        setNewConcert({
          event_title: '',
          artist_id: 1,
          venue_id: 1,
          base_ticket_price: 2500,
          duration_minutes: 180,
          event_date_time: '2026-11-20T19:00:00Z',
          event_description: 'Arena live headline performance.',
        });
      }
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleUpdatePrice = async (eventId: number, currentPrice: number) => {
    const newPrice = prompt(`Enter new base ticket price (₹) for event #${eventId}:`, String(currentPrice + 500));
    if (!newPrice) return;
    try {
      const res = await fetch('/api/events', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ event_id: eventId, base_ticket_price: parseFloat(newPrice) }),
      });
      const data = await res.json();
      if (data.success) {
        setCrudMsg(`Price updated to ₹${newPrice} for Event #${eventId}!`);
        fetchEvents();
      }
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleDeleteConcert = async (eventId: number) => {
    if (!confirm(`Are you sure you want to cancel and delete event #${eventId}?`)) return;
    try {
      const res = await fetch(`/api/events?eventId=${eventId}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        setCrudMsg(`Event #${eventId} successfully removed from catalog.`);
        fetchEvents();
      }
    } catch (err: any) {
      alert(err.message);
    }
  };

  const concertCovers: Record<number, string> = {
    1: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1000&q=80',
    2: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=1000&q=80',
    3: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1000&q=80',
    4: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=1000&q=80',
    5: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=1000&q=80',
    6: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=1000&q=80',
    7: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?auto=format&fit=crop&w=1000&q=80',
    8: 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?auto=format&fit=crop&w=1000&q=80',
    9: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1000&q=80',
    10: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?auto=format&fit=crop&w=1000&q=80',
  };

  // Calculate cart total for selected seats
  const totalCartBase = selectedSeats.reduce((acc, s) => {
    const base = parseFloat(selectedEvent?.base_ticket_price || '2000');
    const mult = parseFloat(s.price_multiplier || '1.0');
    return acc + Math.round(base * mult);
  }, 0);
  const gstAmount = Math.round(totalCartBase * 0.18);
  const convenienceFee = selectedSeats.length > 0 ? 120 : 0;
  const grandTotal = totalCartBase + gstAmount + convenienceFee;

  return (
    <div className="min-h-screen bg-[#08090c] text-zinc-100 flex flex-col font-sans">
      {/* ========================================================================= */}
      {/* 1. TOP HEADER NAVIGATION */}
      {/* ========================================================================= */}
      <header className="border-b border-zinc-800/80 bg-[#0c0d12]/95 backdrop-blur sticky top-0 z-50 px-6 py-3">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
          {/* Brand Logo */}
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-lg bg-orange-600 flex items-center justify-center text-white shadow-md shadow-orange-600/30">
              <Ticket className="h-5 w-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-base tracking-tight text-white">RESERVE LIVE</span>
                <span className="text-[10px] font-semibold px-2 py-0.5 rounded bg-zinc-800 text-orange-400 border border-zinc-700">
                  LIVE TICKETING
                </span>
              </div>
              <p className="text-[11px] text-zinc-400">Intelligent Arena Seat Reservation Platform</p>
            </div>
          </div>

          {/* Navigation Tabs */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveTab('concerts')}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition ${
                activeTab === 'concerts'
                  ? 'bg-zinc-800 text-white shadow-sm'
                  : 'text-zinc-400 hover:text-white'
              }`}
            >
              Concerts & Seats
            </button>

            <button
              onClick={() => setActiveTab('my_tickets')}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition flex items-center gap-1.5 ${
                activeTab === 'my_tickets'
                  ? 'bg-zinc-800 text-white shadow-sm'
                  : 'text-zinc-400 hover:text-white'
              }`}
            >
              <Ticket className="h-3.5 w-3.5 text-orange-400" /> My Passes
              {myBookings.length > 0 && (
                <span className="h-4 px-1.5 rounded-full bg-orange-600 text-white text-[10px] flex items-center justify-center font-bold">
                  {myBookings.length}
                </span>
              )}
            </button>

            {/* Organizer Console (Available for Admin/Organizer Roles) */}
            {user && (user.role === 'ADMIN' || user.role === 'ORGANIZER') && (
              <button
                onClick={() => setActiveTab('organizer_console')}
                className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition flex items-center gap-1.5 ${
                  activeTab === 'organizer_console'
                    ? 'bg-zinc-800 text-white shadow-sm border border-orange-500/30'
                    : 'text-zinc-400 hover:text-white'
                }`}
              >
                <LayoutDashboard className="h-3.5 w-3.5 text-orange-400" /> Organizer Console
              </button>
            )}
          </div>

          {/* User Profile / Quick Login */}
          <div className="flex items-center gap-3">
            {user ? (
              <div className="flex items-center gap-2.5 bg-zinc-900/80 px-3 py-1.5 rounded-xl border border-zinc-800 text-xs">
                <div className="h-7 w-7 rounded-full bg-zinc-800 flex items-center justify-center font-bold text-white border border-zinc-700">
                  {user.full_name.charAt(0)}
                </div>
                <div className="hidden sm:block text-left">
                  <div className="font-semibold text-white leading-tight">{user.full_name}</div>
                  <div className="text-[10px] text-zinc-400 font-mono">{user.role}</div>
                </div>
                <button
                  onClick={() => setShowAuthModal(true)}
                  className="text-zinc-500 hover:text-zinc-300 ml-1 text-[11px]"
                  title="Switch Role"
                >
                  Switch
                </button>
              </div>
            ) : (
              <button
                onClick={() => setShowAuthModal(true)}
                className="px-3.5 py-1.5 rounded-lg bg-orange-600 hover:bg-orange-500 text-white text-xs font-bold shadow-md shadow-orange-600/20"
              >
                Sign In
              </button>
            )}
          </div>
        </div>
      </header>

      {/* ========================================================================= */}
      {/* 2. TAB CONTENT: LIVE CONCERTS & ARENA SEAT SELECTION */}
      {/* ========================================================================= */}
      {activeTab === 'concerts' && (
        <main className="max-w-7xl mx-auto w-full px-6 py-6 flex-1 space-y-8">
          {/* Search & City Filter Bar */}
          <div className="flex flex-col md:flex-row items-center justify-between gap-4 bg-[#0e1017] p-4 rounded-xl border border-zinc-800">
            <div className="flex-1 w-full relative">
              <Search className="h-4 w-4 text-zinc-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search concerts, artists, arenas (A.R. Rahman, Coldplay, Diljit, Bangalore)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-zinc-900 border border-zinc-700/80 rounded-lg pl-10 pr-4 py-2 text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-orange-500"
              />
            </div>

            <div className="flex items-center gap-2 text-xs flex-wrap">
              <span className="text-zinc-400">City:</span>
              {['All', 'Bengaluru', 'Mumbai', 'New Delhi', 'Hyderabad', 'Chennai', 'Kolkata'].map((city) => (
                <button
                  key={city}
                  onClick={() => setSelectedCity(city)}
                  className={`px-3 py-1.5 rounded-md font-medium transition ${
                    selectedCity === city
                      ? 'bg-zinc-800 text-white border border-zinc-700'
                      : 'text-zinc-400 hover:text-white'
                  }`}
                >
                  {city}
                </button>
              ))}
            </div>
          </div>

          {/* Concert Tour Cards */}
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-bold text-zinc-300 uppercase tracking-wider">
                Live Tours on Sale ({filteredEvents.length} Shows)
              </h3>
              <span className="text-xs text-zinc-500">Official arena tickets with real-time seat lock</span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
              {filteredEvents.map((ev) => {
                const isSelected = selectedEvent?.event_id === ev.event_id;
                const cover = concertCovers[ev.event_id] || concertCovers[((ev.event_id - 1) % 10) + 1] || concertCovers[1];
                return (
                  <div
                    key={ev.event_id}
                    onClick={() => selectEvent(ev)}
                    className={`rounded-xl overflow-hidden border cursor-pointer transition flex flex-col justify-between bg-[#0e1017] ${
                      isSelected
                        ? 'border-orange-500 shadow-xl shadow-orange-500/10 ring-1 ring-orange-500'
                        : 'border-zinc-800 hover:border-zinc-700'
                    }`}
                  >
                    <div className="h-40 w-full relative overflow-hidden bg-zinc-900">
                      <img
                        src={cover}
                        alt={ev.event_title}
                        className="w-full h-full object-cover group-hover:scale-105 transition duration-500 opacity-80"
                      />
                      <div className="absolute top-2.5 right-2.5 px-2 py-0.5 rounded bg-black/80 backdrop-blur text-[11px] font-bold text-orange-400 border border-zinc-700">
                        ₹{ev.base_ticket_price}
                      </div>
                      <div className="absolute bottom-2.5 left-2.5 px-2 py-0.5 rounded bg-zinc-900/90 text-[10px] font-semibold text-zinc-300">
                        {ev.artist_name}
                      </div>
                    </div>

                    <div className="p-4 space-y-2 flex-1 flex flex-col justify-between">
                      <div>
                        <h4 className="font-bold text-white text-sm line-clamp-1">{ev.event_title}</h4>
                        <div className="mt-2 text-xs text-zinc-400 space-y-1">
                          <div className="flex items-center gap-1.5">
                            <MapPin className="h-3 w-3 text-zinc-500" /> {ev.venue_name}, {ev.city}
                          </div>
                          <div className="flex items-center gap-1.5">
                            <Calendar className="h-3 w-3 text-zinc-500" /> {new Date(ev.event_date_time).toLocaleDateString()}
                          </div>
                        </div>
                      </div>

                      <div className="pt-2 border-t border-zinc-800/80 flex items-center justify-between text-xs">
                        <span className="text-emerald-400 font-semibold">{ev.available_seats} seats left</span>
                        <span className="text-orange-400 font-bold flex items-center gap-1">
                          Select Seats &rarr;
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* ========================================================================= */}
          {/* REALISTIC MULTI-TIER ARENA SEAT MAP (120+ SEATS) */}
          {/* ========================================================================= */}
          {selectedEvent && (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 pt-4">
              {/* Arena Seating Grid */}
              <div className="lg:col-span-2 bg-[#0e1017] border border-zinc-800 rounded-2xl p-6">
                <div className="flex items-center justify-between pb-4 border-b border-zinc-800">
                  <div>
                    <h3 className="font-bold text-white text-base">
                      {selectedEvent.event_title} &bull; Arena Layout
                    </h3>
                    <p className="text-xs text-zinc-400 mt-0.5">
                      {selectedEvent.venue_name} &bull; Capacity: {selectedEvent.total_capacity} seats
                    </p>
                  </div>

                  {/* Seat Status Legend */}
                  <div className="flex items-center gap-4 text-xs">
                    <div className="flex items-center gap-1.5">
                      <div className="h-3 w-3 rounded bg-zinc-800 border border-zinc-700"></div> Available
                    </div>
                    <div className="flex items-center gap-1.5">
                      <div className="h-3 w-3 rounded bg-orange-600 shadow-sm shadow-orange-600/50"></div> Selected
                    </div>
                    <div className="flex items-center gap-1.5">
                      <div className="h-3 w-3 rounded bg-rose-950 border border-rose-800"></div> Reserved
                    </div>
                  </div>
                </div>

                {/* Stage Performance Deck Visual */}
                <div className="my-6 flex flex-col items-center">
                  <div className="w-3/4 h-8 bg-zinc-800 border border-zinc-700 rounded-t-xl flex items-center justify-center text-xs font-bold text-zinc-300 tracking-wider shadow-inner">
                    MAIN LIVE STAGE & SOUND RIG
                  </div>
                  <div className="w-4/5 h-0.5 bg-orange-500/50 mt-0.5"></div>
                  <span className="text-[10px] text-zinc-500 mt-1">STAGE THIS WAY</span>
                </div>

                {/* 120+ Seats Displayed Across 4 Tiers */}
                <div className="space-y-4">
                  {[
                    { tier: 'VIP_LOUNGE', label: 'VIP Lounge Pit (Multiplier 2.50x - Front Row Experience)', rows: ['A', 'B'] },
                    { tier: 'GOLD_FRONT', label: 'Premium Gold Front (Multiplier 1.60x - Central Proximity)', rows: ['C', 'D', 'E'] },
                    { tier: 'SILVER_MIDDLE', label: 'Silver Middle Arena (Multiplier 1.25x - Elevated Sightlines)', rows: ['F', 'G', 'H'] },
                    { tier: 'BRONZE_BALCONY', label: 'Bronze Balcony Grandstand (Multiplier 1.00x - Panoramic View)', rows: ['J', 'K'] },
                  ].map((section) => (
                    <div key={section.tier} className="bg-zinc-950/60 p-3.5 rounded-xl border border-zinc-800/80">
                      <div className="text-[11px] font-bold text-orange-400 uppercase tracking-wider mb-2.5 flex items-center justify-between">
                        <span>{section.label}</span>
                        <span className="text-zinc-500 font-mono text-[10px]">
                          Base: ₹{selectedEvent.base_ticket_price}
                        </span>
                      </div>

                      <div className="space-y-2">
                        {section.rows.map((rowLetter) => {
                          const rowSeats = seats.filter((s) => s.seat_row === rowLetter);
                          if (rowSeats.length === 0) return null;

                          // Split row into Left Wing and Right Wing for realistic center aisle
                          const mid = Math.ceil(rowSeats.length / 2);
                          const leftWing = rowSeats.slice(0, mid);
                          const rightWing = rowSeats.slice(mid);

                          return (
                            <div key={rowLetter} className="flex items-center justify-center gap-3">
                              {/* Left Row Indicator */}
                              <span className="w-5 text-center text-xs font-bold text-zinc-500 font-mono">
                                {rowLetter}
                              </span>

                              {/* Left Wing Seats */}
                              <div className="flex items-center gap-1.5">
                                {leftWing.map((seat) => {
                                  const isSelected = selectedSeats.some((s) => s.seat_id === seat.seat_id);
                                  const isBooked = seat.current_status === 'BOOKED';
                                  return (
                                    <button
                                      key={seat.seat_id}
                                      onClick={() => toggleSeatSelection(seat)}
                                      disabled={isBooked}
                                      title={`Row ${seat.seat_row}, Seat ${seat.seat_number} (${seat.section_name}) - Multiplier ${seat.price_multiplier}x`}
                                      className={`h-7 w-7 rounded flex items-center justify-center text-[10px] font-bold transition ${
                                        isSelected
                                          ? 'bg-orange-600 text-white shadow-md shadow-orange-600/40 ring-2 ring-orange-400'
                                          : isBooked
                                          ? 'bg-rose-950/40 border border-rose-900 text-rose-700 cursor-not-allowed'
                                          : 'bg-zinc-900 border border-zinc-700 text-zinc-300 hover:border-orange-500 hover:text-white'
                                      }`}
                                    >
                                      {seat.seat_number}
                                    </button>
                                  );
                                })}
                              </div>

                              {/* Walkway Center Aisle */}
                              <div className="w-5 text-center text-[9px] text-zinc-600 font-mono">||</div>

                              {/* Right Wing Seats */}
                              <div className="flex items-center gap-1.5">
                                {rightWing.map((seat) => {
                                  const isSelected = selectedSeats.some((s) => s.seat_id === seat.seat_id);
                                  const isBooked = seat.current_status === 'BOOKED';
                                  return (
                                    <button
                                      key={seat.seat_id}
                                      onClick={() => toggleSeatSelection(seat)}
                                      disabled={isBooked}
                                      title={`Row ${seat.seat_row}, Seat ${seat.seat_number} (${seat.section_name}) - Multiplier ${seat.price_multiplier}x`}
                                      className={`h-7 w-7 rounded flex items-center justify-center text-[10px] font-bold transition ${
                                        isSelected
                                          ? 'bg-orange-600 text-white shadow-md shadow-orange-600/40 ring-2 ring-orange-400'
                                          : isBooked
                                          ? 'bg-rose-950/40 border border-rose-900 text-rose-700 cursor-not-allowed'
                                          : 'bg-zinc-900 border border-zinc-700 text-zinc-300 hover:border-orange-500 hover:text-white'
                                      }`}
                                    >
                                      {seat.seat_number}
                                    </button>
                                  );
                                })}
                              </div>

                              {/* Right Row Indicator */}
                              <span className="w-5 text-center text-xs font-bold text-zinc-500 font-mono">
                                {rowLetter}
                              </span>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Checkout / Order Summary Drawer */}
              <div className="space-y-4">
                <div className="bg-[#0e1017] border border-zinc-800 rounded-2xl p-5 space-y-4">
                  <h4 className="font-bold text-white text-sm pb-2 border-b border-zinc-800 flex items-center justify-between">
                    <span>Order Summary</span>
                    <span className="text-xs font-mono text-orange-400">
                      {selectedSeats.length} seat(s) selected
                    </span>
                  </h4>

                  {selectedSeats.length > 0 ? (
                    <div className="space-y-3 text-xs">
                      {/* Selected Seats Chips */}
                      <div className="flex flex-wrap gap-1.5">
                        {selectedSeats.map((s) => (
                          <span
                            key={s.seat_id}
                            className="px-2 py-0.5 rounded bg-zinc-800 border border-zinc-700 text-white font-mono"
                          >
                            {s.seat_row}{s.seat_number} ({s.section_name})
                          </span>
                        ))}
                      </div>

                      {/* Dynamic Pricing Breakdown */}
                      <div className="bg-zinc-950 p-3 rounded-xl border border-zinc-800 space-y-2">
                        <div className="flex justify-between text-zinc-400">
                          <span>Concert Base Price:</span>
                          <span className="text-zinc-200">₹{selectedEvent.base_ticket_price}</span>
                        </div>
                        <div className="flex justify-between text-zinc-400">
                          <span>Dynamic Surge Factor:</span>
                          <span className="text-amber-400 font-semibold">
                            {dynamicPricing?.surge_factor || '1.00'}x (High Demand Surge)
                          </span>
                        </div>
                        <div className="flex justify-between text-zinc-400">
                          <span>Subtotal (Tickets):</span>
                          <span className="text-zinc-200 font-bold">₹{totalCartBase}</span>
                        </div>
                        <div className="flex justify-between text-zinc-400">
                          <span>GST (18%):</span>
                          <span className="text-zinc-200">₹{gstAmount}</span>
                        </div>
                        <div className="flex justify-between text-zinc-400">
                          <span>Convenience Fee:</span>
                          <span className="text-zinc-200">₹{convenienceFee}</span>
                        </div>
                        <div className="pt-2 border-t border-zinc-800 flex justify-between text-sm font-bold">
                          <span className="text-white">Total Amount:</span>
                          <span className="text-orange-400 text-base">₹{grandTotal}</span>
                        </div>
                      </div>

                      {/* Payment Method Selector */}
                      <div>
                        <label className="block text-zinc-400 mb-1 font-medium">Payment Mode:</label>
                        <div className="grid grid-cols-3 gap-2">
                          {(['UPI', 'CREDIT_CARD', 'NET_BANKING'] as const).map((m) => (
                            <button
                              key={m}
                              type="button"
                              onClick={() => setPaymentMethod(m)}
                              className={`py-1.5 px-2 rounded-lg text-center font-bold text-[11px] transition ${
                                paymentMethod === m
                                  ? 'bg-orange-600 text-white'
                                  : 'bg-zinc-900 border border-zinc-700 text-zinc-400'
                              }`}
                            >
                              {m.replace('_', ' ')}
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Reservation Button */}
                      <button
                        onClick={handleBookTickets}
                        disabled={bookingLoading}
                        className="w-full mt-2 py-3 rounded-xl bg-orange-600 hover:bg-orange-500 text-white font-bold text-xs shadow-lg shadow-orange-600/30 transition flex items-center justify-center gap-2"
                      >
                        {bookingLoading ? (
                          <RefreshCw className="h-4 w-4 animate-spin" />
                        ) : (
                          <CreditCard className="h-4 w-4" />
                        )}
                        Confirm Reservation
                      </button>
                    </div>
                  ) : (
                    <div className="text-center py-10 text-xs text-zinc-500 bg-zinc-950/40 rounded-xl border border-zinc-800/60">
                      Click on any green available seat from the arena layout to select tickets.
                    </div>
                  )}
                </div>

                {/* Confirmed Booking Pass Toast */}
                {bookingSuccess && (
                  <div className="bg-emerald-950/30 border border-emerald-500/40 rounded-2xl p-4 text-xs space-y-2">
                    <div className="flex items-center gap-2 text-emerald-400 font-bold">
                      <CheckCircle2 className="h-4 w-4" /> Reservation Confirmed!
                    </div>
                    <div className="text-zinc-300">
                      <strong>Booking Ref:</strong> <code className="text-emerald-300 font-mono">{bookingSuccess.booking_reference}</code>
                    </div>
                    <div className="text-zinc-300">
                      <strong>Seats:</strong> {bookingSuccess.seat_details} &bull; <strong>Total:</strong> ₹{bookingSuccess.total_amount}
                    </div>
                    <p className="text-[11px] text-zinc-400">
                      Your digital passes are ready. Head over to <strong>My Passes</strong> to view your entry barcode.
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}
        </main>
      )}

      {/* ========================================================================= */}
      {/* 3. TAB CONTENT: MY PASSES & BOOKING HISTORY */}
      {/* ========================================================================= */}
      {activeTab === 'my_tickets' && (
        <main className="max-w-7xl mx-auto w-full px-6 py-6 flex-1 space-y-6">
          <div>
            <h2 className="text-xl font-bold text-white">My Digital Concert Passes</h2>
            <p className="text-xs text-zinc-400 mt-1">
              Your verified access passes. Present the entry pass barcode at the arena turnstile.
            </p>
          </div>

          {myBookings.length === 0 ? (
            <div className="p-12 text-center bg-[#0e1017] border border-zinc-800 rounded-2xl space-y-3">
              <Ticket className="h-10 w-10 text-zinc-600 mx-auto" />
              <h4 className="text-white font-bold text-sm">No Active Tickets Found</h4>
              <p className="text-xs text-zinc-400 max-w-sm mx-auto">
                Select your seats from the live concert map and your verified pass will appear here.
              </p>
              <button
                onClick={() => setActiveTab('concerts')}
                className="px-4 py-2 bg-orange-600 hover:bg-orange-500 text-white rounded-lg text-xs font-semibold"
              >
                Browse Concerts
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {myBookings.map((b) => (
                <div
                  key={b.ticket_id}
                  className="bg-[#0e1017] border border-zinc-800 rounded-2xl overflow-hidden shadow-xl flex flex-col justify-between"
                >
                  <div className="p-5 space-y-3">
                    <div className="flex items-start justify-between">
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                        {b.ticket_status}
                      </span>
                      <span className="text-xs font-mono text-zinc-400 font-bold">{b.booking_reference}</span>
                    </div>
                    <div>
                      <h4 className="font-bold text-white text-base">{b.event_title}</h4>
                      <p className="text-xs text-orange-400 font-semibold">{b.artist_name}</p>
                    </div>
                    <div className="pt-2 border-t border-zinc-800 text-xs text-zinc-400 space-y-1">
                      <div><strong>Venue:</strong> {b.venue_name}</div>
                      <div><strong>Allocated Seat:</strong> <span className="text-white font-bold">{b.seat_code}</span> ({b.section_name})</div>
                      <div><strong>Price Paid:</strong> ₹{b.allocated_price} via {b.payment_method}</div>
                    </div>
                  </div>

                  {/* Perforated Barcode Pass */}
                  <div className="bg-zinc-950 p-4 border-t border-zinc-800 flex items-center justify-between">
                    <div>
                      <div className="text-[10px] text-zinc-500 font-mono truncate max-w-[190px]">
                        {b.barcode_hash}
                      </div>
                      <div className="text-[9px] text-zinc-600 font-mono">GATE ENTRY PASS</div>
                    </div>
                    <span className="text-xs font-bold text-emerald-400">VERIFIED</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </main>
      )}

      {/* ========================================================================= */}
      {/* 4. TAB CONTENT: ORGANIZER CONSOLE (LIVE EVENT MANAGEMENT) */}
      {/* ========================================================================= */}
      {activeTab === 'organizer_console' && user && (user.role === 'ADMIN' || user.role === 'ORGANIZER') && (
        <main className="max-w-7xl mx-auto w-full px-6 py-6 flex-1 space-y-6">
          <div className="flex items-center justify-between pb-2 border-b border-zinc-800">
            <div>
              <h2 className="text-xl font-bold text-white">Organizer Console</h2>
              <p className="text-xs text-zinc-400 mt-0.5">
                Manage upcoming live tours, ticket pricing schedules, and arena allocations.
              </p>
            </div>
            <span className="px-3 py-1 rounded-lg bg-orange-950/40 border border-orange-500/30 text-orange-400 text-xs font-semibold">
              Organizer Mode: {user.full_name}
            </span>
          </div>

          {/* Quick Schedule Concert Form */}
          <form onSubmit={handleCreateConcert} className="bg-[#0e1017] p-5 rounded-2xl border border-zinc-800 space-y-4">
            <h4 className="font-bold text-white text-sm flex items-center gap-2">
              <Plus className="h-4 w-4 text-orange-400" /> Schedule New Tour / Concert
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-5 gap-3 text-xs">
              <div>
                <label className="block text-zinc-400 mb-1">Event Title</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Anirudh Live 2026"
                  value={newConcert.event_title}
                  onChange={(e) => setNewConcert({ ...newConcert, event_title: e.target.value })}
                  className="w-full bg-zinc-900 border border-zinc-700 rounded-lg px-3 py-2 text-white"
                />
              </div>
              <div>
                <label className="block text-zinc-400 mb-1">Headline Artist</label>
                <select
                  value={newConcert.artist_id}
                  onChange={(e) => setNewConcert({ ...newConcert, artist_id: parseInt(e.target.value) })}
                  className="w-full bg-zinc-900 border border-zinc-700 rounded-lg px-3 py-2 text-white"
                >
                  <option value={1}>A. R. Rahman Live</option>
                  <option value={2}>Coldplay Experience</option>
                  <option value={3}>Diljit Dosanjh</option>
                  <option value={4}>Prateek Kuhad</option>
                  <option value={5}>Dua Lipa Electro</option>
                  <option value={6}>Arijit Singh</option>
                  <option value={7}>Anirudh Live Band</option>
                  <option value={8}>Karan Aujla</option>
                </select>
              </div>
              <div>
                <label className="block text-zinc-400 mb-1">Venue & Host City</label>
                <select
                  value={newConcert.venue_id}
                  onChange={(e) => setNewConcert({ ...newConcert, venue_id: parseInt(e.target.value) })}
                  className="w-full bg-zinc-900 border border-zinc-700 rounded-lg px-3 py-2 text-white"
                >
                  <option value={1}>PES University Arena (Bengaluru)</option>
                  <option value={2}>Palace Grounds (Bengaluru)</option>
                  <option value={3}>DY Patil Stadium (Mumbai)</option>
                  <option value={4}>JLN Stadium Arena (New Delhi)</option>
                  <option value={5}>GMC Balayogi Stadium (Hyderabad)</option>
                  <option value={6}>JLN Stadium Marina (Chennai)</option>
                  <option value={7}>Eden Gardens Arena (Kolkata)</option>
                </select>
              </div>
              <div>
                <label className="block text-zinc-400 mb-1">Base Price (₹)</label>
                <input
                  type="number"
                  min={500}
                  value={newConcert.base_ticket_price}
                  onChange={(e) => setNewConcert({ ...newConcert, base_ticket_price: parseFloat(e.target.value) })}
                  className="w-full bg-zinc-900 border border-zinc-700 rounded-lg px-3 py-2 text-white"
                />
              </div>
              <div className="flex items-end">
                <button
                  type="submit"
                  className="w-full py-2 bg-orange-600 hover:bg-orange-500 text-white font-bold rounded-lg text-xs transition"
                >
                  Schedule Concert
                </button>
              </div>
            </div>
          </form>

          {crudMsg && (
            <div className="p-3 bg-emerald-950/30 border border-emerald-500/40 text-emerald-400 rounded-xl text-xs">
              {crudMsg}
            </div>
          )}

          {/* Active Concerts Catalog */}
          <div className="bg-[#0e1017] rounded-2xl border border-zinc-800 overflow-hidden">
            <div className="p-4 border-b border-zinc-800 flex items-center justify-between">
              <span className="font-bold text-white text-sm">Scheduled Arena Concerts ({events.length})</span>
              <span className="text-zinc-500 text-xs">Real-Time Database Sync</span>
            </div>
            <table className="w-full text-left font-sans text-xs">
              <thead className="bg-zinc-900/80 text-zinc-400 uppercase text-[10px]">
                <tr>
                  <th className="p-3">ID</th>
                  <th className="p-3">Concert Title</th>
                  <th className="p-3">Performer</th>
                  <th className="p-3">Base Price</th>
                  <th className="p-3">Status</th>
                  <th className="p-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800 font-mono text-[11px]">
                {events.map((ev) => (
                  <tr key={ev.event_id} className="hover:bg-zinc-900/40 transition">
                    <td className="p-3 text-orange-400">#{ev.event_id}</td>
                    <td className="p-3 font-bold text-white font-sans">{ev.event_title}</td>
                    <td className="p-3 text-zinc-300 font-sans">{ev.artist_name}</td>
                    <td className="p-3 text-emerald-400 font-bold">₹{ev.base_ticket_price}</td>
                    <td className="p-3 text-zinc-400">{ev.event_status}</td>
                    <td className="p-3 text-right space-x-2">
                      <button
                        onClick={() => handleUpdatePrice(ev.event_id, ev.base_ticket_price)}
                        className="px-2.5 py-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded text-xs font-sans"
                      >
                        Edit Price
                      </button>
                      <button
                        onClick={() => handleDeleteConcert(ev.event_id)}
                        className="px-2.5 py-1 bg-rose-950/60 border border-rose-800 text-rose-400 hover:bg-rose-900 hover:text-white rounded text-xs font-sans"
                      >
                        Cancel Event
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </main>
      )}

      {/* ========================================================================= */}
      {/* AUTHENTICATION ROLE SELECTOR MODAL */}
      {/* ========================================================================= */}
      {showAuthModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#0e1017] border border-zinc-800 rounded-2xl w-full max-w-md p-6 space-y-4 shadow-2xl relative">
            <button
              onClick={() => setShowAuthModal(false)}
              className="absolute top-4 right-4 text-zinc-400 hover:text-white"
            >
              <X className="h-5 w-5" />
            </button>

            <div>
              <h3 className="text-base font-bold text-white">Select User Role (RBAC)</h3>
              <p className="text-xs text-zinc-400 mt-0.5">
                Demonstrates database-level access control between Attendee & Organizer.
              </p>
            </div>

            <div className="space-y-2 pt-2">
              <button
                type="button"
                onClick={() => handleQuickLogin('CUSTOMER')}
                className="w-full p-3.5 rounded-xl border border-zinc-800 bg-zinc-900/60 hover:bg-zinc-800 text-left transition flex items-center justify-between text-xs"
              >
                <div>
                  <div className="font-bold text-white">👤 Rohan Verma (Attendee)</div>
                  <div className="text-[11px] text-zinc-400">Can browse concerts, select seats, and reserve passes.</div>
                </div>
                <span className="text-emerald-400 font-bold">&rarr;</span>
              </button>

              <button
                type="button"
                onClick={() => handleQuickLogin('ADMIN')}
                className="w-full p-3.5 rounded-xl border border-orange-500/30 bg-orange-950/20 hover:bg-orange-950/40 text-left transition flex items-center justify-between text-xs"
              >
                <div>
                  <div className="font-bold text-white">👑 Aarav Sharma (Organizer / Admin)</div>
                  <div className="text-[11px] text-orange-400">Full administrative CRUD access & live database inspection.</div>
                </div>
                <span className="text-orange-400 font-bold">&rarr;</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Clean Commercial Footer */}
      <footer className="border-t border-zinc-800/80 bg-[#08090c] px-6 py-4 text-center text-xs text-zinc-500">
        &copy; 2026 RESERVE LIVE Technologies Inc. &bull; Real-Time Arena Ticket Reservation Platform. All rights reserved.
      </footer>
    </div>
  );
}
