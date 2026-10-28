import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { CheckCircle, XCircle } from 'lucide-react';

export default function VerificationQueue() {
  const [users, setUsers] = useState([]);
  const [loadingId, setLoadingId] = useState(null);

  useEffect(() => {
    // Listen for users where isVerified == false or doesn't exist
    const q = query(collection(db, 'users'), where('isVerified', '==', false));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const pendingUsers = [];
      snapshot.forEach((doc) => {
        pendingUsers.push({ id: doc.id, ...doc.data() });
      });
      setUsers(pendingUsers);
    });

    return () => unsubscribe();
  }, []);

  const handleVerify = async (userId) => {
    setLoadingId(userId);
    try {
      await updateDoc(doc(db, 'users', userId), {
        isVerified: true
      });
    } catch (err) {
      console.error('Error verifying user:', err);
      alert('Failed to verify user.');
    }
    setLoadingId(null);
  };

  const handleReject = async (userId) => {
    setLoadingId(userId);
    try {
      await updateDoc(doc(db, 'users', userId), {
        verificationDocUrl: null,
        isVerified: false
      });
    } catch (err) {
      console.error('Error rejecting user:', err);
      alert('Failed to reject user.');
    }
    setLoadingId(null);
  };

  return (
    <div>
      <div className="header">
        <h1>Verification Queue</h1>
        <p>Review KYC and grant Verified Badges.</p>
      </div>

      <div className="glass-panel data-table-container">
        {users.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
            No pending verifications at this time.
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Name / Company</th>
                <th>Role</th>
                <th>Contact</th>
                <th>Document</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id}>
                  <td style={{ fontWeight: '600' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                       {u.photoUrl ? <img src={u.photoUrl} alt="profile" style={{width: 32, height: 32, borderRadius: '50%'}} /> : <div style={{width: 32, height: 32, borderRadius: '50%', background: 'rgba(255,255,255,0.1)'}} />}
                       {u.fullName || u.companyName || 'Unknown'}
                    </div>
                  </td>
                  <td style={{textTransform: 'capitalize'}}>{u.role}</td>
                  <td>{u.phone || u.email || 'N/A'}</td>
                  <td>
                    {u.verificationDocUrl ? (
                      <a href={u.verificationDocUrl} target="_blank" rel="noreferrer" style={{color: '#3b82f6', textDecoration: 'underline'}}>View KYC</a>
                    ) : (
                      <span style={{color: 'var(--text-muted)'}}>No File</span>
                    )}
                  </td>
                  <td>
                    <span className="badge pending">PENDING</span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                        <button 
                          className="btn-verify" 
                          onClick={() => handleVerify(u.id)}
                          disabled={loadingId === u.id}
                        >
                          <CheckCircle size={16} style={{ marginRight: '8px', verticalAlign: 'middle' }}/>
                          {loadingId === u.id ? 'Verifying...' : 'Approve'}
                        </button>
                        <button 
                          className="btn-verify" 
                          style={{color: '#ef4444', borderColor: '#ef4444', background: 'rgba(239, 68, 68, 0.1)'}}
                          onClick={() => handleReject(u.id)}
                        >
                          <XCircle size={16} style={{ marginRight: '8px', verticalAlign: 'middle' }}/>
                          Reject
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
