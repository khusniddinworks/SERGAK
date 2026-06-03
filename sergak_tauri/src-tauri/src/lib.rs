use tauri::command;
use hmac::{Hmac, Mac};
use sha2::Sha256;
use base64::{Engine as _, engine::general_purpose};
use sysinfo::System;
use std::sync::Mutex;

const SECRET_KEY: &str = "SERGAKxavfsizlik2026TAFUxusniddinSecret!";

type HmacSha256 = Hmac<Sha256>;

struct AppState {
    sys: Mutex<System>,
}

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
    
    let mut mac = match HmacSha256::new_from_slice(SECRET_KEY.as_bytes()) {
        Ok(m) => m,
        Err(_) => return false,
    };
    let msg = format!("{}{}", device_id, expiry_str);
    mac.update(msg.as_bytes());
    
    let result = mac.finalize();
    let expected = general_purpose::STANDARD.encode(result.into_bytes());
    
    if signature != expected {
        return false;
    }
    
    // Check expiration using chrono
    if let Ok(expiry_date) = chrono::DateTime::parse_from_rfc3339(expiry_str) {
        if chrono::Utc::now() < expiry_date {
            return true;
        }
    } else if let Ok(naive_dt) = chrono::NaiveDateTime::parse_from_str(expiry_str, "%Y-%m-%dT%H:%M:%S%.f") {
        if chrono::Utc::now().naive_utc() < naive_dt {
            return true;
        }
    }
    
    false
}

#[command]
fn get_system_stats(state: tauri::State<'_, AppState>) -> (f32, u64, u64) {
    let mut sys = state.sys.lock().unwrap();
    sys.refresh_cpu_usage();
    sys.refresh_memory();
    
    let cpu_usage = sys.global_cpu_usage();
    let total_ram = sys.total_memory();
    let used_ram = sys.used_memory();
    
    (cpu_usage, total_ram, used_ram)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(AppState { sys: Mutex::new(System::new_all()) })
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![verify_premium_key, get_system_stats])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
