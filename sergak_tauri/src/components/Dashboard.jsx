import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';

export default function Dashboard({ cpu, ram, moduleStates }) {
  const [securityScore, setSecurityScore] = useState(100);
  const [dbStats, setDbStats] = useState({ total_hashes: 0 });

  useEffect(() => {
    // Fetch DB stats
    invoke('get_hash_db_stats').then(stats => setDbStats(stats)).catch(() => {});
  }, []);

  useEffect(() => {
    // Calculate Security Score
    let score = 100;
    if (!moduleStates.gateway) score -= 15;
    if (!moduleStates.usb) score -= 10;
    if (!moduleStates.camera) score -= 5;
    if (!moduleStates.keylogger) score -= 20;
    
    // Check if FS Monitor is running (simulated here by checking if db has hashes, implies it's setup)
    if (dbStats.total_hashes === 0) score -= 10;

    setSecurityScore(Math.max(0, score));
  }, [moduleStates, dbStats]);

  const getScoreColor = () => {
    if (securityScore >= 90) return "from-green-400 to-emerald-600";
    if (securityScore >= 60) return "from-yellow-400 to-orange-500";
    return "from-red-500 to-rose-700";
  };

  return (
    <div className="space-y-6">
      {/* HEADER STATS */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Security Score */}
        <div className="bg-white/5 p-6 rounded-3xl border border-white/10 flex flex-col items-center justify-center relative overflow-hidden group">
          <div className={`absolute inset-0 bg-gradient-to-br ${getScoreColor()} opacity-0 group-hover:opacity-10 transition-opacity duration-500`}></div>
          <h3 className="text-gray-400 text-sm font-medium mb-2 z-10">Xavfsizlik Darajasi</h3>
          <div className="relative w-32 h-32 flex items-center justify-center z-10">
            <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
              <circle cx="50" cy="50" r="45" fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="8" />
              <circle 
                cx="50" 
                cy="50" 
                r="45" 
                fill="none" 
                stroke={securityScore >= 90 ? "#10b981" : securityScore >= 60 ? "#f59e0b" : "#ef4444"} 
                strokeWidth="8" 
                strokeDasharray={`${(securityScore / 100) * 283} 283`}
                className="transition-all duration-1000 ease-out drop-shadow-[0_0_8px_rgba(16,185,129,0.5)]"
              />
            </svg>
            <div className="absolute flex flex-col items-center">
              <span className="text-4xl font-bold text-white tracking-tighter">{securityScore}</span>
              <span className="text-xs text-gray-400">%</span>
            </div>
          </div>
        </div>

        {/* System Load */}
        <div className="md:col-span-2 bg-white/5 p-6 rounded-3xl border border-white/10 flex flex-col justify-between relative overflow-hidden">
          <div className="absolute right-0 top-0 w-64 h-64 bg-blue-500/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>
          <div>
            <h3 className="text-gray-400 text-sm font-medium mb-6">Tizim Yuklanishi</h3>
            <div className="space-y-6">
              <div>
                <div className="flex justify-between text-sm mb-2">
                  <span className="text-white font-medium flex items-center gap-2"><span className="text-blue-400">⚡</span> CPU</span>
                  <span className="text-gray-400">{cpu}%</span>
                </div>
                <div className="w-full bg-white/5 rounded-full h-3 overflow-hidden border border-white/5">
                  <div className="bg-gradient-to-r from-blue-500 to-cyan-400 h-3 rounded-full transition-all duration-500" style={{ width: `${cpu}%` }}></div>
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-2">
                  <span className="text-white font-medium flex items-center gap-2"><span className="text-purple-400">🧠</span> RAM</span>
                  <span className="text-gray-400">{ram}%</span>
                </div>
                <div className="w-full bg-white/5 rounded-full h-3 overflow-hidden border border-white/5">
                  <div className="bg-gradient-to-r from-purple-500 to-pink-400 h-3 rounded-full transition-all duration-500" style={{ width: `${ram}%` }}></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* QUICK ACTIONS */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Tizim Skaneri', icon: '🔍', color: 'bg-blue-500/20 text-blue-400' },
          { label: 'Fayl Skaneri', icon: '📁', color: 'bg-emerald-500/20 text-emerald-400' },
          { label: 'AI Yordamchi', icon: '🤖', color: 'bg-purple-500/20 text-purple-400' },
          { label: 'PhoneLink', icon: '📱', color: 'bg-pink-500/20 text-pink-400' }
        ].map((item, i) => (
          <div key={i} className="bg-white/5 hover:bg-white/10 p-4 rounded-2xl border border-white/10 cursor-pointer transition-all hover:scale-105 hover:shadow-lg flex flex-col items-center justify-center text-center group">
            <div className={`w-12 h-12 rounded-xl ${item.color} flex items-center justify-center text-2xl mb-3 transition-transform group-hover:-translate-y-1`}>
              {item.icon}
            </div>
            <span className="text-sm font-medium text-gray-300">{item.label}</span>
          </div>
        ))}
      </div>

      {/* PROTECTION MODULES */}
      <div className="bg-white/5 rounded-3xl border border-white/10 p-6 relative overflow-hidden">
        <h3 className="text-white font-bold text-lg mb-4 flex items-center gap-2">
          <span>🛡️</span> Faol Himoya Modullari
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[
            { id: 'gateway', name: 'Tarmoq Gateway', icon: '🌐' },
            { id: 'usb', name: 'USB Qalqon', icon: '💾' },
            { id: 'keylogger', name: 'Anti-Keylogger', icon: '⌨️' },
            { id: 'camera', name: 'Kamera Himoyasi', icon: '📷' },
            { id: 'honeypot', name: 'Honeypot (Qopqon)', icon: '🍯' },
          ].map(mod => {
            const isActive = moduleStates[mod.id];
            return (
              <div key={mod.id} className="flex items-center justify-between p-3 rounded-xl bg-black/20 border border-white/5">
                <div className="flex items-center gap-3">
                  <span className="text-xl">{mod.icon}</span>
                  <span className="text-sm font-medium text-gray-300">{mod.name}</span>
                </div>
                <div className={`w-2.5 h-2.5 rounded-full ${isActive ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.8)]' : 'bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.8)]'}`}></div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
