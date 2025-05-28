import Foundation

public struct ImageAssetGenerator {
    public static func convertToCamelCase(_ string: String) -> String {
        let components = string.split { $0 == "_" || $0 == "-" || $0 == " " }
        guard let first = components.first?.lowercased() else { return "" }
        let rest = components.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }

    public static func collectImageAssets(from path: String) -> (flat: [String], grouped: [String: [String]]) {
        var flatImages: [String] = []
        var groupedImages: [String: [String]] = [:]

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            fatalError("❌ 找不到 Assets.xcassets 資料夾: \(path)")
        }

        for case let file as String in enumerator {
            guard file.hasSuffix(".imageset") else { continue }
            let trimmedPath = String(file.dropLast(".imageset".count))
            let components = trimmedPath.split(separator: "/").map(String.init)

            if components.count >= 2 {
                let group = convertToCamelCase(components[0])
                let name = components.last!
                groupedImages[group, default: []].append(name)
            } else if components.count == 1 {
                flatImages.append(components[0])
            }
        }

        return (flatImages, groupedImages)
    }

    public static func generateEnumContent(flatImages: [String], groupedImages: [String: [String]]) -> String {
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

        for (group, images) in groupedImages.sorted(by: { $0.key < $1.key }) {
            let cases = images.sorted().map {
                "        case \(convertToCamelCase($0)) = \"\($0)\""
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
