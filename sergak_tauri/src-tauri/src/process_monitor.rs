/// process_monitor.rs — Kengaytirilgan Windows jarayonlari va startup tahlili
use serde::{Deserialize, Serialize};
use std::process::Command;
use sysinfo::System;
use tauri::command;

#[derive(Serialize, Deserialize, Clone)]
pub struct ProcessNode {
    pub pid: u32,
    pub name: String,
    pub parent_pid: Option<u32>,
    pub is_suspicious: bool,
    pub reason: String,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct StartupItem {
    pub name: String,
    pub command: String,
    pub location: String, // "HKCU", "HKLM", "Task"
}

/// Jarayon daraxtini tahlil qilish (ayniqsa parent-child)
#[command]
pub fn get_process_tree() -> Vec<ProcessNode> {
    let mut sys = System::new_all();
    sys.refresh_processes();

    let mut nodes = Vec::new();

    for (pid, process) in sys.processes() {
        let name = process.name().to_string();
        let ppid = process.parent().map(|p| p.as_u32());
        let pid_u32 = pid.as_u32();

        let mut is_suspicious = false;
        let mut reason = String::new();

        // Asosiy shubhali parent-child munosabatlari
        // Masalan: Word/Excel -> cmd/powershell ishga tushirishi = zararli
        let name_lower = name.to_lowercase();

        if [
            "cmd.exe",
            "powershell.exe",
            "pwsh.exe",
            "wscript.exe",
            "cscript.exe",
            "mshta.exe",
        ]
        .contains(&name_lower.as_str())
        {
            if let Some(parent_pid) = ppid {
                if let Some(parent) = sys.process(sysinfo::Pid::from_u32(parent_pid)) {
                    let parent_name = parent.name().to_string().to_lowercase();
                    if [
                        "winword.exe",
                        "excel.exe",
                        "powerpnt.exe",
                        "outlook.exe",
                        "chrome.exe",
                        "msedge.exe",
                    ]
                    .contains(&parent_name.as_str())
                    {
                        is_suspicious = true;
                        reason = format!("{} tomonidan ishga tushirildi (XAVFLI!)", parent_name);
                    }
                }
            }
        }

        nodes.push(ProcessNode {
            pid: pid_u32,
            name,
            parent_pid: ppid,
            is_suspicious,
            reason,
        });
    }

    // Sort suspicious first
    nodes.sort_by(|a, b| b.is_suspicious.cmp(&a.is_suspicious));
    nodes
}

/// Windows Startup itemlarini tekshirish (Registry)
#[command]
pub fn monitor_startup_items() -> Vec<StartupItem> {
    let mut items = Vec::new();

    #[cfg(target_os = "windows")]
    {
        // HKCU Run
        let hkcu_out = Command::new("powershell")
            .args(["-NoProfile", "-Command", "Get-ItemProperty 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' | Select-Object -Property * -ExcludeProperty PSPath,PSParentPath,PSChildName,PSDrive,PSProvider,ItemType"])
            .output();

        if let Ok(out) = hkcu_out {
            let text = String::from_utf8_lossy(&out.stdout);
            for line in text.lines() {
                if line.contains(':') && !line.starts_with("---") {
                    let parts: Vec<&str> = line.splitn(2, ':').collect();
                    if parts.len() == 2 {
                        items.push(StartupItem {
                            name: parts[0].trim().to_string(),
                            command: parts[1].trim().to_string(),
                            location: "HKCU\\Run".to_string(),
                        });
                    }
                }
            }
        }

        // HKLM Run
        let hklm_out = Command::new("powershell")
            .args(["-NoProfile", "-Command", "Get-ItemProperty 'HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run' | Select-Object -Property * -ExcludeProperty PSPath,PSParentPath,PSChildName,PSDrive,PSProvider,ItemType"])
            .output();

        if let Ok(out) = hklm_out {
            let text = String::from_utf8_lossy(&out.stdout);
            for line in text.lines() {
                if line.contains(':') && !line.starts_with("---") {
                    let parts: Vec<&str> = line.splitn(2, ':').collect();
                    if parts.len() == 2 {
                        items.push(StartupItem {
                            name: parts[0].trim().to_string(),
                            command: parts[1].trim().to_string(),
                            location: "HKLM\\Run".to_string(),
                        });
                    }
                }
            }
        }
    }

    items
}
