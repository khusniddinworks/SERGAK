import { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";
import "./App.css";

import Sidebar from "./components/Sidebar";
import Dashboard from "./components/Dashboard";
import NetworkScanner from "./components/NetworkScanner";
import PhoneLink from "./components/PhoneLink";
import Settings from "./components/Settings";

function App() {
  const [activeTab, setActiveTab] = useState("home");
  const [deviceId, setDeviceId] = useState("SRGK-WIND-9X82");
  const [licenseKey, setLicenseKey] = useState("");
  const [isPremium, setIsPremium] = useState(false);
  const [cpu, setCpu] = useState(0);
  const [ram, setRam] = useState(0);

  useEffect(() => {
    // Check locally saved license on boot
    const saved = localStorage.getItem("sergak_premium");
    if (saved === "true") {
      setIsPremium(true);
    }

    // Refresh system stats every 2 seconds via Rust backend
    const interval = setInterval(async () => {
      try {
        const [c, totR, usedR] = await invoke("get_system_stats");
        setCpu(c.toFixed(1));
        setRam(((usedR / totR) * 100).toFixed(1));
      } catch (e) {
        // Fallback for dev mode without Tauri backend
        setCpu((Math.random() * 30 + 10).toFixed(1));
        setRam((Math.random() * 20 + 40).toFixed(1));
      }
    }, 2000);

    return () => clearInterval(interval);
  }, []);

  const handleVerify = async () => {
    try {
      const valid = await invoke("verify_premium_key", {
        deviceId,
        key: licenseKey,
      });
      if (valid) {
        setIsPremium(true);
        localStorage.setItem("sergak_premium", "true");
        alert("🎉 Premium faollashtirildi!");
      } else {
        alert("❌ Noto'g'ri kalit yoki kalit muddati tugagan!");
      }
    } catch (e) {
      alert("Xatolik yuz berdi: " + e);
    }
  };

  const renderPage = () => {
    switch (activeTab) {
      case "home":
        return <Dashboard cpu={cpu} ram={ram} />;
      case "network":
        return <NetworkScanner />;
      case "phone":
        return <PhoneLink />;
      case "settings":
        return (
          <Settings
            deviceId={deviceId}
            licenseKey={licenseKey}
            setLicenseKey={setLicenseKey}
            isPremium={isPremium}
            onVerify={handleVerify}
          />
        );
      default:
        return <Dashboard cpu={cpu} ram={ram} />;
    }
  };

  return (
    <div className="app-container">
      <Sidebar
        activeTab={activeTab}
        onTabChange={setActiveTab}
        isPremium={isPremium}
      />
      <div className="main-content">{renderPage()}</div>
    </div>
  );
}

export default App;
