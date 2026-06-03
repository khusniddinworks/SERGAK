import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';

export default function Quarantine() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchQuarantine();
  }, []);

  const fetchQuarantine = async () => {
    setLoading(true);
    try {
      const data = await invoke('list_quarantine');
      setItems(data);
    } catch (e) {
      console.error(e);
    }
    setLoading(false);
  };

  const handleRestore = async (id) => {
    try {
      const success = await invoke('restore_file', { id });
      if (success) {
        fetchQuarantine();
      } else {
        alert("Faylni tiklashda xatolik yuz berdi!");
      }
    } catch (e) {
      console.error(e);
    }
  };

  const handleDelete = async (id) => {
    if (!confirm("Faylni butunlay o'chirib yubormoqchimisiz?")) return;
    try {
      const success = await invoke('delete_quarantine', { id });
      if (success) {
        fetchQuarantine();
      } else {
        alert("Faylni o'chirishda xatolik yuz berdi!");
      }
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center bg-white/5 p-4 rounded-xl border border-white/10 backdrop-blur-md">
        <div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-yellow-400 to-orange-400 bg-clip-text text-transparent drop-shadow-md">
            Karantin
          </h2>
          <p className="text-gray-400 text-sm mt-1">
            Xavfli va shubhali fayllar shu yerda shifrlangan holatda saqlanadi
          </p>
        </div>
        <div className="text-right">
          <div className="text-3xl font-bold text-white">{items.length}</div>
          <div className="text-xs text-gray-400">Jami fayllar</div>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-10 text-gray-400">Yuklanmoqda...</div>
      ) : items.length === 0 ? (
        <div className="text-center py-20 bg-white/5 rounded-xl border border-white/10">
          <div className="text-4xl mb-4">🛡️</div>
          <h3 className="text-xl font-medium text-white mb-2">Karantin bo'sh</h3>
          <p className="text-gray-400">Tizimda xavfli fayllar topilmadi.</p>
        </div>
      ) : (
        <div className="bg-white/5 rounded-xl border border-white/10 overflow-hidden">
          <table className="w-full text-left">
            <thead className="bg-white/5 border-b border-white/10 text-gray-400 text-sm">
              <tr>
                <th className="p-4 font-medium">Tahdid Nomi</th>
                <th className="p-4 font-medium">Asl Joylashuvi</th>
                <th className="p-4 font-medium">Sana</th>
                <th className="p-4 font-medium text-right">Amallar</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {items.map((item) => (
                <tr key={item.id} className="hover:bg-white/5 transition-colors">
                  <td className="p-4">
                    <div className="font-medium text-red-400">{item.threat_name}</div>
                    <div className="text-xs text-gray-500 font-mono mt-1" title="SHA-256 Hash">
                      {item.sha256.substring(0, 16)}...
                    </div>
                  </td>
                  <td className="p-4">
                    <div className="text-sm text-gray-300 break-all">{item.original_path}</div>
                  </td>
                  <td className="p-4 text-sm text-gray-400">
                    {new Date(item.date_added).toLocaleString('uz-UZ')}
                  </td>
                  <td className="p-4 text-right space-x-2">
                    <button 
                      onClick={() => handleRestore(item.id)}
                      className="px-3 py-1.5 bg-blue-500/20 hover:bg-blue-500/30 text-blue-400 rounded-lg text-sm transition-colors"
                    >
                      Tiklash
                    </button>
                    <button 
                      onClick={() => handleDelete(item.id)}
                      className="px-3 py-1.5 bg-red-500/20 hover:bg-red-500/30 text-red-400 rounded-lg text-sm transition-colors"
                    >
                      O'chirish
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
