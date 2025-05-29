import ArgumentParser
import Foundation
import GenerateImageAssetsLib

@main
struct GenerateImageAssets: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "🛠 Generate Swift enums for image assets in an .xcassets folder."
    )

    @Option(name: [.short, .long], help: "Path to your .xcassets folder.")
    var assets: String

    @Option(name: [.short, .long], help: "Output directory for generated .swift files.")
    var output: String

    @Flag(name: [.short, .long], help: "Enable verbose output.")
    var verbose: Bool = false

    func validate() throws {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: assets) else {
            throw ValidationError("❌ Assets path does not exist: \(assets)")
        }

        guard assets.hasSuffix(".xcassets") else {
            throw ValidationError("❌ Must provide a valid .xcassets folder.")
        }

        let parent = (output as NSString).deletingLastPathComponent
        if !parent.isEmpty && !fileManager.fileExists(atPath: parent) {
            throw ValidationError("❌ Output parent folder does not exist: \(parent)")
        }
    }

    func run() throws {
        if verbose {
            print("🔍 Scanning: \(assets)")
        }

        let rootNode = ImageAssetGenerator.collectImageAssets(from: assets)

        if verbose {
            print("📊 Structure:")
            printNodeStructure(rootNode)
        }

        let code = ImageAssetGenerator.generateEnumFiles(from: rootNode)

        try writeFiles(code, to: output)

        print("✅ Done. Files generated in: \(output)")
        if !verbose {
            print("   • ImageAsset.swift")
            print("   • UIImage+ImageAsset.swift")
            print("   • Image+ImageAsset.swift")
        }
    }

    private func writeFiles(_ code: ImageAssetGenerator.GeneratedCode, to path: String) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: path) {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
        }

        let files = [
            ("ImageAsset.swift", code.baseEnum),
            ("UIImage+ImageAsset.swift", code.uikitExt),
            ("Image+ImageAsset.swift", code.swiftuiExt)
        ]

        for (filename, content) in files {
            let filePath = "\(path)/\(filename)"
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            if verbose {
                print("💾 Wrote: \(filePath)")
            }
        }
    }

    private func printNodeStructure(_ node: ImageAssetGenerator.GroupNode, indent: String = "") {
        if node.name != "Root" {
            let ns = node.providesNamespace ? "" : " (no namespace)"
            print("\(indent)📁 \(node.name)\(ns)")
        }

        for image in node.images.sorted() {
            print("\(indent)  🖼 \(image)")
        }

        for child in node.children.sorted(by: { $0.name < $1.name }) {
            printNodeStructure(child, indent: indent + "  ")
        }
    }
}
