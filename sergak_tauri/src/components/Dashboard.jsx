import React, { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";

const MODULE_META = {
  gateway:   { name: "Kiber Darvoza",       desc: "Phishing saytlarni bloklash",       icon: "🔒", iconBg: "success-bg" },
  usb:       { name: "USB Qalqoni",          desc: "Tashqi qurilmalarni nazorat",        icon: "🔌", iconBg: "accent-bg"  },
  camera:    { name: "Kamera Himoyasi",      desc: "Privacy Guard moduli",               icon: "📷", iconBg: "purple-bg"  },
  honeypot:  { name: "Ransomware Qopqon",    desc: "Honeypot fayllarni kuzatish",        icon: "🪤", iconBg: "warning-bg" },
  keylogger: { name: "Anti-Keylogger",       desc: "Klaviatura himoyasi",                icon: "⌨️", iconBg: "danger-bg"  },
};

export default function Dashboard({ cpu, ram, moduleStates = {} }) {
  const [uptime, setUptime]     = useState("00:00:00");
  const [startTime]             = useState(Date.now());
  const [threatCount]           = useState(0);  // Will come from real backend threat log in future

  // Live uptime counter
  useEffect(() => {
    const t = setInterval(() => {
      const elapsed = Math.floor((Date.now() - startTime) / 1000);
      const h = String(Math.floor(elapsed / 3600)).padStart(2, "0");
      const m = String(Math.floor((elapsed % 3600) / 60)).padStart(2, "0");
      const s = String(elapsed % 60).padStart(2, "0");
      setUptime(`${h}:${m}:${s}`);
    }, 1000);
    return () => clearInterval(t);
  }, [startTime]);

  const activeCount   = Object.values(moduleStates).filter(Boolean).length;
  const inactiveCount = Object.keys(MODULE_META).length - activeCount;

  const shieldStatus = inactiveCount === 0
    ? { text: "Kompyuter Himoyalangan", sub: "Barcha xavfsizlik modullari barqaror ishlamoqda.", cls: "protected" }
    : { text: `${inactiveCount} ta modul o'CHIQ`, sub: "Ba'zi himoya modullari faol emas. Sozlamalardan yoqing.", cls: "warning" };

  return (
    <div className="page-enter">
      {/* Shield Status */}
      <div className={`glass-card shield-status ${inactiveCount > 0 ? "shield-warn" : ""}`}>
        <div className={`shield-orb ${shieldStatus.cls}`}>🛡️</div>
        <div className="shield-text">
          <h2 style={{ color: inactiveCount > 0 ? "#ffa502" : undefined }}>{shieldStatus.text}</h2>
          <p>{shieldStatus.sub}</p>
        </div>
      </div>

      {/* Stats */}
      <div className="stats-grid stagger">
        <div className="glass-card stat-card">
          <span className="stat-icon">🎯</span>
          <div className="stat-value val-success">{threatCount}</div>
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
          <div className="stat-value val-warning" style={{ fontSize: 18 }}>{uptime}</div>
          <div className="stat-label">Ishga tushganiga</div>
        </div>
      </div>

      {/* Module Status — from real moduleStates prop */}
      <div className="section-title">
        <span>📦</span> Modul Holati ({activeCount}/{Object.keys(MODULE_META).length} faol)
      </div>
      <div className="module-grid stagger">
        {Object.entries(MODULE_META).map(([key, m]) => {
          const isActive = moduleStates[key] !== false; // default true
          return (
            <div
              key={key}
              className={`glass-card module-card ${isActive ? "is-active" : "is-inactive"}`}
            >
              <div className={`module-icon ${m.iconBg}`}>{m.icon}</div>
              <div className="module-info">
                <h4>{m.name}</h4>
                <p>{m.desc}</p>
              </div>
              <span className={`status-badge ${isActive ? "badge-active" : "badge-inactive"}`}>
                {isActive ? "FAOL" : "O'CHIQ"}
              </span>
            </div>
          );
        })}
        {/* Phone Link — always shows state from phonelink */}
        <div className="glass-card module-card is-inactive">
          <div className="module-icon accent-bg">📱</div>
          <div className="module-info">
            <h4>Phone Link</h4>
            <p>Telefon bilan sinxronizatsiya</p>
          </div>
          <span className="status-badge badge-inactive">O'CHIQ</span>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="section-title mt-lg">
        <span>⚡</span> Tezkor Harakatlar
      </div>
      <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
        <div className="glass-card" style={{ flex: 1, minWidth: 150, padding: "14px 16px", cursor: "pointer",
          borderLeft: "3px solid #2ed573", transition: "all 0.2s" }}
          onClick={() => {}}>
          <div style={{ fontSize: 20, marginBottom: 4 }}>🔍</div>
          <div style={{ fontSize: 12, fontWeight: 600 }}>Zaifliklarni skanerlash</div>
          <div style={{ fontSize: 11, color: "var(--text-muted)" }}>Tizim tekshiruvi</div>
        </div>
        <div className="glass-card" style={{ flex: 1, minWidth: 150, padding: "14px 16px", cursor: "pointer",
          borderLeft: "3px solid #5352ed", transition: "all 0.2s" }}
          onClick={() => {}}>
          <div style={{ fontSize: 20, marginBottom: 4 }}>🛡️</div>
          <div style={{ fontSize: 12, fontWeight: 600 }}>Ma'lumot filtri</div>
          <div style={{ fontSize: 11, color: "var(--text-muted)" }}>Tarmoqni kuzatish</div>
        </div>
        <div className="glass-card" style={{ flex: 1, minWidth: 150, padding: "14px 16px", cursor: "pointer",
          borderLeft: "3px solid #ff6b35", transition: "all 0.2s" }}
          onClick={() => {}}>
          <div style={{ fontSize: 20, marginBottom: 4 }}>🌐</div>
          <div style={{ fontSize: 12, fontWeight: 600 }}>Tarmoq skaneri</div>
          <div style={{ fontSize: 11, color: "var(--text-muted)" }}>Qurilmalarni topish</div>
        </div>
      </div>
    </div>
  );
}
