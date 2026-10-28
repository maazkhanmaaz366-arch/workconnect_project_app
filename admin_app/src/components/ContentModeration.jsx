import React, { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { Trash2, EyeOff } from 'lucide-react';

export default function ContentModeration() {
  const [jobs, setJobs] = useState([]);
  const [loadingId, setLoadingId] = useState(null);

  useEffect(() => {
    // Listen for all active jobs that might need moderation
    const q = query(collection(db, 'jobs'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const allJobs = [];
      snapshot.forEach((doc) => {
        allJobs.push({ id: doc.id, ...doc.data() });
      });
      // Filter out hidden jobs locally or display them with a flag
      setJobs(allJobs);
    });

    return () => unsubscribe();
  }, []);

  const hideJob = async (jobId) => {
    setLoadingId(jobId);
    try {
      await updateDoc(doc(db, 'jobs', jobId), {
        status: 'hidden', // or any logic you use to hide
        isHiddenByAdmin: true
      });
    } catch (err) {
      console.error('Error hiding job:', err);
      alert('Failed to hide job.');
    }
    setLoadingId(null);
  };

  const deleteJob = async (jobId) => {
    if (!window.confirm("Are you sure you want to permanently delete this job?")) return;
    setLoadingId(jobId);
    try {
      await deleteDoc(doc(db, 'jobs', jobId));
    } catch (err) {
      console.error('Error deleting job:', err);
      alert('Failed to delete job.');
    }
    setLoadingId(null);
  };

  return (
    <div>
      <div className="header">
        <h1>Content Moderation</h1>
        <p>Review active job postings and remove inappropriate content.</p>
      </div>

      <div className="glass-panel data-table-container">
        {jobs.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
            No jobs found.
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Job Title</th>
                <th>Category</th>
                <th>Budget</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {jobs.map((j) => {
                const isHidden = j.isHiddenByAdmin || j.status === 'hidden';
                return (
                  <tr key={j.id} style={{ opacity: isHidden ? 0.5 : 1 }}>
                    <td style={{ fontWeight: '600' }}>
                        <div>{j.title || 'Untitled Job'}</div>
                        <div style={{fontSize: '12px', color: 'var(--text-muted)', fontWeight: 'normal'}}>{j.location}</div>
                    </td>
                    <td>{j.category}</td>
                    <td style={{color: '#34d399', fontWeight: 'bold'}}>PKR {j.budget}/hr</td>
                    <td>
                      {isHidden ? (
                         <span className="badge" style={{background: 'rgba(245, 158, 11, 0.2)', color: '#fbbf24'}}>HIDDEN</span>
                      ) : (
                         <span className="badge" style={{background: 'rgba(16, 185, 129, 0.2)', color: '#34d399'}}>VISIBLE</span>
                      )}
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '8px' }}>
                          {!isHidden && (
                             <button 
                               className="btn-verify" 
                               style={{color: '#f59e0b', borderColor: '#f59e0b', background: 'rgba(245, 158, 11, 0.1)'}}
                               onClick={() => hideJob(j.id)}
                               disabled={loadingId === j.id}
                             >
                               <EyeOff size={16} style={{ marginRight: '8px', verticalAlign: 'middle' }}/>
                               {loadingId === j.id ? 'Hiding...' : 'Hide'}
                             </button>
                          )}
                          <button 
                            className="btn-verify" 
                            style={{color: '#ef4444', borderColor: '#ef4444', background: 'rgba(239, 68, 68, 0.1)'}}
                            onClick={() => deleteJob(j.id)}
                            disabled={loadingId === j.id}
                          >
                            <Trash2 size={16} style={{ marginRight: '8px', verticalAlign: 'middle' }}/>
                            {loadingId === j.id ? 'Deleting...' : 'Delete'}
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
    </div>
  );
}
