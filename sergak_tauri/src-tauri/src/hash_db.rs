use crate::db::get_db_path;
/// hash_db.rs — MalwareBazaar dan zararli dasturlar hash bazasini saqlash va tekshirish
use rusqlite::Connection;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
pub struct HashMatch {
    pub sha256: String,
    pub malware_name: String,
    pub severity: String,
    pub family: String,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct HashDbStats {
    pub total_hashes: i64,
    pub last_updated: String,
}

/// Hash jadvali yaratish (agar mavjud bo'lmasa)
pub fn init_hash_db() -> rusqlite::Result<()> {
    let path = get_db_path();
    let conn = Connection::open(&path)?;
    conn.execute(
        "CREATE TABLE IF NOT EXISTS malware_hashes (
            sha256      TEXT PRIMARY KEY,
            name        TEXT NOT NULL,
            severity    TEXT NOT NULL DEFAULT 'medium',
            family      TEXT NOT NULL DEFAULT 'unknown',
            date_added  TEXT NOT NULL
        )",
        [],
    )?;
    conn.execute(
        "CREATE TABLE IF NOT EXISTS hash_db_meta (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )",
        [],
    )?;
    Ok(())
}

/// Berilgan sha256 hashni malware bazasida tekshirish
#[tauri::command]
pub fn check_file_hash(sha256: String) -> Option<HashMatch> {
    let path = get_db_path();
    let conn = Connection::open(&path).ok()?;
    let mut stmt = conn
        .prepare("SELECT sha256, name, severity, family FROM malware_hashes WHERE sha256 = ?1")
        .ok()?;
    let mut rows = stmt.query([&sha256]).ok()?;
    if let Some(row) = rows.next().ok()? {
        Some(HashMatch {
            sha256: row.get(0).unwrap_or_default(),
            malware_name: row.get(1).unwrap_or_default(),
            severity: row.get(2).unwrap_or_default(),
            family: row.get(3).unwrap_or_default(),
        })
    } else {
        None
    }
}

/// Hash DB statistikasi
#[tauri::command]
pub fn get_hash_db_stats() -> HashDbStats {
    let path = get_db_path();
    let default = HashDbStats {
        total_hashes: 0,
        last_updated: "Hali yangilanmagan".to_string(),
    };
    let conn = match Connection::open(&path) {
        Ok(c) => c,
        Err(_) => return default,
    };

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM malware_hashes", [], |r| r.get(0))
        .unwrap_or(0);

    let last_updated: String = conn
        .query_row(
            "SELECT value FROM hash_db_meta WHERE key = 'last_updated'",
            [],
            |r| r.get(0),
        )
        .unwrap_or_else(|_| "Hali yangilanmagan".to_string());

    HashDbStats {
        total_hashes: count,
        last_updated,
    }
}

/// MalwareBazaar'dan yangi hashlar yuklab olish (HTTP orqali)
/// Bu funksiya async bo'lgani sababli tokio runtime'da ishlaydi
#[tauri::command]
pub async fn update_hash_db() -> Result<String, String> {
    let _ = init_hash_db();

    // MalwareBazaar query_tag API orqali oxirgi 1000 ta yozuvni olish
    // (bepul, API key kerak emas)
    let client = reqwest::Client::new();

    // Bir nechta tahdid turlarini yuklaymiz
    let tags = vec!["AgentTesla", "Emotet", "Redline", "Raccoon", "Formbook"];
    let mut total_inserted: i64 = 0;

    let path = get_db_path();
    let conn = Connection::open(&path).map_err(|e| e.to_string())?;

    for tag in &tags {
        let res = client
            .post("https://mb-api.abuse.ch/api/v1/")
            .form(&[("query", "get_taginfo"), ("tag", tag), ("limit", "200")])
            .send()
            .await;

        if let Ok(resp) = res {
            if let Ok(json) = resp.json::<serde_json::Value>().await {
                if let Some(data) = json.get("data").and_then(|d| d.as_array()) {
                    for entry in data {
                        let sha256 = entry
                            .get("sha256_hash")
                            .and_then(|v| v.as_str())
                            .unwrap_or("")
                            .to_string();
                        let name = entry
                            .get("signature")
                            .and_then(|v| v.as_str())
                            .unwrap_or(tag)
                            .to_string();
                        let date_added = chrono::Utc::now().to_rfc3339();

                        if !sha256.is_empty() {
                            let _ = conn.execute(
                                "INSERT OR IGNORE INTO malware_hashes (sha256, name, severity, family, date_added) VALUES (?1, ?2, ?3, ?4, ?5)",
                                [&sha256, &name, "high", tag, &date_added],
                            );
                            total_inserted += 1;
                        }
                    }
                }
            }
        }
    }

    // Meta yangilash
    let now = chrono::Utc::now().format("%Y-%m-%d %H:%M UTC").to_string();
    let _ = conn.execute(
        "INSERT OR REPLACE INTO hash_db_meta (key, value) VALUES ('last_updated', ?1)",
        [&now],
    );

    Ok(format!(
        "✅ {} ta hash bazaga qo'shildi. Yangilangan: {}",
        total_inserted, now
    ))
}
