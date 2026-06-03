use serde::{Deserialize, Serialize};
use std::process::Command;
use std::os::windows::process::CommandExt;
use tauri::command;

#[derive(Serialize, Deserialize, Clone)]
pub struct AiResponse {
    pub success: bool,
    pub message: String,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct OllamaStatus {
    pub is_installed: bool,
    pub is_running: bool,
    pub has_llama3_2: bool,
}

// 1. Check if Ollama is installed and running
#[command]
pub async fn check_ollama_status() -> OllamaStatus {
    let mut status = OllamaStatus {
        is_installed: false,
        is_running: false,
        has_llama3_2: false,
    };

    // Check installation by running `ollama --version`
    #[cfg(target_os = "windows")]
    {
        let output = Command::new("cmd")
            .creation_flags(0x08000000)
            .args(["/C", "ollama --version"])
            .output();
        if let Ok(out) = output {
            if out.status.success() {
                status.is_installed = true;
            }
        }
    }

    if !status.is_installed {
        return status;
    }

    // Check if it's running via HTTP API
    if let Ok(resp) = reqwest::get("http://localhost:11434/api/tags").await {
        if resp.status().is_success() {
            status.is_running = true;

            // Check if llama3.2 is installed
            if let Ok(json) = resp.json::<serde_json::Value>().await {
                if let Some(models) = json.get("models").and_then(|m| m.as_array()) {
                    for model in models {
                        if let Some(name) = model.get("name").and_then(|n| n.as_str()) {
                            if name.starts_with("llama3.2") {
                                status.has_llama3_2 = true;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    status
}

// 2. Start Ollama service automatically if not running
#[command]
pub async fn start_ollama_service() -> bool {
    #[cfg(target_os = "windows")]
    {
        // Try starting the Ollama background process silently
        let _ = Command::new("cmd")
            .creation_flags(0x08000000)
            .args(["/C", "start /B ollama serve"])
            .spawn();

        // Wait a bit for the server to spin up
        tokio::time::sleep(tokio::time::Duration::from_secs(3)).await;

        let status = check_ollama_status().await;
        return status.is_running;
    }
    #[cfg(not(target_os = "windows"))]
    {
        false
    }
}

// 3. Pull Llama 3.2 model if missing
#[command]
pub async fn pull_ai_model() -> AiResponse {
    let status = check_ollama_status().await;
    if !status.is_running {
        return AiResponse {
            success: false,
            message: "Ollama server ishlamayapti.".to_string(),
        };
    }

    if status.has_llama3_2 {
        return AiResponse {
            success: true,
            message: "Model allaqachon o'rnatilgan.".to_string(),
        };
    }

    // Start pulling. This blocks until complete. In production, this should stream progress.
    let client = reqwest::Client::new();
    let res = client
        .post("http://localhost:11434/api/pull")
        .json(&serde_json::json!({
            "name": "llama3.2",
            "stream": false
        }))
        .send()
        .await;

    match res {
        Ok(resp) if resp.status().is_success() => AiResponse {
            success: true,
            message: "Model muvaffaqiyatli yuklandi!".to_string(),
        },
        _ => AiResponse {
            success: false,
            message: "Modelni yuklashda xatolik yuz berdi.".to_string(),
        },
    }
}

// 4. Send chat message to AI
#[command]
pub async fn analyze_threat_with_ai(prompt: String) -> AiResponse {
    let client = reqwest::Client::new();

    let system_prompt =
        "Sen 'SERGAK PC' kiberxavfsizlik dasturining sun'iy intellektli yordamchisisan. \
        Maqsading foydalanuvchiga kompyuterdagi xavflar, viruslar va xavfsizlik muammolarini \
        sodda, tushunarli o'zbek tilida tushuntirish va qanday chora ko'rishni maslahat berish. \
        Qisqa, aniq va professional javob ber. Dasturlash tillarida kod yozma, faqat maslahat ber.";

    let payload = serde_json::json!({
        "model": "llama3.2",
        "messages": [
            { "role": "system", "content": system_prompt },
            { "role": "user", "content": prompt }
        ],
        "stream": false
    });

    let res = client
        .post("http://localhost:11434/api/chat")
        .json(&payload)
        .send()
        .await;

    match res {
        Ok(resp) => {
            if let Ok(json) = resp.json::<serde_json::Value>().await {
                if let Some(content) = json
                    .get("message")
                    .and_then(|m| m.get("content"))
                    .and_then(|c| c.as_str())
                {
                    return AiResponse {
                        success: true,
                        message: content.to_string(),
                    };
                }
            }
            AiResponse {
                success: false,
                message: "AI dan noto'g'ri javob keldi.".to_string(),
            }
        }
        Err(e) => AiResponse {
            success: false,
            message: format!("AI ga ulanishda xatolik: {}", e),
        },
    }
}
