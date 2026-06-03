import React from "react";

const modules = [
  {
    name: "Kiber Darvoza",
    desc: "Phishing saytlarni bloklash",
    icon: "🔒",
    iconBg: "success-bg",
    status: "active",
  },
  {
    name: "USB Qalqoni",
    desc: "Tashqi qurilmalarni nazorat",
    icon: "🔌",
    iconBg: "accent-bg",
    status: "active",
  },
  {
    name: "Kamera Himoyasi",
    desc: "Privacy Guard moduli",
    icon: "📷",
    iconBg: "purple-bg",
    status: "active",
  },
  {
    name: "Ransomware Qopqon",
    desc: "Honeypot fayllarni kuzatish",
    icon: "🪤",
    iconBg: "warning-bg",
    status: "active",
  },
  {
    name: "Anti-Keylogger",
    desc: "Klaviatura himoyasi",
    icon: "⌨️",
    iconBg: "danger-bg",
    status: "active",
  },
  {
    name: "Phone Link",
    desc: "Telefon bilan sinxronizatsiya",
    icon: "📱",
    iconBg: "accent-bg",
    status: "inactive",
  },
];

const activities = [
  { dot: "dot-success", text: "USB qurilma skanerlandi — xavfsiz", time: "Hozir" },
  { dot: "dot-accent",  text: "Tizim xavfsizlik tekshiruvi yakunlandi", time: "2 daq. oldin" },
  { dot: "dot-warning", text: "Wi-Fi tarmoq nomi o'zgardi — tekshirilmoqda", time: "15 daq. oldin" },
  { dot: "dot-success", text: "Kiber Darvoza: 3 ta shubhali havola bloklandi", time: "1 soat oldin" },
  { dot: "dot-danger",  text: "Keylogger urinishi aniqlandi va bloklandi", time: "3 soat oldin" },
];

export default function Dashboard({ cpu, ram }) {
  return (
    <div className="page-enter">
      {/* Shield Status */}
      <div className="glass-card shield-status">
        <div className="shield-orb protected">🛡️</div>
        <div className="shield-text">
          <h2>Kompyuter Himoyalangan</h2>
          <p>Barcha xavfsizlik modullari barqaror ishlamoqda. Hech qanday tahdid aniqlanmadi.</p>
        </div>
      </div>

      {/* Stats */}
      <div className="stats-grid stagger">
        <div className="glass-card stat-card">
          <span className="stat-icon">🎯</span>
          <div className="stat-value val-success">0</div>
          <div className="stat-label">Tahdidlar</div>
        </div>
        <div className="glass-card stat-card">
          <span className="stat-icon">⚡</span>
          <div className="stat-value val-accent">{cpu}%</div>
          <div className="stat-label">CPU Yuklanishi</div>
        </div>
        <div className="glass-card stat-card">
          <span className="stat-icon">💾</span>
          <div className="stat-value val-purple">{ram}%</div>
          <div className="stat-label">RAM Yuklanishi</div>
        </div>
        <div className="glass-card stat-card">
          <span className="stat-icon">⏱️</span>
          <div className="stat-value val-warning">24/7</div>
          <div className="stat-label">Himoya Vaqti</div>
        </div>
      </div>

      {/* Module Status */}
      <div className="section-title">
        <span>📦</span> Modul Holati
      </div>
      <div className="module-grid stagger">
        {modules.map((m, i) => (
          <div
            key={i}
            className={`glass-card module-card ${
              m.status === "active" ? "is-active" : "is-inactive"
            }`}
          >
            <div className={`module-icon ${m.iconBg}`}>{m.icon}</div>
            <div className="module-info">
              <h4>{m.name}</h4>
              <p>{m.desc}</p>
            </div>
            <span
              className={`status-badge ${
                m.status === "active" ? "badge-active" : "badge-inactive"
              }`}
            >
              {m.status === "active" ? "FAOL" : "O'CHIQ"}
            </span>
          </div>
        ))}
      </div>

      {/* Activity Log */}
      <div className="section-title mt-lg">
        <span>📋</span> So'nggi Hodisalar
      </div>
      <div className="activity-list stagger">
        {activities.map((a, i) => (
          <div key={i} className="activity-item">
            <span className={`activity-dot ${a.dot}`} />
            <span className="activity-text">{a.text}</span>
            <span className="activity-time">{a.time}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
