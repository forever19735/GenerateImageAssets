# GenerateImageAssets

🛠 **Auto-generate Swift enums for your Xcode `.xcassets` image sets.**

This CLI tool scans your `Assets.xcassets` folder and generates an `ImageAsset.swift` file with:

✅ Flat `ImageAsset` enum for root-level images  
✅ Nested enums (`ImageAsset.GroupName`) for grouped images  
✅ Convenience `UIImage` initializers

---

## ✨ Features

- Automatically detects `.imageset` in subfolders
- Converts snake_case, kebab-case, and space names to camelCase enum cases
- Swift `enum` + `UIImage` extension generation
- Easy to integrate in your project or CI pipeline

---

## 📦 Installation

### Using Swift Package Manager (SPM)

```bash
git clone https://github.com/yourgithub/GenerateImageAssets.git
cd GenerateImageAssets
swift build -c release
cp .build/release/generate-image-assets /usr/local/bin/
