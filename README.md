# SERGAK: Mobile Threat Detection & Offline Security PoC

> **Disclaimer:** This project is a Security Research Proof of Concept (PoC) developed for academic defense (Scored 96/100). It explores the boundaries and limitations of offline-first mobile cybersecurity on constrained OS environments (Android/iOS).

## Overview
SERGAK is an experimental architecture designed to test local (offline) execution of threat detection algorithms, permission parsing, and data encryption. The core thesis explores whether mobile devices can autonomously detect phishing, SMS fraud, and malicious app permissions without relying on Cloud Threat Intelligence.

## Core Security Modules (Experimental)

### 1. SMS Fraud & Threat Monitor
- **Concept:** Local parsing of incoming SMS for banking fraud, phishing URLs, and social engineering patterns.
- **Mechanism:** Uses offline regex-based heuristics and lightweight NLP to detect malicious payloads (e.g., Click/Payme scams in local contexts).
- **Limitation Discovered:** Android OS Sandboxing strictly limits `READ_SMS` permissions to default SMS handlers. Real-time offline interception is fundamentally restricted by modern Google Play Developer Policies.

### 2. Permission Analyzer (Static Analysis)
- **Concept:** Identifies potential privacy violations by analyzing manifest permissions of installed applications.
- **Mechanism:** Queries the package manager to extract requested permissions (Camera, Microphone, Background Location, SMS) and scores apps based on the principle of least privilege.

### 3. AES-256 Secure Vault
- **Concept:** Cryptographic isolation of sensitive local files.
- **Mechanism:** Implements AES-256 encryption. Explored integration with hardware-backed Keystores (Android Keystore System) for secure key generation and storage, preventing extraction even on rooted devices.

### 4. Local Threat Intelligence (Link Scanner)
- **Concept:** Anti-phishing mechanism executing locally.
- **Mechanism:** Matches URLs against an offline localized blacklist.
- **Limitation Discovered:** Zero-day phishing domains rotate rapidly. Maintaining an offline-only blacklist is structurally inefficient compared to cloud-based real-time telemetry (e.g., Google Safe Browsing API).

## Threat Model & Architecture Findings
During the development and testing of SERGAK (utilizing OWASP Mobile Top 10 guidelines), several architectural conclusions were reached:
1. **Compute Constraints:** Running ML models entirely offline causes unacceptable thermal throttling and battery drain on low-end ARM devices.
2. **OS Sandboxing:** True endpoint detection and response (EDR) on unrooted mobile devices is impossible without compromising user experience (via forced Accessibility Services or Local VPN loops).
3. **Cloud Dependency:** Effective threat intelligence requires real-time cloud synchronization. Offline-only security is a paradox in a continuously evolving threat landscape.

## Tech Stack
- **Frontend/Mobile:** Flutter / Dart
- **Desktop/Web Wrapper:** Tauri / JS / HTML
- **Backend/Bot (Research Tools):** Python

## Author & Academic Context
Created by **Xusniddin Xamidov** and team.
This repository serves as a portfolio piece demonstrating practical knowledge of OS security constraints, mobile app vulnerabilities, and cryptography concepts.

## License
MIT License. For educational and research purposes only.
