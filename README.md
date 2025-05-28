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

### Using Mint (Recommended)

```bash
mint install forever19735/GenerateImageAssets
```

---

## 🚀 Usage

```bash
generate-image-assets --assets <path_to/Assets.xcassets> --output <path_to/ImageAsset.swift>
```

---

## 💡 Generated Output

```swift
enum ImageAsset: String {
    case logo = "logo"
    case banner = "banner"
}

extension ImageAsset {
    enum Icons: String {
        case home = "home"
        case settings = "settings"
    }
}

extension UIImage {
    convenience init?(asset: ImageAsset) {
        self.init(named: asset.rawValue)
    }

    convenience init?(asset: ImageAsset.Icons) {
        self.init(named: asset.rawValue)
    }
}
```
