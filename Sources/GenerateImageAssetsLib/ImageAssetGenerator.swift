import Foundation

public struct ImageAssetGenerator {
    public static func convertToCamelCase(_ string: String) -> String {
        let components = string.split { $0 == "_" || $0 == "-" || $0 == " " }
        guard let first = components.first?.lowercased() else { return "" }
        let rest = components.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }

    public static func checkGroupProvidesNamespace(at assetsPath: String, groupName: String) -> Bool {
        let contentsPath = "\(assetsPath)/\(groupName)/Contents.json"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: contentsPath),
              let data = fileManager.contents(atPath: contentsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let properties = json["properties"] as? [String: Any] else {
            return false
        }

        return properties["provides-namespace"] as? Bool ?? false
    }

    public static func collectImageAssets(from path: String) -> (
        flat: [String],
        grouped: [String: (images: [String], providesNamespace: Bool, originalName: String)]
    ) {
        var flatImages: [String] = []
        var groupedImages: [String: (images: [String], providesNamespace: Bool, originalName: String)] = [:]

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            fatalError("❌ Assets.xcassets not found: \(path)")
        }

        for case let file as String in enumerator {
            guard file.hasSuffix(".imageset") else { continue }
            let trimmedPath = String(file.dropLast(".imageset".count))
            let components = trimmedPath.split(separator: "/").map(String.init)

            if components.count >= 2 {
                let groupName = components[0]
                let groupCamelCase = convertToCamelCase(groupName)
                let imageName = components.last!
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

    public static func generateEnumFiles(
        flatImages: [String],
        groupedImages: [String: (images: [String], providesNamespace: Bool, originalName: String)]
    ) -> (baseEnum: String, uikitExt: String, swiftuiExt: String) {
        // Base Enum
        var baseEnum = """
        // Auto-generated
        import Foundation

        enum ImageAsset: String {
        """

        baseEnum += flatImages.sorted().map {
            "\n    case \(convertToCamelCase($0)) = \"\($0)\""
        }.joined()

        baseEnum += "\n}\n\n"

        for (group, groupData) in groupedImages.sorted(by: { $0.key < $1.key }) {
            let cases = groupData.images.sorted().map { imageName in
                let assetPath = groupData.providesNamespace
                    ? "\(groupData.originalName)/\(imageName)"
                    : imageName
                return "        case \(convertToCamelCase(imageName)) = \"\(assetPath)\""
            }.joined(separator: "\n")

            baseEnum += """
            extension ImageAsset {
                enum \(group.capitalized): String {
            \(cases)
                }
            }

            """
        }

        // UIKit Extension
        var uikitExt = """
        #if canImport(UIKit)
        import UIKit

        extension UIImage {
            convenience init?(asset: ImageAsset) {
                self.init(named: asset.rawValue)
            }
        }
        """

        for (group, _) in groupedImages {
            uikitExt += """

            extension UIImage {
                convenience init?(asset: ImageAsset.\(group.capitalized)) {
                    self.init(named: asset.rawValue)
                }
            }
            """
        }

        uikitExt += "\n#endif\n"

        // SwiftUI Extension
        var swiftuiExt = """
        import SwiftUI

        extension Image {
            init(asset: ImageAsset) {
                self.init(asset.rawValue)
            }
        }
        """

        for (group, _) in groupedImages {
            swiftuiExt += """

            extension Image {
                init(asset: ImageAsset.\(group.capitalized)) {
                    self.init(asset.rawValue)
                }
            }
            """
        }

        swiftuiExt += "\n"

        return (baseEnum, uikitExt, swiftuiExt)
    }

    public static func writeEnumFiles(
        assetsPath: String,
        outputPath: String,
        fileNames: (base: String, uikit: String, swiftui: String) = ("ImageAsset.swift", "ImageAsset+UIKit.swift", "ImageAsset+SwiftUI.swift")
    ) {
        let (flat, grouped) = collectImageAssets(from: assetsPath)
        let (base, uikit, swiftui) = generateEnumFiles(flatImages: flat, groupedImages: grouped)

        do {
            try base.write(to: URL(fileURLWithPath: outputPath).appendingPathComponent(fileNames.base), atomically: true, encoding: .utf8)
            try uikit.write(to: URL(fileURLWithPath: outputPath).appendingPathComponent(fileNames.uikit), atomically: true, encoding: .utf8)
            try swiftui.write(to: URL(fileURLWithPath: outputPath).appendingPathComponent(fileNames.swiftui), atomically: true, encoding: .utf8)
            print("✅ 所有 enum 檔案成功寫入：\(outputPath)")
        } catch {
            print("❌ 檔案寫入失敗：\(error.localizedDescription)")
        }
    }
}
