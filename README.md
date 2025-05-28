# GenerateImageAssets

🛠 **Auto-generate Swift enums for your Xcode `.xcassets` image sets with full namespace support.**

This CLI tool scans your `Assets.xcassets` folder and generates an `ImageAsset.swift` file with intelligent handling of Xcode's "Provides Namespace" setting.

✅ Flat `ImageAsset` enum for root-level images  
✅ Nested enums (`ImageAsset.GroupName`) for grouped images  
✅ Smart namespace handling based on Xcode group settings  
✅ Convenience `UIImage` initializers  
✅ Preserves original folder naming and case sensitivity  

---

## ✨ Features

- **Smart Namespace Detection**: Automatically reads group `Contents.json` to determine if "Provides Namespace" is enabled
- **Preserves Folder Names**: Maintains original folder naming (e.g., "City" stays "City", not "city")
- **Flexible Asset Paths**: Generates correct asset paths based on namespace settings
- **Case Conversion**: Converts snake_case, kebab-case, and space names to camelCase enum cases
- **Nested Group Support**: Handles grouped images with proper Swift enum extensions

---

## 🔧 How Namespace Works

### With "Provides Namespace" ✅
```swift
// Folder: City (with "Provides Namespace" enabled)
extension ImageAsset {
    enum City: String {
        case iconChicago = "City/icon_chicago"
        case iconNewYork = "City/icon_new_york"
    }
}
```

### Without "Provides Namespace" ❌
```swift
// Folder: Outdoor (without "Provides Namespace")
extension ImageAsset {
    enum Outdoor: String {
        case iconOutdoor = "icon_outdoor"
    }
}
```

### Root Level Images
```swift
// Images not in any group
enum ImageAsset: String {
    case iconWater = "icon_water"
}
```

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

### Example Command
```bash
generate-image-assets --assets ./MyApp/Assets.xcassets --output ./MyApp/Generated/ImageAsset.swift
```

---

## 💡 Complete Example Output

Given this folder structure:
```
Assets.xcassets/
├── icon_water.imageset          # Root level
├── City/                        # Group with namespace
│   ├── Contents.json           # "provides-namespace": true
│   ├── icon_chicago.imageset
│   └── icon_new_york.imageset
└── Outdoor/                     # Group without namespace
    ├── Contents.json           # "provides-namespace": false
    └── icon_outdoor.imageset
```

Generated Swift code:
```swift
// Auto-generated
import UIKit

enum ImageAsset: String {
    case iconWater = "icon_water"
}

extension ImageAsset {
    enum City: String {
        case iconChicago = "City/icon_chicago"
        case iconNewYork = "City/icon_new_york"
    }
}

extension ImageAsset {
    enum Outdoor: String {
        case iconOutdoor = "icon_outdoor"
    }
}

extension UIImage {
    convenience init?(asset: ImageAsset) {
        self.init(named: asset.rawValue)
    }
}

extension UIImage {
    convenience init?(asset: ImageAsset.City) {
        self.init(named: asset.rawValue)
    }
}

extension UIImage {
    convenience init?(asset: ImageAsset.Outdoor) {
        self.init(named: asset.rawValue)
    }
}
```

---

## 🎯 Usage in Code

```swift
// Root level images
let waterIcon = UIImage(asset: .iconWater)

// Grouped images with namespace
let chicagoIcon = UIImage(asset: ImageAsset.City.iconChicago)
let newYorkIcon = UIImage(asset: ImageAsset.City.iconNewYork)

// Grouped images without namespace
let outdoorIcon = UIImage(asset: ImageAsset.Outdoor.iconOutdoor)
```

---
