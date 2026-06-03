import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';

export default function ProcessMonitor() {
  const [processes, setProcesses] = useState([]);
  const [startupItems, setStartupItems] = useState([]);
  const [activeTab, setActiveTab] = useState('processes'); // processes, startup
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
    const interval = setInterval(() => {
      if (activeTab === 'processes') {
        fetchProcesses();
      }
    }, 3000);
    return () => clearInterval(interval);
  }, [activeTab]);

  const fetchData = async () => {
    setLoading(true);
    await fetchProcesses();
    await fetchStartup();
    setLoading(false);
  };

  const fetchProcesses = async () => {
    try {
      const data = await invoke('get_process_tree');
      setProcesses(data);
    } catch (e) {
      console.error(e);
    }
  };

  const fetchStartup = async () => {
    try {
      const data = await invoke('monitor_startup_items');
      setStartupItems(data);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center bg-white/5 p-4 rounded-xl border border-white/10 backdrop-blur-md">
        <div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent drop-shadow-md">
            Jarayonlar va Avtoyuklanish
          </h2>
          <p className="text-gray-400 text-sm mt-1">
            Xavfli jarayonlar daraxti va yashirin avtoyuklanish dasturlarini tahlil qilish
          </p>
        </div>
        <div className="flex gap-2 bg-black/30 p-1 rounded-lg border border-white/5">
          <button
            onClick={() => setActiveTab('processes')}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              activeTab === 'processes' ? 'bg-white/10 text-white' : 'text-gray-400 hover:text-white'
            }`}
          >
            Jarayonlar Daraxti
          </button>
          <button
            onClick={() => setActiveTab('startup')}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              activeTab === 'startup' ? 'bg-white/10 text-white' : 'text-gray-400 hover:text-white'
            }`}
          >
            Avtoyuklanish (Startup)
          </button>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-10 text-gray-400">Tahlil qilinmoqda...</div>
      ) : activeTab === 'processes' ? (
        <div className="bg-white/5 rounded-xl border border-white/10 overflow-hidden">
          <table className="w-full text-left">
            <thead className="bg-white/5 border-b border-white/10 text-gray-400 text-sm">
              <tr>
                <th className="p-4 font-medium">Jarayon nomi (PID)</th>
                <th className="p-4 font-medium">Holati</th>
                <th className="p-4 font-medium">Tafsilotlar</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {processes.map((proc) => (
                <tr key={proc.pid} className={`hover:bg-white/5 transition-colors ${proc.is_suspicious ? 'bg-red-500/5' : ''}`}>
                  <td className="p-4">
                    <div className={`font-medium ${proc.is_suspicious ? 'text-red-400' : 'text-gray-200'}`}>
                      {proc.name}
                    </div>
                    <div className="text-xs text-gray-500 font-mono mt-1">
                      PID: {proc.pid} {proc.parent_pid && `| Parent: ${proc.parent_pid}`}
                    </div>
                  </td>
                  <td className="p-4">
                    {proc.is_suspicious ? (
                      <span className="px-2 py-1 bg-red-500/20 text-red-400 text-xs rounded border border-red-500/30 font-medium">
                        🚨 XAVFLI
                      </span>
                    ) : (
                      <span className="px-2 py-1 bg-green-500/10 text-green-400/70 text-xs rounded border border-green-500/20">
                        Xavfsiz
                      </span>
                    )}
                  </td>
                  <td className="p-4 text-sm">
                    {proc.is_suspicious ? (
                      <span className="text-red-300">{proc.reason}</span>
                    ) : (
                      <span className="text-gray-500">-</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="bg-white/5 rounded-xl border border-white/10 overflow-hidden">
          <table className="w-full text-left">
            <thead className="bg-white/5 border-b border-white/10 text-gray-400 text-sm">
              <tr>
                <th className="p-4 font-medium">Dastur Nomi</th>
                <th className="p-4 font-medium">Buyruq (Command)</th>
                <th className="p-4 font-medium">Joylashuvi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {startupItems.map((item, idx) => {
                const isSuspicious = item.command.toLowerCase().includes('powershell') || 
                                     item.command.toLowerCase().includes('cmd.exe') ||
                                     item.command.toLowerCase().includes('vbs');
                return (
                  <tr key={idx} className={`hover:bg-white/5 transition-colors ${isSuspicious ? 'bg-yellow-500/5' : ''}`}>
                    <td className="p-4 font-medium text-gray-200">
                      {item.name}
                      {isSuspicious && <span className="ml-2 text-xs bg-yellow-500/20 text-yellow-400 px-2 py-0.5 rounded">Shubhali</span>}
                    </td>
                    <td className="p-4 text-sm text-gray-400 font-mono break-all">
                      {item.command}
                    </td>
                    <td className="p-4 text-sm text-gray-500">
                      <span className="bg-white/10 px-2 py-1 rounded">{item.location}</span>
                    </td>
                  </tr>
                );
              })}
              {startupItems.length === 0 && (
                <tr>
                  <td colSpan="3" className="p-8 text-center text-gray-500">
                    Avtoyuklanishda dasturlar topilmadi.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
