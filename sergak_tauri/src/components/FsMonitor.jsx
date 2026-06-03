import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';

export default function FsMonitor() {
  const [alerts, setAlerts] = useState([]);
  const [isMonitoring, setIsMonitoring] = useState(false);
  const [dbStats, setDbStats] = useState({ total_hashes: 0, last_updated: 'Yuklanmoqda...' });

  useEffect(() => {
    fetchStats();
    let interval;
    if (isMonitoring) {
      invoke('start_fs_monitor');
      interval = setInterval(fetchAlerts, 2000);
    } else {
      invoke('stop_fs_monitor');
    }
    return () => {
      clearInterval(interval);
      invoke('stop_fs_monitor');
    };
  }, [isMonitoring]);

  const fetchAlerts = async () => {
    try {
      const data = await invoke('get_fs_alerts');
      setAlerts(data.reverse()); // Show newest first
    } catch (e) {
      console.error(e);
    }
  };

  const fetchStats = async () => {
    try {
      const stats = await invoke('get_hash_db_stats');
      setDbStats(stats);
    } catch (e) {}
  };

  const updateDb = async () => {
    setDbStats(prev => ({ ...prev, last_updated: 'Yangilanmoqda...' }));
    try {
      const msg = await invoke('update_hash_db');
      alert(msg);
      fetchStats();
    } catch (e) {
      alert("Xatolik yuz berdi: " + e);
      fetchStats();
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center bg-white/5 p-4 rounded-xl border border-white/10 backdrop-blur-md">
        <div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent drop-shadow-md">
            Fayl Tizimi Himoyasi
          </h2>
          <p className="text-gray-400 text-sm mt-1">
            Yangi va o'zgartirilgan fayllarni real vaqtda zararli dasturlarga tekshirish
          </p>
        </div>
        <div className="flex gap-4">
          <button 
            onClick={() => setIsMonitoring(!isMonitoring)}
            className={`px-4 py-2 rounded-xl font-medium transition-colors ${
              isMonitoring 
                ? 'bg-red-500/20 text-red-400 border border-red-500/50 hover:bg-red-500/30' 
                : 'bg-green-500/20 text-green-400 border border-green-500/50 hover:bg-green-500/30'
            }`}
          >
            {isMonitoring ? 'To\'xtatish' : 'Monitoringni Boshlash'}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-white/5 p-4 rounded-xl border border-white/10 flex items-center justify-between">
          <div>
            <div className="text-gray-400 text-sm mb-1">Hash Ma'lumotlar Bazasi</div>
            <div className="text-2xl font-bold text-white">{dbStats.total_hashes.toLocaleString()} ta xavf</div>
          </div>
          <div className="text-3xl">🦠</div>
        </div>
        <div className="bg-white/5 p-4 rounded-xl border border-white/10 flex items-center justify-between">
          <div>
            <div className="text-gray-400 text-sm mb-1">Oxirgi Yangilanish</div>
            <div className="text-md font-medium text-white">{dbStats.last_updated}</div>
          </div>
          <button 
            onClick={updateDb}
            className="text-sm bg-blue-500/20 text-blue-400 px-3 py-1.5 rounded-lg border border-blue-500/30 hover:bg-blue-500/30"
          >
            Yangilash
          </button>
        </div>
      </div>

      <div className="bg-white/5 rounded-xl border border-white/10 overflow-hidden">
        <div className="p-4 border-b border-white/10 bg-black/20 flex justify-between items-center">
          <h3 className="font-semibold text-white">Jonli Tarmoq (Live Feed)</h3>
          {isMonitoring && <span className="flex h-3 w-3"><span className="animate-ping absolute inline-flex h-3 w-3 rounded-full bg-blue-400 opacity-75"></span><span className="relative inline-flex rounded-full h-3 w-3 bg-blue-500"></span></span>}
        </div>
        
        {alerts.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            {isMonitoring ? 'Tizim kuzatilmoqda... Yangi fayllar paydo bo\'lsa shu yerda ko\'rsatiladi.' : 'Monitoring to\'xtatilgan'}
          </div>
        ) : (
          <div className="divide-y divide-white/5 max-h-[500px] overflow-y-auto">
            {alerts.map(alert => (
              <div key={alert.id} className={`p-4 transition-colors ${alert.is_threat ? 'bg-red-500/10' : 'hover:bg-white/5'}`}>
                <div className="flex justify-between items-start mb-2">
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-0.5 rounded text-xs font-medium uppercase ${alert.action === 'created' ? 'bg-green-500/20 text-green-400' : 'bg-yellow-500/20 text-yellow-400'}`}>
                      {alert.action}
                    </span>
                    <span className="font-mono text-sm text-gray-300 truncate max-w-md" title={alert.path}>
                      {alert.path}
                    </span>
                  </div>
                  <span className="text-xs text-gray-500">{new Date(alert.timestamp).toLocaleTimeString()}</span>
                </div>
                
                {alert.is_threat ? (
                  <div className="mt-2 p-2 bg-red-500/20 border border-red-500/30 rounded-lg flex items-center justify-between">
                    <div>
                      <div className="text-red-400 font-bold text-sm flex items-center gap-2">
                        <span>🚨 ZARARLI DASTUR TOPILDI:</span>
                        <span>{alert.threat_name}</span>
                      </div>
                      <div className="text-xs text-red-400/70 font-mono mt-1">Hash: {alert.sha256.substring(0, 32)}...</div>
                    </div>
                    <button 
                      onClick={() => invoke('quarantine_file', { originalPath: alert.path, threatName: alert.threat_name }).then(res => alert(res ? "Fayl karantinga olindi!" : "Xatolik"))}
                      className="bg-red-500 text-white px-3 py-1 rounded text-sm hover:bg-red-600 transition-colors shadow-lg"
                    >
                      Karantinga olish
                    </button>
                  </div>
                ) : (
                  <div className="text-xs text-green-400/70 font-mono mt-1 flex items-center gap-1">
                    <span>✅ Xavfsiz fayl</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
