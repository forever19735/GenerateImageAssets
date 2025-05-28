import Foundation

public struct ImageAssetGenerator {
    public static func convertToCamelCase(_ string: String) -> String {
        let components = string.split { $0 == "_" || $0 == "-" || $0 == " " }
        guard let first = components.first?.lowercased() else { return "" }
        let rest = components.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }
    
    // Helper function to check if a group provides namespace
    public static func checkGroupProvidesNamespace(at assetsPath: String, groupName: String) -> Bool {
        let groupPath = "\(assetsPath)/\(groupName)"
        let contentsPath = "\(groupPath)/Contents.json"
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: contentsPath),
              let data = fileManager.contents(atPath: contentsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let properties = json["properties"] as? [String: Any] else {
            print("⚠️ 無法讀取群組 \(groupName) 的 Contents.json，預設為不提供 namespace")
            return false // Default to no namespace if can't read
        }
        
        let providesNamespace = properties["provides-namespace"] as? Bool ?? false
        print("📁 群組 \(groupName) provides-namespace: \(providesNamespace)")
        return providesNamespace
    }

    public static func collectImageAssets(from path: String) -> (flat: [String], grouped: [String: (images: [String], providesNamespace: Bool, originalName: String)]) {
        var flatImages: [String] = []
        var groupedImages: [String: (images: [String], providesNamespace: Bool, originalName: String)] = [:]

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            fatalError("❌ 找不到 Assets.xcassets 資料夾: \(path)")
        }

        for case let file as String in enumerator {
            guard file.hasSuffix(".imageset") else { continue }
            let trimmedPath = String(file.dropLast(".imageset".count))
            let components = trimmedPath.split(separator: "/").map(String.init)

            if components.count >= 2 {
                let groupName = components[0]  // 保留原始群組名稱
                let groupCamelCase = convertToCamelCase(groupName)
                let imageName = components.last!
                
                // Check if this group provides namespace
                let providesNamespace = checkGroupProvidesNamespace(at: path, groupName: groupName)
                
                if groupedImages[groupCamelCase] == nil {
                    groupedImages[groupCamelCase] = (images: [], providesNamespace: providesNamespace, originalName: groupName)
                }
                groupedImages[groupCamelCase]?.images.append(imageName)
            } else if components.count == 1 {
                flatImages.append(components[0])
            }
        }

        return (flatImages, groupedImages)
    }

    public static func generateEnumContent(flatImages: [String], groupedImages: [String: (images: [String], providesNamespace: Bool, originalName: String)]) -> String {
        var sections: [String] = []

        let flatCases = flatImages.sorted().map {
            "    case \(convertToCamelCase($0)) = \"\($0)\""
        }.joined(separator: "\n")

        sections.append("""
        // Auto-generated
        import UIKit

        enum ImageAsset: String {
        \(flatCases)
        }

        """)

        for (group, groupData) in groupedImages.sorted(by: { $0.key < $1.key }) {
            let cases = groupData.images.sorted().map { imageName in
                let assetPath: String
                if groupData.providesNamespace {
                    // 使用原始群組名稱（保持大小寫）
                    assetPath = "\(groupData.originalName)/\(imageName)"
                } else {
                    // Use only the image name
                    assetPath = imageName
                }
                return "        case \(convertToCamelCase(imageName)) = \"\(assetPath)\""
            }.joined(separator: "\n")

            sections.append("""
            extension ImageAsset {
                enum \(group.capitalized): String {
            \(cases)
                }
            }

            """)
        }

        var imageExtensions: [String] = []

        imageExtensions.append("""
        extension UIImage {
            convenience init?(asset: ImageAsset) {
                self.init(named: asset.rawValue)
            }
        }
        """)

        for (group, _) in groupedImages {
            imageExtensions.append("""
            extension UIImage {
                convenience init?(asset: ImageAsset.\(group.capitalized)) {
                    self.init(named: asset.rawValue)
                }
            }
            """)
        }

        sections.append(imageExtensions.joined(separator: "\n\n"))
        return sections.joined(separator: "\n")
    }
}
