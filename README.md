# RemoteTerm - SSH Terminal App

A mobile SSH terminal application built with Flutter. Connect to remote servers securely from your iOS or Android device.

## Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
  - [Android](#android)
  - [iOS](#ios)
- [Development Setup](#development-setup)
  - [Prerequisites](#prerequisites)
  - [Windows](#windows)
  - [macOS](#macos)
  - [Linux](#linux)
- [Building from Source](#building-from-source)
- [Tailscale Integration](#tailscale-integration)
  - [What is Tailscale?](#what-is-tailscale)
  - [Setting Up Tailscale](#setting-up-tailscale)
  - [Using Tailscale with RemoteTerm](#using-tailscale-with-remoterm)
- [Usage Guide](#usage-guide)
  - [Adding a Connection](#adding-a-connection)
  - [Connecting to a Server](#connecting-to-a-server)
  - [Quick Actions](#quick-actions)
  - [Settings](#settings)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## Features

- SSH password and private key authentication
- Secure credential storage
- Multiple terminal sessions (tabs)
- Quick action buttons for common terminal shortcuts
- Dark/Light theme support
- Customizable terminal font size
- Tailscale/Headscale support for secure remote access
- Copy/paste support

## System Requirements

| Platform | Minimum Version |
|----------|----------------|
| Android  | API 21+        |
| iOS      | 12.0+          |

## Installation

### Android

1. **From APK (Debug Build)**
   - Download `app-debug.apk` from the build output
   - Enable "Install from unknown sources" in settings
   - Open the APK file and install

2. **From Google Play Store** (Coming Soon)
   - Search for "RemoteTerm" in the Play Store
   - Install the app

### iOS

1. **From TestFlight** (Coming Soon)
   - Join the TestFlight beta program
   - Install via TestFlight app

2. **From Source**
   - See [Development Setup](#development-setup)

## Development Setup

### Prerequisites

- Flutter SDK 3.11.0 or higher
- Dart SDK 3.11.0 or higher
- Git

### Windows

#### 1. Install Flutter

```powershell
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -c stable C:\flutter

# Add to PATH (User variables)
# Add C:\flutter\bin to your PATH environment variable
```

#### 2. Verify Installation

```powershell
flutter --version
flutter doctor
```

#### 3. Enable Developer Mode

1. Go to **Settings > Update & Security > For developers**
2. Enable **Developer Mode**

#### 4. Connect Device

- Enable USB debugging on your Android device
- Connect via USB
- Accept the RSA key prompt on your device

#### 5. Run the App

```powershell
flutter run
```

### macOS

#### 1. Install Flutter

```bash
# Using Homebrew
brew install flutter

# Or manually
git clone https://github.com/flutter/flutter.git -c stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"
```

#### 2. Install Xcode Command Line Tools

```bash
xcode-select --install
```

#### 3. Accept Xcode Licenses

```bash
sudo xcodebuild -license
```

#### 4. iOS Development (for iPhone/iPad)

```bash
# Open Simulator
open -a Simulator

# List available simulators
xcrun simctl list devices available

# Run on simulator
flutter run -d <device-id>
```

#### 5. Android Development

```bash
# Android SDK is typically installed automatically
flutter doctor

# Run on connected device
flutter run
```

### Linux

#### 1. Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev

# Fedora
sudo dnf install -y curl git unzip xz zip mesa-libGLU clang cmake ninja-build pkgconfig gtk3-devel

# Arch Linux
sudo pacman -Syu --needed curl git unzip xz zip mesa glu clang cmake ninja pkgconf gtk3
```

#### 2. Install Flutter

```bash
git clone https://github.com/flutter/flutter.git -c stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Verify
flutter --version
```

#### 3. Android SDK Setup

```bash
# Download Android command line tools
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip cmdline-tools.zip
mv cmdline-tools latest

# Set environment variables
export ANDROID_HOME=~/android-sdk
export ANDROID_SDK_ROOT=~/android-sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Accept licenses
yes | sdkmanager --licenses

# Install required packages
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

#### 4. Run the App

```bash
flutter run
```

## Building from Source

### Debug Build

```bash
# Clone the repository
git clone <repository-url>
cd remoterm

# Get dependencies
flutter pub get

# Run (development)
flutter run

# Build debug APK (Android)
flutter build apk --debug

# Build release APK (Android)
flutter build apk --release

# Build iOS (macOS only)
flutter build ios --release --no-codesign
```

### Release Build

```bash
# Android release
flutter build apk --release

# The APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

## Tailscale Integration

### What is Tailscale?

Tailscale is a VPN service that creates a secure, encrypted connection between your devices. It uses WireGuard protocol and allows you to access your servers using private IP addresses without exposing them to the public internet.

### Setting Up Tailscale

#### 1. Install Tailscale on Your Server

**Linux (Ubuntu/Debian)**
```bash
# Add Tailscale's package signing key and repository
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
sudo tailscale up

# Authenticate by following the printed URL
```

**macOS**
```bash
# Install via Homebrew
brew install tailscale

# Start Tailscale
tailscale up
```

**Windows**
- Download from https://tailscale.com/download
- Install and sign in

#### 2. Get Your Tailscale IP

```bash
# On your server, run
tailscale ip -4
```

This will return an IP address like `100.x.x.x`.

#### 3. Note Your Server's hostname (Optional)

```bash
hostname
```

### Using Tailscale with RemoteTerm

#### Method 1: Direct Tailscale Connection

1. **Ensure Tailscale is running on both your mobile device and server**

2. **Get your server's Tailscale IP**
   ```bash
   tailscale ip -4
   ```

3. **In RemoteTerm, add a new connection:**
   - **Name**: My Server (or any name)
   - **Host**: `100.x.x.x` (your server's Tailscale IP)
   - **Port**: `22` (default SSH)
   - **Username**: Your Linux/macOS username
   - **Auth Method**: Password or Private Key

4. **Save and connect!**

#### Method 2: Tailnet DNS Names

If you've set up Tailnet DNS in Tailscale:

1. **Use your server's DNS name instead of IP**
   - Format: `hostname.tail-scale.ts.net`
   - Example: `myserver.tail-scale.ts.net`

2. **Add connection in RemoteTerm:**
   - **Host**: `myserver.tail-scale.ts.net`
   - Other settings same as above

#### Method 3: Using RemoteTerm's Tailscale Settings

RemoteTerm has built-in Tailscale configuration:

1. **Go to Settings** in RemoteTerm
2. **Tap "Tailscale Server"**
3. **Enter your Tailscale IP or hostname**
4. This creates a quick-add option for Tailscale connections

### Headscale Setup

If you're using a self-hosted Headscale server:

1. **Install Headscale CLI on your server**
   ```bash
   # Follow Headscale installation docs
   ```

2. **Register your node**
   ```bash
   headscale nodes list
   ```

3. **Get your node's IP from Headscale**
   - The IP will be in the `100.x.x.x` range

4. **Use this IP in RemoteTerm**

### Advantages of Using Tailscale

| Benefit | Description |
|---------|-------------|
| Security | All traffic is encrypted via WireGuard |
| No Port Forwarding | No need to open ports on your router |
| Private Network | Servers aren't exposed to the internet |
| Easy Access | Connect from anywhere with internet |

## Usage Guide

### Adding a Connection

1. **Open RemoteTerm** - You'll see the home screen with saved connections
2. **Tap the + button** - This opens the "New Connection" dialog
3. **Fill in connection details:**
   - **Connection Name**: A friendly name (e.g., "Production Server")
   - **Host**: Server IP address or hostname
   - **Port**: SSH port (default: 22)
   - **Username**: Your SSH username
4. **Choose authentication:**
   - **Password**: Enter your password
   - **Private Key**: Paste your private key or use file picker
5. **Optional: Enable "Save Password"** for secure storage
6. **Tap "Test"** to verify connection works
7. **Tap "Save"** to store the connection

### Connecting to a Server

1. **From home screen**, tap on a saved connection
2. **Wait for connection** - You'll see a loading indicator
3. **Terminal opens** - You can now type commands

### Quick Actions

The Quick Actions bar provides common terminal shortcuts:

| Button | Action |
|--------|--------|
| TAB | Insert tab character |
| ESC | Escape key |
| Ctrl+C | Interrupt/SIGINT |
| Ctrl+D | End of file (logout) |
| ↑↓←→ | Arrow keys for navigation |

### Settings

Access settings from the gear icon on the home screen:

- **Theme**: System/Light/Dark
- **Terminal Font Size**: 10-24px slider
- **Max Tabs**: 1-10 (maximum concurrent sessions)
- **Auto Reconnect**: Automatically reconnect on disconnect
- **Tailscale Server**: Quick Tailscale IP configuration
- **About**: App version and info

## Security

- **Credentials are stored securely** using platform-native encryption (Keychain on iOS, EncryptedSharedPreferences on Android)
- **Private keys never leave your device**
- **Connection testing** validates credentials before saving
- **Memory is cleared** on disconnect

## Troubleshooting

### Connection Issues

**"Connection refused"**
- Check if SSH server is running: `sudo systemctl status ssh`
- Verify port (default 22): `sudo ss -tlnp | grep ssh`

**"Connection timed out"**
- Check firewall: `sudo ufw status`
- Verify server IP address

**"Authentication failed"**
- Double-check username and password
- For private key, ensure the public key is on server

### Tailscale Issues

**"Can't connect to server"**
- Ensure Tailscale is running on both devices
- Check Tailscale status: `tailscale status`
- Verify firewall allows Tailscale

**"Getting Tailscale IP"**
- Run on server: `tailscale ip -4`
- Make sure you're logged into the same Tailscale network

### Build Issues

**"Flutter command not found"**
- Add Flutter to your PATH
- Restart terminal after installation

**"Android SDK not found"**
- Run `flutter doctor` to see issues
- Set `ANDROID_HOME` environment variable

**"Permission denied" (Linux)**
- Add udev rules for Android device
- See: https://developer.android.com/studio/run/device
