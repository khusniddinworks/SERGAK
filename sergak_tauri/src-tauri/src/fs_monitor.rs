/// fs_monitor.rs — Windows fayl tizimi monitoringi (notify)
use notify::{Event, EventKind, RecommendedWatcher, RecursiveMode, Watcher};
use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct FsAlert {
    pub id: String,
    pub path: String,
    pub action: String, // "created", "modified"
    pub sha256: String,
    pub timestamp: String,
    pub is_threat: bool,
    pub threat_name: String,
}

// Global state for alerts
pub static FS_ALERTS: Lazy<Arc<Mutex<Vec<FsAlert>>>> =
    Lazy::new(|| Arc::new(Mutex::new(Vec::new())));
// Global state for watcher to keep it alive
static WATCHER: Lazy<Arc<Mutex<Option<RecommendedWatcher>>>> =
    Lazy::new(|| Arc::new(Mutex::new(None)));

#[tauri::command]
pub fn start_fs_monitor() -> bool {
    let mut watcher_guard = WATCHER.lock().unwrap();
    if watcher_guard.is_some() {
        return true; // Already running
    }

    let mut watcher = match notify::recommended_watcher(|res: notify::Result<Event>| match res {
        Ok(event) => handle_fs_event(event),
        Err(e) => println!("watch error: {:?}", e),
    }) {
        Ok(w) => w,
        Err(_) => return false,
    };

    // Watch key directories
    let dirs_to_watch = vec![
        dirs::download_dir(),
        dirs::desktop_dir(),
        Some(std::env::temp_dir()),
    ];

    for dir in dirs_to_watch.into_iter().flatten() {
        let _ = watcher.watch(&dir, RecursiveMode::Recursive);
    }

    *watcher_guard = Some(watcher);
    true
}

#[tauri::command]
pub fn stop_fs_monitor() -> bool {
    let mut watcher_guard = WATCHER.lock().unwrap();
    *watcher_guard = None; // Drops the watcher, stopping it
    true
}

#[tauri::command]
pub fn get_fs_alerts() -> Vec<FsAlert> {
    let alerts = FS_ALERTS.lock().unwrap();
    alerts.clone()
}

fn handle_fs_event(event: Event) {
    let action = match event.kind {
        EventKind::Create(_) => "created",
        EventKind::Modify(_) => "modified",
        _ => return,
    };

    for path in event.paths {
        if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
            let ext_lower = ext.to_lowercase();
            if ["exe", "dll", "bat", "ps1", "vbs"].contains(&ext_lower.as_str()) {
                analyze_file(&path, action);
            }
        }
    }
}

fn analyze_file(path: &Path, action: &str) {
    // 1. Calculate SHA256
    let hash = match calculate_hash(path) {
        Some(h) => h,
        None => return,
    };

    // 2. Check against Hash DB
    let is_threat;
    let threat_name;

    // Call the check_file_hash function from hash_db module
    // We need to use crate::hash_db::check_file_hash
    if let Some(match_info) = crate::hash_db::check_file_hash(hash.clone()) {
        is_threat = true;
        threat_name = match_info.malware_name;
    } else {
        is_threat = false;
        threat_name = "Noma'lum".to_string();
    }

    let alert = FsAlert {
        id: format!("{:x}", rand::random::<u64>()),
        path: path.to_string_lossy().to_string(),
        action: action.to_string(),
        sha256: hash,
        timestamp: chrono::Utc::now().to_rfc3339(),
        is_threat,
        threat_name,
    };

    let mut alerts = FS_ALERTS.lock().unwrap();
    alerts.push(alert);

    // Keep only last 100 alerts
    if alerts.len() > 100 {
        alerts.remove(0);
    }
}

fn calculate_hash(path: &Path) -> Option<String> {
    // Read up to 10MB to avoid freezing on huge files
    use std::io::Read;
    let mut file = match fs::File::open(path) {
        Ok(f) => f,
        Err(_) => return None,
    };

    let mut hasher = Sha256::new();
    let mut buffer = [0; 8192];
    let mut bytes_read = 0;
    let max_bytes = 10 * 1024 * 1024; // 10MB

    while let Ok(count) = file.read(&mut buffer) {
        if count == 0 {
            break;
        }
        hasher.update(&buffer[..count]);
        bytes_read += count;
        if bytes_read >= max_bytes {
            break;
        }
    }

    Some(format!("{:x}", hasher.finalize()))
}
