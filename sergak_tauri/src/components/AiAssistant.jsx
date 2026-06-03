import { useState, useEffect, useRef } from 'react';
import { invoke } from '@tauri-apps/api/core';

export default function AiAssistant() {
  const [messages, setMessages] = useState([
    { role: 'assistant', content: 'Salom! Men SERGAK AI yordamchisiman. Tizimdagi tahdidlar yoki xavfsizlik haqida savollaringiz bormi?' }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState({ is_installed: false, is_running: false, has_llama3_2: false });
  const messagesEndRef = useRef(null);

  useEffect(() => {
    checkStatus();
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const checkStatus = async () => {
    try {
      const st = await invoke('check_ollama_status');
      setStatus(st);
    } catch (e) {
      console.error(e);
    }
  };

  const handleSend = async () => {
    if (!input.trim() || loading) return;
    const userMsg = input.trim();
    setMessages(prev => [...prev, { role: 'user', content: userMsg }]);
    setInput('');
    setLoading(true);

    try {
      if (!status.is_running || !status.has_llama3_2) {
        setMessages(prev => [...prev, { role: 'assistant', content: "AI xizmati hozircha to'liq tayyor emas. Iltimos, modellar yuklanishini kuting." }]);
        setLoading(false);
        return;
      }

      const res = await invoke('analyze_threat_with_ai', { prompt: userMsg });
      if (res.success) {
        setMessages(prev => [...prev, { role: 'assistant', content: res.message }]);
      } else {
        setMessages(prev => [...prev, { role: 'assistant', content: `Xatolik: ${res.message}` }]);
      }
    } catch (e) {
      setMessages(prev => [...prev, { role: 'assistant', content: 'Tizim xatosi yuz berdi.' }]);
    }
    setLoading(false);
  };

  return (
    <div className="space-y-6 flex flex-col h-[calc(100vh-6rem)]">
      <div className="flex justify-between items-center bg-white/5 p-4 rounded-xl border border-white/10 backdrop-blur-md">
        <div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-400 to-indigo-400 bg-clip-text text-transparent drop-shadow-md">
            AI Assistant
          </h2>
          <p className="text-gray-400 text-sm mt-1">SERGAK sun'iy idroki bilan suhbat</p>
        </div>
        
        <div className="flex gap-2">
          <div className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-2 ${
            status.is_installed ? 'bg-green-500/20 border-green-500/50 text-green-300' : 'bg-red-500/20 border-red-500/50 text-red-300'
          }`}>
            <span className={`w-2 h-2 rounded-full ${status.is_installed ? 'bg-green-400 animate-pulse' : 'bg-red-400'}`}></span>
            {status.is_installed ? 'Ollama: O`rnatilgan' : 'Ollama: O`rnatilmagan'}
          </div>
          <div className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-2 ${
            status.has_llama3_2 ? 'bg-blue-500/20 border-blue-500/50 text-blue-300' : 'bg-yellow-500/20 border-yellow-500/50 text-yellow-300'
          }`}>
            {status.has_llama3_2 ? 'Llama 3.2: Tayyor' : 'Llama 3.2: Kutilmoqda'}
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto bg-black/20 rounded-xl border border-white/10 p-4 space-y-4">
        {messages.map((msg, i) => (
          <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[80%] rounded-2xl p-4 ${
              msg.role === 'user' 
                ? 'bg-blue-600/50 border border-blue-500/30 text-white rounded-tr-sm' 
                : 'bg-white/10 border border-white/10 text-gray-200 rounded-tl-sm'
            }`}>
              <p className="whitespace-pre-wrap text-sm leading-relaxed">{msg.content}</p>
            </div>
          </div>
        ))}
        {loading && (
          <div className="flex justify-start">
            <div className="bg-white/10 border border-white/10 text-gray-400 rounded-2xl p-4 rounded-tl-sm text-sm flex gap-2">
              <span className="animate-bounce">●</span>
              <span className="animate-bounce" style={{animationDelay: '0.2s'}}>●</span>
              <span className="animate-bounce" style={{animationDelay: '0.4s'}}>●</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="flex gap-2">
        <input 
          type="text" 
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSend()}
          placeholder="Savolingizni yozing..."
          className="flex-1 bg-black/30 border border-white/10 rounded-xl px-4 text-white focus:outline-none focus:border-blue-500/50 transition-colors"
          disabled={loading || !status.has_llama3_2}
        />
        <button 
          onClick={handleSend}
          disabled={loading || !status.has_llama3_2}
          className="bg-blue-600 hover:bg-blue-500 text-white px-6 py-3 rounded-xl transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium shadow-lg"
        >
          Yuborish
        </button>
      </div>
    </div>
  );
}
