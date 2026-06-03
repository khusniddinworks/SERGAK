import React from "react";

const navItems = [
  { id: 'home', label: 'Dashboard', icon: '🏠' },
  { id: 'vuln', label: 'Tizim Skaneri', icon: '🔍' },
  { id: 'dataguard', label: 'Ma\'lumot Filtr', icon: '🛡️' },
  { id: 'fsmonitor', label: 'Fayl Skaneri', icon: '📁' },
  { id: 'processes', label: 'Jarayonlar', icon: '⚙️' },
  { id: 'network', label: 'Tarmoq', icon: '🌐' },
  { id: 'ai', label: 'AI Yordamchi', icon: '🤖' },
  { id: 'quarantine', label: 'Karantin', icon: '🔒' },
  { id: 'phone', label: 'Telefon', icon: '📱' },
  { id: 'settings', label: 'Sozlamalar', icon: '⚙️' }
];

export default function Sidebar({ activeTab, onTabChange, isPremium }) {
  return (
    <div className="sidebar">
      {/* Logo */}
      <div className="logo-section">
        <div className="logo-icon">🛡️</div>
        <div className="logo-title">SERGAK PC</div>
        <div className="logo-subtitle">Kiber Qalqon v2.0</div>
      </div>

      {/* Navigation */}
      <div className="nav-section">
        <div className="nav-label">Boshqaruv</div>
        {navItems.map((item) => (
          <button
            key={item.id}
            className={`nav-item ${activeTab === item.id ? "active" : ""}`}
            onClick={() => onTabChange(item.id)}
          >
            <span className="nav-icon">{item.icon}</span>
            {item.label}
          </button>
        ))}
      </div>

      {/* Premium Badge */}
      <div className="sidebar-footer">
        <div className={`premium-badge ${isPremium ? "is-premium" : "is-free"}`}>
          <span className={`premium-dot ${isPremium ? "active" : "inactive"}`} />
          {isPremium ? "Premium Faol" : "Bepul Rejim"}
        </div>
      </div>
    </div>
  );
}
