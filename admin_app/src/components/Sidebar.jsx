import React from 'react';
import { LayoutDashboard, Users, ShieldAlert, LogOut, ShieldCheck, Scale, DollarSign, Settings } from 'lucide-react';
import { auth } from '../firebase';

export default function Sidebar({ activeTab, setActiveTab }) {
  
  const handleLogout = () => {
    auth.signOut();
  };

  return (
    <div className="sidebar">
      <div className="brand-logo">
        <ShieldCheck size={28} color="#60a5fa" />
        WC Admin
      </div>
      <div className="nav-links">
        <div className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`} onClick={() => setActiveTab('dashboard')}>
          <LayoutDashboard size={20} /> Dashboard
        </div>
        <div className={`nav-item ${activeTab === 'verification' ? 'active' : ''}`} onClick={() => setActiveTab('verification')}>
          <Users size={20} /> Verifications
        </div>
        <div className={`nav-item ${activeTab === 'disputes' ? 'active' : ''}`} onClick={() => setActiveTab('disputes')}>
          <Scale size={20} /> Dispute Resolution
        </div>
        <div className={`nav-item ${activeTab === 'billing' ? 'active' : ''}`} onClick={() => setActiveTab('billing')}>
          <DollarSign size={20} /> Billing & Payments
        </div>
        <div className={`nav-item ${activeTab === 'users' ? 'active' : ''}`} onClick={() => setActiveTab('users')}>
          <Users size={20} /> User Management
        </div>
        <div className={`nav-item ${activeTab === 'moderation' ? 'active' : ''}`} onClick={() => setActiveTab('moderation')}>
          <ShieldAlert size={20} /> Moderation
        </div>
      </div>
      <div style={{ marginTop: 'auto' }}>
        <div className={`nav-item ${activeTab === 'profile' ? 'active' : ''}`} onClick={() => setActiveTab('profile')}>
          <Settings size={20} /> Profile Settings
        </div>
        <div className="nav-item" onClick={handleLogout}>
          <LogOut size={20} /> Logout
        </div>
      </div>
    </div>
  );
}
