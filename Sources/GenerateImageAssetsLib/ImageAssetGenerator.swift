import Foundation

// MARK: - ImageAssetGenerator

public enum ImageAssetGenerator {
    // MARK: - Types
    
    public typealias GeneratedCode = (baseEnum: String, uikitExt: String, swiftuiExt: String)
    public typealias EnumTypeInfo = (enumPath: String, enumName: String)
    
    // MARK: - Public Interface
    
    /// 從指定路徑收集圖片資源並生成程式碼
    public static func generateCode(from assetPath: String) -> GeneratedCode {
        let rootNode = collectImageAssets(from: assetPath)
        return generateEnumFiles(from: rootNode)
    }
    
    /// 收集所有 imageset 資料，產生樹狀結構
    public static func collectImageAssets(from path: String) -> GroupNode {
        let collector = AssetCollector(basePath: path)
        return collector.collect()
    }
    
    /// 根據 GroupNode 產生 enum 及擴充字串
    public static func generateEnumFiles(from rootNode: GroupNode) -> GeneratedCode {
        let generator = CodeGenerator(rootNode: rootNode)
        return generator.generate()
    }
}

// MARK: - GroupNode

public extension ImageAssetGenerator {
    /// 表示資源群組的樹狀節點
    class GroupNode {
        public let name: String
        public var images: [String] = []
        public var children: [GroupNode] = []
        public var providesNamespace: Bool = true
        
        // 標記根節點
        public let isRoot: Bool
        
        public init(name: String, isRoot: Bool = false) {
            self.name = name
            self.isRoot = isRoot
        }
        
        /// 創建根節點的便利方法
        public static func createRoot() -> GroupNode {
            return GroupNode(name: "", isRoot: true)
        }
        
        /// 找子節點或新增子節點
        func childNode(named name: String) -> GroupNode {
            if let existing = children.first(where: { $0.name == name }) {
                return existing
            }
            
            let newNode = GroupNode(name: name)
            children.append(newNode)
            return newNode
        }
        
        /// 取得完整路徑（從根節點到此節點）
        func fullPath(from root: GroupNode) -> String {
            // 根節點沒有路徑
            guard !isRoot && self !== root else { return "" }
            
            if let pathComponents = findPathComponents(in: root, target: self) {
                return pathComponents.joined(separator: "/")
            }
            return name
        }
        
        /// 取得顯示名稱（用於調試和日誌）
        var displayName: String {
            return isRoot ? "<Root>" : name
        }
        
        /// 檢查是否為根層級圖片（直接在根節點下）
        var isRootLevelContent: Bool {
            return isRoot
        }
        
        /// 遞迴尋找路徑組件
        private func findPathComponents(in node: GroupNode, target: GroupNode, currentPath: [String] = []) -> [String]? {
            if node === target {
                return currentPath
            }
            
            for child in node.children {
                if let path = findPathComponents(in: child, target: target, currentPath: currentPath + [child.name]) {
                    return path
                }
            }
            return nil
        }
    }
}

// MARK: - AssetCollector

private struct AssetCollector {
    let basePath: String
    private let fileManager = FileManager.default
    
    func collect() -> ImageAssetGenerator.GroupNode {
        let root = ImageAssetGenerator.GroupNode.createRoot()
        
        guard let enumerator = fileManager.enumerator(atPath: basePath) else {
            print("Error: Cannot enumerate path: \(basePath)")
            return root
        }
        
        let groupNamespaceInfo = collectGroupNamespaceInfo(from: enumerator)
        let imageAssets = collectImageAssets()
        
        return buildNodeTree(root: root, assets: imageAssets, namespaceInfo: groupNamespaceInfo)
    }
    
    /// 收集所有群組的 namespace 資訊
    private func collectGroupNamespaceInfo(from enumerator: FileManager.DirectoryEnumerator) -> [String: Bool] {
        var groupNamespaceInfo: [String: Bool] = [:]
        
        for case let file as String in enumerator {
            if file.hasSuffix("/Contents.json"), !file.contains(".imageset") {
                let groupPath = String(file.dropLast("/Contents.json".count))
                groupNamespaceInfo[groupPath] = checkNamespaceForGroup(groupPath: groupPath)
            }
        }
        
        return groupNamespaceInfo
    }
    
    /// 收集所有 imageset 檔案
    private func collectImageAssets() -> [String] {
        guard let enumerator = fileManager.enumerator(atPath: basePath) else {
            print("Error: Cannot enumerate path for images: \(basePath)")
            return []
        }
        
        var assets: [String] = []
        var processedPaths: Set<String> = []
        
        for case let file as String in enumerator {
            guard file.hasSuffix(".imageset"), !processedPaths.contains(file) else { continue }
            processedPaths.insert(file)
            assets.append(file)
        }
        
        return assets
    }
    
    /// 建構節點樹
    private func buildNodeTree(
        root: ImageAssetGenerator.GroupNode,
        assets: [String],
        namespaceInfo: [String: Bool]
    ) -> ImageAssetGenerator.GroupNode {
        for asset in assets {
            let trimmedPath = String(asset.dropLast(".imageset".count))
            let components = trimmedPath.split(separator: "/").map(String.init)
            
            var currentNode = root
            
            for (index, component) in components.enumerated() {
                if index == components.count - 1 {
                    // 最後一層是圖片名稱
                    currentNode.images.append(component)
                } else {
                    // 中間層是群組
                    let childNode = currentNode.childNode(named: component)
                    
                    // 設定該群組的 namespace 資訊
                    let groupPath = components[0 ... index].joined(separator: "/")
                    childNode.providesNamespace = namespaceInfo[groupPath] ?? true
                    
                    currentNode = childNode
                }
            }
        }
        
        return root
    }
    
    /// 檢查群組是否提供 namespace
    private func checkNamespaceForGroup(groupPath: String) -> Bool {
        let contentsPath = "\(basePath)/\(groupPath)/Contents.json"
        
        guard fileManager.fileExists(atPath: contentsPath),
              let data = fileManager.contents(atPath: contentsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let properties = json["properties"] as? [String: Any],
              let providesNamespace = properties["provides-namespace"] as? Bool
        else {
            return false
        }
        
        return providesNamespace
    }
}

// MARK: - CodeGenerator

private struct CodeGenerator {
    let rootNode: ImageAssetGenerator.GroupNode
    
    func generate() -> ImageAssetGenerator.GeneratedCode {
        let baseEnum = generateBaseEnum()
        let enumTypes = collectAllEnumTypes()
        let uikitExt = generateUIKitExtensions(enumTypes: enumTypes)
        let swiftuiExt = generateSwiftUIExtensions(enumTypes: enumTypes)
        
        return (baseEnum, uikitExt, swiftuiExt)
    }
    
    // MARK: - Base Enum Generation
    
    private func generateBaseEnum() -> String {
        var code = """
        // Auto-generated by ImageAssetGenerator
        import Foundation

        enum ImageAsset: String {
        """
        
        code += "\n" + generateEnumCases(for: rootNode)
        code += "}\n"
        
        return code
    }
    
    private func generateEnumCases(for node: ImageAssetGenerator.GroupNode, indent: String = "    ", pathPrefix: String = "") -> String {
        var result = ""
        
        if node.isRoot {
            result += generateRootLevelImages(node.images, indent: indent)
            
            if !node.images.isEmpty && !node.children.isEmpty {
                result += "\n"
            }
        }
        
        // 處理子群組
        result += generateChildGroups(for: node, indent: indent, pathPrefix: pathPrefix)
        
        return result
    }
    
    private func generateRootLevelImages(_ images: [String], indent: String) -> String {
        return images.sorted()
            .map { "case \(StringUtils.convertToCamelCase($0)) = \"\($0)\"" }
            .map { "\(indent)\($0)\n" }
            .joined()
    }
    
    private func generateChildGroups(for node: ImageAssetGenerator.GroupNode, indent: String, pathPrefix: String) -> String {
        var result = ""
        let sortedChildren = node.children.sorted { $0.name < $1.name }
        
        for (index, child) in sortedChildren.enumerated() {
            let enumName = StringUtils.sanitizeEnumName(child.name)
            result += "\(indent)enum \(enumName): String {\n"
            
            // 處理該子群組的圖片
            result += generateGroupImages(for: child, indent: indent + "    ", pathPrefix: pathPrefix)
            
            // 處理更深層的子群組
            let childPath = child.providesNamespace ?
                (pathPrefix.isEmpty ? child.name : "\(pathPrefix)/\(child.name)") :
                pathPrefix
            
            result += generateEnumCases(for: child, indent: indent + "    ", pathPrefix: childPath)
            result += "\(indent)}\n"
            
            if index < sortedChildren.count - 1 {
                result += "\n"
            }
        }
        
        return result
    }
    
    private func generateGroupImages(for node: ImageAssetGenerator.GroupNode, indent: String, pathPrefix: String) -> String {
        var result = ""
        
        for image in node.images.sorted() {
            let caseName = StringUtils.convertToCamelCase(image)
            let rawValue = node.providesNamespace ?
                (pathPrefix.isEmpty ? "\(node.name)/\(image)" : "\(pathPrefix)/\(node.name)/\(image)") :
                image
            
            result += "\(indent)case \(caseName) = \"\(rawValue)\"\n"
        }
        
        if !node.images.isEmpty && !node.children.isEmpty {
            result += "\n"
        }
        
        return result
    }
    
    // MARK: - Extensions Generation
    
    private func collectAllEnumTypes() -> [ImageAssetGenerator.EnumTypeInfo] {
        var enumTypes: [ImageAssetGenerator.EnumTypeInfo] = []
        collectEnumTypes(from: rootNode, pathPrefix: "", enumTypes: &enumTypes)
        return enumTypes
    }
    
    private func collectEnumTypes(
        from node: ImageAssetGenerator.GroupNode,
        pathPrefix: String,
        enumTypes: inout [ImageAssetGenerator.EnumTypeInfo]
    ) {
        for child in node.children {
            let enumName = StringUtils.sanitizeEnumName(child.name)
            let enumPath = pathPrefix.isEmpty ? "ImageAsset.\(enumName)" : "\(pathPrefix).\(enumName)"
            enumTypes.append((enumPath: enumPath, enumName: enumName))
            
            let childPrefix = pathPrefix.isEmpty ? "ImageAsset.\(enumName)" : "\(pathPrefix).\(enumName)"
            collectEnumTypes(from: child, pathPrefix: childPrefix, enumTypes: &enumTypes)
        }
    }
    
    private func generateUIKitExtensions(enumTypes: [ImageAssetGenerator.EnumTypeInfo]) -> String {
        var code = """
        #if canImport(UIKit)
        import UIKit

        extension UIImage {
            convenience init?(asset: ImageAsset) {
                self.init(named: asset.rawValue)
            }
        }
        """
        
        for enumType in enumTypes {
            code += """
            
            extension UIImage {
                convenience init?(asset: \(enumType.enumPath)) {
                    self.init(named: asset.rawValue)
                }
            }
            """
        }
        
        code += "\n#endif\n"
        return code
    }
    
    private func generateSwiftUIExtensions(enumTypes: [ImageAssetGenerator.EnumTypeInfo]) -> String {
        var code = """
        import SwiftUI

        extension Image {
            init(asset: ImageAsset) {
                self.init(asset.rawValue)
            }
        }
        """
        
        for enumType in enumTypes {
            code += """
            
            extension Image {
                init(asset: \(enumType.enumPath)) {
                    self.init(asset.rawValue)
                }
            }
            """
        }
        
        code += "\n"
        return code
    }
}

// MARK: - StringUtils

private enum StringUtils {
    /// 將名字轉成 camelCase
    static func convertToCamelCase(_ string: String) -> String {
        let sanitized = string.replacingOccurrences(of: "-", with: "_")
        let parts = sanitized.split(separator: "_").map(String.init)
        
        guard !parts.isEmpty else { return string }
        
        let first = parts.first?.lowercased() ?? ""
        let rest = parts.dropFirst().map { $0.capitalized }
        let result = ([first] + rest).joined()
        
        // 確保第一個字符是字母
        if result.first?.isLetter != true {
            return "image" + result.capitalized
        }
        
        return result
    }
    
    /// 產生安全的 enum 名稱
    static func sanitizeEnumName(_ name: String) -> String {
        let sanitized = name
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        let capitalized = sanitized.prefix(1).uppercased() + sanitized.dropFirst()
        
        // 確保不以數字開頭
        if capitalized.first?.isNumber == true {
            return "Group" + capitalized
        }
        
        return capitalized
    }
}

enum ImageAssetGeneratorError: Error, LocalizedError {
    case invalidEnumName(String, reason: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEnumName(let name, let reason):
            return "Invalid enum name '\(name)': \(reason)"
        }
    }
}
