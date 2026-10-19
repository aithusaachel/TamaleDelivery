'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabaseClient';
import {
  Package,
  Users,
  Wallet,
  Settings as SettingsIcon,
  PhoneCall,
  ShieldCheck,
  LogOut,
  AlertTriangle,
  CheckCircle2,
  Clock,
  Bike,
  Plus,
  RefreshCw,
  Search,
  ArrowRight,
  MapPin,
  UserCheck,
  ChevronRight,
  DollarSign,
  X,
  Radio,
} from 'lucide-react';

interface Profile {
  id: string;
  role: 'customer' | 'rider' | 'dispatcher' | 'admin';
  full_name: string | null;
  phone: string | null;
}

interface Delivery {
  id: string;
  status: string;
  vehicle: 'motorbike' | 'moto_king';
  pickup_text: string | null;
  dropoff_text: string | null;
  receiver_name: string;
  receiver_phone: string;
  distance_km: number;
  fare: number;
  commission_amount: number | null;
  payer: string;
  created_at: string;
  rider_id: string | null;
}

interface Rider {
  profile_id: string;
  vehicle: string | null;
  plate_number: string | null;
  verification: string;
  is_online: boolean;
  wallet_balance: number;
  completed_trips: number;
  profiles: Profile | null;
}

interface TopupRequest {
  id: string;
  rider_id: string;
  amount: number;
  momo_reference: string;
  status: string;
  submitted_at: string;
}

interface AppSettings {
  commission_rate: number;
  credit_limit: number;
  offer_timeout_seconds: number;
  search_radius_m: number;
  max_price_override: number;
}

export default function AdminApp() {
  const [session, setSession] = useState<any>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'overview' | 'create_order' | 'deliveries' | 'riders' | 'wallet' | 'settings'>('overview');

  // Login form state
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [authError, setAuthError] = useState('');
  const [authLoading, setAuthLoading] = useState(false);

  // Operational state
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [riders, setRiders] = useState<Rider[]>([]);
  const [topups, setTopups] = useState<TopupRequest[]>([]);
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Dispatcher Create Order Form State
  const [callerName, setCallerName] = useState('');
  const [callerPhone, setCallerPhone] = useState('');
  const [pickupText, setPickupText] = useState('');
  const [dropoffText, setDropoffText] = useState('');
  const [receiverName, setReceiverName] = useState('');
  const [receiverPhone, setReceiverPhone] = useState('');
  const [vehicle, setVehicle] = useState<'motorbike' | 'moto_king'>('motorbike');
  const [payer, setPayer] = useState<'sender' | 'receiver'>('sender');
  const [estimatedKm, setEstimatedKm] = useState('3.5');
  const [quotedFare, setQuotedFare] = useState('20.00');
  const [createOrderLoading, setCreateOrderLoading] = useState(false);
  const [orderSuccessMsg, setOrderSuccessMsg] = useState('');
  const [orderErrorMsg, setOrderErrorMsg] = useState('');

  // Rider Review Modal
  const [selectedRider, setSelectedRider] = useState<Rider | null>(null);
  const [reviewReason, setReviewReason] = useState('');

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      if (session) {
        fetchUserProfile(session.user.id);
      } else {
        setLoading(false);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      if (session) {
        fetchUserProfile(session.user.id);
      } else {
        setProfile(null);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  async function fetchUserProfile(userId: string) {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) throw error;
      setProfile(data);

      if (data && (data.role === 'admin' || data.role === 'dispatcher')) {
        loadDashboardData();
      }
    } catch (err: any) {
      console.error('Error fetching profile:', err.message);
    } finally {
      setLoading(false);
    }
  }

  async function loadDashboardData() {
    setRefreshing(true);
    try {
      const { data: delivData } = await supabase
        .from('deliveries')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      setDeliveries(delivData || []);

      const { data: riderData } = await supabase
        .from('riders')
        .select('*, profiles(id, full_name, phone, role)');
      setRiders(riderData || []);

      const { data: topupData } = await supabase
        .from('topup_requests')
        .select('*')
        .order('submitted_at', { ascending: false })
        .limit(20);
      setTopups(topupData || []);

      const { data: settingsData } = await supabase
        .from('settings')
        .select('*')
        .single();
      setSettings(settingsData || null);
    } catch (err: any) {
      console.error('Dashboard data load error:', err.message);
    } finally {
      setRefreshing(false);
    }
  }

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setAuthLoading(true);
    setAuthError('');

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;

      if (data.user) {
        const { data: prof, error: profErr } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', data.user.id)
          .single();

        if (profErr || !prof || (prof.role !== 'admin' && prof.role !== 'dispatcher')) {
          await supabase.auth.signOut();
          throw new Error('Access Restricted: This dashboard is strictly for authorized dispatchers.');
        }
      }
    } catch (err: any) {
      setAuthError(err.message || 'Login failed');
    } finally {
      setAuthLoading(false);
    }
  }

  async function handleSignOut() {
    await supabase.auth.signOut();
  }

  async function handleCreateDispatcherOrder(e: React.FormEvent) {
    e.preventDefault();
    if (!profile) return;
    setCreateOrderLoading(true);
    setOrderErrorMsg('');
    setOrderSuccessMsg('');

    try {
      const distance = parseFloat(estimatedKm) || 3.0;
      const fare = parseFloat(quotedFare) || 20.0;

      // Call authoritative backend stored procedure
      const { data, error } = await supabase.rpc('dispatcher_create_order', {
        p_caller_name: callerName || 'Phone Caller',
        p_caller_phone: callerPhone,
        p_pickup_text: pickupText,
        p_dropoff_text: dropoffText,
        p_vehicle: vehicle,
        p_distance_km: distance,
        p_fare: fare,
        p_receiver_name: receiverName,
        p_receiver_phone: receiverPhone,
        p_payer: payer,
      });

      if (error) throw error;
      if (!data || !data.ok) throw new Error(data?.error || 'Order creation failed');

      setOrderSuccessMsg(`Order #${data.delivery_id.slice(0, 8)} created! Handover code: ${data.code}`);
      setCallerName('');
      setCallerPhone('');
      setPickupText('');
      setDropoffText('');
      setReceiverName('');
      setReceiverPhone('');
      loadDashboardData();
    } catch (err: any) {
      setOrderErrorMsg(err.message || 'Failed to create order');
    } finally {
      setCreateOrderLoading(false);
    }
  }

  // Cancel order action
  async function handleCancelDelivery(deliveryId: string) {
    if (!profile) return;
    const reason = prompt('Enter cancellation reason (e.g. Caller cancelled, test order):', 'Cancelled by dispatcher');
    if (!reason) return;

    try {
      const { error } = await supabase.rpc('admin_cancel_delivery', {
        p_delivery_id: deliveryId,
        p_reason: reason,
      });

      if (error) throw error;
      loadDashboardData();
    } catch (err: any) {
      alert('Failed to cancel order: ' + err.message);
    }
  }

  async function updateRiderVerification(riderId: string, status: 'approved' | 'rejected' | 'suspended') {
    if (!profile) return;
    try {
      const { error } = await supabase
        .from('riders')
        .update({
          verification: status,
          rejection_reason: status !== 'approved' ? (reviewReason || 'Administrative update') : null,
          updated_at: new Date().toISOString(),
        })
        .eq('profile_id', riderId);

      if (error) throw error;

      await supabase.from('audit_log').insert({
        actor_id: profile.id,
        action: `rider_${status}`,
        target: riderId,
        reason: reviewReason || 'Staff review',
      });

      setSelectedRider(null);
      setReviewReason('');
      loadDashboardData();
    } catch (err: any) {
      alert('Error updating rider: ' + err.message);
    }
  }

  async function confirmTopup(topup: TopupRequest) {
    if (!profile) return;
    if (!confirm(`Confirm GH₵ ${topup.amount} MoMo deposit (Ref: ${topup.momo_reference})?`)) return;

    try {
      const { data: rider, error: rErr } = await supabase
        .from('riders')
        .select('wallet_balance')
        .eq('profile_id', topup.rider_id)
        .single();

      if (rErr) throw rErr;
      const newBalance = Number(rider.wallet_balance) + Number(topup.amount);

      const { error: txErr } = await supabase.from('wallet_transactions').insert({
        rider_id: topup.rider_id,
        type: 'topup',
        amount: topup.amount,
        balance_after: newBalance,
        idempotency_key: `topup:${topup.id}`,
        reference: topup.momo_reference,
        created_by: profile.id,
        reason: 'Confirmed MoMo deposit',
      });

      if (txErr) throw txErr;

      await supabase
        .from('riders')
        .update({ wallet_balance: newBalance, updated_at: new Date().toISOString() })
        .eq('profile_id', topup.rider_id);

      await supabase
        .from('topup_requests')
        .update({
          status: 'confirmed',
          reviewed_by: profile.id,
          reviewed_at: new Date().toISOString(),
        })
        .eq('id', topup.id);

      loadDashboardData();
    } catch (err: any) {
      alert('Error confirming top-up: ' + err.message);
    }
  }

  const filteredDeliveries = deliveries.filter(d => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return (
      d.id.toLowerCase().includes(q) ||
      (d.receiver_name && d.receiver_name.toLowerCase().includes(q)) ||
      (d.receiver_phone && d.receiver_phone.includes(q)) ||
      (d.pickup_text && d.pickup_text.toLowerCase().includes(q)) ||
      (d.dropoff_text && d.dropoff_text.toLowerCase().includes(q))
    );
  });

  if (loading) {
    return (
      <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', background: 'var(--color-warm-ivory)' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ display: 'inline-block', width: '32px', height: '32px', border: '3px solid var(--color-border)', borderTopColor: 'var(--color-clear-blue)', borderRadius: '50%' }} className="animate-spin" />
          <p style={{ marginTop: '16px', color: 'var(--color-secondary-text)', fontSize: '14px', fontWeight: 500 }}>Connecting to Tamale Ops Dispatch...</p>
        </div>
      </div>
    );
  }

  // -------------------------------------------------------------
  // Apple-Grade Responsive Login
  // -------------------------------------------------------------
  if (!session || !profile) {
    return (
      <div style={{
        display: 'flex',
        minHeight: '100vh',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
        backgroundColor: 'var(--color-warm-ivory)',
      }}>
        <div style={{
          width: '100%',
          maxWidth: '400px',
          backgroundColor: 'var(--color-card-bg)',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--shadow-card)',
          border: '1px solid var(--color-border-subtle)',
          padding: '36px 28px',
        }}>
          <div style={{ textAlign: 'center', marginBottom: '28px' }}>
            <div style={{
              display: 'inline-flex',
              padding: '14px',
              borderRadius: '16px',
              backgroundColor: 'var(--color-midnight-navy)',
              color: 'var(--color-white)',
              marginBottom: '14px',
              boxShadow: '0 8px 16px -4px rgba(16, 38, 75, 0.2)'
            }}>
              <Package size={28} color="#ffffff" />
            </div>
            <h1 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-midnight-navy)', letterSpacing: '-0.4px', marginBottom: '4px' }}>
              Tamale Delivery
            </h1>
            <p style={{ fontSize: '13px', color: 'var(--color-secondary-text)', fontWeight: 500 }}>
              Staff & Dispatch Operations
            </p>
          </div>

          {authError && (
            <div style={{
              padding: '12px 14px',
              borderRadius: 'var(--radius-sm)',
              backgroundColor: 'var(--color-error-bg)',
              border: '1px solid var(--color-error-border)',
              color: 'var(--color-error)',
              fontSize: '13px',
              marginBottom: '20px',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              <AlertTriangle size={16} />
              <span>{authError}</span>
            </div>
          )}

          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--color-secondary-text)', marginBottom: '6px' }}>
                Staff Email
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="staff@tamaledelivery.com"
                style={{
                  width: '100%',
                  padding: '12px 14px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)',
                  backgroundColor: '#ffffff',
                  fontSize: '14px',
                  color: 'var(--color-primary-text)',
                }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--color-secondary-text)', marginBottom: '6px' }}>
                Password
              </label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••••"
                style={{
                  width: '100%',
                  padding: '12px 14px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)',
                  backgroundColor: '#ffffff',
                  fontSize: '14px',
                  color: 'var(--color-primary-text)',
                }}
              />
            </div>

            <button
              type="submit"
              disabled={authLoading}
              style={{
                marginTop: '6px',
                padding: '14px',
                backgroundColor: 'var(--color-clear-blue)',
                color: 'var(--color-white)',
                borderRadius: 'var(--radius-sm)',
                fontSize: '14px',
                fontWeight: 700,
                opacity: authLoading ? 0.7 : 1,
              }}
            >
              {authLoading ? 'Signing In...' : 'Log In to Dispatch'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  // Active metrics
  const activeDeliveries = deliveries.filter(d => ['searching', 'accepted', 'arrived_pickup', 'picked_up', 'arrived_dropoff'].includes(d.status));
  const unassignedDeliveries = deliveries.filter(d => d.status === 'unassigned');
  const onlineRiders = riders.filter(r => r.is_online);
  const pendingRiders = riders.filter(r => r.verification === 'pending');
  const pendingTopups = topups.filter(t => t.status === 'pending');

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* 1. Header with Responsive Padding */}
      <header style={{
        position: 'sticky',
        top: 0,
        zIndex: 50,
        minHeight: '60px',
        backgroundColor: 'rgba(255, 255, 255, 0.88)',
        backdropFilter: 'blur(16px)',
        WebkitBackdropFilter: 'blur(16px)',
        borderBottom: '1px solid var(--color-border-subtle)',
        padding: '10px 16px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '10px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '32px',
            height: '32px',
            borderRadius: '10px',
            backgroundColor: 'var(--color-midnight-navy)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#fff',
          }}>
            <Package size={17} />
          </div>
          <div>
            <span style={{ fontSize: '15px', fontWeight: 800, color: 'var(--color-midnight-navy)', letterSpacing: '-0.3px' }}>
              Tamale Delivery
            </span>
            <span className="mobile-hide" style={{ marginLeft: '6px', fontSize: '11px', fontWeight: 600, color: 'var(--color-muted-text)', textTransform: 'uppercase' }}>
              Ops
            </span>
          </div>
        </div>

        {/* Live Network & User Badge */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '4px 10px',
            borderRadius: 'var(--radius-full)',
            backgroundColor: 'var(--color-success-bg)',
            border: '1px solid var(--color-success-border)',
            fontSize: '11px',
            fontWeight: 700,
            color: 'var(--color-success)',
          }}>
            <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: 'var(--color-success)' }} className="pulse-online" />
            <span className="mobile-hide">Tamale Mesh</span> Live
          </div>

          <button
            onClick={loadDashboardData}
            title="Synchronize Data"
            style={{
              padding: '6px 10px',
              borderRadius: 'var(--radius-sm)',
              backgroundColor: 'var(--color-warm-ivory)',
              color: 'var(--color-secondary-text)',
              fontSize: '12px',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <RefreshCw size={12} className={refreshing ? 'animate-spin' : ''} />
            <span className="mobile-hide">Sync</span>
          </button>

          <span style={{
            fontSize: '10px',
            fontWeight: 700,
            padding: '2px 8px',
            borderRadius: 'var(--radius-full)',
            backgroundColor: profile.role === 'admin' ? '#2463EB' : '#107551',
            color: '#ffffff',
            textTransform: 'uppercase',
          }}>
            {profile.role}
          </span>

          <button
            onClick={handleSignOut}
            title="Sign Out"
            style={{
              padding: '6px',
              color: 'var(--color-muted-text)',
            }}
          >
            <LogOut size={16} />
          </button>
        </div>
      </header>

      {/* 2. Responsive Segmented Pill Navigation Bar */}
      <div style={{
        padding: '14px 16px 0 16px',
        display: 'flex',
        flexDirection: 'column',
        gap: '12px',
        maxWidth: '1440px',
        margin: '0 auto',
        width: '100%',
      }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '12px',
        }}>
          <div className="nav-scroll-container mobile-full-width" style={{
            backgroundColor: '#eae8e1',
            padding: '4px',
            borderRadius: 'var(--radius-sm)',
          }}>
            {[
              { id: 'overview', label: 'Overview' },
              { id: 'create_order', label: 'Take Order', icon: Plus },
              { id: 'deliveries', label: 'Deliveries', badge: activeDeliveries.length },
              { id: 'riders', label: 'Fleet & KYC', badge: pendingRiders.length },
              { id: 'wallet', label: 'Top-ups', badge: pendingTopups.length },
              { id: 'settings', label: 'Settings' },
            ].map((tab) => {
              const isSelected = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  style={{
                    padding: '8px 16px',
                    borderRadius: '7px',
                    backgroundColor: isSelected ? '#ffffff' : 'transparent',
                    color: isSelected ? 'var(--color-midnight-navy)' : 'var(--color-secondary-text)',
                    fontSize: '13px',
                    fontWeight: isSelected ? 800 : 600,
                    boxShadow: isSelected ? '0 1px 3px rgba(0,0,0,0.06)' : 'none',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    flexShrink: 0,
                  }}
                >
                  {tab.icon && <tab.icon size={13} />}
                  <span>{tab.label}</span>
                  {tab.badge && tab.badge > 0 ? (
                    <span style={{
                      fontSize: '10px',
                      fontWeight: 700,
                      padding: '1px 6px',
                      borderRadius: 'var(--radius-full)',
                      backgroundColor: isSelected ? 'var(--color-clear-blue)' : '#94a3b8',
                      color: '#ffffff',
                    }}>
                      {tab.badge}
                    </span>
                  ) : null}
                </button>
              );
            })}
          </div>

          {/* Quick Search */}
          <div className="mobile-full-width" style={{ position: 'relative', minWidth: '220px' }}>
            <Search size={14} style={{ position: 'absolute', left: '12px', top: '11px', color: 'var(--color-muted-text)' }} />
            <input
              type="text"
              placeholder="Filter ref, phone, receiver..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: '100%',
                padding: '8px 12px 8px 34px',
                borderRadius: 'var(--radius-full)',
                border: '1px solid var(--color-border)',
                backgroundColor: '#ffffff',
                fontSize: '12px',
              }}
            />
          </div>
        </div>
      </div>

      {/* 3. Main Body */}
      <main style={{ flex: 1, padding: '20px 16px', maxWidth: '1440px', width: '100%', margin: '0 auto' }}>
        
        {/* ======================================================== */}
        {/* TAB 1: OVERVIEW */}
        {/* ======================================================== */}
        {activeTab === 'overview' && (
          <div>
            {/* Ultra-Simple Big 2-Action Hero Cards (Even a 2-year old knows what to tap!) */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
              gap: '14px',
              marginBottom: '20px',
            }}>
              <div
                onClick={() => setActiveTab('create_order')}
                style={{
                  backgroundColor: 'var(--color-clear-blue)',
                  color: '#ffffff',
                  borderRadius: 'var(--radius-lg)',
                  padding: '24px',
                  boxShadow: 'var(--shadow-card)',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  transition: 'transform 0.2s, box-shadow 0.2s',
                }}
              >
                <div>
                  <div style={{ display: 'inline-flex', padding: '10px', borderRadius: '12px', backgroundColor: 'rgba(255,255,255,0.2)', marginBottom: '12px' }}>
                    <PhoneCall size={22} color="#ffffff" />
                  </div>
                  <h3 style={{ fontSize: '18px', fontWeight: 800 }}>+ Book Caller Delivery</h3>
                  <p style={{ fontSize: '12px', opacity: 0.9, marginTop: '2px' }}>Take a phone or WhatsApp order in 30 seconds</p>
                </div>
                <ArrowRight size={24} />
              </div>

              <div
                onClick={() => setActiveTab('riders')}
                style={{
                  backgroundColor: 'var(--color-midnight-navy)',
                  color: '#ffffff',
                  borderRadius: 'var(--radius-lg)',
                  padding: '24px',
                  boxShadow: 'var(--shadow-card)',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  transition: 'transform 0.2s, box-shadow 0.2s',
                }}
              >
                <div>
                  <div style={{ display: 'inline-flex', padding: '10px', borderRadius: '12px', backgroundColor: 'rgba(255,255,255,0.15)', marginBottom: '12px' }}>
                    <Bike size={22} color="#ffffff" />
                  </div>
                  <h3 style={{ fontSize: '18px', fontWeight: 800 }}>Manage Rider Fleet</h3>
                  <p style={{ fontSize: '12px', opacity: 0.9, marginTop: '2px' }}>{onlineRiders.length} couriers online in Tamale right now</p>
                </div>
                <ArrowRight size={24} />
              </div>
            </div>

            {/* Responsive KPI Metrics */}
            <div className="kpi-grid">
              <div style={{
                backgroundColor: 'var(--color-card-bg)',
                borderRadius: 'var(--radius-md)',
                padding: '18px 20px',
                border: '1px solid var(--color-border-subtle)',
                boxShadow: 'var(--shadow-card)',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.4px', color: 'var(--color-secondary-text)' }}>
                    Active Deliveries
                  </span>
                  <Package size={16} color="var(--color-clear-blue)" />
                </div>
                <div style={{ fontSize: '26px', fontWeight: 800, color: 'var(--color-midnight-navy)' }}>
                  {activeDeliveries.length}
                </div>
                <div style={{ fontSize: '12px', color: 'var(--color-muted-text)', marginTop: '2px' }}>
                  In-transit across Tamale
                </div>
              </div>

              <div style={{
                backgroundColor: 'var(--color-card-bg)',
                borderRadius: 'var(--radius-md)',
                padding: '18px 20px',
                border: '1px solid var(--color-border-subtle)',
                boxShadow: 'var(--shadow-card)',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.4px', color: 'var(--color-secondary-text)' }}>
                    Unassigned Alerts
                  </span>
                  <AlertTriangle size={16} color={unassignedDeliveries.length > 0 ? 'var(--color-error)' : 'var(--color-muted-text)'} />
                </div>
                <div style={{ fontSize: '26px', fontWeight: 800, color: unassignedDeliveries.length > 0 ? 'var(--color-error)' : 'var(--color-midnight-navy)' }}>
                  {unassignedDeliveries.length}
                </div>
                <div style={{ fontSize: '12px', color: 'var(--color-muted-text)', marginTop: '2px' }}>
                  Orders needing attention
                </div>
              </div>

              <div style={{
                backgroundColor: 'var(--color-card-bg)',
                borderRadius: 'var(--radius-md)',
                padding: '18px 20px',
                border: '1px solid var(--color-border-subtle)',
                boxShadow: 'var(--shadow-card)',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.4px', color: 'var(--color-secondary-text)' }}>
                    Online Riders
                  </span>
                  <Bike size={16} color="var(--color-success)" />
                </div>
                <div style={{ fontSize: '26px', fontWeight: 800, color: 'var(--color-midnight-navy)' }}>
                  {onlineRiders.length} <span style={{ fontSize: '13px', fontWeight: 500, color: 'var(--color-muted-text)' }}>/ {riders.length}</span>
                </div>
                <div style={{ fontSize: '12px', color: 'var(--color-muted-text)', marginTop: '2px' }}>
                  Ready to accept offers
                </div>
              </div>

              <div style={{
                backgroundColor: 'var(--color-card-bg)',
                borderRadius: 'var(--radius-md)',
                padding: '18px 20px',
                border: '1px solid var(--color-border-subtle)',
                boxShadow: 'var(--shadow-card)',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.4px', color: 'var(--color-secondary-text)' }}>
                    Pending Top-ups
                  </span>
                  <Wallet size={16} color="var(--color-warning)" />
                </div>
                <div style={{ fontSize: '26px', fontWeight: 800, color: 'var(--color-midnight-navy)' }}>
                  {pendingTopups.length}
                </div>
                <div style={{ fontSize: '12px', color: 'var(--color-muted-text)', marginTop: '2px' }}>
                  Awaiting MoMo review
                </div>
              </div>
            </div>

            {/* In-Flight Orders Card */}
            <div style={{
              backgroundColor: 'var(--color-card-bg)',
              borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--color-border-subtle)',
              boxShadow: 'var(--shadow-card)',
              overflow: 'hidden',
            }}>
              <div style={{
                padding: '16px 20px',
                borderBottom: '1px solid var(--color-border-subtle)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}>
                <div>
                  <h3 style={{ fontSize: '15px', fontWeight: 800, color: 'var(--color-midnight-navy)' }}>
                    In-Flight Delivery Stream
                  </h3>
                  <p style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>
                    Active orders being fulfilled right now
                  </p>
                </div>
              </div>

              {activeDeliveries.length === 0 ? (
                <div style={{ padding: '40px 20px', textAlign: 'center' }}>
                  <div style={{
                    width: '40px',
                    height: '40px',
                    borderRadius: '50%',
                    backgroundColor: 'var(--color-warm-ivory)',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'var(--color-secondary-text)',
                    marginBottom: '10px',
                  }}>
                    <Package size={20} />
                  </div>
                  <p style={{ fontSize: '14px', fontWeight: 700, color: 'var(--color-primary-text)' }}>No active deliveries</p>
                  <p style={{ fontSize: '12px', color: 'var(--color-secondary-text)', marginTop: '2px' }}>
                    Tap "+ Book Caller Delivery" above to dispatch your first test order!
                  </p>
                </div>
              ) : (
                <div className="table-responsive-wrapper">
                  <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
                    <thead>
                      <tr style={{ borderBottom: '1px solid var(--color-border-subtle)', color: 'var(--color-secondary-text)' }}>
                        <th style={{ padding: '12px 20px', fontWeight: 600 }}>Reference</th>
                        <th style={{ padding: '12px 20px', fontWeight: 600 }}>Status</th>
                        <th style={{ padding: '12px 20px', fontWeight: 600 }}>Pickup → Dropoff</th>
                        <th style={{ padding: '12px 20px', fontWeight: 600 }}>Receiver</th>
                        <th style={{ padding: '12px 20px', fontWeight: 600 }}>Fare</th>
                        <th style={{ padding: '12px 20px', fontWeight: 600 }}>Payer</th>
                        <th style={{ padding: '12px 20px', fontWeight: 600 }}>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {activeDeliveries.map((d) => (
                        <tr key={d.id} style={{ borderBottom: '1px solid var(--color-border-subtle)' }}>
                          <td style={{ padding: '12px 20px', fontWeight: 700, fontFamily: 'var(--font-mono)', fontSize: '12px' }}>
                            #{d.id.slice(0, 8)}
                          </td>
                          <td style={{ padding: '12px 20px' }}>
                            <span style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '4px',
                              padding: '2px 8px',
                              borderRadius: 'var(--radius-full)',
                              fontSize: '11px',
                              fontWeight: 700,
                              backgroundColor: d.status === 'searching' ? 'var(--color-warning-bg)' : 'var(--color-success-bg)',
                              color: d.status === 'searching' ? 'var(--color-warning)' : 'var(--color-success)',
                            }}>
                              <span style={{
                                width: '5px',
                                height: '5px',
                                borderRadius: '50%',
                                backgroundColor: d.status === 'searching' ? 'var(--color-warning)' : 'var(--color-success)',
                              }} />
                              {d.status}
                            </span>
                          </td>
                          <td style={{ padding: '12px 20px', maxWidth: '280px' }}>
                            <div style={{ fontWeight: 600 }}>{d.pickup_text || 'Pinned Point'}</div>
                            <div style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>→ {d.dropoff_text || 'Pinned Point'} ({d.distance_km} km)</div>
                          </td>
                          <td style={{ padding: '12px 20px' }}>
                            <div style={{ fontWeight: 600 }}>{d.receiver_name}</div>
                            <div style={{ fontSize: '12px', color: 'var(--color-secondary-text)', fontFamily: 'var(--font-mono)' }}>{d.receiver_phone}</div>
                          </td>
                          <td style={{ padding: '12px 20px', fontWeight: 800 }} className="tabular-nums">
                            GH₵ {Number(d.fare).toFixed(2)}
                          </td>
                          <td style={{ padding: '12px 20px', textTransform: 'capitalize' }}>
                            {d.payer}
                          </td>
                          <td style={{ padding: '12px 20px' }}>
                            <button
                              onClick={() => handleCancelDelivery(d.id)}
                              style={{
                                padding: '4px 10px',
                                borderRadius: 'var(--radius-sm)',
                                backgroundColor: 'var(--color-error-bg)',
                                color: 'var(--color-error)',
                                border: '1px solid var(--color-error-border)',
                                fontSize: '11px',
                                fontWeight: 700,
                              }}
                            >
                              Cancel
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ======================================================== */}
        {/* TAB 2: CREATE ORDER (TOUCH-FRIENDLY & RESPONSIVE) */}
        {/* ======================================================== */}
        {activeTab === 'create_order' && (
          <div style={{ maxWidth: '640px', margin: '0 auto' }}>
            <div style={{ textAlign: 'center', marginBottom: '24px' }}>
              <h2 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-midnight-navy)', letterSpacing: '-0.3px' }}>
                Book Delivery for Caller
              </h2>
              <p style={{ fontSize: '13px', color: 'var(--color-secondary-text)', marginTop: '2px' }}>
                For customers who call or WhatsApp Tamale Dispatch directly.
              </p>
            </div>

            {orderSuccessMsg && (
              <div style={{
                padding: '14px 16px',
                borderRadius: 'var(--radius-md)',
                backgroundColor: 'var(--color-success-bg)',
                border: '1px solid var(--color-success-border)',
                color: 'var(--color-success)',
                marginBottom: '16px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                fontSize: '13px',
                fontWeight: 700,
              }}>
                <CheckCircle2 size={18} />
                <span>{orderSuccessMsg}</span>
              </div>
            )}

            {orderErrorMsg && (
              <div style={{
                padding: '14px 16px',
                borderRadius: 'var(--radius-md)',
                backgroundColor: 'var(--color-error-bg)',
                border: '1px solid var(--color-error-border)',
                color: 'var(--color-error)',
                marginBottom: '16px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                fontSize: '13px',
              }}>
                <AlertTriangle size={18} />
                <span>{orderErrorMsg}</span>
              </div>
            )}

            <form onSubmit={handleCreateDispatcherOrder} style={{
              backgroundColor: 'var(--color-card-bg)',
              borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--color-border-subtle)',
              boxShadow: 'var(--shadow-card)',
              padding: '24px',
              display: 'flex',
              flexDirection: 'column',
              gap: '20px',
            }}>
              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--color-secondary-text)', marginBottom: '8px' }}>
                  1. Caller Details (Sender)
                </label>
                <div className="form-2col">
                  <input
                    type="text"
                    required
                    placeholder="Caller Full Name"
                    value={callerName}
                    onChange={(e) => setCallerName(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '14px',
                    }}
                  />
                  <input
                    type="text"
                    required
                    placeholder="Caller Phone (e.g. 0241234567)"
                    value={callerPhone}
                    onChange={(e) => setCallerPhone(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '14px',
                    }}
                  />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--color-secondary-text)', marginBottom: '8px' }}>
                  2. Route / Landmarks
                </label>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  <div style={{ position: 'relative' }}>
                    <MapPin size={16} style={{ position: 'absolute', left: '12px', top: '13px', color: 'var(--color-clear-blue)' }} />
                    <input
                      type="text"
                      required
                      placeholder="Pickup address / landmark (e.g. Tamale Central Market)"
                      value={pickupText}
                      onChange={(e) => setPickupText(e.target.value)}
                      style={{
                        width: '100%',
                        padding: '12px 14px 12px 36px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        fontSize: '14px',
                      }}
                    />
                  </div>
                  <div style={{ position: 'relative' }}>
                    <MapPin size={16} style={{ position: 'absolute', left: '12px', top: '13px', color: 'var(--color-success)' }} />
                    <input
                      type="text"
                      required
                      placeholder="Drop-off destination (e.g. Kukuo Hospital Road)"
                      value={dropoffText}
                      onChange={(e) => setDropoffText(e.target.value)}
                      style={{
                        width: '100%',
                        padding: '12px 14px 12px 36px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        fontSize: '14px',
                      }}
                    />
                  </div>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--color-secondary-text)', marginBottom: '8px' }}>
                  3. Vehicle & Fare
                </label>
                <div className="form-3col">
                  <select
                    value={vehicle}
                    onChange={(e) => setVehicle(e.target.value as any)}
                    style={{
                      padding: '12px 14px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '14px',
                      backgroundColor: '#fff',
                      fontWeight: 600,
                    }}
                  >
                    <option value="motorbike">Motorbike (Small)</option>
                    <option value="moto_king">Moto King (Heavy)</option>
                  </select>

                  <div style={{ position: 'relative' }}>
                    <input
                      type="number"
                      step="0.1"
                      placeholder="KM"
                      value={estimatedKm}
                      onChange={(e) => {
                        setEstimatedKm(e.target.value);
                        const dist = parseFloat(e.target.value) || 0;
                        setQuotedFare(Math.max(15, 10 + dist * 3).toFixed(2));
                      }}
                      style={{
                        width: '100%',
                        padding: '12px 14px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        fontSize: '14px',
                      }}
                    />
                    <span style={{ position: 'absolute', right: '12px', top: '14px', fontSize: '11px', color: 'var(--color-muted-text)', fontWeight: 700 }}>KM</span>
                  </div>

                  <div style={{ position: 'relative' }}>
                    <input
                      type="number"
                      step="0.50"
                      placeholder="Fare"
                      value={quotedFare}
                      onChange={(e) => setQuotedFare(e.target.value)}
                      style={{
                        width: '100%',
                        padding: '12px 14px',
                        borderRadius: 'var(--radius-sm)',
                        border: '1px solid var(--color-border)',
                        fontSize: '15px',
                        fontWeight: 800,
                        color: 'var(--color-midnight-navy)',
                      }}
                    />
                    <span style={{ position: 'absolute', right: '12px', top: '14px', fontSize: '11px', color: 'var(--color-muted-text)', fontWeight: 800 }}>GH₵</span>
                  </div>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', color: 'var(--color-secondary-text)', marginBottom: '8px' }}>
                  4. Receiver & Payment
                </label>
                <div className="form-2col" style={{ marginBottom: '12px' }}>
                  <input
                    type="text"
                    required
                    placeholder="Receiver Name"
                    value={receiverName}
                    onChange={(e) => setReceiverName(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '14px',
                    }}
                  />
                  <input
                    type="text"
                    required
                    placeholder="Receiver Phone Number"
                    value={receiverPhone}
                    onChange={(e) => setReceiverPhone(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--color-border)',
                      fontSize: '14px',
                    }}
                  />
                </div>

                <div style={{
                  padding: '12px',
                  borderRadius: 'var(--radius-sm)',
                  backgroundColor: 'var(--color-warm-ivory)',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', fontWeight: 600, cursor: 'pointer' }}>
                    <input
                      type="radio"
                      name="payer"
                      value="sender"
                      checked={payer === 'sender'}
                      onChange={() => setPayer('sender')}
                    />
                    <span>Caller pays cash at pickup</span>
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', fontWeight: 600, cursor: 'pointer' }}>
                    <input
                      type="radio"
                      name="payer"
                      value="receiver"
                      checked={payer === 'receiver'}
                      onChange={() => setPayer('receiver')}
                    />
                    <span>Receiver pays cash on delivery</span>
                  </label>
                </div>
              </div>

              <button
                type="submit"
                disabled={createOrderLoading}
                style={{
                  padding: '15px',
                  backgroundColor: 'var(--color-clear-blue)',
                  color: '#ffffff',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '15px',
                  fontWeight: 800,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                  marginTop: '4px',
                }}
              >
                {createOrderLoading ? (
                  <>
                    <RefreshCw size={16} className="animate-spin" />
                    <span>Booking Delivery...</span>
                  </>
                ) : (
                  <>
                    <span>Confirm & Dispatch Order</span>
                    <ArrowRight size={16} />
                  </>
                )}
              </button>
            </form>
          </div>
        )}

        {/* ======================================================== */}
        {/* TAB 3: DELIVERIES (RESPONSIVE TABLE) */}
        {/* ======================================================== */}
        {activeTab === 'deliveries' && (
          <div style={{
            backgroundColor: 'var(--color-card-bg)',
            borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border-subtle)',
            boxShadow: 'var(--shadow-card)',
            overflow: 'hidden',
          }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--color-border-subtle)' }}>
              <h3 style={{ fontSize: '15px', fontWeight: 800, color: 'var(--color-midnight-navy)' }}>
                All Deliveries Record
              </h3>
              <p style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>
                Authoritative history of all customer and dispatcher bookings
              </p>
            </div>

            <div className="table-responsive-wrapper">
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--color-border-subtle)', color: 'var(--color-secondary-text)' }}>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Reference</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Status</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Vehicle</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Pickup → Dropoff</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Receiver</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Fare</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Payer</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredDeliveries.map((d) => (
                    <tr key={d.id} style={{ borderBottom: '1px solid var(--color-border-subtle)' }}>
                      <td style={{ padding: '12px 20px', fontWeight: 700, fontFamily: 'var(--font-mono)', fontSize: '12px' }}>
                        #{d.id.slice(0, 8)}
                      </td>
                      <td style={{ padding: '12px 20px' }}>
                        <span style={{
                          padding: '2px 8px',
                          borderRadius: 'var(--radius-full)',
                          fontSize: '11px',
                          fontWeight: 700,
                          backgroundColor: d.status === 'delivered' ? 'var(--color-success-bg)' : d.status === 'cancelled' ? 'var(--color-error-bg)' : 'var(--color-warning-bg)',
                          color: d.status === 'delivered' ? 'var(--color-success)' : d.status === 'cancelled' ? 'var(--color-error)' : 'var(--color-warning)',
                        }}>
                          {d.status}
                        </span>
                      </td>
                      <td style={{ padding: '12px 20px', textTransform: 'capitalize' }}>
                        {d.vehicle.replace('_', ' ')}
                      </td>
                      <td style={{ padding: '12px 20px', maxWidth: '280px' }}>
                        <div style={{ fontWeight: 600 }}>{d.pickup_text || 'Pinned'}</div>
                        <div style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>→ {d.dropoff_text || 'Pinned'}</div>
                      </td>
                      <td style={{ padding: '12px 20px' }}>
                        <div style={{ fontWeight: 600 }}>{d.receiver_name}</div>
                        <div style={{ fontSize: '12px', color: 'var(--color-secondary-text)', fontFamily: 'var(--font-mono)' }}>{d.receiver_phone}</div>
                      </td>
                      <td style={{ padding: '12px 20px', fontWeight: 800 }} className="tabular-nums">
                        GH₵ {Number(d.fare).toFixed(2)}
                      </td>
                      <td style={{ padding: '12px 20px', textTransform: 'capitalize' }}>
                        {d.payer}
                      </td>
                      <td style={{ padding: '12px 20px' }}>
                        {['searching', 'unassigned', 'accepted'].includes(d.status) && (
                          <button
                            onClick={() => handleCancelDelivery(d.id)}
                            style={{
                              padding: '4px 10px',
                              borderRadius: 'var(--radius-sm)',
                              backgroundColor: 'var(--color-error-bg)',
                              color: 'var(--color-error)',
                              border: '1px solid var(--color-error-border)',
                              fontSize: '11px',
                              fontWeight: 700,
                            }}
                          >
                            Cancel
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ======================================================== */}
        {/* TAB 4: RIDERS & FLEET (RESPONSIVE TABLE) */}
        {/* ======================================================== */}
        {activeTab === 'riders' && (
          <div style={{
            backgroundColor: 'var(--color-card-bg)',
            borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border-subtle)',
            boxShadow: 'var(--shadow-card)',
            overflow: 'hidden',
          }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--color-border-subtle)' }}>
              <h3 style={{ fontSize: '15px', fontWeight: 800, color: 'var(--color-midnight-navy)' }}>
                Courier Fleet & KYC Verification
              </h3>
              <p style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>
                Inspect registered riders, credentials, and wallet balances
              </p>
            </div>

            <div className="table-responsive-wrapper">
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--color-border-subtle)', color: 'var(--color-secondary-text)' }}>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Rider</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Vehicle</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>KYC Status</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Status</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Wallet</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Trips</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {riders.length === 0 ? (
                    <tr>
                      <td colSpan={7} style={{ padding: '36px', textAlign: 'center', color: 'var(--color-secondary-text)' }}>
                        No riders registered yet. Couriers will show up here once they complete the mobile application.
                      </td>
                    </tr>
                  ) : (
                    riders.map((r) => (
                      <tr key={r.profile_id} style={{ borderBottom: '1px solid var(--color-border-subtle)' }}>
                        <td style={{ padding: '12px 20px', fontWeight: 700 }}>
                          {r.profiles?.full_name || 'Rider Candidate'}
                        </td>
                        <td style={{ padding: '12px 20px' }}>
                          <span style={{ textTransform: 'capitalize', fontWeight: 600 }}>{r.vehicle?.replace('_', ' ') || 'Motorbike'}</span>
                        </td>
                        <td style={{ padding: '12px 20px' }}>
                          <span style={{
                            padding: '2px 8px',
                            borderRadius: 'var(--radius-full)',
                            fontSize: '11px',
                            fontWeight: 700,
                            backgroundColor: r.verification === 'approved' ? 'var(--color-success-bg)' : 'var(--color-warning-bg)',
                            color: r.verification === 'approved' ? 'var(--color-success)' : 'var(--color-warning)',
                          }}>
                            {r.verification}
                          </span>
                        </td>
                        <td style={{ padding: '12px 20px' }}>
                          <span style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '5px',
                            fontSize: '12px',
                            fontWeight: 600,
                            color: r.is_online ? 'var(--color-success)' : 'var(--color-muted-text)'
                          }}>
                            <span style={{
                              width: '6px',
                              height: '6px',
                              borderRadius: '50%',
                              backgroundColor: r.is_online ? 'var(--color-success)' : 'var(--color-border)',
                            }} />
                            {r.is_online ? 'Online' : 'Offline'}
                          </span>
                        </td>
                        <td style={{ padding: '12px 20px', fontWeight: 800, color: r.wallet_balance < 0 ? 'var(--color-error)' : 'inherit' }} className="tabular-nums">
                          GH₵ {Number(r.wallet_balance).toFixed(2)}
                        </td>
                        <td style={{ padding: '12px 20px', fontWeight: 600 }}>{r.completed_trips}</td>
                        <td style={{ padding: '12px 20px' }}>
                          <button
                            onClick={() => setSelectedRider(r)}
                            style={{
                              padding: '5px 12px',
                              borderRadius: 'var(--radius-sm)',
                              backgroundColor: 'var(--color-warm-ivory)',
                              color: 'var(--color-primary-text)',
                              fontSize: '12px',
                              fontWeight: 700,
                              border: '1px solid var(--color-border)',
                            }}
                          >
                            Review
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ======================================================== */}
        {/* TAB 5: WALLET LEDGER & TOP-UPS */}
        {/* ======================================================== */}
        {activeTab === 'wallet' && (
          <div style={{
            backgroundColor: 'var(--color-card-bg)',
            borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border-subtle)',
            boxShadow: 'var(--shadow-card)',
            overflow: 'hidden',
          }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--color-border-subtle)' }}>
              <h3 style={{ fontSize: '15px', fontWeight: 800, color: 'var(--color-midnight-navy)' }}>
                MoMo Deposit Verification
              </h3>
              <p style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>
                Confirm rider wallet top-ups before approving commission credit
              </p>
            </div>

            <div className="table-responsive-wrapper">
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--color-border-subtle)', color: 'var(--color-secondary-text)' }}>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Date</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Rider Ref</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Amount</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>MoMo Reference</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Status</th>
                    <th style={{ padding: '12px 20px', fontWeight: 600 }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {topups.length === 0 ? (
                    <tr>
                      <td colSpan={6} style={{ padding: '36px', textAlign: 'center', color: 'var(--color-secondary-text)' }}>
                        No pending wallet top-up requests.
                      </td>
                    </tr>
                  ) : (
                    topups.map((t) => (
                      <tr key={t.id} style={{ borderBottom: '1px solid var(--color-border-subtle)' }}>
                        <td style={{ padding: '12px 20px', fontSize: '12px', color: 'var(--color-secondary-text)' }}>
                          {new Date(t.submitted_at).toLocaleDateString()}
                        </td>
                        <td style={{ padding: '12px 20px', fontWeight: 700, fontFamily: 'var(--font-mono)' }}>
                          #{t.rider_id.slice(0, 8)}
                        </td>
                        <td style={{ padding: '12px 20px', fontWeight: 800, color: 'var(--color-success)' }} className="tabular-nums">
                          +GH₵ {Number(t.amount).toFixed(2)}
                        </td>
                        <td style={{ padding: '12px 20px', fontFamily: 'var(--font-mono)', fontSize: '12px' }}>
                          {t.momo_reference}
                        </td>
                        <td style={{ padding: '12px 20px' }}>
                          <span style={{
                            padding: '2px 8px',
                            borderRadius: 'var(--radius-full)',
                            fontSize: '11px',
                            fontWeight: 700,
                            backgroundColor: t.status === 'confirmed' ? 'var(--color-success-bg)' : 'var(--color-warning-bg)',
                            color: t.status === 'confirmed' ? 'var(--color-success)' : 'var(--color-warning)',
                          }}>
                            {t.status}
                          </span>
                        </td>
                        <td style={{ padding: '12px 20px' }}>
                          {t.status === 'pending' && (
                            <button
                              onClick={() => confirmTopup(t)}
                              style={{
                                padding: '6px 12px',
                                backgroundColor: 'var(--color-clear-blue)',
                                color: '#ffffff',
                                borderRadius: 'var(--radius-sm)',
                                fontSize: '12px',
                                fontWeight: 700,
                              }}
                            >
                              Confirm Deposit
                            </button>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ======================================================== */}
        {/* TAB 6: SETTINGS (SUPER ADMIN) */}
        {/* ======================================================== */}
        {activeTab === 'settings' && (
          <div style={{ maxWidth: '540px', margin: '0 auto' }}>
            <div style={{ textAlign: 'center', marginBottom: '24px' }}>
              <h2 style={{ fontSize: '22px', fontWeight: 800, color: 'var(--color-midnight-navy)', letterSpacing: '-0.3px' }}>
                Platform Settings
              </h2>
              <p style={{ fontSize: '13px', color: 'var(--color-secondary-text)', marginTop: '2px' }}>
                Governing rules for commission and credit limits.
              </p>
            </div>

            {settings && (
              <div style={{
                backgroundColor: 'var(--color-card-bg)',
                borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--color-border-subtle)',
                boxShadow: 'var(--shadow-card)',
                padding: '24px',
                display: 'flex',
                flexDirection: 'column',
                gap: '16px',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 700 }}>Platform Commission</div>
                    <div style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>Deducted automatically per completed trip</div>
                  </div>
                  <div style={{ fontSize: '18px', fontWeight: 800, color: 'var(--color-clear-blue)' }}>
                    {(Number(settings.commission_rate) * 100).toFixed(0)}%
                  </div>
                </div>

                <div style={{ height: '1px', backgroundColor: 'var(--color-border-subtle)' }} />

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 700 }}>Wallet Credit Limit</div>
                    <div style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>Negative balance cutoff</div>
                  </div>
                  <div style={{ fontSize: '18px', fontWeight: 800, color: 'var(--color-error)' }} className="tabular-nums">
                    -GH₵ {Number(settings.credit_limit).toFixed(2)}
                  </div>
                </div>

                <div style={{ height: '1px', backgroundColor: 'var(--color-border-subtle)' }} />

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 700 }}>Job Offer Window</div>
                    <div style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>Time before auto-redispatch</div>
                  </div>
                  <div style={{ fontSize: '18px', fontWeight: 800 }}>
                    {settings.offer_timeout_seconds}s
                  </div>
                </div>

                <div style={{ height: '1px', backgroundColor: 'var(--color-border-subtle)' }} />

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 700 }}>Courier Match Radius</div>
                    <div style={{ fontSize: '12px', color: 'var(--color-secondary-text)' }}>Search distance in Tamale</div>
                  </div>
                  <div style={{ fontSize: '18px', fontWeight: 800 }}>
                    {(settings.search_radius_m / 1000).toFixed(1)} km
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </main>

      {/* Responsive Rider KYC Review Modal */}
      {selectedRider && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(15, 23, 42, 0.45)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100,
          padding: '16px',
        }}>
          <div style={{
            backgroundColor: '#ffffff',
            borderRadius: 'var(--radius-lg)',
            width: '100%',
            maxWidth: '460px',
            boxShadow: 'var(--shadow-float)',
            border: '1px solid var(--color-border-subtle)',
            padding: '24px',
            maxHeight: '90vh',
            overflowY: 'auto',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div>
                <h3 style={{ fontSize: '17px', fontWeight: 800, color: 'var(--color-midnight-navy)' }}>
                  {selectedRider.profiles?.full_name || 'Rider Candidate'}
                </h3>
                <p style={{ fontSize: '12px', color: 'var(--color-secondary-text)', fontFamily: 'var(--font-mono)' }}>
                  ID: #{selectedRider.profile_id.slice(0, 8)}
                </p>
              </div>
              <button onClick={() => setSelectedRider(null)} style={{ color: 'var(--color-muted-text)', padding: '4px' }}>
                <X size={20} />
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginBottom: '20px', fontSize: '13px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 12px', backgroundColor: 'var(--color-warm-ivory)', borderRadius: 'var(--radius-sm)' }}>
                <span style={{ color: 'var(--color-secondary-text)', fontWeight: 600 }}>Vehicle:</span>
                <span style={{ fontWeight: 700, textTransform: 'capitalize' }}>{selectedRider.vehicle || 'Motorbike'} ({selectedRider.plate_number || 'N/A'})</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 12px', backgroundColor: 'var(--color-warm-ivory)', borderRadius: 'var(--radius-sm)' }}>
                <span style={{ color: 'var(--color-secondary-text)', fontWeight: 600 }}>Phone:</span>
                <span style={{ fontWeight: 700, fontFamily: 'var(--font-mono)' }}>{selectedRider.profiles?.phone || 'Not Provided'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 12px', backgroundColor: 'var(--color-warm-ivory)', borderRadius: 'var(--radius-sm)' }}>
                <span style={{ color: 'var(--color-secondary-text)', fontWeight: 600 }}>KYC Status:</span>
                <span style={{ fontWeight: 700, textTransform: 'uppercase', color: selectedRider.verification === 'approved' ? 'var(--color-success)' : 'var(--color-warning)' }}>
                  {selectedRider.verification}
                </span>
              </div>
            </div>

            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: 'var(--color-secondary-text)', marginBottom: '6px' }}>
                Review Note / Reason
              </label>
              <input
                type="text"
                placeholder="e.g. Ghana Card and license verified"
                value={reviewReason}
                onChange={(e) => setReviewReason(e.target.value)}
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)',
                  fontSize: '13px',
                }}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
              <button
                onClick={() => updateRiderVerification(selectedRider.profile_id, 'approved')}
                style={{
                  padding: '12px',
                  backgroundColor: 'var(--color-success)',
                  color: '#ffffff',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '13px',
                  fontWeight: 700,
                }}
              >
                Approve Rider
              </button>
              <button
                onClick={() => updateRiderVerification(selectedRider.profile_id, 'suspended')}
                style={{
                  padding: '12px',
                  backgroundColor: 'var(--color-error)',
                  color: '#ffffff',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '13px',
                  fontWeight: 700,
                }}
              >
                Suspend
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
