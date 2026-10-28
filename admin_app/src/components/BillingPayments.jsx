import React, { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, updateDoc, serverTimestamp, orderBy } from 'firebase/firestore';
import { db } from '../firebase';
import { DollarSign, RefreshCcw, CheckCircle, Clock } from 'lucide-react';

export default function BillingPayments() {
  const [payments, setPayments] = useState([]);
  const [loadingId, setLoadingId] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'payments'), orderBy('timestamp', 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const allPayments = [];
      snapshot.forEach((doc) => {
        allPayments.push({ id: doc.id, ...doc.data() });
      });
      setPayments(allPayments);
    });

    return () => unsubscribe();
  }, []);

  const handleManualAction = async (paymentId, newStatus) => {
    if (!window.confirm(`Are you sure you want to mark this payment as ${newStatus.toUpperCase()}?`)) return;
    
    setLoadingId(paymentId);
    try {
      const updateData = { status: newStatus };
      if (newStatus === 'released') updateData.releasedAt = serverTimestamp();
      if (newStatus === 'refunded') updateData.refundedAt = serverTimestamp();
      
      await updateDoc(doc(db, 'payments', paymentId), updateData);
    } catch (err) {
      console.error('Error updating payment status:', err);
      alert('Failed to update payment status.');
    }
    setLoadingId(null);
  };

  return (
    <div>
      <div className="header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1>Billing & Payments</h1>
          <p>Monitor all platform transactions, escrow holds, and completed payouts.</p>
        </div>
        <div style={{ position: 'relative' }}>
          <input
            type="text"
            placeholder="Search by worker ID or status..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{
              padding: '10px 16px',
              borderRadius: '8px',
              border: '1px solid var(--border-color)',
              background: 'var(--card-bg)',
              color: 'var(--text-color)',
              width: '300px'
            }}
          />
        </div>
      </div>

      <div className="glass-panel data-table-container">
        {payments.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
            No transactions found.
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Transaction ID</th>
                <th>Worker ID</th>
                <th>Amount</th>
                <th>Date</th>
                <th>Status</th>
                <th>Admin Override</th>
              </tr>
            </thead>
            <tbody>
              {payments.filter(p => {
                 const term = searchTerm.toLowerCase();
                 return ((p.id || '').toLowerCase().includes(term) || (p.workerId || '').toLowerCase().includes(term) || (p.status || '').toLowerCase().includes(term));
              }).map((p) => {
                let statusBadge;
                if (p.status === 'held_in_escrow') {
                  statusBadge = <span className="badge" style={{background: 'rgba(245, 158, 11, 0.2)', color: '#f59e0b'}}><Clock size={12} style={{marginRight: 4, verticalAlign: 'middle'}}/>ESCROW</span>;
                } else if (p.status === 'released' || p.status === 'completed') {
                  statusBadge = <span className="badge" style={{background: 'rgba(16, 185, 129, 0.2)', color: '#34d399'}}><CheckCircle size={12} style={{marginRight: 4, verticalAlign: 'middle'}}/>RELEASED</span>;
                } else if (p.status === 'refunded') {
                  statusBadge = <span className="badge" style={{background: 'rgba(239, 68, 68, 0.2)', color: '#ef4444'}}><RefreshCcw size={12} style={{marginRight: 4, verticalAlign: 'middle'}}/>REFUNDED</span>;
                } else {
                  statusBadge = <span className="badge" style={{background: 'rgba(156, 163, 175, 0.2)', color: '#9ca3af'}}>{(p.status || 'UNKNOWN').toUpperCase()}</span>;
                }

                const dateStr = p.timestamp ? new Date(p.timestamp.seconds * 1000).toLocaleString() : 'N/A';

                return (
                  <tr key={p.id}>
                    <td style={{ fontSize: '12px', fontFamily: 'monospace' }}>{p.id}</td>
                    <td style={{ fontSize: '12px' }}>{p.workerId || 'N/A'}</td>
                    <td style={{ fontWeight: 'bold', color: '#60a5fa' }}>PKR {p.amount || 0}</td>
                    <td style={{ fontSize: '13px' }}>{dateStr}</td>
                    <td>{statusBadge}</td>
                    <td>
                      {p.status === 'held_in_escrow' ? (
                        <div style={{ display: 'flex', gap: '8px' }}>
                          <button 
                            className="btn-verify" 
                            style={{color: '#34d399', borderColor: '#34d399', background: 'rgba(16, 185, 129, 0.1)', padding: '6px 12px'}}
                            onClick={() => handleManualAction(p.id, 'released')}
                            disabled={loadingId === p.id}
                            title="Force Release to Worker"
                          >
                            <DollarSign size={14} style={{ marginRight: '4px', verticalAlign: 'middle' }}/>
                            Release
                          </button>
                          <button 
                            className="btn-verify" 
                            style={{color: '#ef4444', borderColor: '#ef4444', background: 'rgba(239, 68, 68, 0.1)', padding: '6px 12px'}}
                            onClick={() => handleManualAction(p.id, 'refunded')}
                            disabled={loadingId === p.id}
                            title="Force Refund to Employer"
                          >
                            <RefreshCcw size={14} style={{ marginRight: '4px', verticalAlign: 'middle' }}/>
                            Refund
                          </button>
                        </div>
                      ) : (
                        <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>No actions available</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
