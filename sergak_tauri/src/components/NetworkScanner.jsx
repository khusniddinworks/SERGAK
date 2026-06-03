import React, { useState, useEffect } from "react";

const mockDevices = [
  { name: "Bu Kompyuter",      ip: "192.168.1.2",   mac: "A4:5E:60:XX:XX:01", type: "💻", status: "safe" },
  { name: "Router / Gateway",  ip: "192.168.1.1",   mac: "C8:3A:35:XX:XX:00", type: "📡", status: "safe" },
  { name: "Android Telefon",   ip: "192.168.1.15",  mac: "F0:72:EA:XX:XX:12", type: "📱", status: "safe" },
  { name: "Smart TV",          ip: "192.168.1.20",  mac: "00:1A:2B:XX:XX:33", type: "📺", status: "safe" },
  { name: "Noma'lum Qurilma",  ip: "192.168.1.105", mac: "DE:AD:BE:EF:CA:FE", type: "❓", status: "unknown" },
];

export default function NetworkScanner() {
  const [scanning, setScanning] = useState(false);
  const [scanDone, setScanDone] = useState(false);
  const [devices, setDevices] = useState([]);
  const [target, setTarget] = useState("192.168.1.0/24");

  const handleScan = () => {
    setScanning(true);
    setScanDone(false);
    setDevices([]);
    // Simulate scanning
    setTimeout(() => {
      setScanning(false);
      setScanDone(true);
      setDevices(mockDevices);
    }, 3000);
  };

  return (
    <div className="page-enter">
      <div className="page-header">
        <h1>🌐 Tarmoq Skaneri</h1>
        <p>Mahalliy tarmoqda ulangan barcha qurilmalarni aniqlash va tahlil qilish</p>
      </div>

      {/* Controls */}
      <div className="scanner-controls">
        <input
          className="scan-input"
          type="text"
          value={target}
          onChange={(e) => setTarget(e.target.value)}
          placeholder="IP yoki tarmoq diapazoni (masalan, 192.168.1.0/24)"
        />
        <button
          className="btn btn-primary btn-lg"
          onClick={handleScan}
          disabled={scanning}
        >
          {scanning ? "⏳ Skanerlash..." : "🔍 Skanerlash"}
        </button>
      </div>

      {/* Scan Animation */}
      {(scanning || !scanDone) && (
        <div className={`scan-ring ${scanning ? "scanning" : ""}`}>
          <div className="scan-center-text">
            <span className="scan-icon">{scanning ? "📡" : "🔍"}</span>
            <span className="scan-status">
              {scanning ? "Skanerlanmoqda..." : "Boshlash uchun tugmani bosing"}
            </span>
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
              <div key={i} className="glass-card device-card">
                <div className={`device-avatar ${d.status}`}>{d.type}</div>
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
    </div>
  );
}
