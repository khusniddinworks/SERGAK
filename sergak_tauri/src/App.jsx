import { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";
import "./App.css";

import Sidebar      from "./components/Sidebar";
import Dashboard    from "./components/Dashboard";
import NetworkScanner from "./components/NetworkScanner";
import PhoneLink    from "./components/PhoneLink";
import Settings     from "./components/Settings";
import VulnScanner  from "./components/VulnScanner";
import DataGuard    from "./components/DataGuard";

function App() {
  const [activeTab,   setActiveTab]   = useState("home");
  const [deviceId,    setDeviceId]    = useState("Yuklanmoqda...");
  const [licenseKey,  setLicenseKey]  = useState("");
  const [isPremium,   setIsPremium]   = useState(false);
  const [cpu,         setCpu]         = useState(0);
  const [ram,         setRam]         = useState(0);
  const [moduleStates, setModuleStates] = useState({
    gateway: true, usb: true, camera: true, keylogger: true, honeypot: true,
  });

  useEffect(() => {
    // 1. Load saved license
    const saved = localStorage.getItem("sergak_premium");
    if (saved === "true") setIsPremium(true);

    // 2. Fetch real device ID from Windows registry
    invoke("get_device_id")
      .then(id => setDeviceId(id))
      .catch(() => setDeviceId("SRGK-UNKNOWN"));

    // 3. Load persisted module states
    invoke("get_module_states")
      .then(states => setModuleStates(prev => ({ ...prev, ...states })))
      .catch(() => {});

    // 4. System stats polling every 2 seconds
    const interval = setInterval(async () => {
      try {
        const [c, totR, usedR] = await invoke("get_system_stats");
        setCpu(c.toFixed(1));
        setRam(((usedR / totR) * 100).toFixed(1));
      } catch {
        // In dev mode without backend — show zeros (no fake random)
        setCpu(0);
        setRam(0);
      }
    }, 2000);

    return () => clearInterval(interval);
  }, []);

  const handleVerify = async () => {
    try {
      const valid = await invoke("verify_premium_key", { deviceId, key: licenseKey });
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

  const handleModuleToggle = async (key) => {
    const newVal = !moduleStates[key];
    setModuleStates(prev => ({ ...prev, [key]: newVal }));
    try {
      await invoke("set_module_state", { module: key, enabled: newVal });
    } catch {
      // Revert on failure
      setModuleStates(prev => ({ ...prev, [key]: !newVal }));
    }
  };

  const renderPage = () => {
    switch (activeTab) {
      case "home":
        return <Dashboard cpu={cpu} ram={ram} moduleStates={moduleStates} />;
      case "vuln":
        return <VulnScanner />;
      case "dataguard":
        return <DataGuard />;
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
            moduleStates={moduleStates}
            onModuleToggle={handleModuleToggle}
          />
        );
      default:
        return <Dashboard cpu={cpu} ram={ram} moduleStates={moduleStates} />;
    }
  };

  return (
    <div className="app-container">
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} isPremium={isPremium} />
      <div className="main-content">{renderPage()}</div>
    </div>
  );
}

export default App;
