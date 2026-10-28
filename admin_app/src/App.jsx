import React, { useState, useEffect } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from './firebase';
import './App.css';

// Components
import Sidebar from './components/Sidebar';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import VerificationQueue from './components/VerificationQueue';
import DisputeResolution from './components/DisputeResolution';
import UserManagement from './components/UserManagement';
import ContentModeration from './components/ContentModeration';
import BillingPayments from './components/BillingPayments';
import ProfileSettings from './components/ProfileSettings';

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('dashboard');

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  if (loading) {
    return (
      <div className="login-wrapper">
        <div className="loader">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return <Login />;
  }

  return (
    <div className="app-container">
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Main Content Area */}
      <div className="main-content">
        {activeTab === 'dashboard' && <Dashboard />}
        {activeTab === 'verification' && <VerificationQueue />}
        {activeTab === 'disputes' && <DisputeResolution />}
        {activeTab === 'users' && <UserManagement />}
        {activeTab === 'billing' && <BillingPayments />}
        {activeTab === 'moderation' && <ContentModeration />}
        {activeTab === 'profile' && <ProfileSettings />}
      </div>
    </div>
  );
}

export default App;
