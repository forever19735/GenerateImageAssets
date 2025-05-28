import Foundation
import GenerateImageAssetsLib

struct CLIArguments {
    let assetsPath: String
    let outputPath: String

    init?(from args: [String]) {
        guard
            let assetsIndex = args.firstIndex(of: "--assets"),
            let outputIndex = args.firstIndex(of: "--output"),
            args.indices.contains(assetsIndex + 1),
            args.indices.contains(outputIndex + 1)
        else {
            return nil
        }
        self.assetsPath = args[assetsIndex + 1]
        self.outputPath = args[outputIndex + 1]
    }

    static func printUsage() {
        print("""
        ❌ 使用方式錯誤

        正確格式：
        generate-image-assets --assets <Assets.xcassets 路徑> --output <輸出資料夾路徑>
        """)
    }
}

guard let cli = CLIArguments(from: CommandLine.arguments) else {
    CLIArguments.printUsage()
    exit(1)
}

// 收集 image assets
let (flatImages, groupedImages) = ImageAssetGenerator.collectImageAssets(from: cli.assetsPath)

// 產生三個檔案的內容：base enum、UIKit extension、SwiftUI extension
let (baseEnumContent, uikitExtensionContent, swiftuiExtensionContent) =
    ImageAssetGenerator.generateEnumFiles(flatImages: flatImages, groupedImages: groupedImages)

// 建立輸出目錄（如果尚未存在）
let fileManager = FileManager.default
try? fileManager.createDirectory(atPath: cli.outputPath, withIntermediateDirectories: true, attributes: nil)

// 定義檔案路徑
let baseEnumPath = "\(cli.outputPath)/ImageAsset.swift"
let uikitExtensionPath = "\(cli.outputPath)/ImageAsset+UIKit.swift"
let swiftuiExtensionPath = "\(cli.outputPath)/ImageAsset+SwiftUI.swift"

do {
    try baseEnumContent.write(toFile: baseEnumPath, atomically: true, encoding: .utf8)
    try uikitExtensionContent.write(toFile: uikitExtensionPath, atomically: true, encoding: .utf8)
    try swiftuiExtensionContent.write(toFile: swiftuiExtensionPath, atomically: true, encoding: .utf8)

    print("✅ 成功產生 ImageAsset 檔案：")
    print("  • \(baseEnumPath)")
    print("  • \(uikitExtensionPath)")
    print("  • \(swiftuiExtensionPath)")
} catch {
    print("❌ 寫入失敗：\(error)")
    exit(1)
}
