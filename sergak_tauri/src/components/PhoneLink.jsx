import React, { useState } from "react";

const phoneActions = [
  {
    icon: "🔔",
    title: "Bildirishnomalar",
    desc: "Telefondagi barcha bildirishnomalarni real vaqtda kompyuterda ko'ring",
  },
  {
    icon: "🚫",
    title: "SMS Bloklash",
    desc: "Shubhali SMS xabarlarni kompyuterdan turib bloklang",
  },
  {
    icon: "🔒",
    title: "Masofaviy Qulflash",
    desc: "Yo'qolgan telefoningizni masofadan qulflang",
  },
  {
    icon: "📸",
    title: "Kamera Himoyasi",
    desc: "Telefon kamerasini ruxsatsiz foydalanishdan himoyalang",
  },
  {
    icon: "🗑️",
    title: "Ma'lumotlarni O'chirish",
    desc: "O'g'irlangan telefondagi ma'lumotlarni masofadan o'chirish",
  },
  {
    icon: "📍",
    title: "Joylashuvni Kuzatish",
    desc: "Yo'qolgan telefonni oflayn Wi-Fi orqali topish",
  },
];

export default function PhoneLink() {
  const [connected, setConnected] = useState(false);

  const handleConnect = () => {
    setConnected((prev) => !prev);
  };

  return (
    <div className="page-enter">
      <div className="page-header">
        <h1>📱 Phone Link (P2P)</h1>
        <p>
          Telefoningizni xavfsiz Wi-Fi Direct orqali ulab, kompyuterdan boshqaring
        </p>
      </div>

      <div className="glass-card phone-connect-area">
        {/* Phone visual */}
        <div className={`phone-visual ${connected ? "connected" : ""}`}>
          {connected ? "📱" : "📴"}
        </div>

        {/* Connection animation */}
        <div className="connection-dots">
          <span className="dot" />
          <span className="dot" />
          <span className="dot" />
        </div>

        <h3 style={{ marginBottom: 6 }}>
          {connected ? (
            <span className="text-success">Telefon Ulangan</span>
          ) : (
            "Hech qanday qurilma ulanmagan"
          )}
        </h3>
        <p className="text-muted mb-md" style={{ fontSize: 13 }}>
          {connected
            ? "SERGAK Android ilovasi orqali P2P ulanish o'rnatildi"
            : "Ulash uchun telefonda SERGAK ilovasini oching va QR kodni skanerlang"}
        </p>

        <button
          className={`btn ${connected ? "btn-danger" : "btn-primary"} btn-lg`}
          onClick={handleConnect}
        >
          {connected ? "🔌 Ulanishni Uzish" : "📶 Ulanishni Boshlash"}
        </button>
      </div>

      {/* Action Cards */}
      <div className="section-title mt-lg">
        <span>⚡</span> Boshqaruv Funksiyalari
      </div>
      <div className="phone-actions stagger">
        {phoneActions.map((action, i) => (
          <div key={i} className="glass-card phone-action-card">
            <span className="action-icon">{action.icon}</span>
            <h4>{action.title}</h4>
            <p>{action.desc}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
