use rusqlite::{Connection, Result};
use std::collections::HashMap;
use std::path::PathBuf;

pub fn get_db_path() -> PathBuf {
    let mut path = dirs::data_dir().unwrap_or_else(|| std::env::temp_dir());
    path.push("SERGAK");
    std::fs::create_dir_all(&path).unwrap_or_default();
    path.push("sergak.db");
    path
}

pub fn init_db() -> Result<()> {
    let path = get_db_path();
    let conn = Connection::open(&path)?;

    // Create tables if they don't exist
    conn.execute(
        "CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS quarantine (
            id TEXT PRIMARY KEY,
            original_path TEXT NOT NULL,
            quarantine_path TEXT NOT NULL,
            threat_name TEXT NOT NULL,
            date_added TEXT NOT NULL,
            sha256 TEXT NOT NULL
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS scan_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scan_type TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            threats_found INTEGER NOT NULL
        )",
        [],
    )?;

    // Initialize default module settings if they don't exist
    let default_modules = vec![
        ("module_gateway", "true"),
        ("module_usb", "true"),
        ("module_camera", "true"),
        ("module_keylogger", "true"),
        ("module_honeypot", "true"),
    ];

    for (key, val) in default_modules {
        conn.execute(
            "INSERT OR IGNORE INTO settings (key, value) VALUES (?1, ?2)",
            [key, val],
        )?;
    }

    Ok(())
}

pub fn set_setting(key: &str, value: &str) -> Result<()> {
    let path = get_db_path();
    let conn = Connection::open(&path)?;
    conn.execute(
        "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
        [key, value],
    )?;
    Ok(())
}

pub fn get_setting(key: &str, default: &str) -> String {
    let path = get_db_path();
    if let Ok(conn) = Connection::open(&path) {
        let mut stmt = conn
            .prepare("SELECT value FROM settings WHERE key = ?1")
            .unwrap();
        let mut rows = stmt.query([key]).unwrap();
        if let Some(row) = rows.next().unwrap() {
            return row.get(0).unwrap_or_else(|_| default.to_string());
        }
    }
    default.to_string()
}

pub fn get_all_module_settings() -> HashMap<String, bool> {
    let mut map = HashMap::new();
    let modules = ["gateway", "usb", "camera", "keylogger", "honeypot"];
    for m in &modules {
        let key = format!("module_{}", m);
        let val = get_setting(&key, "true");
        map.insert(m.to_string(), val == "true");
    }
    map
}
