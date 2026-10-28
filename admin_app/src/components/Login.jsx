import React, { useState } from 'react';
import { ShieldCheck, Loader2 } from 'lucide-react';
import { signInWithEmailAndPassword, sendPasswordResetEmail } from 'firebase/auth';
import { auth } from '../firebase';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  const [resetMessage, setResetMessage] = useState(null);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setResetMessage(null);
    try {
      await signInWithEmailAndPassword(auth, email, password);
      // Wait for auth state change to update App.jsx
    } catch (err) {
      setError('Invalid admin credentials.');
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    setError(null);
    setResetMessage(null);
    if (!email) {
      setError('Please enter your admin email above first.');
      return;
    }
    try {
      await sendPasswordResetEmail(auth, email);
      setResetMessage('If this email address exists in our system, you will receive a password reset link shortly. Please check your Spam/Junk folder.');
    } catch (err) {
      setError(err.message.replace('Firebase: ', ''));
    }
  };

  return (
    <div className="login-wrapper">
      <div className="glass-panel login-card">
        <div className="brand-logo" style={{ justifyContent: 'center', marginBottom: '24px' }}>
          <ShieldCheck size={32} color="#60a5fa" />
          WorkConnect Admin
        </div>
        <p style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Secure Authentication</p>
        <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <input 
            type="email" 
            placeholder="Admin Email" 
            className="glass-input" 
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required 
          />
          <input 
            type="password" 
            placeholder="Passcode" 
            className="glass-input" 
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required 
          />
          {error && <div style={{ color: '#ef4444', fontSize: '14px', textAlign: 'center' }}>{error}</div>}
          {resetMessage && <div style={{ color: '#10b981', fontSize: '14px', textAlign: 'center' }}>{resetMessage}</div>}
          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button type="button" onClick={handleForgotPassword} style={{ background: 'none', border: 'none', color: '#60a5fa', cursor: 'pointer', fontSize: '14px' }}>
              Forgot Password?
            </button>
          </div>
          <button type="submit" className="glass-btn" disabled={loading}>
            {loading ? <Loader2 className="spinner" size={20} style={{ margin: '0 auto' }} /> : 'Access Secure Panel'}
          </button>
        </form>
      </div>
    </div>
  );
}
