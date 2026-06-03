import React, { useState } from "react";
import { invoke } from "@tauri-apps/api/core";

export default function NetworkScanner() {
  const [scanning,  setScanning]  = useState(false);
  const [scanDone,  setScanDone]  = useState(false);
  const [devices,   setDevices]   = useState([]);
  const [target,    setTarget]    = useState("192.168.1.0/24");
  const [scanTime,  setScanTime]  = useState(null);

  const handleScan = async () => {
    setScanning(true);
    setScanDone(false);
    setDevices([]);
    const t0 = Date.now();
    try {
      // Real ARP scan via Rust backend
      const result = await invoke("scan_network", { target });
      setDevices(result);
      setScanDone(true);
      setScanTime(((Date.now() - t0) / 1000).toFixed(1));
    } catch (e) {
      alert("Skaner xatosi: " + e);
    } finally {
      setScanning(false);
    }
  };

  const unknownCount = devices.filter(d => d.status === "unknown").length;

  return (
    <div className="page-enter">
      <div className="page-header">
        <h1>🌐 Tarmoq Skaneri</h1>
        <p>Mahalliy tarmoqda ulangan barcha qurilmalarni ARP orqali aniqlash va tahlil qilish</p>
      </div>

      {/* Controls */}
      <div className="scanner-controls">
        <input
          className="scan-input"
          type="text"
          value={target}
          onChange={(e) => setTarget(e.target.value)}
          placeholder="IP yoki tarmoq diapazoni (masalan, 192.168.1.0/24)"
          disabled={scanning}
        />
        <button
          className="btn btn-primary btn-lg"
          onClick={handleScan}
          disabled={scanning}
        >
          {scanning ? "⏳ Skanerlanmoqda..." : "🔍 Skanerlash"}
        </button>
      </div>

      {/* Info note */}
      <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 16, padding: "8px 12px",
        background: "rgba(255,255,255,0.03)", borderRadius: 8, border: "1px solid var(--border)" }}>
        ℹ️ Skaner ARP jadvali va ping orqali ishlaydi. Natijalar 1-3 daqiqa olishi mumkin.
        {scanTime && <span style={{ color: "var(--accent)", marginLeft: 8 }}>✅ {scanTime} soniyada yakunlandi</span>}
      </div>

      {/* Scan Animation */}
      {(scanning || !scanDone) && (
        <div className={`scan-ring ${scanning ? "scanning" : ""}`}>
          <div className="scan-center-text">
            <span className="scan-icon">{scanning ? "📡" : "🔍"}</span>
            <span className="scan-status">
              {scanning ? "ARP va ping skanerlanmoqda..." : "Boshlash uchun tugmani bosing"}
            </span>
          </div>
        </div>
      )}

      {/* Summary */}
      {scanDone && (
        <div className="stats-grid" style={{ marginBottom: 16 }}>
          <div className="glass-card stat-card">
            <span className="stat-icon">🔗</span>
            <div className="stat-value val-accent">{devices.length}</div>
            <div className="stat-label">Jami Qurilma</div>
          </div>
          <div className="glass-card stat-card">
            <span className="stat-icon">✅</span>
            <div className="stat-value val-success">{devices.length - unknownCount}</div>
            <div className="stat-label">Xavfsiz</div>
          </div>
          <div className="glass-card stat-card">
            <span className="stat-icon">❓</span>
            <div className="stat-value" style={{ color: unknownCount > 0 ? "#ffa502" : "#2ed573" }}>{unknownCount}</div>
            <div className="stat-label">Noma'lum</div>
          </div>
        </div>
      )}

      {/* Results */}
      {scanDone && devices.length > 0 && (
        <>
          <div className="section-title mt-lg">
            <span>📊</span> Natijalar — {devices.length} ta qurilma topildi
          </div>
          <div className="network-grid stagger">
            {devices.map((d, i) => (
              <div key={i} className="glass-card device-card"
                style={{ borderLeft: `3px solid ${d.status === "unknown" ? "#ffa502" : "#2ed573"}` }}>
                <div className={`device-avatar ${d.status}`}>{d.device_type}</div>
                <div className="device-info">
                  <h4>{d.name}</h4>
                  <span className="device-ip">{d.ip} • {d.mac}</span>
                </div>
                <span className={`device-status ${d.status}`}>
                  {d.status === "safe" ? "XAVFSIZ" : "NOMA'LUM"}
                </span>
              </div>
            ))}
          </div>
        </>
      )}

      {scanDone && devices.length === 0 && (
        <div className="glass-card" style={{ textAlign: "center", padding: 32 }}>
          <div style={{ fontSize: 40, marginBottom: 8 }}>📡</div>
          <p>Hech qanday qurilma topilmadi. Tarmoq diapazonini tekshiring.</p>
        </div>
      )}
    </div>
  );
}
