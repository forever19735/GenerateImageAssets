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
        generate-image-assets --assets <Assets.xcassets 路徑> --output <輸出檔案路徑>
        """)
    }
}

guard let cli = CLIArguments(from: CommandLine.arguments) else {
    CLIArguments.printUsage()
    exit(1)
}

let (flat, grouped) = ImageAssetGenerator.collectImageAssets(from: cli.assetsPath)
let content = ImageAssetGenerator.generateEnumContent(flatImages: flat, groupedImages: grouped)

do {
    try content.write(toFile: cli.outputPath, atomically: true, encoding: .utf8)
    print("✅ 成功產生 ImageAsset.swift → \(cli.outputPath)")
} catch {
    print("❌ 寫入失敗：\(error)")
}
