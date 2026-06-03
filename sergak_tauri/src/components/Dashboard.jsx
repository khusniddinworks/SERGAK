import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';

export default function Dashboard({ cpu, ram, moduleStates }) {
  const [securityScore, setSecurityScore] = useState(100);
  const [dbStats, setDbStats] = useState({ total_hashes: 0 });

  useEffect(() => {
    invoke('get_hash_db_stats').then(stats => setDbStats(stats)).catch(() => {});
  }, []);

  useEffect(() => {
    let score = 100;
    if (!moduleStates.gateway) score -= 15;
    if (!moduleStates.usb) score -= 10;
    if (!moduleStates.camera) score -= 5;
    if (!moduleStates.keylogger) score -= 20;
    if (dbStats.total_hashes === 0) score -= 10;
    setSecurityScore(Math.max(0, score));
  }, [moduleStates, dbStats]);

  const getScoreClass = () => {
    if (securityScore >= 90) return "val-success";
    if (securityScore >= 60) return "val-warning";
    return "val-danger";
  };

  const getScoreIcon = () => {
    if (securityScore >= 90) return "🛡️";
    if (securityScore >= 60) return "⚠️";
    return "🚨";
  };

  const modulesList = [
    { id: 'gateway', name: 'Tarmoq Gateway', icon: '🌐', desc: 'Phishing saytlarni bloklash', bg: 'success-bg' },
    { id: 'usb', name: 'USB Qalqon', icon: '💾', desc: 'Tashqi qurilmalarni nazorat', bg: 'accent-bg' },
    { id: 'keylogger', name: 'Anti-Keylogger', icon: '⌨️', desc: 'Klaviatura himoyasi', bg: 'danger-bg' },
    { id: 'camera', name: 'Kamera Himoyasi', icon: '📷', desc: 'Privacy Guard moduli', bg: 'purple-bg' },
    { id: 'honeypot', name: 'Honeypot (Qopqon)', icon: '🍯', desc: 'Honeypot fayllar', bg: 'warning-bg' },
  ];

  return (
    <div className="page-enter">
      <div className="page-header">
        <h1>📊 Boshqaruv Paneli</h1>
        <p>Kompyuteringizning xavfsizlik holati va tizim yuklanishi</p>
      </div>

      <div className="stats-grid">
        <div className="glass-card stat-card">
          <span className="stat-icon">{getScoreIcon()}</span>
          <div className={`stat-value ${getScoreClass()}`}>{securityScore}%</div>
          <div className="stat-label">Xavfsizlik Darajasi</div>
        </div>

        <div className="glass-card stat-card">
          <span className="stat-icon">⚡</span>
          <div className="stat-value val-accent">{cpu}%</div>
          <div className="stat-label">CPU Yuklanishi</div>
        </div>

        <div className="glass-card stat-card">
          <span className="stat-icon">🧠</span>
          <div className="stat-value val-purple">{ram}%</div>
          <div className="stat-label">RAM Yuklanishi</div>
        </div>
      </div>

      <div className="section-title mt-lg">
        <span>📦</span> Faol Himoya Modullari
      </div>
      <div className="module-grid stagger">
        {modulesList.map(mod => {
          const isActive = moduleStates[mod.id];
          return (
            <div
              key={mod.id}
              className={`glass-card module-card ${isActive ? 'is-active' : 'is-inactive'}`}
            >
              <div className={`module-icon ${isActive ? mod.bg : ''}`}>{mod.icon}</div>
              <div className="module-info">
                <h4>{mod.name}</h4>
                <p>{mod.desc}</p>
              </div>
              <span className={`status-badge ${isActive ? 'badge-active' : 'badge-inactive'}`}>
                {isActive ? 'FAOL' : 'O`CHIQ'}
              </span>
            </div>
          );
        })}
      </div>

      <div className="section-title mt-lg">
        <span>⚡</span> Tezkor Harakatlar
      </div>
      <div className="stats-grid stagger">
        <div className="glass-card stat-card" style={{ cursor: 'pointer' }}>
          <span className="stat-icon">🔍</span>
          <div className="stat-label" style={{ marginTop: 8 }}>Tizim Skaneri</div>
        </div>
        <div className="glass-card stat-card" style={{ cursor: 'pointer' }}>
          <span className="stat-icon">📁</span>
          <div className="stat-label" style={{ marginTop: 8 }}>Fayl Skaneri</div>
        </div>
        <div className="glass-card stat-card" style={{ cursor: 'pointer' }}>
          <span className="stat-icon">🤖</span>
          <div className="stat-label" style={{ marginTop: 8 }}>AI Yordamchi</div>
        </div>
      </div>
    </div>
  );
}
