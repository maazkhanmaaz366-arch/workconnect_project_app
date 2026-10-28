import React, { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, updateDoc, getDocs, where } from 'firebase/firestore';
import { db } from '../firebase';
import { Ban, Unlock } from 'lucide-react';

export default function UserManagement() {
  const [users, setUsers] = useState([]);
  const [loadingId, setLoadingId] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [userCertificates, setUserCertificates] = useState([]);

  useEffect(() => {
    if (!selectedUser) {
      setUserCertificates([]);
      return;
    }
    const fetchCerts = async () => {
      const q = query(collection(db, 'certificates'), where('userId', '==', selectedUser.id));
      const snapshot = await getDocs(q);
      const certs = [];
      snapshot.forEach(doc => certs.push({id: doc.id, ...doc.data()}));
      setUserCertificates(certs);
    };
    fetchCerts();
  }, [selectedUser]);

  useEffect(() => {
    // Listen for all users to manage them
    const q = query(collection(db, 'users'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const allUsers = [];
      snapshot.forEach((doc) => {
        allUsers.push({ id: doc.id, ...doc.data() });
      });
      setUsers(allUsers);
    });

    return () => unsubscribe();
  }, []);

  const removeUser = async (userId) => {
    if (!window.confirm("Are you sure you want to permanently remove this user? This cannot be undone.")) return;
    setLoadingId(userId);
    try {
      const res = await fetch(`http://127.0.0.1:8000/users/${userId}`, { method: 'DELETE' });
      if (!res.ok) throw new Error("Failed to delete user on backend.");
      // They will automatically disappear from the snapshot since we deleted from Firestore
      setSelectedUser(null);
    } catch (err) {
      console.error('Error removing user:', err);
      alert('Failed to remove user.');
    }
    setLoadingId(null);
  };

  const downloadReport = (user) => {
    const reportStr = JSON.stringify(user, null, 2);
    const blob = new Blob([reportStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `user_report_${user.id}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div>
      <div className="header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1>User Management</h1>
          <p>View all users, suspend or permanently ban bad actors.</p>
        </div>
        <div style={{ position: 'relative' }}>
          <input
            type="text"
            placeholder="Search by name or email..."
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
        {users.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
            No users found.
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Role</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.filter(u => {
                 const term = searchTerm.toLowerCase();
                 return (u.fullName?.toLowerCase().includes(term) || u.companyName?.toLowerCase().includes(term) || u.email?.toLowerCase().includes(term));
              }).map((u) => {
                const isBanned = u.isBanned === true;
                return (
                  <tr key={u.id} style={{ opacity: isBanned ? 0.6 : 1, cursor: 'pointer' }} onClick={() => setSelectedUser(u)}>
                    <td style={{ fontWeight: '600' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        {u.photoUrl ? <img src={u.photoUrl} alt="profile" style={{width: 32, height: 32, borderRadius: '50%'}} /> : <div style={{width: 32, height: 32, borderRadius: '50%', background: 'rgba(255,255,255,0.1)'}} />}
                        <div>
                           <div>{u.fullName || u.companyName || 'Unknown User'}</div>
                           <div style={{fontSize: '12px', color: 'var(--text-muted)', fontWeight: 'normal'}}>{u.email}</div>
                        </div>
                      </div>
                    </td>
                    <td style={{textTransform: 'capitalize'}}>{u.role || 'Unknown'}</td>
                    <td>
                      {isBanned ? (
                         <span className="badge" style={{background: 'rgba(239, 68, 68, 0.2)', color: '#ef4444'}}>BANNED</span>
                      ) : (
                         <span className="badge" style={{background: 'rgba(16, 185, 129, 0.2)', color: '#34d399'}}>ACTIVE</span>
                      )}
                    </td>
                    <td onClick={(e) => e.stopPropagation()}>
                      <div style={{ display: 'flex', gap: '8px' }}>
                          <button 
                             className="btn-verify" 
                             style={{color: '#ef4444', borderColor: '#ef4444', background: 'rgba(239, 68, 68, 0.1)'}}
                             onClick={() => removeUser(u.id)}
                             disabled={loadingId === u.id}
                           >
                             <Ban size={16} style={{ marginRight: '8px', verticalAlign: 'middle' }}/>
                             {loadingId === u.id ? 'Removing...' : 'Remove User'}
                           </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {selectedUser && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100%', height: '100%',
          backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000
        }} onClick={() => setSelectedUser(null)}>
          <div style={{
            background: '#0f172a', padding: '24px', borderRadius: '12px', width: '500px', maxWidth: '90%', maxHeight: '90vh', overflowY: 'auto',
            color: '#f8fafc', border: '1px solid #334155', boxShadow: '0 8px 32px rgba(0,0,0,0.5)'
          }} onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 style={{ margin: 0 }}>User Details</h2>
              <button onClick={() => setSelectedUser(null)} style={{ background: 'transparent', border: 'none', color: 'var(--text-color)', cursor: 'pointer', fontSize: '20px' }}>&times;</button>
            </div>
            
            <div style={{ display: 'flex', gap: '16px', marginBottom: '20px', alignItems: 'center' }}>
               {selectedUser.photoUrl ? <img src={selectedUser.photoUrl} alt="profile" style={{width: 64, height: 64, borderRadius: '50%'}} /> : <div style={{width: 64, height: 64, borderRadius: '50%', background: 'rgba(255,255,255,0.1)'}} />}
               <div>
                  <h3 style={{ margin: 0 }}>{selectedUser.fullName || selectedUser.companyName || 'Unknown User'}</h3>
                  <p style={{ margin: 0, color: 'var(--text-muted)' }}>{selectedUser.email}</p>
                  <span className="badge" style={{marginTop: '4px', display: 'inline-block', background: 'rgba(255,255,255,0.1)'}}>{(selectedUser.role || 'Unknown').toUpperCase()}</span>
               </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '20px' }}>
              <div>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Phone Number</p>
                 <p style={{ margin: 0, fontWeight: '500' }}>{selectedUser.phoneNumber || 'N/A'}</p>
              </div>
              <div>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Location</p>
                 <p style={{ margin: 0, fontWeight: '500' }}>{selectedUser.city || selectedUser.location || 'N/A'}</p>
              </div>
              <div>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Verification Status</p>
                 <p style={{ margin: 0, fontWeight: '500', color: selectedUser.isVerified ? '#34d399' : '#f59e0b' }}>{selectedUser.isVerified ? 'Verified' : 'Pending/Unverified'}</p>
              </div>
              <div>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Coordinates</p>
                 <p style={{ margin: 0, fontWeight: '500' }}>{selectedUser.latitude ? `${selectedUser.latitude.toFixed(2)}, ${selectedUser.longitude.toFixed(2)}` : 'N/A'}</p>
              </div>
            </div>
            
            {selectedUser.role === 'worker' && (
              <div style={{ marginBottom: '20px' }}>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Professional Title</p>
                 <p style={{ margin: '0 0 8px 0', fontWeight: '500' }}>{selectedUser.professionalTitle || 'N/A'}</p>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Hourly Rate</p>
                 <p style={{ margin: '0 0 8px 0', fontWeight: '500' }}>PKR {selectedUser.hourlyRate || '0'}</p>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Bio</p>
                 <p style={{ margin: 0, fontSize: '14px', background: 'rgba(0,0,0,0.2)', padding: '8px', borderRadius: '4px' }}>{selectedUser.bio || 'No bio provided'}</p>
              </div>
            )}

            {selectedUser.role === 'employer' && (
              <div style={{ marginBottom: '20px' }}>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Industry</p>
                 <p style={{ margin: '0 0 8px 0', fontWeight: '500' }}>{selectedUser.industry || 'N/A'}</p>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Company Size</p>
                 <p style={{ margin: '0 0 8px 0', fontWeight: '500' }}>{selectedUser.companySize || 'N/A'}</p>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Website</p>
                 <p style={{ margin: '0 0 8px 0', fontWeight: '500' }}>{selectedUser.website || 'N/A'}</p>
                 <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-muted)' }}>Bio</p>
                 <p style={{ margin: 0, fontSize: '14px', background: 'rgba(0,0,0,0.2)', padding: '8px', borderRadius: '4px' }}>{selectedUser.bio || 'No bio provided'}</p>
              </div>
            )}
            
            {selectedUser.verificationDocUrl && (
              <div style={{ marginBottom: '20px' }}>
                 <p style={{ margin: '0 0 8px 0', fontSize: '12px', color: '#94a3b8' }}>Verification Document</p>
                 <a href={selectedUser.verificationDocUrl} target="_blank" rel="noreferrer" style={{ color: '#60a5fa' }}>View Document</a>
              </div>
            )}

            {selectedUser.portfolioUrls && selectedUser.portfolioUrls.length > 0 && (
              <div style={{ marginBottom: '20px' }}>
                 <p style={{ margin: '0 0 8px 0', fontSize: '12px', color: '#94a3b8' }}>Portfolio Images</p>
                 <div style={{ display: 'flex', gap: '8px', overflowX: 'auto' }}>
                    {selectedUser.portfolioUrls.map((url, i) => (
                       <a key={i} href={url} target="_blank" rel="noreferrer">
                         <img src={url} alt={`Portfolio ${i}`} style={{ width: 64, height: 64, borderRadius: '8px', objectFit: 'cover' }} />
                       </a>
                    ))}
                 </div>
              </div>
            )}

            {userCertificates.length > 0 && (
              <div style={{ marginBottom: '20px' }}>
                 <p style={{ margin: '0 0 8px 0', fontSize: '12px', color: '#94a3b8' }}>Certificates</p>
                 {userCertificates.map(c => (
                    <div key={c.id} style={{ background: 'rgba(255,255,255,0.05)', padding: '8px', borderRadius: '4px', marginBottom: '4px' }}>
                       <div style={{ fontWeight: '500', fontSize: '14px' }}>{c.title}</div>
                       <div style={{ fontSize: '12px', color: '#94a3b8' }}>Issued by: {c.issuer}</div>
                       {c.fileUrl && <a href={c.fileUrl} target="_blank" rel="noreferrer" style={{ color: '#60a5fa', fontSize: '12px' }}>View Certificate</a>}
                    </div>
                 ))}
              </div>
            )}
            
            <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '20px', textAlign: 'right' }}>
               <button 
                  onClick={() => downloadReport(selectedUser)}
                  style={{
                    background: 'var(--primary-color)', color: 'white', border: 'none', 
                    padding: '10px 20px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold'
                  }}>
                  Download User Report
               </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
