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
import AiAssistant  from "./components/AiAssistant";
import Quarantine   from "./components/Quarantine";
import FsMonitor    from "./components/FsMonitor";
import ProcessMonitor from "./components/ProcessMonitor";

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
  const [showOllamaModal, setShowOllamaModal] = useState(false);

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

    // 5. Check Ollama Installation
    invoke("check_ollama_status")
      .then(status => {
        if (!status.is_installed) {
          setShowOllamaModal(true);
        } else if (!status.is_running) {
          invoke("start_ollama_service");
        }
      })
      .catch(() => {});

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
      case "fsmonitor":
        return <FsMonitor />;
      case "processes":
        return <ProcessMonitor />;
      case "network":
        return <NetworkScanner />;
      case "ai":
        return <AiAssistant />;
      case "quarantine":
        return <Quarantine />;
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
      {showOllamaModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div className="bg-[#1a1f2e] border border-blue-500/30 p-8 rounded-2xl shadow-2xl max-w-md w-full text-center">
            <div className="text-6xl mb-4">🤖</div>
            <h2 className="text-2xl font-bold text-white mb-2">Ollama Talab Qilinadi</h2>
            <p className="text-gray-300 mb-6">
              SERGAK sun'iy idroki ishlashi uchun kompyuteringizda Ollama o'rnatilgan bo'lishi kerak. 
              Iltimos, rasmiy saytdan yuklab oling va o'rnating. Qolgan jarayonlarni (model yuklash) o'zimiz bajaramiz.
            </p>
            <div className="space-y-3">
              <a 
                href="https://ollama.com/download" 
                target="_blank" 
                rel="noreferrer"
                className="block w-full bg-blue-600 hover:bg-blue-500 text-white font-semibold py-3 px-4 rounded-xl transition-colors"
              >
                Yuklab Olish (ollama.com)
              </a>
              <button 
                onClick={() => {
                  invoke("check_ollama_status").then(s => {
                    if(s.is_installed) setShowOllamaModal(false);
                    else alert("Ollama hali o'rnatilmagan yoki ishga tushmagan!");
                  });
                }}
                className="w-full bg-white/10 hover:bg-white/20 text-white font-medium py-3 px-4 rounded-xl transition-colors"
              >
                O'rnatdim, davom etish
              </button>
            </div>
          </div>
        </div>
      )}
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} isPremium={isPremium} />
      <div className="main-content">{renderPage()}</div>
    </div>
  );
}

export default App;
