
# LiDAR Depth Capture 

This is the project we will use to check accessibilty of LiDAR  (on supported devices) to extract real-time depth data and visualize it. It also exports sampled depth data to a local JSON file so we can see the data format.

---

## Requirements

- macOS with Xcode 14+
- An iPhone or iPad **with LiDAR** (e.g., iPhone 12 Pro, 13 Pro, 14 Pro, iPad Pro)
- Apple Developer Account (Free or Paid)
- USB cable to connect iPhone
- GitHub Desktop or Git CLI

---

## Setup Instructions

### 1. Clone the Project

```bash
git clone https://github.com/flashBombHack/lidar-poc-depth-capture.git
cd lidar-poc-depth-capture
open LidarPoCApp.xcodeproj
```

### 2. Open in Xcode

- Open the `.xcodeproj` file.
- Navigate to `ViewController.swift` and `Main.storyboard`.

### 3. Set Team for Signing

- Click the project root in the navigator.
- Under "Signing & Capabilities":
  - Select your Apple ID Team
  - Set **Bundle Identifier** to something unique like `com.lidarTeam.lidarapp`.

### 4. Connect Your iPhone

- Connect via USB.
- Select your iPhone from the device dropdown.
- Allow trust access on both macOS and iPhone.

### 5. Build & Run

- Press ⌘ + R to build and run.
- Accept camera access when prompted.

---

## Exported Data

- The app logs real-time depth data to the console.
- Also saves a `depth_data.json` to the app’s **Documents** folder.
- You can access this in:
  - Xcode > Window > Devices & Simulators > Select Your Device > Installed Apps > Download Container

---

