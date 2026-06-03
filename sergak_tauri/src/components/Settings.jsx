import React, { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";

export default function Settings({
  deviceId,
  licenseKey,
  setLicenseKey,
  isPremium,
  onVerify,
  moduleStates,
  onModuleToggle,
}) {
  const [autoStart, setAutoStart] = useState(false);
  const [savingAutoStart, setSavingAutoStart] = useState(false);
  const [appVersion, setAppVersion] = useState("1.0.0");

  useEffect(() => {
    // Load real autostart status from Windows registry
    invoke("get_autostart")
      .then(val => setAutoStart(val))
      .catch(() => {});
  }, []);

  const handleAutoStartToggle = async () => {
    setSavingAutoStart(true);
    const newVal = !autoStart;
    try {
      const ok = await invoke("set_autostart", { enabled: newVal });
      if (ok) {
        setAutoStart(newVal);
      } else {
        alert("Xatolik: Administrator huquqi kerak bo'lishi mumkin.");
      }
    } catch (e) {
      alert("Xatolik: " + e);
    } finally {
      setSavingAutoStart(false);
    }
  };

  const MODULE_LABELS = {
    gateway:   { title: "Kiber Darvoza (DNS Blocker)", desc: "Zararli saytlarni bloklash" },
    usb:       { title: "USB Qalqoni",                 desc: "Tashqi qurilmalarni skanerlash" },
    camera:    { title: "Kamera / Mikrofon Himoyasi",  desc: "Privacy Guard moduli" },
    keylogger: { title: "Anti-Keylogger",              desc: "Klaviatura himoyachisi" },
    honeypot:  { title: "Ransomware Qopqon",           desc: "Honeypot fayllar kuzatuvi" },
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
              style={{ fontFamily: "monospace", fontSize: 13 }}
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
            <div className="text-success mt-md"
              style={{ fontSize: 13, textAlign: "center", fontWeight: 600 }}>
              ✅ Premium versiya faol!
            </div>
          )}
        </div>

        {/* Security Module Toggles — REAL backend calls */}
        <div className="glass-card settings-card">
          <h3>🔐 Xavfsizlik Modullari</h3>
          <p className="card-desc">
            Har bir modul alohida yoqilishi yoki o'chirilishi mumkin.
            O'zgarishlar darhol saqlanadi.
          </p>

          {Object.entries(MODULE_LABELS).map(([key, label]) => (
            <div key={key} className="toggle-row">
              <div className="toggle-label">
                <span className="t-title">{label.title}</span>
                <span className="t-desc">{label.desc}</span>
              </div>
              <button
                className={`toggle-switch ${moduleStates?.[key] !== false ? "on" : ""}`}
                onClick={() => onModuleToggle?.(key)}
                title={moduleStates?.[key] !== false ? "Yoqilgan — o'chirish uchun bosing" : "O'chirilgan — yoqish uchun bosing"}
              />
            </div>
          ))}

          {/* Autostart — Real Windows registry */}
          <div className="toggle-row" style={{ marginTop: 12, borderTop: "1px solid var(--border)", paddingTop: 12 }}>
            <div className="toggle-label">
              <span className="t-title">
                Windows bilan birga ishga tushish
                {savingAutoStart && <span style={{ fontSize: 11, color: "var(--text-muted)", marginLeft: 8 }}>saqlanmoqda...</span>}
              </span>
              <span className="t-desc">SERGAK avtomatik yuklansin (Registry: HKCU\Run)</span>
            </div>
            <button
              className={`toggle-switch ${autoStart ? "on" : ""}`}
              onClick={handleAutoStartToggle}
              disabled={savingAutoStart}
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
            <span className="text-accent text-mono">v1.0.0</span>
          </div>
          <div className="toggle-row">
            <span className="t-title">Platforma</span>
            <span className="text-muted text-mono">Tauri v2 + React</span>
          </div>
          <div className="toggle-row">
            <span className="t-title">Yaratuvchi</span>
            <span className="text-muted">TAFU — Xavfsizlik Jamoasi</span>
          </div>
          <div className="toggle-row">
            <span className="t-title">Litsenziya turi</span>
            <span className={isPremium ? "text-accent" : "text-muted"}>
              {isPremium ? "Premium ✅" : "Bepul rejim"}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
