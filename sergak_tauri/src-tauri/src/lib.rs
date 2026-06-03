use tauri::command;
use hmac::{Hmac, Mac};
use sha2::Sha256;
use base64::{Engine as _, engine::general_purpose};
use sysinfo::System;
use std::sync::Mutex;
use rsa::{RsaPublicKey, pkcs8::DecodePublicKey};
use rsa::Pkcs1v15Sign;
use sha2::Digest;

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
    
    pub_key.verify(Pkcs1v15Sign::new::<Sha256>(), &hashed, &sig_bytes).is_ok()
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
    
    let msg = format!("{}|{}", device_id, expiry_str);
    
    // RSA verification (primary)
    let mut signature_valid = verify_rsa_signature(&msg, signature);
    
    // HMAC-SHA256 verification (fallback)
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
    
    let cpu_usage = sys.global_cpu_info().cpu_usage();
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
