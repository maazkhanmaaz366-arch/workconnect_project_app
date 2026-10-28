import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';

export default function Dashboard() {
  const [stats, setStats] = useState({
    workers: 0,
    employers: 0,
    pendingVerifications: 0,
    activeJobs: 0,
    disputes: 0
  });

  useEffect(() => {
    // Total Workers
    const wQ = query(collection(db, 'users'), where('role', '==', 'worker'));
    const unsubW = onSnapshot(wQ, (snap) => setStats(s => ({ ...s, workers: snap.size })));

    // Total Employers
    const eQ = query(collection(db, 'users'), where('role', '==', 'employer'));
    const unsubE = onSnapshot(eQ, (snap) => setStats(s => ({ ...s, employers: snap.size })));

    // Pending Verifications
    const vQ = query(collection(db, 'users'), where('isVerified', '==', false));
    const unsubV = onSnapshot(vQ, (snap) => setStats(s => ({ ...s, pendingVerifications: snap.size })));

    // Active Jobs
    const jQ = query(collection(db, 'jobs'), where('status', '==', 'open'));
    const unsubJ = onSnapshot(jQ, (snap) => setStats(s => ({ ...s, activeJobs: snap.size })));

    // Open Disputes
    const dQ = query(collection(db, 'disputes'), where('status', '==', 'open'));
    const unsubD = onSnapshot(dQ, (snap) => setStats(s => ({ ...s, disputes: snap.size })));

    return () => {
      unsubW(); unsubE(); unsubV(); unsubJ(); unsubD();
    };
  }, []);

  return (
    <div>
      <div className="header">
        <h1>Admin Dashboard</h1>
        <p>Live metrics from the WorkConnect Platform.</p>
      </div>

      <div className="stats-grid">
        <div className="glass-panel stat-card">
          <span className="stat-title">Total Workers</span>
          <span className="stat-value">{stats.workers}</span>
        </div>
        <div className="glass-panel stat-card">
          <span className="stat-title">Total Employers</span>
          <span className="stat-value">{stats.employers}</span>
        </div>
        <div className="glass-panel stat-card" style={{ borderColor: stats.pendingVerifications > 0 ? 'rgba(245, 158, 11, 0.5)' : '' }}>
          <span className="stat-title">Pending KYC</span>
          <span className="stat-value" style={{ color: stats.pendingVerifications > 0 ? '#fbbf24' : '' }}>{stats.pendingVerifications}</span>
        </div>
        <div className="glass-panel stat-card">
          <span className="stat-title">Active Jobs</span>
          <span className="stat-value">{stats.activeJobs}</span>
        </div>
        <div className="glass-panel stat-card" style={{ borderColor: stats.disputes > 0 ? 'rgba(239, 68, 68, 0.5)' : '' }}>
          <span className="stat-title">Open Disputes</span>
          <span className="stat-value" style={{ color: stats.disputes > 0 ? '#ef4444' : '' }}>{stats.disputes}</span>
        </div>
        <div className="glass-panel stat-card">
          <span className="stat-title">System Health</span>
          <span className="stat-value" style={{ color: '#34d399' }}>100%</span>
        </div>
      </div>
    </div>
  );
}
