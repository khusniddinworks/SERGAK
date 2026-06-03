import React, { useState, useEffect, useRef } from "react";
import { invoke } from "@tauri-apps/api/core";

const RISK_CONFIG = {
  danger:  { color: "#ff4757", bg: "rgba(255,71,87,0.15)",  icon: "🚨", label: "XAVFLI" },
  warning: { color: "#ffa502", bg: "rgba(255,165,2,0.15)",  icon: "⚠️", label: "SHUBHALI" },
  safe:    { color: "#2ed573", bg: "rgba(46,213,115,0.12)", icon: "✅", label: "XAVFSIZ" },
};

const ALERT_CONFIG = {
  critical: { color: "#ff4757", bg: "rgba(255,71,87,0.18)", border: "#ff4757", icon: "🚨" },
  high:     { color: "#ff6b35", bg: "rgba(255,107,53,0.18)", border: "#ff6b35", icon: "🔥" },
  medium:   { color: "#ffa502", bg: "rgba(255,165,2,0.18)", border: "#ffa502", icon: "⚠️" },
};

export default function DataGuard() {
  const [connections, setConnections]       = useState([]);
  const [clipAlerts, setClipAlerts]         = useState([]);
  const [monitoring, setMonitoring]         = useState(false);
  const [loadingConn, setLoadingConn]       = useState(false);
  const [lastScanTime, setLastScanTime]     = useState(null);
  const [dismissedAlerts, setDismissedAlerts] = useState(new Set());
  const intervalRef = useRef(null);

  const scanConnections = async () => {
    setLoadingConn(true);
    try {
      const conns = await invoke("get_active_connections");
      setConnections(conns);
      setLastScanTime(new Date());
    } catch (e) {
      console.error("Connection scan error:", e);
    } finally {
      setLoadingConn(false);
    }
  };

  const scanClipboard = async () => {
    try {
      const alerts = await invoke("scan_clipboard_for_leaks");
      if (alerts.length > 0) {
        setClipAlerts(prev => {
          // Avoid duplicates by alert_type
          const existing = new Set(prev.map(a => a.alert_type));
          const newAlerts = alerts.filter(a => !existing.has(a.alert_type));
          return [...prev, ...newAlerts];
        });
      }
    } catch (e) {
      console.error("Clipboard scan error:", e);
    }
  };

  const startMonitoring = () => {
    setMonitoring(true);
    scanConnections();
    scanClipboard();
    intervalRef.current = setInterval(() => {
      scanConnections();
      scanClipboard();
    }, 5000);
  };

  const stopMonitoring = () => {
    setMonitoring(false);
    if (intervalRef.current) clearInterval(intervalRef.current);
  };

  useEffect(() => {
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []);

  const dismissAlert = (type) => {
    setDismissedAlerts(prev => new Set([...prev, type]));
    setClipAlerts(prev => prev.filter(a => a.alert_type !== type));
  };

  const clearHistory = () => setClipAlerts([]);

  const dangerConns = connections.filter(c => c.risk === "danger");
  const warnConns   = connections.filter(c => c.risk === "warning");
  const safeConns   = connections.filter(c => c.risk === "safe");
  const activeAlerts = clipAlerts.filter(a => !dismissedAlerts.has(a.alert_type));

  return (
    <div className="page-enter">
      <div className="page-header">
        <h1>🛡️ Ma'lumot Qo'riqchisi</h1>
        <p>Tarmoq ulanishlarini real vaqtda kuzatish va sezgir ma'lumot filtrlash</p>
      </div>

      {/* Control Bar */}
      <div style={{ display: "flex", gap: 12, marginBottom: 24, alignItems: "center", flexWrap: "wrap" }}>
        <button
          className={`btn ${monitoring ? "btn-danger" : "btn-primary"} btn-lg`}
          onClick={monitoring ? stopMonitoring : startMonitoring}
          style={{ flex: 1, minWidth: 200,
            background: monitoring ? "rgba(255,71,87,0.2)" : undefined,
            border: monitoring ? "1px solid #ff4757" : undefined,
            color: monitoring ? "#ff4757" : undefined,
          }}
        >
          {monitoring ? "⏹️ Monitoringni To'xtatish" : "▶️ Monitoringni Boshlash"}
        </button>

        {monitoring && (
          <div style={{ display: "flex", alignItems: "center", gap: 8, color: "#2ed573", fontSize: 13 }}>
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: "#2ed573",
              animation: "pulse 1.5s infinite", display: "inline-block" }} />
            Monitoring faol — har 5 soniyada yangilanadi
          </div>
        )}

        {lastScanTime && (
          <span style={{ color: "var(--text-muted)", fontSize: 12 }}>
            Oxirgi: {lastScanTime.toLocaleTimeString()}
          </span>
        )}
      </div>

      {/* === CLIPBOARD ALERTS === */}
      {activeAlerts.length > 0 && (
        <div style={{ marginBottom: 24 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
            <div className="section-title" style={{ margin: 0 }}>
              <span>🚨</span> Sezgir Ma'lumot Ogohlantirishlari
            </div>
            <button onClick={clearHistory}
              style={{ background: "transparent", border: "1px solid var(--border)", color: "var(--text-muted)",
                borderRadius: 6, padding: "4px 12px", cursor: "pointer", fontSize: 12 }}>
              Hammasini tozalash
            </button>
          </div>

          {activeAlerts.map((alert, i) => {
            const cfg = ALERT_CONFIG[alert.severity] || ALERT_CONFIG.medium;
            return (
              <div key={i} className="glass-card" style={{
                padding: "16px 20px", marginBottom: 10,
                borderLeft: `4px solid ${cfg.border}`,
                background: cfg.bg,
                animation: "slideIn 0.3s ease",
              }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <div>
                    <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                      <span style={{ fontSize: 20 }}>{cfg.icon}</span>
                      <strong style={{ color: cfg.color }}>
                        Clipboard'da {alert.alert_type} topildi!
                      </strong>
                    </div>
                    <p style={{ margin: 0, fontSize: 13, color: "var(--text-secondary)", marginBottom: 4 }}>
                      {alert.description}
                    </p>
                    <p style={{ margin: 0, fontSize: 11, color: "var(--text-muted)", fontFamily: "monospace",
                      background: "rgba(0,0,0,0.2)", padding: "4px 8px", borderRadius: 4, display: "inline-block" }}>
                      {alert.snippet}
                    </p>
                  </div>
                  <button onClick={() => dismissAlert(alert.alert_type)}
                    style={{ background: "transparent", border: "none", color: "var(--text-muted)",
                      cursor: "pointer", fontSize: 18, padding: "0 4px", lineHeight: 1 }}>
                    ✕
                  </button>
                </div>
                <div style={{ marginTop: 10, fontSize: 12, color: cfg.color }}>
                  ⚠️ Bu ma'lumotni noto'g'ri joyga joylashtirishdan saqlaning. Clipboard'ni tozalang.
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* === NETWORK CONNECTIONS === */}
      <div style={{ marginBottom: 16 }}>
        <div className="section-title">
          <span>🌐</span> Aktiv Tarmoq Ulanishlari
          {loadingConn && <span style={{ fontSize: 12, color: "var(--text-muted)", marginLeft: 8 }}>yangilanmoqda...</span>}
        </div>

        {/* Summary */}
        {connections.length > 0 && (
          <div className="stats-grid" style={{ marginBottom: 16 }}>
            <div className="glass-card stat-card" style={{ borderTop: "2px solid #ff4757" }}>
              <span className="stat-icon">🚨</span>
              <div className="stat-value" style={{ color: "#ff4757" }}>{dangerConns.length}</div>
              <div className="stat-label">Xavfli</div>
            </div>
            <div className="glass-card stat-card" style={{ borderTop: "2px solid #ffa502" }}>
              <span className="stat-icon">⚠️</span>
              <div className="stat-value" style={{ color: "#ffa502" }}>{warnConns.length}</div>
              <div className="stat-label">Shubhali</div>
            </div>
            <div className="glass-card stat-card" style={{ borderTop: "2px solid #2ed573" }}>
              <span className="stat-icon">✅</span>
              <div className="stat-value" style={{ color: "#2ed573" }}>{safeConns.length}</div>
              <div className="stat-label">Xavfsiz</div>
            </div>
            <div className="glass-card stat-card">
              <span className="stat-icon">🔗</span>
              <div className="stat-value">{connections.length}</div>
              <div className="stat-label">Jami</div>
            </div>
          </div>
        )}

        {/* Connection list — danger first */}
        {[...dangerConns, ...warnConns, ...safeConns].map((conn, i) => {
          const cfg = RISK_CONFIG[conn.risk] || RISK_CONFIG.safe;
          return (
            <div key={i} className="glass-card" style={{
              padding: "12px 16px", marginBottom: 8,
              borderLeft: `3px solid ${cfg.color}`,
            }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 8 }}>
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span>{cfg.icon}</span>
                    <strong style={{ fontSize: 13, color: cfg.color }}>{conn.process_name}</strong>
                    <span style={{ fontSize: 11, color: "var(--text-muted)" }}>PID: {conn.pid}</span>
                    <span style={{ fontSize: 10, padding: "2px 6px", borderRadius: 4,
                      background: cfg.bg, color: cfg.color, fontWeight: 700 }}>
                      {cfg.label}
                    </span>
                  </div>
                  <div style={{ fontSize: 12, color: "var(--text-muted)", marginTop: 4 }}>
                    <span style={{ fontFamily: "monospace" }}>{conn.local_addr}</span>
                    <span style={{ margin: "0 6px" }}>→</span>
                    <span style={{ fontFamily: "monospace", color: conn.risk === "danger" ? "#ff4757" : "inherit" }}>
                      {conn.remote_addr}
                    </span>
                    <span style={{ marginLeft: 8, opacity: 0.7 }}>{conn.protocol} {conn.state}</span>
                  </div>
                  {conn.risk_reason && (
                    <div style={{ fontSize: 11, color: cfg.color, marginTop: 4 }}>
                      ⚡ {conn.risk_reason}
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}

        {connections.length === 0 && !monitoring && (
          <div className="glass-card" style={{ textAlign: "center", padding: 48 }}>
            <div style={{ fontSize: 48, marginBottom: 12 }}>🌐</div>
            <h3>Monitoringni boshlang</h3>
            <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
              Barcha aktif TCP/UDP ulanishlar, jarayonlar va xavf darajasi ko'rsatiladi.
              Clipboard sezgir ma'lumotlar: parol, karta, pasport, JWT token kuzatiladi.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
