import React, { useState } from "react";
import { invoke } from "@tauri-apps/api/core";

const SEVERITY_CONFIG = {
  critical: { label: "KRITIK",  color: "#ff4757", bg: "rgba(255,71,87,0.15)",  icon: "🚨" },
  high:     { label: "YUQORI",  color: "#ff6b35", bg: "rgba(255,107,53,0.15)", icon: "⚠️" },
  medium:   { label: "O'RTA",   color: "#ffa502", bg: "rgba(255,165,2,0.15)",  icon: "🔶" },
  low:      { label: "PAST",    color: "#2ed573", bg: "rgba(46,213,115,0.15)", icon: "ℹ️" },
  safe:     { label: "XAVFSIZ", color: "#2ed573", bg: "rgba(46,213,115,0.15)", icon: "✅" },
};

export default function VulnScanner() {
  const [scanning, setScanning]     = useState(false);
  const [vulns, setVulns]           = useState([]);
  const [fixing, setFixing]         = useState({});
  const [fixedIds, setFixedIds]     = useState(new Set());
  const [scanDone, setScanDone]     = useState(false);

  const handleScan = async () => {
    setScanning(true);
    setScanDone(false);
    setVulns([]);
    try {
      const result = await invoke("scan_vulnerabilities");
      setVulns(result);
      setScanDone(true);
    } catch (e) {
      alert("Skaner xatosi: " + e);
    } finally {
      setScanning(false);
    }
  };

  const handleFix = async (id) => {
    setFixing(prev => ({ ...prev, [id]: true }));
    try {
      const ok = await invoke("fix_vulnerability", { id });
      if (ok) {
        setFixedIds(prev => new Set([...prev, id]));
        setVulns(prev => prev.map(v => v.id === id ? { ...v, fixed: true } : v));
      } else {
        alert("Yopishda xatolik. Administrator sifatida ishga tushiring.");
      }
    } catch (e) {
      alert("Xatolik: " + e);
    } finally {
      setFixing(prev => ({ ...prev, [id]: false }));
    }
  };

  const handleFixAll = async () => {
    const fixable = vulns.filter(v => v.fixable && !fixedIds.has(v.id));
    for (const v of fixable) {
      await handleFix(v.id);
      await new Promise(r => setTimeout(r, 300));
    }
  };

  const criticalCount = vulns.filter(v => v.severity === "critical" && !fixedIds.has(v.id)).length;
  const highCount     = vulns.filter(v => v.severity === "high"     && !fixedIds.has(v.id)).length;
  const fixableCount  = vulns.filter(v => v.fixable && !fixedIds.has(v.id)).length;

  return (
    <div className="page-enter">
      <div className="page-header">
        <h1>🔍 Zaiflik Skaneri</h1>
        <p>Tizimda xavfsizlik zaifliklarini aniqlash va avtomatik yopish</p>
      </div>

      {/* Action Bar */}
      <div style={{ display: "flex", gap: 12, marginBottom: 24, flexWrap: "wrap" }}>
        <button
          className="btn btn-primary btn-lg"
          onClick={handleScan}
          disabled={scanning}
          style={{ flex: 1, minWidth: 200 }}
        >
          {scanning ? "⏳ Skanerlanmoqda..." : "🔍 Tizimni Skaner Qilish"}
        </button>

        {fixableCount > 0 && (
          <button
            className="btn btn-danger"
            onClick={handleFixAll}
            style={{ flex: 1, minWidth: 200, background: "rgba(255,71,87,0.2)", border: "1px solid #ff4757", color: "#ff4757" }}
          >
            🛠️ Barchasini Yop ({fixableCount} ta)
          </button>
        )}
      </div>

      {/* Scanning animation */}
      {scanning && (
        <div className="glass-card" style={{ textAlign: "center", padding: 40 }}>
          <div style={{ fontSize: 48, marginBottom: 16, animation: "spin 1s linear infinite" }}>🔍</div>
          <p style={{ color: "var(--text-muted)" }}>Tizim tekshirilmoqda... Iltimos kuting.</p>
          <p style={{ color: "var(--text-muted)", fontSize: 12 }}>
            Firewall, Defender, RDP, SMB, ochiq portlar va boshqalar...
          </p>
        </div>
      )}

      {/* Summary Cards */}
      {scanDone && (
        <div className="stats-grid" style={{ marginBottom: 24 }}>
          <div className="glass-card stat-card">
            <span className="stat-icon">🚨</span>
            <div className="stat-value" style={{ color: "#ff4757" }}>{criticalCount}</div>
            <div className="stat-label">Kritik Zaiflik</div>
          </div>
          <div className="glass-card stat-card">
            <span className="stat-icon">⚠️</span>
            <div className="stat-value" style={{ color: "#ff6b35" }}>{highCount}</div>
            <div className="stat-label">Yuqori Xavf</div>
          </div>
          <div className="glass-card stat-card">
            <span className="stat-icon">🛠️</span>
            <div className="stat-value" style={{ color: "#2ed573" }}>{fixedIds.size}</div>
            <div className="stat-label">Yopilgan</div>
          </div>
          <div className="glass-card stat-card">
            <span className="stat-icon">📋</span>
            <div className="stat-value" style={{ color: "var(--accent)" }}>{vulns.length}</div>
            <div className="stat-label">Jami Topildi</div>
          </div>
        </div>
      )}

      {/* Vulnerability List */}
      {scanDone && (
        <div className="section-title">
          <span>🛡️</span> Natijalar
        </div>
      )}

      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {vulns.map((v) => {
          const cfg = SEVERITY_CONFIG[v.severity] || SEVERITY_CONFIG.low;
          const isFixed = fixedIds.has(v.id) || v.fixed;
          return (
            <div
              key={v.id}
              className="glass-card"
              style={{
                padding: "16px 20px",
                borderLeft: `3px solid ${isFixed ? "#2ed573" : cfg.color}`,
                opacity: isFixed ? 0.7 : 1,
                transition: "all 0.3s ease",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 12 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                    <span style={{ fontSize: 18 }}>{isFixed ? "✅" : cfg.icon}</span>
                    <h4 style={{ margin: 0, fontSize: 14, color: isFixed ? "#2ed573" : "var(--text-primary)" }}>
                      {v.title}
                    </h4>
                    <span style={{
                      fontSize: 10, fontWeight: 700, padding: "2px 8px",
                      borderRadius: 4, background: isFixed ? "rgba(46,213,115,0.15)" : cfg.bg,
                      color: isFixed ? "#2ed573" : cfg.color
                    }}>
                      {isFixed ? "YOPILDI" : cfg.label}
                    </span>
                  </div>
                  <p style={{ margin: 0, fontSize: 12, color: "var(--text-muted)", lineHeight: 1.5 }}>
                    {v.description}
                  </p>
                </div>

                {v.fixable && !isFixed && (
                  <button
                    onClick={() => handleFix(v.id)}
                    disabled={fixing[v.id]}
                    style={{
                      background: cfg.bg, border: `1px solid ${cfg.color}`,
                      color: cfg.color, borderRadius: 8, padding: "8px 16px",
                      cursor: "pointer", fontSize: 12, fontWeight: 600,
                      whiteSpace: "nowrap", transition: "all 0.2s",
                      minWidth: 90,
                    }}
                  >
                    {fixing[v.id] ? "⏳..." : "🛠️ Yop"}
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {!scanning && !scanDone && (
        <div className="glass-card" style={{ textAlign: "center", padding: 48 }}>
          <div style={{ fontSize: 64, marginBottom: 16 }}>🛡️</div>
          <h3>Tizimni tekshirish uchun "Skaner Qilish" tugmasini bosing</h3>
          <p style={{ color: "var(--text-muted)", fontSize: 13 }}>
            Firewall, Defender, RDP, SMBv1, ochiq portlar, UAC va boshqa 10+ zaiflik tekshiriladi.
          </p>
        </div>
      )}
    </div>
  );
}
