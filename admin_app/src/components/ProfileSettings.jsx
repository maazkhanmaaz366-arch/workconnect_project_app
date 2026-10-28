import React, { useState } from 'react';
import { updatePassword, updateProfile } from 'firebase/auth';
import { auth } from '../firebase';
import { Save, User, Key, Loader2 } from 'lucide-react';

export default function ProfileSettings() {
  const [displayName, setDisplayName] = useState(auth.currentUser?.displayName || '');
  const [newPassword, setNewPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState(null);
  const [error, setError] = useState(null);

  const handleUpdateProfile = async (e) => {
    e.preventDefault();
    if (!displayName) return;
    setLoading(true);
    setMessage(null);
    setError(null);
    try {
      await updateProfile(auth.currentUser, { displayName });
      setMessage('Profile updated successfully.');
    } catch (err) {
      setError(err.message);
    }
    setLoading(false);
  };

  const handleUpdatePassword = async (e) => {
    e.preventDefault();
    if (!newPassword || newPassword.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }
    setLoading(true);
    setMessage(null);
    setError(null);
    try {
      await updatePassword(auth.currentUser, newPassword);
      setMessage('Password updated successfully.');
      setNewPassword('');
    } catch (err) {
      // Re-authentication might be required for password update
      if (err.code === 'auth/requires-recent-login') {
        setError('Please log out and log back in to change your password.');
      } else {
        setError(err.message.replace('Firebase: ', ''));
      }
    }
    setLoading(false);
  };

  return (
    <div className="glass-panel" style={{ maxWidth: '600px', margin: '0 auto', padding: '32px' }}>
      <h2 style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        <User size={24} color="#60a5fa" />
        Admin Profile Settings
      </h2>

      <div style={{ marginBottom: '24px', color: 'var(--text-muted)' }}>
        <strong>Current Email:</strong> {auth.currentUser?.email}
      </div>

      {message && <div style={{ color: '#10b981', marginBottom: '16px', padding: '12px', background: 'rgba(16, 185, 129, 0.1)', borderRadius: '8px' }}>{message}</div>}
      {error && <div style={{ color: '#ef4444', marginBottom: '16px', padding: '12px', background: 'rgba(239, 68, 68, 0.1)', borderRadius: '8px' }}>{error}</div>}

      <form onSubmit={handleUpdateProfile} style={{ marginBottom: '32px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <h3>Update Details</h3>
        <input 
          type="text" 
          placeholder="Display Name" 
          className="glass-input" 
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          required 
        />
        <button type="submit" className="glass-btn" disabled={loading} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
          {loading ? <Loader2 className="spinner" size={16} /> : <Save size={16} />} Update Profile
        </button>
      </form>

      <form onSubmit={handleUpdatePassword} style={{ display: 'flex', flexDirection: 'column', gap: '16px', borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '32px' }}>
        <h3>Change Password</h3>
        <input 
          type="password" 
          placeholder="New Password (min 6 chars)" 
          className="glass-input" 
          value={newPassword}
          onChange={(e) => setNewPassword(e.target.value)}
          required 
        />
        <button type="submit" className="glass-btn" disabled={loading} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', background: 'rgba(96, 165, 250, 0.1)', border: '1px solid rgba(96, 165, 250, 0.3)' }}>
          {loading ? <Loader2 className="spinner" size={16} /> : <Key size={16} />} Change Password
        </button>
      </form>
    </div>
  );
}
