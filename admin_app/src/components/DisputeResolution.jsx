import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, doc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { ShieldAlert, RefreshCcw, DollarSign } from 'lucide-react';

export default function DisputeResolution() {
  const [disputes, setDisputes] = useState([]);
  const [loadingId, setLoadingId] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    // Listen for open disputes (filtered locally for case insensitivity)
    const q = query(collection(db, 'disputes'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const openDisputes = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        if (data.status && data.status.toLowerCase() === 'open') {
           openDisputes.push({ id: doc.id, ...data });
        }
      });
      setDisputes(openDisputes);
    });

    return () => unsubscribe();
  }, []);

  const handleResolve = async (disputeId, jobId, resolution) => {
    setLoadingId(disputeId);
    try {
      // 1. Update the dispute status
      await updateDoc(doc(db, 'disputes', disputeId), {
        status: 'resolved',
        resolution: resolution,
        resolvedAt: serverTimestamp(),
      });

      // 2. Update the payment status (the payment document usually has ID matching jobId or has jobId as field)
      // Since we don't have the exact payment doc ID mapping in frontend, we assume payment doc ID == jobId 
      // or we update a job document. According to the PDF requirements snippet:
      // payment doc id == jobId. Let's execute that:
      if (resolution === 'paid_to_worker') {
        await updateDoc(doc(db, 'payments', jobId), {
          status: 'released',
          releasedAt: serverTimestamp(),
        });
      } else {
        await updateDoc(doc(db, 'payments', jobId), {
          status: 'refunded',
          refundedAt: serverTimestamp()
        });
      }
    } catch (err) {
      console.error('Error resolving dispute:', err);
      alert('Failed to resolve dispute. Are you sure the payment doc exists for this jobId?');
    }
    setLoadingId(null);
  };

  return (
    <div>
      <div className="header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1>Dispute Resolution</h1>
          <p>Review conflicts and manage escrow releases.</p>
        </div>
        <div style={{ position: 'relative' }}>
          <input
            type="text"
            placeholder="Search by job title or reason..."
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
        {disputes.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
            No open disputes. Great job!
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Job Title</th>
                <th>Raised By</th>
                <th>Reason</th>
                <th>Amount</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {disputes.filter(d => {
                 const term = searchTerm.toLowerCase();
                 return ((d.jobTitle || d.jobId || '').toLowerCase().includes(term) || (d.reason || '').toLowerCase().includes(term));
              }).map((d) => (
                <tr key={d.id}>
                  <td style={{ fontWeight: '600' }}>{d.jobTitle || d.jobId || d.chatRoomId || 'Unknown Job'}</td>
                  <td>{d.raisedByName || 'Unknown'} ({(d.raisedByRole || 'User').toUpperCase()})</td>
                  <td>{d.reason}</td>
                  <td style={{ fontWeight: 'bold', color: '#60a5fa' }}>PKR {d.amount !== undefined && d.amount !== null ? d.amount : '---'}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                        <button 
                          className="btn-verify" 
                          style={{color: '#34d399', borderColor: '#34d399', background: 'rgba(16, 185, 129, 0.1)'}}
                          onClick={() => handleResolve(d.id, d.jobId, 'paid_to_worker')}
                          disabled={loadingId === d.id}
                        >
                          <DollarSign size={16} style={{ marginRight: '8px', verticalAlign: 'middle' }}/>
                          Release Escrow
                        </button>
                        <button 
                          className="btn-verify" 
                          style={{color: '#f59e0b', borderColor: '#f59e0b', background: 'rgba(245, 158, 11, 0.1)'}}
                          onClick={() => handleResolve(d.id, d.jobId, 'refunded_to_employer')}
                          disabled={loadingId === d.id}
                        >
                          <RefreshCcw size={16} style={{ marginRight: '8px', verticalAlign: 'middle' }}/>
                          Refund Employer
                        </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
