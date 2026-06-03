/// phone_link.rs — WebSocket server for Phone to PC link
use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use tokio::net::{TcpListener, TcpStream};
use tokio_tungstenite::accept_async;
use futures_util::{StreamExt, SinkExt};
use serde::{Deserialize, Serialize};
use once_cell::sync::Lazy;
use tauri::command;

#[derive(Serialize, Deserialize, Clone)]
pub struct PhoneState {
    pub is_connected: bool,
    pub device_name: Option<String>,
    pub connection_time: Option<String>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct QrCodeData {
    pub ip: String,
    pub port: u16,
    pub otp: String, // One-time password for the session
}

// Global state for phone connection
pub static PHONE_STATE: Lazy<Arc<Mutex<PhoneState>>> = Lazy::new(|| {
    Arc::new(Mutex::new(PhoneState {
        is_connected: false,
        device_name: None,
        connection_time: None,
    }))
});

pub static CURRENT_OTP: Lazy<Arc<Mutex<String>>> = Lazy::new(|| Arc::new(Mutex::new(String::new())));
pub static SERVER_STARTED: Lazy<Arc<Mutex<bool>>> = Lazy::new(|| Arc::new(Mutex::new(false)));

#[command]
pub fn get_connected_phone() -> PhoneState {
    let state = PHONE_STATE.lock().unwrap();
    state.clone()
}

#[command]
pub fn disconnect_phone() -> bool {
    let mut state = PHONE_STATE.lock().unwrap();
    state.is_connected = false;
    state.device_name = None;
    state.connection_time = None;
    // We can also drop the socket if we stored it, but for now we just change state
    true
}

#[command]
pub async fn start_websocket_server() -> Result<QrCodeData, String> {
    let mut started = SERVER_STARTED.lock().unwrap();
    
    // Generate new OTP
    let otp = format!("{:06}", rand::random::<u32>() % 1000000);
    {
        let mut current_otp = CURRENT_OTP.lock().unwrap();
        *current_otp = otp.clone();
    }
    
    let port = 8765;
    
    // Local IP (dummy way to get an IP for QR)
    let ip = match local_ip_address::local_ip() {
        Ok(ip) => ip.to_string(),
        Err(_) => "127.0.0.1".to_string(), // Fallback
    };
    
    if !*started {
        *started = true;
        let addr = format!("0.0.0.0:{}", port);
        
        tokio::spawn(async move {
            let listener = TcpListener::bind(&addr).await.expect("Failed to bind websocket port");
            println!("WebSocket listening on: {}", addr);

            while let Ok((stream, _)) = listener.accept().await {
                tokio::spawn(handle_connection(stream));
            }
        });
    }

    Ok(QrCodeData {
        ip,
        port,
        otp,
    })
}

async fn handle_connection(raw_stream: TcpStream) {
    let ws_stream = match accept_async(raw_stream).await {
        Ok(s) => s,
        Err(e) => {
            println!("Error during the websocket handshake: {}", e);
            return;
        }
    };

    println!("New WebSocket connection established");
    let (mut write, mut read) = ws_stream.split();

    while let Some(msg) = read.next().await {
        let msg = match msg {
            Ok(m) => m,
            Err(_) => break,
        };

        if msg.is_text() {
            let text = msg.to_text().unwrap_or("");
            
            // Expected format for auth: "AUTH:123456:DeviceName"
            if text.starts_with("AUTH:") {
                let parts: Vec<&str> = text.split(':').collect();
                if parts.len() >= 3 {
                    let provided_otp = parts[1];
                    let device_name = parts[2];
                    
                    let expected_otp = {
                        let lock = CURRENT_OTP.lock().unwrap();
                        lock.clone()
                    };
                    
                    if provided_otp == expected_otp {
                        let mut state = PHONE_STATE.lock().unwrap();
                        state.is_connected = true;
                        state.device_name = Some(device_name.to_string());
                        state.connection_time = Some(chrono::Utc::now().format("%Y-%m-%d %H:%M").to_string());
                        
                        let _ = write.send(tokio_tungstenite::tungstenite::Message::Text("AUTH_OK".into())).await;
                    } else {
                        let _ = write.send(tokio_tungstenite::tungstenite::Message::Text("AUTH_FAILED".into())).await;
                    }
                }
            } else if text == "LOCK_PC" {
                let is_auth = {
                    PHONE_STATE.lock().unwrap().is_connected
                };
                if is_auth {
                    // Lock PC
                    #[cfg(target_os = "windows")]
                    let _ = std::process::Command::new("rundll32.exe")
                        .args(["user32.dll,LockWorkStation"])
                        .spawn();
                }
            }
        }
    }
    
    // On disconnect
    let mut state = PHONE_STATE.lock().unwrap();
    state.is_connected = false;
    state.device_name = None;
    state.connection_time = None;
}
