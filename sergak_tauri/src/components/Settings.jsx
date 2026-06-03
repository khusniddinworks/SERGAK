import React, { useState } from "react";

export default function Settings({
  deviceId,
  licenseKey,
  setLicenseKey,
  isPremium,
  onVerify,
}) {
  const [toggles, setToggles] = useState({
    gateway: true,
    usb: true,
    camera: true,
    keylogger: true,
    honeypot: true,
    autoStart: false,
  });

  const toggle = (key) => {
    setToggles((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="page-enter">
      <div className="page-header">
        <h1>⚙️ Sozlamalar</h1>
        <p>Premium versiyani faollashtirish va xavfsizlik modullarini sozlash</p>
      </div>

      <div className="settings-grid">
        {/* License Card */}
        <div className="glass-card settings-card">
          <h3>🔑 Litsenziya Faollashtirish</h3>
          <p className="card-desc">
            Saytdan xarid qilingan Premium kalitni quyidagi maydonga kiriting.
            Kalitingiz Device ID ga bog'langan.
          </p>

          <div className="input-group">
            <label>Sizning Device ID</label>
            <input
              type="text"
              className="glass-input"
              value={deviceId}
              readOnly
            />
          </div>

          <div className="input-group">
            <label>Premium Kalitni Kiriting</label>
            <input
              type="text"
              className="glass-input"
              placeholder="SRGK-XXXX-XXXX-XXXX..."
              value={licenseKey}
              onChange={(e) => setLicenseKey(e.target.value)}
            />
          </div>

          <button className="btn btn-primary btn-full mt-sm" onClick={onVerify}>
            <span className="btn-icon">✨</span>
            {isPremium ? "Kalitni Yangilash" : "Kalitni Tekshirish"}
          </button>

          {isPremium && (
            <div
              className="text-success mt-md"
              style={{ fontSize: 13, textAlign: "center", fontWeight: 600 }}
            >
              ✅ Premium versiya faol!
            </div>
          )}
        </div>

        {/* Security Toggles */}
        <div className="glass-card settings-card">
          <h3>🔐 Xavfsizlik Modullari</h3>
          <p className="card-desc">
            Har bir modul alohida yoqilishi yoki o'chirilishi mumkin.
          </p>

          <div className="toggle-row">
            <div className="toggle-label">
              <span className="t-title">Kiber Darvoza (DNS Blocker)</span>
              <span className="t-desc">Zararli saytlarni bloklash</span>
            </div>
            <button
              className={`toggle-switch ${toggles.gateway ? "on" : ""}`}
              onClick={() => toggle("gateway")}
            />
          </div>

          <div className="toggle-row">
            <div className="toggle-label">
              <span className="t-title">USB Qalqoni</span>
              <span className="t-desc">Tashqi qurilmalarni skanerlash</span>
            </div>
            <button
              className={`toggle-switch ${toggles.usb ? "on" : ""}`}
              onClick={() => toggle("usb")}
            />
          </div>

          <div className="toggle-row">
            <div className="toggle-label">
              <span className="t-title">Kamera / Mikrofon Himoyasi</span>
              <span className="t-desc">Privacy Guard moduli</span>
            </div>
            <button
              className={`toggle-switch ${toggles.camera ? "on" : ""}`}
              onClick={() => toggle("camera")}
            />
          </div>

          <div className="toggle-row">
            <div className="toggle-label">
              <span className="t-title">Anti-Keylogger</span>
              <span className="t-desc">Klaviatura himoyachisi</span>
            </div>
            <button
              className={`toggle-switch ${toggles.keylogger ? "on" : ""}`}
              onClick={() => toggle("keylogger")}
            />
          </div>

          <div className="toggle-row">
            <div className="toggle-label">
              <span className="t-title">Ransomware Qopqon</span>
              <span className="t-desc">Honeypot fayllar kuzatuvi</span>
            </div>
            <button
              className={`toggle-switch ${toggles.honeypot ? "on" : ""}`}
              onClick={() => toggle("honeypot")}
            />
          </div>

          <div className="toggle-row">
            <div className="toggle-label">
              <span className="t-title">Windows bilan birga ishga tushish</span>
              <span className="t-desc">SERGAK avtomatik yuklansin</span>
            </div>
            <button
              className={`toggle-switch ${toggles.autoStart ? "on" : ""}`}
              onClick={() => toggle("autoStart")}
            />
          </div>
        </div>

        {/* About */}
        <div className="glass-card settings-card">
          <h3>ℹ️ Ilova Haqida</h3>
          <p className="card-desc">
            SERGAK PC — O'zbekistonlik dasturchilar tomonidan yaratilgan zamonaviy
            kiberxavfsizlik tizimi.
          </p>

          <div className="toggle-row">
            <span className="t-title">Versiya</span>
            <span className="text-accent text-mono">v2.0.0</span>
          </div>
          <div className="toggle-row">
            <span className="t-title">Platforma</span>
            <span className="text-muted text-mono">Tauri + React</span>
          </div>
          <div className="toggle-row">
            <span className="t-title">Yaratuvchi</span>
            <span className="text-muted">TAFU — Xavfsizlik Jamoasi</span>
          </div>
        </div>
      </div>
    </div>
  );
}
