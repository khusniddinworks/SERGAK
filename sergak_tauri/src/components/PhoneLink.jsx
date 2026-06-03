import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { QRCodeSVG } from 'qrcode.react';

export default function PhoneLink() {
  const [phoneState, setPhoneState] = useState({
    is_connected: false,
    device_name: null,
    connection_time: null,
  });
  const [qrData, setQrData] = useState(null);

  useEffect(() => {
    checkStatus();
    const interval = setInterval(checkStatus, 3000);
    return () => clearInterval(interval);
  }, []);

  const checkStatus = async () => {
    try {
      const state = await invoke('get_connected_phone');
      setPhoneState(state);
    } catch (e) {
      console.error(e);
    }
  };

  const startServer = async () => {
    try {
      const data = await invoke('start_websocket_server');
      setQrData(data);
    } catch (e) {
      alert("Server xatosi: " + e);
    }
  };

  const disconnect = async () => {
    await invoke('disconnect_phone');
    checkStatus();
  };

  return (
    <div className="space-y-6">
      <div className="bg-white/5 p-6 rounded-2xl border border-white/10 text-center">
        <h2 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent drop-shadow-md">
          PhoneLink — Mobil Boshqaruv
        </h2>
        <p className="text-gray-400 mt-2">
          Kompyuterni mobil telefoningiz orqali masofadan himoya qiling va qulflang
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* QR KOD QISMI */}
        <div className="bg-white/5 p-6 rounded-2xl border border-white/10 flex flex-col items-center justify-center min-h-[300px]">
          {phoneState.is_connected ? (
            <div className="text-center">
              <div className="text-6xl mb-4">📱</div>
              <h3 className="text-xl font-bold text-green-400 mb-1">Qurilma Ulangan</h3>
              <p className="text-gray-400">Mobil telefoningiz tizimga ulandi.</p>
            </div>
          ) : qrData ? (
            <div className="flex flex-col items-center">
              <div className="bg-white p-4 rounded-xl mb-4">
                <QRCodeSVG 
                  value={`sergak://${qrData.ip}:${qrData.port}/${qrData.otp}`}
                  size={200}
                  level={"M"}
                  includeMargin={false}
                />
              </div>
              <p className="text-gray-300 font-medium mb-1">Mobil ilovadan skanerlang</p>
              <div className="font-mono text-xs text-blue-400/80 bg-blue-500/10 px-3 py-1 rounded">
                IP: {qrData.ip}:{qrData.port} | KOD: {qrData.otp}
              </div>
            </div>
          ) : (
            <div className="text-center">
              <div className="text-5xl mb-4 opacity-50">📡</div>
              <button 
                onClick={startServer}
                className="bg-blue-600 hover:bg-blue-500 text-white font-medium py-3 px-6 rounded-xl transition-all shadow-lg shadow-blue-500/20"
              >
                QR Kod Yaratish
              </button>
              <p className="text-xs text-gray-500 mt-4">Telefoningiz kompyuter bilan bir xil Wi-Fi tarmog'ida bo'lishi kerak</p>
            </div>
          )}
        </div>

        {/* STATUS QISMI */}
        <div className="bg-white/5 p-6 rounded-2xl border border-white/10 flex flex-col">
          <h3 className="font-bold text-xl mb-4 text-white">Ulanish Holati</h3>
          
          <div className="flex-1 space-y-4">
            <div className="bg-black/30 p-4 rounded-xl border border-white/5">
              <div className="text-sm text-gray-500 mb-1">Qurilma Nomi</div>
              <div className="font-medium text-lg text-gray-200">
                {phoneState.device_name || "Ulanmagan"}
              </div>
            </div>
            
            <div className="bg-black/30 p-4 rounded-xl border border-white/5">
              <div className="text-sm text-gray-500 mb-1">Ulanish Vaqti</div>
              <div className="font-medium text-gray-200">
                {phoneState.connection_time || "-"}
              </div>
            </div>
          </div>

          <div className="mt-6 pt-6 border-t border-white/10">
            <button 
              onClick={disconnect}
              disabled={!phoneState.is_connected}
              className={`w-full py-3 rounded-xl font-medium transition-colors ${
                phoneState.is_connected 
                ? 'bg-red-500/20 text-red-400 hover:bg-red-500/30 border border-red-500/50' 
                : 'bg-white/5 text-gray-500 cursor-not-allowed border border-white/10'
              }`}
            >
              Uzib qo'yish
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
