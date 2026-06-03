use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use tauri::command;
use aes_gcm::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    Aes256Gcm, Key, Nonce
};
use rand::RngCore;
use std::fs;
use rusqlite::Connection;
use crate::db::get_db_path;

const QUARANTINE_KEY: &[u8; 32] = b"SERGAK_AES256_QUARANTINE_KEY_32B";

#[derive(Serialize, Deserialize, Clone)]
pub struct QuarantineItem {
    pub id: String,
    pub original_path: String,
    pub quarantine_path: String,
    pub threat_name: String,
    pub date_added: String,
    pub sha256: String,
}

pub fn get_quarantine_dir() -> PathBuf {
    let mut path = dirs::data_dir().unwrap_or_else(|| std::env::temp_dir());
    path.push("SERGAK");
    path.push("quarantine");
    fs::create_dir_all(&path).unwrap_or_default();
    path
}

#[command]
pub fn list_quarantine() -> Vec<QuarantineItem> {
    let mut items = Vec::new();
    let db_path = get_db_path();
    
    if let Ok(conn) = Connection::open(&db_path) {
        let mut stmt = conn.prepare("SELECT id, original_path, quarantine_path, threat_name, date_added, sha256 FROM quarantine").unwrap();
        let rows = stmt.query_map([], |row| {
            Ok(QuarantineItem {
                id: row.get(0)?,
                original_path: row.get(1)?,
                quarantine_path: row.get(2)?,
                threat_name: row.get(3)?,
                date_added: row.get(4)?,
                sha256: row.get(5)?,
            })
        });

        if let Ok(mapped_rows) = rows {
            for item in mapped_rows.flatten() {
                items.push(item);
            }
        }
    }
    items
}

#[command]
pub fn quarantine_file(original_path: String, threat_name: String) -> bool {
    let path = Path::new(&original_path);
    if !path.exists() {
        return false;
    }

    // 1. Read file
    let data = match fs::read(path) {
        Ok(d) => d,
        Err(_) => return false,
    };

    // 2. Encrypt
    let key = Key::<Aes256Gcm>::from_slice(QUARANTINE_KEY);
    let cipher = Aes256Gcm::new(key);
    let nonce = Aes256Gcm::generate_nonce(&mut OsRng); // 96-bits; unique per message
    
    let encrypted_data = match cipher.encrypt(&nonce, data.as_ref()) {
        Ok(d) => d,
        Err(_) => return false,
    };

    // Prepend nonce to the encrypted file
    let mut final_data = nonce.to_vec();
    final_data.extend_from_slice(&encrypted_data);

    // 3. Save to quarantine folder
    let id = format!("{:016x}", rand::thread_rng().next_u64());
    let mut q_path = get_quarantine_dir();
    q_path.push(format!("{}.srgk", id));

    if fs::write(&q_path, final_data).is_err() {
        return false;
    }

    // 4. Delete original file
    let _ = fs::remove_file(path);

    // 5. Calculate SHA256 (of original data) for DB
    use sha2::{Sha256, Digest};
    let mut hasher = Sha256::new();
    hasher.update(&data);
    let sha256_hash = format!("{:x}", hasher.finalize());

    // 6. Save to DB
    let db_path = get_db_path();
    if let Ok(conn) = Connection::open(&db_path) {
        let date_added = chrono::Utc::now().to_rfc3339();
        let _ = conn.execute(
            "INSERT INTO quarantine (id, original_path, quarantine_path, threat_name, date_added, sha256) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            [&id, &original_path, q_path.to_str().unwrap(), &threat_name, &date_added, &sha256_hash],
        );
    }

    true
}

#[command]
pub fn restore_file(id: String) -> bool {
    let db_path = get_db_path();
    let conn = match Connection::open(&db_path) {
        Ok(c) => c,
        Err(_) => return false,
    };

    let mut stmt = match conn.prepare("SELECT original_path, quarantine_path FROM quarantine WHERE id = ?1") {
        Ok(s) => s,
        Err(_) => return false,
    };

    let mut rows = stmt.query([&id]).unwrap();
    if let Some(row) = rows.next().unwrap() {
        let orig_path: String = row.get(0).unwrap();
        let q_path: String = row.get(1).unwrap();

        // 1. Read encrypted file
        let data = match fs::read(&q_path) {
            Ok(d) => d,
            Err(_) => return false,
        };

        if data.len() < 12 { return false; }

        // 2. Decrypt
        let (nonce_bytes, ciphertext) = data.split_at(12);
        let nonce = Nonce::from_slice(nonce_bytes);
        let key = Key::<Aes256Gcm>::from_slice(QUARANTINE_KEY);
        let cipher = Aes256Gcm::new(key);

        let decrypted_data = match cipher.decrypt(nonce, ciphertext) {
            Ok(d) => d,
            Err(_) => return false,
        };

        // 3. Write back to original path
        if fs::write(&orig_path, decrypted_data).is_ok() {
            // 4. Remove from quarantine and DB
            let _ = fs::remove_file(&q_path);
            let _ = conn.execute("DELETE FROM quarantine WHERE id = ?1", [&id]);
            return true;
        }
    }
    false
}

#[command]
pub fn delete_quarantine(id: String) -> bool {
    let db_path = get_db_path();
    let conn = match Connection::open(&db_path) {
        Ok(c) => c,
        Err(_) => return false,
    };

    let mut stmt = match conn.prepare("SELECT quarantine_path FROM quarantine WHERE id = ?1") {
        Ok(s) => s,
        Err(_) => return false,
    };

    let mut rows = stmt.query([&id]).unwrap();
    if let Some(row) = rows.next().unwrap() {
        let q_path: String = row.get(0).unwrap();
        let _ = fs::remove_file(&q_path);
        let _ = conn.execute("DELETE FROM quarantine WHERE id = ?1", [&id]);
        return true;
    }
    false
}
