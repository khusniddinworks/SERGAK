mod ai;
mod db;
mod fs_monitor;
mod hash_db;
mod process_monitor;
mod quarantine;
mod phone_link;

use base64::{engine::general_purpose, Engine as _};
use hmac::{Hmac, Mac};
use rsa::Pkcs1v15Sign;
use rsa::{pkcs8::DecodePublicKey, RsaPublicKey};
use sha2::Digest;
use sha2::Sha256;
use std::collections::HashMap;
#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;
use std::sync::Mutex;
use sysinfo::System;
use tauri::command;

const SECRET_KEY: &str = "SERGAKxavfsizlik2026TAFUxusniddinSecret!";

const PUBLIC_KEY_PEM: &str = "-----BEGIN PUBLIC KEY-----\n\
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsuuTUtYckMfnlaXu3LaZ\n\
HPxfE4h7pMt6FUsk12CLIBE74F2FPMQAZyIdt8JBg6OtsRKv/E2Kv7S2zttIRjET\n\
Df5ikZWHlzgttpl4EDBBSEBAmkBCDA4/BoaIABo42gTmLas/6x9NwZXfssloZ8ID\n\
YxgDjFTL2Z2i3Hn7ewCEszyd+gMTqsCkKZ85K1qcrNXGusY8NgJaY11WLMLbHgG3\n\
9DEilhq+JDDwExh3CfXUfLF6EYTEPrIqlomFVaE1538BEwhh1LFIgSC+mVO2+Y98\n\
98iUatCl+6vY+eKcHX+lVtBsiqsUOncpm2hW2h2imKp2uzQnpgUX9rA2MvB+W4+u\n\
JQIDAQAB\n\
-----END PUBLIC KEY-----";

type HmacSha256 = Hmac<Sha256>;

struct AppState {
    sys: Mutex<System>,
}

// ═══════════════════════════════════════════════════════════════
// RSA helpers
// ═══════════════════════════════════════════════════════════════
fn verify_rsa_signature(message: &str, signature_b64: &str) -> bool {
    let pub_key = match RsaPublicKey::from_public_key_pem(PUBLIC_KEY_PEM) {
        Ok(k) => k,
        Err(_) => return false,
    };
    let sig_bytes = match general_purpose::STANDARD.decode(signature_b64) {
        Ok(b) => b,
        Err(_) => return false,
    };
    let mut hasher = Sha256::new();
    hasher.update(message.as_bytes());
    let hashed = hasher.finalize();
    pub_key
        .verify(Pkcs1v15Sign::new::<Sha256>(), &hashed, &sig_bytes)
        .is_ok()
}

// ═══════════════════════════════════════════════════════════════
// Device ID — Windows MachineGuid
// ═══════════════════════════════════════════════════════════════
#[command]
fn get_device_id() -> String {
    #[cfg(target_os = "windows")]
    {
        let output = std::process::Command::new("powershell")
            .creation_flags(0x08000000)
            .args(["-NoProfile", "-Command",
                "(Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Cryptography' -Name MachineGuid).MachineGuid"])
            .output();
        if let Ok(out) = output {
            let raw = String::from_utf8_lossy(&out.stdout).trim().to_string();
            if !raw.is_empty() {
                let parts: Vec<&str> = raw.splitn(5, '-').collect();
                if parts.len() >= 4 {
                    return format!(
                        "SRGK-{}-{}-{}",
                        parts[1].to_uppercase(),
                        parts[2].to_uppercase(),
                        parts[3][..4.min(parts[3].len())].to_uppercase()
                    );
                }
                return format!("SRGK-{}", &raw[..12.min(raw.len())].to_uppercase());
            }
        }
        let hostname = std::process::Command::new("hostname")
            .creation_flags(0x08000000)
            .output()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_else(|_| "UNKNOWN".to_string());
        format!("SRGK-{}", hostname.to_uppercase())
    }
    #[cfg(not(target_os = "windows"))]
    {
        "SRGK-DEMO-0000-0000".to_string()
    }
}

// ═══════════════════════════════════════════════════════════════
// VULNERABILITY SCANNER
// ═══════════════════════════════════════════════════════════════
#[derive(serde::Serialize, Clone)]
pub struct Vulnerability {
    pub id: String,
    pub title: String,
    pub description: String,
    pub severity: String, // "critical" | "high" | "medium" | "low"
    pub fixable: bool,
    pub fixed: bool,
}

fn ps(cmd: &str) -> String {
    let mut command = std::process::Command::new("powershell");
    #[cfg(target_os = "windows")]
    command.creation_flags(0x08000000);
    command.args(["-NoProfile", "-NonInteractive", "-Command", cmd])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

fn ps_run(cmd: &str) -> bool {
    let mut command = std::process::Command::new("powershell");
    #[cfg(target_os = "windows")]
    command.creation_flags(0x08000000);
    command.args(["-NoProfile", "-NonInteractive", "-Command", cmd])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

#[command]
fn scan_vulnerabilities() -> Vec<Vulnerability> {
    let mut vulns: Vec<Vulnerability> = Vec::new();

    // 1. Windows Firewall
    let fw = ps("(Get-NetFirewallProfile -Profile Domain,Private,Public | Where-Object { $_.Enabled -eq $false }).Name");
    if !fw.trim().is_empty() {
        vulns.push(Vulnerability {
            id: "FW_DISABLED".into(),
            title: "Windows Firewall O'CHIQ".into(),
            description: format!("Quyidagi firewall profillari o'chirilgan: {}. Bu tizimni tashqaridan hujumlarga ochiq qoldirishadi.", fw),
            severity: "critical".into(),
            fixable: true,
            fixed: false,
        });
    }

    // 2. Windows Defender
    let defender = ps("(Get-MpComputerStatus).AntivirusEnabled");
    if defender.trim().to_lowercase() == "false" {
        vulns.push(Vulnerability {
            id: "DEFENDER_OFF".into(),
            title: "Windows Defender O'CHIQ".into(),
            description:
                "Antivirus himoyasi faol emas. Zararli dasturlar tizimga kirib ketishi mumkin."
                    .into(),
            severity: "critical".into(),
            fixable: true,
            fixed: false,
        });
    }

    // 3. Remote Desktop (RDP)
    let rdp = ps("(Get-ItemProperty 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server').fDenyTSConnections");
    if rdp.trim() == "0" {
        vulns.push(Vulnerability {
            id: "RDP_OPEN".into(),
            title: "Remote Desktop (RDP) OCHIQ".into(),
            description: "RDP port 3389 ochiq. Agar kerak bo'lmasa, bu xakerlar uchun keng eshik."
                .into(),
            severity: "high".into(),
            fixable: true,
            fixed: false,
        });
    }

    // 4. Guest Account
    let guest = ps("(Get-LocalUser -Name 'Guest').Enabled");
    if guest.trim().to_lowercase() == "true" {
        vulns.push(Vulnerability {
            id: "GUEST_ON".into(),
            title: "Guest Hisob Faol".into(),
            description:
                "Guest (mehmon) hisobi yoqilgan — bu noto'g'ri kirishlarni osonlashtiradi.".into(),
            severity: "medium".into(),
            fixable: true,
            fixed: false,
        });
    }

    // 5. SMBv1
    let smb1 = ps("(Get-SmbServerConfiguration).EnableSMB1Protocol");
    if smb1.trim().to_lowercase() == "true" {
        vulns.push(Vulnerability {
            id: "SMB1_ON".into(),
            title: "Eski SMBv1 Protokoli Faol (WannaCry!)".into(),
            description: "SMBv1 — WannaCry ransomware hujumi ishlatgan protokol. Darhol o'chiring."
                .into(),
            severity: "critical".into(),
            fixable: true,
            fixed: false,
        });
    }

    // 6. AutoRun (USB)
    let autorun = ps("(Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer' -ErrorAction SilentlyContinue).NoDriveTypeAutoRun");
    let autorun_val = autorun.trim().parse::<u32>().unwrap_or(0);
    if autorun_val != 255 {
        vulns.push(Vulnerability {
            id: "AUTORUN_ON".into(),
            title: "USB AutoRun Yoqilgan".into(),
            description: "USB qurilma ulanganda avtomatik ishga tushish yoqilgan — zararli dastur tarqatish uchun keng qo'llaniladigan usul.".into(),
            severity: "high".into(),
            fixable: true,
            fixed: false,
        });
    }

    // 7. Windows Update / Automatic updates
    let au = ps("(Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WindowsUpdate\\Auto Update' -ErrorAction SilentlyContinue).AUOptions");
    if au.trim() == "1" || au.trim() == "2" {
        vulns.push(Vulnerability {
            id: "AUTOUPDATE_OFF".into(),
            title: "Avtomatik Yangilanishlar O'CHIQ".into(),
            description:
                "Windows xavfsizlik yangilanishlari avtomatik o'rnatilmaydi. Tizim zaif qoladi."
                    .into(),
            severity: "high".into(),
            fixable: true,
            fixed: false,
        });
    }

    // 8. Open dangerous ports
    let mut command = std::process::Command::new("netstat");
    #[cfg(target_os = "windows")]
    command.creation_flags(0x08000000);
    let netstat = command
        .args(["-ano"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
        .unwrap_or_default();

    let dangerous_ports = vec![
        (23u16, "Telnet"),
        (21, "FTP"),
        (135, "RPC"),
        (137, "NetBIOS"),
        (139, "NetBIOS Session"),
        (445, "SMB"),
        (1433, "MSSQL"),
        (3389, "RDP"),
        (5900, "VNC"),
    ];

    let mut open_dangerous: Vec<String> = Vec::new();
    for (port, name) in &dangerous_ports {
        let pattern = format!("0.0.0.0:{} ", port);
        if netstat.contains(&pattern) {
            open_dangerous.push(format!("{} ({})", port, name));
        }
    }
    if !open_dangerous.is_empty() {
        vulns.push(Vulnerability {
            id: "OPEN_PORTS".into(),
            title: format!("Xavfli Ochiq Portlar: {}", open_dangerous.join(", ")),
            description: "Bu portlar tashqi tarmoqdan kirish imkonini beradi. Agar ishlatilinmasa, yopilishi kerak.".into(),
            severity: "high".into(),
            fixable: false,
            fixed: false,
        });
    }

    // 9. PowerShell Execution Policy
    let ep = ps("Get-ExecutionPolicy");
    if ep.trim().to_lowercase() == "unrestricted" || ep.trim().to_lowercase() == "bypass" {
        vulns.push(Vulnerability {
            id: "PS_POLICY".into(),
            title: "PowerShell Ijro Siyosati — XAVFLI".into(),
            description: format!(
                "PowerShell siyosati '{}' ga o'rnatilgan. Har qanday skript ishga tushishi mumkin.",
                ep.trim()
            ),
            severity: "medium".into(),
            fixable: true,
            fixed: false,
        });
    }

    // 10. Check UAC (User Account Control)
    let uac = ps("(Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System').EnableLUA");
    if uac.trim() == "0" {
        vulns.push(Vulnerability {
            id: "UAC_OFF".into(),
            title: "UAC (Foydalanuvchi Nazorat Paneli) O'CHIQ".into(),
            description: "UAC o'chirilgan — zararli dasturlar administrator huquqini so'ramasdan olishi mumkin.".into(),
            severity: "critical".into(),
            fixable: true,
            fixed: false,
        });
    }

    // If all good
    if vulns.is_empty() {
        vulns.push(Vulnerability {
            id: "ALL_SAFE".into(),
            title: "Barcha tekshiruvlar muvaffaqiyatli!".into(),
            description: "Tizimda hozircha hech qanday zaiflik topilmadi.".into(),
            severity: "safe".into(),
            fixable: false,
            fixed: true,
        });
    }

    vulns
}

#[command]
fn fix_vulnerability(id: String) -> bool {
    match id.as_str() {
        "FW_DISABLED" => ps_run(
            "Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True"
        ),
        "DEFENDER_OFF" => ps_run(
            "Set-MpPreference -DisableRealtimeMonitoring $false"
        ),
        "RDP_OPEN" => ps_run(
            "Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 1; \
             netsh advfirewall firewall set rule group='remote desktop' new enable=No"
        ),
        "GUEST_ON" => ps_run(
            "Disable-LocalUser -Name 'Guest'"
        ),
        "SMB1_ON" => ps_run(
            "Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force"
        ),
        "AUTORUN_ON" => ps_run(
            "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer' -Name 'NoDriveTypeAutoRun' -Value 255 -Type DWord"
        ),
        "AUTOUPDATE_OFF" => ps_run(
            "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WindowsUpdate\\Auto Update' -Name 'AUOptions' -Value 4"
        ),
        "PS_POLICY" => ps_run(
            "Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"
        ),
        "UAC_OFF" => ps_run(
            "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System' -Name 'EnableLUA' -Value 1"
        ),
        _ => false,
    }
}

// ═══════════════════════════════════════════════════════════════
// NETWORK DATA GUARD — Aktiv ulanishlar + sezgir ma'lumot tekshiruvi
// ═══════════════════════════════════════════════════════════════
#[derive(serde::Serialize)]
pub struct NetworkConnection {
    pub protocol: String,
    pub local_addr: String,
    pub remote_addr: String,
    pub state: String,
    pub pid: String,
    pub process_name: String,
    pub risk: String, // "safe" | "warning" | "danger"
    pub risk_reason: String,
}

fn get_process_name(pid: &str) -> String {
    if pid == "0" || pid.is_empty() {
        return "System".to_string();
    }
    let out = ps(&format!(
        "(Get-Process -Id {} -ErrorAction SilentlyContinue).Name",
        pid
    ));
    if out.trim().is_empty() {
        pid.to_string()
    } else {
        out.trim().to_string()
    }
}

fn assess_risk(remote: &str, process: &str) -> (String, String) {
    // Known suspicious: remote IPs from high-risk countries / patterns
    let sus_processes = [
        "powershell",
        "cmd",
        "wscript",
        "cscript",
        "regsvr32",
        "mshta",
        "bitsadmin",
        "certutil",
    ];
    let proc_lower = process.to_lowercase();

    for sp in &sus_processes {
        if proc_lower.contains(sp) {
            return (
                "danger".into(),
                format!(
                    "'{process}' jarayoni tarmoqqa ulandi — bu potensial zararli skript belgisi"
                ),
            );
        }
    }

    // Check if remote port is suspicious
    let remote_port: u16 = remote
        .split(':')
        .last()
        .and_then(|p| p.parse().ok())
        .unwrap_or(0);

    match remote_port {
        4444 | 1337 | 31337 | 6666 | 6667 => {
            return (
                "danger".into(),
                format!(
                    "Port {} — ko'pincha C2 (Command & Control) serverlari tomonidan ishlatiladi",
                    remote_port
                ),
            );
        }
        1080 | 9050 | 9150 => {
            return (
                "warning".into(),
                format!("Port {} — Tor/Proxy ulanishi mumkin", remote_port),
            );
        }
        _ => {}
    }

    // Unknown foreign IPs (non-local)
    if !remote.starts_with("127.")
        && !remote.starts_with("192.168.")
        && !remote.starts_with("10.")
        && !remote.starts_with("0.0.0.0")
        && remote != "*:*"
    {
        return (
            "warning".into(),
            format!("Tashqi IP: {remote} — tekshiring"),
        );
    }

    ("safe".into(), String::new())
}

#[command]
fn get_active_connections() -> Vec<NetworkConnection> {
    let mut conns: Vec<NetworkConnection> = Vec::new();

    let mut command = std::process::Command::new("netstat");
    #[cfg(target_os = "windows")]
    command.creation_flags(0x08000000);
    let out = command
        .args(["-ano"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
        .unwrap_or_default();

    for line in out.lines().skip(4) {
        let cols: Vec<&str> = line.split_whitespace().collect();
        if cols.len() < 4 {
            continue;
        }

        let protocol = cols[0].to_string();
        let local = cols[1].to_string();
        let remote = cols[2].to_string();

        let (state, pid) = if cols.len() >= 5 {
            (cols[3].to_string(), cols[4].to_string())
        } else {
            (String::new(), cols[3].to_string())
        };

        // Skip local-only and listening uninteresting
        if remote == "0.0.0.0:0" || remote == "[::]:0" {
            continue;
        }
        if remote.starts_with("127.") || remote.starts_with("[::1]") {
            continue;
        }

        let process_name = get_process_name(&pid);
        let (risk, risk_reason) = assess_risk(&remote, &process_name);

        conns.push(NetworkConnection {
            protocol,
            local_addr: local,
            remote_addr: remote,
            state,
            pid,
            process_name,
            risk,
            risk_reason,
        });

        if conns.len() >= 50 {
            break;
        } // limit output
    }
    conns
}

// ═══════════════════════════════════════════════════════════════
// DATA LEAK SCANNER — Clipboard'da sezgir ma'lumot tekshiruvi
// ═══════════════════════════════════════════════════════════════
#[derive(serde::Serialize)]
pub struct DataLeakAlert {
    pub alert_type: String,
    pub description: String,
    pub severity: String,
    pub snippet: String,
}

#[command]
fn scan_clipboard_for_leaks() -> Vec<DataLeakAlert> {
    let mut alerts: Vec<DataLeakAlert> = Vec::new();

    #[cfg(target_os = "windows")]
    {
        let clip = ps("Get-Clipboard");
        let text = clip.trim();
        if text.is_empty() {
            return alerts;
        }

        // Detect patterns
        check_pattern(
            text,
            r"(?i)(password|parol|pwd|pass)\s*[=:]\s*\S+",
            "Parol",
            "Clipboard'da parol iborasi topildi — nusxa olishdan ehtiyot bo'ling",
            "critical",
            &mut alerts,
        );

        check_pattern(
            text,
            r"\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b",
            "Karta Raqami",
            "Clipboard'da 16 xonali karta raqamiga o'xshash son topildi",
            "critical",
            &mut alerts,
        );

        check_pattern(
            text,
            r"\b[A-Z]{2}\d{7}\b",
            "Pasport Raqami",
            "O'zbek pasport formatiga o'xshash ma'lumot topildi",
            "high",
            &mut alerts,
        );

        check_pattern(
            text,
            r"eyJ[A-Za-z0-9+/=]{20,}",
            "JWT Token",
            "Clipboard'da autentifikatsiya tokeni topildi — noto'g'ri joyga yubormaslik kerak",
            "high",
            &mut alerts,
        );

        check_pattern(
            text,
            r"(?i)(secret|api[_\-]?key|token|private[_\-]?key)\s*[=:]\s*\S+",
            "API Kalit",
            "Clipboard'da maxfiy API kalit yoki token iborasi topildi",
            "high",
            &mut alerts,
        );

        check_pattern(
            text,
            r"\b\d{2,3}-\d{3}-\d{2}-\d{2}\b",
            "PINFL / Shaxsiy Raqam",
            "O'zbekiston PINFL formatiga o'xshash 14 xonali son topildi",
            "medium",
            &mut alerts,
        );
    }

    alerts
}

fn check_pattern(
    text: &str,
    pattern: &str,
    alert_type: &str,
    desc: &str,
    severity: &str,
    alerts: &mut Vec<DataLeakAlert>,
) {
    // Simple substring-based checks (no regex crate needed)
    let found = match alert_type {
        "Parol" => {
            let t = text.to_lowercase();
            t.contains("password=")
                || t.contains("parol=")
                || t.contains("pwd=")
                || t.contains("pass=")
        }
        "Karta Raqami" => {
            // Check 16 consecutive digits (with possible spaces/dashes)
            let digits_only: String = text.chars().filter(|c| c.is_ascii_digit()).collect();
            digits_only.len() >= 16
                && (text.contains(' ') || text.contains('-') || digits_only.len() == 16)
        }
        "Pasport Raqami" => {
            // 2 uppercase letters followed by 7 digits
            let bytes = text.as_bytes();
            for i in 0..bytes.len().saturating_sub(8) {
                if bytes[i].is_ascii_uppercase() && bytes[i + 1].is_ascii_uppercase() {
                    let digits = &text[i + 2..];
                    if digits.starts_with(|c: char| c.is_ascii_digit()) {
                        let num_digits = digits
                            .chars()
                            .take(7)
                            .filter(|c| c.is_ascii_digit())
                            .count();
                        if num_digits == 7 {
                            return alerts.push(DataLeakAlert {
                                alert_type: alert_type.into(),
                                description: desc.into(),
                                severity: severity.into(),
                                snippet: text.chars().take(30).collect::<String>() + "...",
                            });
                        }
                    }
                }
            }
            false
        }
        "JWT Token" => text.contains("eyJ"),
        "API Kalit" => {
            let t = text.to_lowercase();
            t.contains("secret=")
                || t.contains("api_key=")
                || t.contains("apikey=")
                || t.contains("token=")
                || t.contains("private_key=")
        }
        "PINFL / Shaxsiy Raqam" => {
            let digits_only: String = text.chars().filter(|c| c.is_ascii_digit()).collect();
            digits_only.len() == 14
        }
        _ => text.to_lowercase().contains(&pattern.to_lowercase()),
    };

    if found {
        let snippet: String = text.chars().take(40).collect::<String>();
        let snippet = format!("{}...", snippet);
        alerts.push(DataLeakAlert {
            alert_type: alert_type.into(),
            description: desc.into(),
            severity: severity.into(),
            snippet,
        });
    }
    let _ = pattern; // suppress warning
}

// ═══════════════════════════════════════════════════════════════
// NETWORK SCANNER — Real ARP scan
// ═══════════════════════════════════════════════════════════════
#[derive(serde::Serialize)]
struct NetworkDevice {
    name: String,
    ip: String,
    mac: String,
    device_type: String,
    status: String,
}

#[command]
fn scan_network(target: String) -> Vec<NetworkDevice> {
    let mut devices: Vec<NetworkDevice> = Vec::new();

    #[cfg(target_os = "windows")]
    {
        let base_ip = target.split('/').next().unwrap_or("192.168.1.0");
        let parts: Vec<&str> = base_ip.split('.').collect();
        if parts.len() == 4 {
            let prefix = format!("{}.{}.{}.", parts[0], parts[1], parts[2]);
            let _ = std::process::Command::new("powershell")
                .creation_flags(0x08000000)
                .args([
                    "-NoProfile",
                    "-WindowStyle",
                    "Hidden",
                    "-Command",
                    &format!(
                        "1..254 | ForEach-Object {{ ping -n 1 -w 150 {}{} | Out-Null }}",
                        prefix, "$_"
                    ),
                ])
                .output();
        }

        let arp_out = std::process::Command::new("arp").creation_flags(0x08000000).args(["-a"]).output();
        if let Ok(out) = arp_out {
            let text = String::from_utf8_lossy(&out.stdout);
            for line in text.lines() {
                let cols: Vec<&str> = line.split_whitespace().collect();
                if cols.len() >= 2 {
                    let ip = cols[0];
                    let mac = cols[1];
                    if (ip.starts_with("192.168")
                        || ip.starts_with("10.")
                        || ip.starts_with("172."))
                        && (mac.contains('-') || mac.contains(':'))
                    {
                        let mac_clean = mac.replace('-', ":").to_uppercase();
                        let (name, dtype) = classify_device(&mac_clean, ip);
                        let status = if mac_clean.starts_with("DE:AD:BE") {
                            "unknown"
                        } else {
                            "safe"
                        };
                        devices.push(NetworkDevice {
                            name,
                            ip: ip.to_string(),
                            mac: mac_clean,
                            device_type: dtype,
                            status: status.to_string(),
                        });
                    }
                }
            }
        }
    }
    devices
}

fn classify_device(mac: &str, ip: &str) -> (String, String) {
    if ip.ends_with(".1") {
        return ("Router / Gateway".into(), "📡".into());
    }
    let oui = &mac[..8.min(mac.len())].to_uppercase();
    let name = match oui.as_str() {
        "00:16:32" | "00:17:C9" | "34:AA:8B" | "5C:3C:27" => "Samsung Qurilma",
        "00:17:F2" | "3C:D0:F8" | "A4:C3:F0" => "Apple Qurilma",
        "54:60:09" | "3C:5A:B4" => "Google Qurilma",
        "50:C7:BF" | "A0:F3:C1" | "98:DA:C4" => "TP-Link Router",
        _ => "Noma'lum Qurilma",
    };
    let dtype = if name.contains("Router") {
        "📡"
    } else if name.contains("Apple") {
        "🍎"
    } else if name.contains("Samsung") {
        "📱"
    } else {
        "❓"
    };
    (name.into(), dtype.into())
}

// ═══════════════════════════════════════════════════════════════
// MODULE STATE PERSISTENCE
// ═══════════════════════════════════════════════════════════════
#[command]
fn set_module_state(module: String, enabled: bool) -> bool {
    db::set_setting(
        &format!("module_{}", module),
        if enabled { "true" } else { "false" },
    )
    .is_ok()
}

#[command]
fn get_module_states() -> HashMap<String, bool> {
    db::get_all_module_settings()
}

// ═══════════════════════════════════════════════════════════════
// AUTO-START (Windows Registry)
// ═══════════════════════════════════════════════════════════════
#[command]
fn set_autostart(enabled: bool) -> bool {
    #[cfg(target_os = "windows")]
    {
        let exe = std::env::current_exe()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();
        let cmd = if enabled {
            format!("Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' -Name 'SERGAK' -Value '\"{}\"'", exe)
        } else {
            "Remove-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' -Name 'SERGAK' -ErrorAction SilentlyContinue".to_string()
        };
        ps_run(&cmd)
    }
    #[cfg(not(target_os = "windows"))]
    {
        false
    }
}

#[command]
fn get_autostart() -> bool {
    #[cfg(target_os = "windows")]
    {
        let out = ps("Get-ItemProperty 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' -Name 'SERGAK' -ErrorAction SilentlyContinue");
        !out.trim().is_empty()
    }
    #[cfg(not(target_os = "windows"))]
    {
        false
    }
}

// ═══════════════════════════════════════════════════════════════
// LICENSE VERIFICATION
// ═══════════════════════════════════════════════════════════════
#[command]
fn verify_premium_key(device_id: String, key: String) -> bool {
    let decoded = match general_purpose::STANDARD.decode(key) {
        Ok(v) => v,
        Err(_) => return false,
    };
    let decoded_str = match String::from_utf8(decoded) {
        Ok(v) => v,
        Err(_) => return false,
    };
    let parts: Vec<&str> = decoded_str.split('|').collect();
    if parts.len() != 2 {
        return false;
    }
    let signature = parts[0];
    let expiry_str = parts[1];
    let msg = format!("{}|{}", device_id, expiry_str);
    let mut signature_valid = verify_rsa_signature(&msg, signature);
    if !signature_valid {
        let legacy_msg = format!("{}{}", device_id, expiry_str);
        if let Ok(mut mac) = HmacSha256::new_from_slice(SECRET_KEY.as_bytes()) {
            mac.update(legacy_msg.as_bytes());
            let result = mac.finalize();
            let expected = general_purpose::STANDARD.encode(result.into_bytes());
            if signature == expected {
                signature_valid = true;
            }
        }
    }
    if !signature_valid {
        return false;
    }
    if let Ok(expiry_date) = chrono::DateTime::parse_from_rfc3339(expiry_str) {
        if chrono::Utc::now() < expiry_date {
            return true;
        }
    } else if let Ok(naive_dt) =
        chrono::NaiveDateTime::parse_from_str(expiry_str, "%Y-%m-%dT%H:%M:%S%.f")
    {
        if chrono::Utc::now().naive_utc() < naive_dt {
            return true;
        }
    }
    false
}

// ═══════════════════════════════════════════════════════════════
// SYSTEM STATS
// ═══════════════════════════════════════════════════════════════
#[command]
fn get_system_stats(state: tauri::State<'_, AppState>) -> (f32, u64, u64) {
    let mut sys = state.sys.lock().unwrap();
    sys.refresh_cpu_usage();
    sys.refresh_memory();
    (
        sys.global_cpu_info().cpu_usage(),
        sys.total_memory(),
        sys.used_memory(),
    )
}

// ═══════════════════════════════════════════════════════════════
// APP ENTRY
// ═══════════════════════════════════════════════════════════════
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_notification::init())
        .manage(AppState {
            sys: Mutex::new(System::new_all()),
        })
        .plugin(tauri_plugin_opener::init())
        .setup(|_app| {
            let _ = db::init_db();
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            // Core
            verify_premium_key,
            get_system_stats,
            get_device_id,
            // Vulnerability Scanner
            scan_vulnerabilities,
            fix_vulnerability,
            // Network
            scan_network,
            get_active_connections,
            // Data Guard
            scan_clipboard_for_leaks,
            // Module state
            set_module_state,
            get_module_states,
            // Auto-start
            set_autostart,
            get_autostart,
            // AI
            ai::check_ollama_status,
            ai::start_ollama_service,
            ai::pull_ai_model,
            ai::analyze_threat_with_ai,
            quarantine::list_quarantine,
            quarantine::quarantine_file,
            quarantine::restore_file,
            quarantine::delete_quarantine,
            // Hash DB
            hash_db::check_file_hash,
            hash_db::update_hash_db,
            hash_db::get_hash_db_stats,
            // FS Monitor
            fs_monitor::start_fs_monitor,
            fs_monitor::stop_fs_monitor,
            fs_monitor::get_fs_alerts,
            // Process Monitor
            process_monitor::get_process_tree,
            process_monitor::monitor_startup_items,
            // Phone Link
            phone_link::start_websocket_server,
            phone_link::get_connected_phone,
            phone_link::disconnect_phone,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
