/* ═══════════════════════════════════════════════════════════════
   SERGAK PC — Windows Simulation Interactive Logic
   ═══════════════════════════════════════════════════════════════ */

// ─── Tab Switching ───
function switchTab(tabId) {
  document.querySelectorAll('.sim-tab-content').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.sim-nav-item').forEach(n => n.classList.remove('active'));
  const tab = document.getElementById('tab-' + tabId);
  if (tab) tab.classList.add('active');
  const nav = document.querySelector(`.sim-nav-item[data-tab="${tabId}"]`);
  if (nav) nav.classList.add('active');
}

document.querySelectorAll('.sim-nav-item').forEach(btn => {
  btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

// ─── Live CPU/RAM Animation ───
function animateStats() {
  const cpuEl = document.getElementById('cpu-usage');
  const ramEl = document.getElementById('ram-usage');
  if (cpuEl) cpuEl.textContent = (18 + Math.floor(Math.random() * 25)) + '%';
  if (ramEl) ramEl.textContent = (55 + Math.floor(Math.random() * 20)) + '%';
}
setInterval(animateStats, 3000);

// ═══════════════════════════════════════════════════════════════
//  VULNERABILITY SCANNER (Simulated)
// ═══════════════════════════════════════════════════════════════
const FAKE_VULNS = [
  { id: 'fw', title: 'Windows Firewall o\'chirilgan', desc: 'Tarmoq himoyasi buzilgan. Kirib keluvchi ulanishlar filtrlanmaydi.', severity: 'critical', fixable: true },
  { id: 'rdp', title: 'RDP (3389-port) ochiq', desc: 'Remote Desktop xizmati yoqilgan va ochiq port aniqlandi.', severity: 'high', fixable: true },
  { id: 'smb', title: 'SMBv1 protokoli faol', desc: 'Eskirgan SMBv1 (EternalBlue zaifligiga moyil) — WannaCry hujumiga ochiq.', severity: 'critical', fixable: true },
  { id: 'def', title: 'Windows Defender real-time himoyasi o\'chiq', desc: 'Antivirus real-time monitoring o\'chirilgan.', severity: 'high', fixable: true },
  { id: 'uac', title: 'UAC daraja past', desc: 'User Account Control minimal darajada. Zararli dasturlar osongina admin huquqini olishi mumkin.', severity: 'medium', fixable: true },
  { id: 'upd', title: 'Windows Update 45 kundan beri yangilanmagan', desc: 'Xavfsizlik yamoqlari qo\'llanilmagan — tizim zaif holda.', severity: 'medium', fixable: false },
  { id: 'pwd', title: 'Administrator parolsiz', desc: 'Mahalliy Administrator hisobi parolsiz ochiq turgan.', severity: 'high', fixable: true },
  { id: 'ports', title: '5 ta noma\'lum ochiq port aniqlandi', desc: 'Portlar: 4444, 5555, 8080, 9090, 1234. Ba\'zilari ma\'lum backdoor portlari.', severity: 'critical', fixable: true },
];

const SEVERITY_MAP = {
  critical: { label: 'KRITIK', color: '#ff4757', bg: 'rgba(255,71,87,0.15)', icon: '🚨' },
  high:     { label: 'YUQORI', color: '#ff6b35', bg: 'rgba(255,107,53,0.15)', icon: '⚠️' },
  medium:   { label: 'O\'RTA', color: '#ffa502', bg: 'rgba(255,165,2,0.15)', icon: '🔶' },
  low:      { label: 'PAST', color: '#2ed573', bg: 'rgba(46,213,115,0.15)', icon: 'ℹ️' },
};

let fixedVulns = new Set();

function startVulnScan() {
  const btn = document.getElementById('vuln-scan-btn');
  const spinner = document.getElementById('vuln-spinner');
  const placeholder = document.getElementById('vuln-placeholder');
  const summary = document.getElementById('vuln-summary');
  const results = document.getElementById('vuln-results');
  const fixAllBtn = document.getElementById('vuln-fix-all-btn');

  btn.disabled = true;
  btn.textContent = '⏳ Skanerlanmoqda...';
  placeholder.style.display = 'none';
  results.innerHTML = '';
  summary.style.display = 'none';
  fixAllBtn.style.display = 'none';
  spinner.style.display = 'block';
  fixedVulns = new Set();

  setTimeout(() => {
    spinner.style.display = 'none';
    btn.disabled = false;
    btn.textContent = '🔍 Tizimni Skaner Qilish';
    renderVulns();
    updateVulnSummary();
    summary.style.display = '';
    fixAllBtn.style.display = '';
  }, 2500);
}

function renderVulns() {
  const results = document.getElementById('vuln-results');
  results.innerHTML = '<div class="sim-section-title"><span>🛡️</span> Natijalar</div><div class="sim-vulns stagger">' +
    FAKE_VULNS.map(v => {
      const cfg = SEVERITY_MAP[v.severity];
      const isFixed = fixedVulns.has(v.id);
      return `<div class="sim-card sim-vuln-item ${isFixed ? 'fixed' : ''}" id="vuln-${v.id}" style="border-left:3px solid ${isFixed ? '#2ed573' : cfg.color}">
        <div style="flex:1">
          <div class="sim-vuln-header">
            <span style="font-size:16px">${isFixed ? '✅' : cfg.icon}</span>
            <h4 style="color:${isFixed ? '#2ed573' : 'var(--text-main)'}">${v.title}</h4>
            <span class="sim-vuln-severity" style="background:${isFixed ? 'rgba(46,213,115,0.15)' : cfg.bg};color:${isFixed ? '#2ed573' : cfg.color}">${isFixed ? 'YOPILDI' : cfg.label}</span>
          </div>
          <p class="sim-vuln-desc">${v.desc}</p>
        </div>
        ${v.fixable && !isFixed ? `<button class="sim-vuln-fix-btn" style="border-color:${cfg.color};color:${cfg.color};background:${cfg.bg}" onclick="fixVuln('${v.id}', this)">🛠️ Yop</button>` : ''}
      </div>`;
    }).join('') + '</div>';
}

function fixVuln(id, btn) {
  if (btn) {
    btn.textContent = '⏳...';
    btn.disabled = true;
  }
  setTimeout(() => {
    fixedVulns.add(id);
    renderVulns();
    updateVulnSummary();
  }, 600);
}

function fixAllVulns() {
  const fixable = FAKE_VULNS.filter(v => v.fixable && !fixedVulns.has(v.id));
  let delay = 0;
  fixable.forEach(v => {
    delay += 500;
    setTimeout(() => fixVuln(v.id), delay);
  });
}

function updateVulnSummary() {
  const critCount = FAKE_VULNS.filter(v => v.severity === 'critical' && !fixedVulns.has(v.id)).length;
  const highCount = FAKE_VULNS.filter(v => v.severity === 'high' && !fixedVulns.has(v.id)).length;
  document.getElementById('vuln-critical').textContent = critCount;
  document.getElementById('vuln-high').textContent = highCount;
  document.getElementById('vuln-fixed').textContent = fixedVulns.size;
  const fixableCount = FAKE_VULNS.filter(v => v.fixable && !fixedVulns.has(v.id)).length;
  const fixAllBtn = document.getElementById('vuln-fix-all-btn');
  if (fixableCount > 0) {
    fixAllBtn.style.display = '';
    fixAllBtn.textContent = `🛠️ Barchasini Yop (${fixableCount} ta)`;
  } else {
    fixAllBtn.style.display = 'none';
  }
}

// ═══════════════════════════════════════════════════════════════
//  NETWORK SCANNER (Simulated)
// ═══════════════════════════════════════════════════════════════
const FAKE_DEVICES = [
  { name: 'Router (Gateway)', ip: '192.168.1.1', mac: 'AA:BB:CC:11:22:33', type: '📡', status: 'safe' },
  { name: 'Khamidov-PC', ip: '192.168.1.105', mac: '50:C2:E8:8E:D2:35', type: '💻', status: 'safe' },
  { name: 'Smart TV', ip: '192.168.1.42', mac: 'DD:EE:FF:44:55:66', type: '📺', status: 'safe' },
  { name: 'iPhone 14', ip: '192.168.1.67', mac: '11:22:33:44:55:66', type: '📱', status: 'safe' },
  { name: 'Noma\'lum qurilma', ip: '192.168.1.89', mac: '77:88:99:AA:BB:CC', type: '❓', status: 'unknown' },
  { name: 'Printer', ip: '192.168.1.15', mac: 'EE:DD:CC:BB:AA:99', type: '🖨️', status: 'safe' },
  { name: 'IoT Kamera', ip: '192.168.1.201', mac: 'FF:11:22:33:44:55', type: '📷', status: 'unknown' },
];

function startNetScan() {
  const btn = document.getElementById('net-scan-btn');
  const ring = document.getElementById('net-scan-ring');
  const ringIcon = document.getElementById('net-ring-icon');
  const ringText = document.getElementById('net-ring-text');
  const ringContainer = document.getElementById('net-ring');
  const summary = document.getElementById('net-summary');
  const results = document.getElementById('net-results');
  const timeEl = document.getElementById('net-scan-time');

  btn.disabled = true;
  btn.textContent = '⏳ Skanerlanmoqda...';
  ring.classList.add('scanning');
  ringIcon.textContent = '📡';
  ringText.textContent = 'ARP va ping skanerlanmoqda...';
  summary.style.display = 'none';
  results.innerHTML = '';
  timeEl.textContent = '';

  const startTime = Date.now();

  setTimeout(() => {
    ring.classList.remove('scanning');
    ringContainer.style.display = 'none';
    btn.disabled = false;
    btn.textContent = '🔍 Skanerlash';

    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    timeEl.textContent = `✅ ${elapsed} soniyada yakunlandi`;

    const safeCount = FAKE_DEVICES.filter(d => d.status === 'safe').length;
    const unknownCount = FAKE_DEVICES.filter(d => d.status === 'unknown').length;
    document.getElementById('net-total').textContent = FAKE_DEVICES.length;
    document.getElementById('net-safe').textContent = safeCount;
    document.getElementById('net-unknown').textContent = unknownCount;
    summary.style.display = '';

    results.innerHTML = FAKE_DEVICES.map(d =>
      `<div class="sim-card sim-device ${d.status}">
        <div class="sim-device-avatar">${d.type}</div>
        <div class="sim-device-info">
          <h4>${d.name}</h4>
          <span>${d.ip} • ${d.mac}</span>
        </div>
        <span class="sim-device-status ${d.status}">${d.status === 'safe' ? 'XAVFSIZ' : 'NOMA\'LUM'}</span>
      </div>`
    ).join('');
  }, 3000);
}

// ═══════════════════════════════════════════════════════════════
//  FILE SYSTEM MONITOR (Simulated)
// ═══════════════════════════════════════════════════════════════
let fsMonitoring = false;
let fsInterval = null;

const FAKE_FS_PATHS = [
  'C:\\Users\\Khamidov\\Downloads\\report_2026.docx',
  'C:\\Users\\Khamidov\\Desktop\\photo.jpg',
  'C:\\Windows\\Temp\\svc_update.exe',
  'C:\\Users\\Khamidov\\AppData\\Local\\Temp\\cache_x32.dll',
  'C:\\Program Files\\Office\\template.dotm',
  'D:\\Projects\\backend\\server.js',
  'C:\\Users\\Khamidov\\Documents\\budget.xlsx',
  'C:\\Users\\Khamidov\\Downloads\\free_vpn_setup.exe',
];

const FAKE_THREATS = [
  { name: 'Trojan.GenericKD.48901', hash: 'a3f2e8c9d4b6a1f0e7c5d3b2a9f8e6c4' },
  { name: 'Backdoor.Win32.Agent', hash: 'b7d1f3e5a2c4d6f8e1b3a5c7d9f2e4a6' },
];

function toggleFsMonitor() {
  fsMonitoring = !fsMonitoring;
  const btn = document.getElementById('fs-monitor-btn');
  const dot = document.getElementById('fs-live-dot');
  const feed = document.getElementById('fs-feed');

  if (fsMonitoring) {
    btn.textContent = "To'xtatish";
    btn.className = 'sim-btn sim-btn-danger';
    dot.style.display = '';
    feed.innerHTML = '';
    fsInterval = setInterval(addFsFeedItem, 2000);
  } else {
    btn.textContent = "Monitoringni Boshlash";
    btn.className = 'sim-btn sim-btn-success';
    dot.style.display = 'none';
    clearInterval(fsInterval);
  }
}

function addFsFeedItem() {
  const feed = document.getElementById('fs-feed');
  const isThreat = Math.random() < 0.2;
  const path = FAKE_FS_PATHS[Math.floor(Math.random() * FAKE_FS_PATHS.length)];
  const action = Math.random() < 0.6 ? 'created' : 'modified';
  const now = new Date().toLocaleTimeString();

  let html = `<div class="sim-feed-item ${isThreat ? 'threat' : ''} fade-in">
    <div class="sim-feed-top">
      <div>
        <span class="sim-feed-action ${action}">${action}</span>
        <span class="sim-feed-path">${path}</span>
      </div>
      <span class="sim-feed-time">${now}</span>
    </div>`;

  if (isThreat) {
    const threat = FAKE_THREATS[Math.floor(Math.random() * FAKE_THREATS.length)];
    html += `<div class="sim-feed-threat-box">
      <div>
        <div class="sim-feed-threat-name">🚨 ZARARLI DASTUR TOPILDI: ${threat.name}</div>
        <div class="sim-feed-threat-hash">Hash: ${threat.hash}...</div>
      </div>
      <button class="sim-btn" style="background:var(--danger);color:white;padding:4px 12px;font-size:11px">Karantinga olish</button>
    </div>`;
  } else {
    html += `<div class="sim-feed-safe">✅ Xavfsiz fayl</div>`;
  }
  html += '</div>';

  feed.insertAdjacentHTML('afterbegin', html);

  // Keep max 15 items
  while (feed.children.length > 15) {
    feed.removeChild(feed.lastChild);
  }
}

// ═══════════════════════════════════════════════════════════════
//  PROCESS MONITOR (Simulated)
// ═══════════════════════════════════════════════════════════════
const FAKE_PROCESSES = [
  { name: 'svchost.exe', pid: 876, parent: 4, suspicious: false, reason: '' },
  { name: 'explorer.exe', pid: 3412, parent: 876, suspicious: false, reason: '' },
  { name: 'chrome.exe', pid: 5128, parent: 3412, suspicious: false, reason: '' },
  { name: 'sergak.exe', pid: 7890, parent: 3412, suspicious: false, reason: '' },
  { name: 'powershell.exe (yashirin)', pid: 9123, parent: 1, suspicious: true, reason: 'Yashirin PowerShell — backdoor uchun ishlatilishi mumkin' },
  { name: 'cmd.exe', pid: 2456, parent: 1, suspicious: true, reason: 'CMD foydalanuvchisiz ishga tushgan — shubhali' },
  { name: 'notepad.exe', pid: 4321, parent: 3412, suspicious: false, reason: '' },
  { name: 'Code.exe (VS Code)', pid: 6789, parent: 3412, suspicious: false, reason: '' },
  { name: 'miner_hidden.exe', pid: 1111, parent: 9123, suspicious: true, reason: 'Kripto-miner — CPU dan noqonuniy foydalanish' },
];

const FAKE_STARTUP = [
  { name: 'SERGAK PC', command: 'C:\\Program Files\\SERGAK\\sergak.exe --autostart', location: 'HKCU\\Run' },
  { name: 'OneDrive', command: 'C:\\Users\\Khamidov\\AppData\\OneDrive.exe /background', location: 'HKCU\\Run' },
  { name: 'Shubhali skript', command: 'powershell.exe -enc QwBvAG0AbQBhAG4AZA...', location: 'HKLM\\Run', suspicious: true },
  { name: 'Windows Defender', command: 'C:\\ProgramData\\Microsoft\\Windows Defender\\MsMpEng.exe', location: 'TaskScheduler' },
  { name: 'Hidden VBS', command: 'wscript.exe C:\\Users\\Temp\\update.vbs', location: 'HKCU\\RunOnce', suspicious: true },
];

function showProcTab(tab, btn) {
  document.querySelectorAll('.sim-proc-tab').forEach(t => t.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById('proc-table-area').style.display = tab === 'processes' ? '' : 'none';
  document.getElementById('startup-table-area').style.display = tab === 'startup' ? '' : 'none';
}

function renderProcesses() {
  const tbody = document.getElementById('proc-tbody');
  tbody.innerHTML = FAKE_PROCESSES.map(p =>
    `<tr class="${p.suspicious ? 'suspicious' : ''}">
      <td>
        <div class="sim-proc-name ${p.suspicious ? 'danger' : ''}">${p.name}</div>
        <div class="sim-proc-pid">PID: ${p.pid}${p.parent ? ' | Parent: ' + p.parent : ''}</div>
      </td>
      <td>${p.suspicious
        ? '<span class="sim-proc-badge dangerous">🚨 XAVFLI</span>'
        : '<span class="sim-proc-badge safe">Xavfsiz</span>'
      }</td>
      <td style="font-size:12px;color:${p.suspicious ? 'var(--danger)' : 'var(--text-muted)'}">${p.reason || '-'}</td>
    </tr>`
  ).join('');
}

function renderStartup() {
  const tbody = document.getElementById('startup-tbody');
  tbody.innerHTML = FAKE_STARTUP.map(s =>
    `<tr class="${s.suspicious ? 'suspicious' : ''}">
      <td style="font-weight:500;color:var(--text-main)">${s.name}${s.suspicious ? ' <span style="font-size:10px;background:var(--warning-dim);color:var(--warning);padding:2px 8px;border-radius:4px;margin-left:8px">Shubhali</span>' : ''}</td>
      <td style="font-size:12px;color:var(--text-muted);font-family:JetBrains Mono,monospace;word-break:break-all">${s.command}</td>
      <td><span style="background:rgba(255,255,255,0.08);padding:4px 10px;border-radius:4px;font-size:12px">${s.location}</span></td>
    </tr>`
  ).join('');
}

// ═══════════════════════════════════════════════════════════════
//  AI CHAT (Simulated)
// ═══════════════════════════════════════════════════════════════
const AI_RESPONSES = [
  "Sizning tizimingizda hozircha jiddiy tahdid aniqlanmadi. Lekin muntazam skanerlashni davom ettirishni tavsiya qilaman.",
  "Firewall (xavfsizlik devori) — bu kompyuteringizga kirib/chiqib ketayotgan tarmoq trafigini nazorat qiluvchi tizim. Uni har doim yoqib qo'yishingiz kerak.",
  "Phishing — bu firibgarlik usuli. Hujumchi soxta veb-sahifa yoki xabar orqali parolingizni yoki bank ma'lumotlaringizni o'g'irlashga urinadi. SERGAK buni avtomatik aniqlaydi.",
  "Keylogger — bu klaviaturadagi har bir tugma bosishni yozib oladigan zararli dastur. SERGAK Anti-Keylogger moduli bu xavfdan himoya qiladi.",
  "Ransomware — bu fayllaringizni shifrlab, ochish uchun pul talab qiladigan virus. SERGAK Honeypot texnologiyasi buni darhol aniqlaydi.",
  "USB qurilma ulanganda SERGAK darhol uni skanerlaydi va xavfli fayllar mavjud bo'lsa, ogohlantirib turadi.",
  "Windows Update ni har doim yangilab turish juda muhim. Eskirgan tizimda xavfsizlik zaifliklar ancha ko'p bo'ladi.",
  "SMBv1 protokoli juda eski va WannaCry kabi yirik hujumlarga sabab bo'lgan. Uni o'chirib qo'yish tavsiya etiladi — SERGAK buni bir tugma bilan amalga oshiradi.",
];

function sendChat() {
  const input = document.getElementById('chat-input');
  const messages = document.getElementById('chat-messages');
  const text = input.value.trim();
  if (!text) return;

  // Add user message
  messages.innerHTML += `<div class="sim-chat-msg user fade-in">${escapeHtml(text)}</div>`;
  input.value = '';

  // Add typing indicator
  messages.innerHTML += `<div class="sim-chat-msg assistant fade-in" id="typing-indicator" style="color:var(--text-muted)">● ● ●</div>`;
  messages.scrollTop = messages.scrollHeight;

  // Simulate response
  setTimeout(() => {
    const typing = document.getElementById('typing-indicator');
    if (typing) typing.remove();
    const response = AI_RESPONSES[Math.floor(Math.random() * AI_RESPONSES.length)];
    messages.innerHTML += `<div class="sim-chat-msg assistant fade-in">${response}</div>`;
    messages.scrollTop = messages.scrollHeight;
  }, 1200);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// ═══════════════════════════════════════════════════════════════
//  INIT
// ═══════════════════════════════════════════════════════════════
renderProcesses();
renderStartup();
