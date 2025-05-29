//
//  ImageAssetGeneratorTests.swift
//  GenerateImageAssets
//
//  Created by john on 2025/5/29.
//

import XCTest
import Foundation
@testable import GenerateImageAssetsLib

class ImageAssetGeneratorTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var tempDirectory: URL!
    var testAssetsPath: String!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        tempDirectory = createTempDirectory()
        testAssetsPath = tempDirectory.appendingPathComponent("TestAssets.xcassets").path
        setupTestAssets()
    }
    
    override func tearDown() {
        removeTempDirectory()
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try! FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
        
        return tempDir
    }
    
    private func removeTempDirectory() {
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }
    }
    
    private func setupTestAssets() {
        let fileManager = FileManager.default
        
        // 建立基本 .xcassets 目錄
        try! fileManager.createDirectory(atPath: testAssetsPath, withIntermediateDirectories: true)
        
        // 建立根層級圖片
        createImageSet(name: "app_logo")
        createImageSet(name: "background-image")
        
        // 建立群組結構
        createGroup(path: "Icons", providesNamespace: true)
        createImageSet(name: "Icons/home_icon")
        createImageSet(name: "Icons/profile-icon")
        
        // 建立巢狀群組
        createGroup(path: "Icons/Navigation", providesNamespace: true)
        createImageSet(name: "Icons/Navigation/arrow_left")
        createImageSet(name: "Icons/Navigation/arrow_right")
        
        // 建立不提供 namespace 的群組
        createGroup(path: "NoNamespace", providesNamespace: false)
        createImageSet(name: "NoNamespace/shared_icon")
    }
    
    private func createImageSet(name: String) {
        let imageSetPath = "\(testAssetsPath!)/\(name).imageset"
        let contentsPath = "\(imageSetPath)/Contents.json"
        
        try! FileManager.default.createDirectory(
            atPath: imageSetPath,
            withIntermediateDirectories: true
        )
        
        // Extract just the image name without the path
        let imageName = URL(fileURLWithPath: name).lastPathComponent
        
        let contentsJSON = """
        {
          "images" : [
            {
              "filename" : "\(imageName).png",
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        
        try! contentsJSON.write(toFile: contentsPath, atomically: true, encoding: .utf8)
        
        // Create fake image file with just the image name
        let imagePath = "\(imageSetPath)/\(imageName).png"
        try! Data().write(to: URL(fileURLWithPath: imagePath))
    }
    
    private func createGroup(path: String, providesNamespace: Bool) {
        let groupPath = "\(testAssetsPath!)/\(path)"
        let contentsPath = "\(groupPath)/Contents.json"
        
        try! FileManager.default.createDirectory(
            atPath: groupPath,
            withIntermediateDirectories: true
        )
        
        let contentsJSON = """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          },
          "properties" : {
            "provides-namespace" : \(providesNamespace)
          }
        }
        """
        
        try! contentsJSON.write(toFile: contentsPath, atomically: true, encoding: .utf8)
    }
}

// MARK: - GroupNode Tests

extension ImageAssetGeneratorTests {
    
    func testGroupNodeInitialization() {
        let node = ImageAssetGenerator.GroupNode(name: "TestGroup")
        
        XCTAssertEqual(node.name, "TestGroup")
        XCTAssertTrue(node.images.isEmpty)
        XCTAssertTrue(node.children.isEmpty)
        XCTAssertTrue(node.providesNamespace)
        XCTAssertFalse(node.isRoot)
    }
    
    func testRootNodeCreation() {
        let rootNode = ImageAssetGenerator.GroupNode.createRoot()
        
        XCTAssertEqual(rootNode.name, "")
        XCTAssertTrue(rootNode.isRoot)
        XCTAssertEqual(rootNode.displayName, "<Root>")
        XCTAssertTrue(rootNode.isRootLevelContent)
    }
    
    func testChildNodeCreation() {
        let parent = ImageAssetGenerator.GroupNode(name: "Parent")
        
        let child1 = parent.childNode(named: "Child1")
        let child2 = parent.childNode(named: "Child2")
        let child1Again = parent.childNode(named: "Child1")
        
        XCTAssertEqual(parent.children.count, 2)
        XCTAssertEqual(child1.name, "Child1")
        XCTAssertEqual(child2.name, "Child2")
        XCTAssertTrue(child1 === child1Again) // 應該返回相同的實例
        XCTAssertFalse(child1.isRoot)
    }
    
    func testFullPathGeneration() {
        let root = ImageAssetGenerator.GroupNode.createRoot()
        let level1 = root.childNode(named: "Level1")
        let level2 = level1.childNode(named: "Level2")
        
        XCTAssertEqual(root.fullPath(from: root), "")
        XCTAssertEqual(level1.fullPath(from: root), "Level1")
        XCTAssertEqual(level2.fullPath(from: root), "Level1/Level2")
    }
    
    func testDisplayName() {
        let root = ImageAssetGenerator.GroupNode.createRoot()
        let child = ImageAssetGenerator.GroupNode(name: "TestChild")
        
        XCTAssertEqual(root.displayName, "<Root>")
        XCTAssertEqual(child.displayName, "TestChild")
    }
}

// MARK: - Asset Collection Tests

extension ImageAssetGeneratorTests {
    
    func testAssetCollection() {
        let rootNode = ImageAssetGenerator.collectImageAssets(from: testAssetsPath)
        
        // 檢查根節點屬性
        XCTAssertTrue(rootNode.isRoot)
        XCTAssertEqual(rootNode.displayName, "<Root>")
        
        // 檢查根層級圖片
        XCTAssertTrue(rootNode.images.contains("app_logo"))
        XCTAssertTrue(rootNode.images.contains("background-image"))
        
        // 檢查群組結構
        let iconsGroup = rootNode.children.first { $0.name == "Icons" }
        XCTAssertNotNil(iconsGroup)
        XCTAssertTrue(iconsGroup!.providesNamespace)
        XCTAssertTrue(iconsGroup!.images.contains("home_icon"))
        XCTAssertTrue(iconsGroup!.images.contains("profile-icon"))
        XCTAssertFalse(iconsGroup!.isRoot)
        
        // 檢查巢狀群組
        let navigationGroup = iconsGroup?.children.first { $0.name == "Navigation" }
        XCTAssertNotNil(navigationGroup)
        XCTAssertTrue(navigationGroup!.providesNamespace)
        XCTAssertTrue(navigationGroup!.images.contains("arrow_left"))
        XCTAssertTrue(navigationGroup!.images.contains("arrow_right"))
        XCTAssertFalse(navigationGroup!.isRoot)
        
        // 檢查不提供 namespace 的群組
        let noNamespaceGroup = rootNode.children.first { $0.name == "NoNamespace" }
        XCTAssertNotNil(noNamespaceGroup)
        XCTAssertFalse(noNamespaceGroup!.providesNamespace)
        XCTAssertTrue(noNamespaceGroup!.images.contains("shared_icon"))
        XCTAssertFalse(noNamespaceGroup!.isRoot)
    }
    
    func testEmptyAssetsCollection() {
        let emptyPath = tempDirectory.appendingPathComponent("Empty.xcassets").path
        try! FileManager.default.createDirectory(atPath: emptyPath, withIntermediateDirectories: true)
        
        let rootNode = ImageAssetGenerator.collectImageAssets(from: emptyPath)
        
        XCTAssertEqual(rootNode.name, "")
        XCTAssertTrue(rootNode.isRoot)
        XCTAssertTrue(rootNode.images.isEmpty)
        XCTAssertTrue(rootNode.children.isEmpty)
    }
}

// MARK: - Code Generation Tests

extension ImageAssetGeneratorTests {
    
    func testCompleteCodeGeneration() {
        let generatedCode = ImageAssetGenerator.generateCode(from: testAssetsPath)
        
        XCTAssertFalse(generatedCode.baseEnum.isEmpty)
        XCTAssertFalse(generatedCode.uikitExt.isEmpty)
        XCTAssertFalse(generatedCode.swiftuiExt.isEmpty)
        
        // 檢查基本 enum 內容
        XCTAssertTrue(generatedCode.baseEnum.contains("enum ImageAsset: String"))
        XCTAssertTrue(generatedCode.baseEnum.contains("case appLogo = \"app_logo\""))
        XCTAssertTrue(generatedCode.baseEnum.contains("case backgroundImage = \"background-image\""))
        
        // 檢查群組 enum
        XCTAssertTrue(generatedCode.baseEnum.contains("enum Icons: String"))
        XCTAssertTrue(generatedCode.baseEnum.contains("case homeIcon = \"Icons/home_icon\""))
        
        // 檢查 UIKit 擴展
        XCTAssertTrue(generatedCode.uikitExt.contains("#if canImport(UIKit)"))
        XCTAssertTrue(generatedCode.uikitExt.contains("extension UIImage"))
        XCTAssertTrue(generatedCode.uikitExt.contains("convenience init?(asset: ImageAsset)"))
        
        // 檢查 SwiftUI 擴展
        XCTAssertTrue(generatedCode.swiftuiExt.contains("import SwiftUI"))
        XCTAssertTrue(generatedCode.swiftuiExt.contains("extension Image"))
        XCTAssertTrue(generatedCode.swiftuiExt.contains("init(asset: ImageAsset)"))
    }
    
    func testNamespaceHandling() {
        let generatedCode = ImageAssetGenerator.generateCode(from: testAssetsPath)
        
        // 有 namespace 的群組應該包含路徑
        XCTAssertTrue(generatedCode.baseEnum.contains("case homeIcon = \"Icons/home_icon\""))
        XCTAssertTrue(generatedCode.baseEnum.contains("case arrowLeft = \"Icons/Navigation/arrow_left\""))
        
        // 沒有 namespace 的群組不應該包含路徑
        XCTAssertTrue(generatedCode.baseEnum.contains("case sharedIcon = \"shared_icon\""))
    }
    
    func testEnumFileGeneration() {
        let rootNode = ImageAssetGenerator.collectImageAssets(from: testAssetsPath)
        let generatedCode = ImageAssetGenerator.generateEnumFiles(from: rootNode)
        
        // 檢查所有三個檔案都有內容
        XCTAssertFalse(generatedCode.baseEnum.isEmpty)
        XCTAssertFalse(generatedCode.uikitExt.isEmpty)
        XCTAssertFalse(generatedCode.swiftuiExt.isEmpty)
        
        // 檢查自動生成的註解
        XCTAssertTrue(generatedCode.baseEnum.contains("Auto-generated by ImageAssetGenerator"))
    }
}

// MARK: - String Utilities Tests

extension ImageAssetGeneratorTests {
    
    func testCamelCaseConversion() {
        // 這些測試需要存取 StringUtils，但它是 private 的
        // 我們透過測試生成的程式碼來間接測試
        let rootNode = ImageAssetGenerator.GroupNode.createRoot()
        rootNode.images = ["app_logo", "background-image", "icon-24", "123icon"]
        
        let generatedCode = ImageAssetGenerator.generateEnumFiles(from: rootNode)
        
        XCTAssertTrue(generatedCode.baseEnum.contains("case appLogo"))
        XCTAssertTrue(generatedCode.baseEnum.contains("case backgroundImage"))
        XCTAssertTrue(generatedCode.baseEnum.contains("case icon24"))
        XCTAssertTrue(generatedCode.baseEnum.contains("case image123Icon")) // 數字開頭應該加前綴
    }
    
    func testEnumNameSanitization() {
        let rootNode = ImageAssetGenerator.GroupNode.createRoot()
        let _ = rootNode.childNode(named: "my-group")
        let _ = rootNode.childNode(named: "123group")
        let _ = rootNode.childNode(named: "normal_group")
        
        let generatedCode = ImageAssetGenerator.generateEnumFiles(from: rootNode)
        
        XCTAssertTrue(generatedCode.baseEnum.contains("enum My_group"))
        XCTAssertTrue(generatedCode.baseEnum.contains("enum Group123group"))
        XCTAssertTrue(generatedCode.baseEnum.contains("enum Normal_group"))
    }
}

// MARK: - Integration Tests

extension ImageAssetGeneratorTests {
    
    func testFullWorkflow() {
        // 測試完整的工作流程
        let rootNode = ImageAssetGenerator.collectImageAssets(from: testAssetsPath)
        let generatedCode = ImageAssetGenerator.generateEnumFiles(from: rootNode)
        
        // 確保生成的程式碼在語法上是有效的
        XCTAssertTrue(isValidSwiftCode(generatedCode.baseEnum))
        XCTAssertTrue(isValidSwiftCode(generatedCode.uikitExt))
        XCTAssertTrue(isValidSwiftCode(generatedCode.swiftuiExt))
    }
    
    func testComplexNestedStructure() {
        // 建立更複雜的巢狀結構
        createGroup(path: "Complex", providesNamespace: true)
        createGroup(path: "Complex/SubGroup1", providesNamespace: true)
        createGroup(path: "Complex/SubGroup2", providesNamespace: false)
        createImageSet(name: "Complex/SubGroup1/nested_icon")
        createImageSet(name: "Complex/SubGroup2/another_icon")
        
        let rootNode = ImageAssetGenerator.collectImageAssets(from: testAssetsPath)
        let generatedCode = ImageAssetGenerator.generateEnumFiles(from: rootNode)
        
        // 檢查複雜結構是否正確處理
        XCTAssertTrue(generatedCode.baseEnum.contains("enum Complex"))
        XCTAssertTrue(generatedCode.baseEnum.contains("enum SubGroup1"))
        XCTAssertTrue(generatedCode.baseEnum.contains("enum SubGroup2"))
        XCTAssertTrue(generatedCode.baseEnum.contains("Complex/SubGroup1/nested_icon"))
        XCTAssertTrue(generatedCode.baseEnum.contains("another_icon")) // SubGroup2 不提供 namespace
    }
    
    private func isValidSwiftCode(_ code: String) -> Bool {
        // 簡單的語法檢查
        let braceCount = code.filter { $0 == "{" }.count - code.filter { $0 == "}" }.count
        return braceCount == 0 && !code.contains("case  ") && !code.contains("enum  ")
    }
}

// MARK: - Error Handling Tests

extension ImageAssetGeneratorTests {
    
    func testInvalidPath() {
        let invalidPath = "/nonexistent/path/Assets.xcassets"
        let rootNode = ImageAssetGenerator.collectImageAssets(from: invalidPath)
        
        // 應該返回空的根節點而不是崩潰
        XCTAssertEqual(rootNode.name, "")
        XCTAssertTrue(rootNode.isRoot)
        XCTAssertTrue(rootNode.images.isEmpty)
        XCTAssertTrue(rootNode.children.isEmpty)
    }
    
    func testCorruptedJSON() {
        // 建立損壞的 JSON 檔案
        let corruptedGroupPath = "\(testAssetsPath!)/CorruptedGroup"
        let contentsPath = "\(corruptedGroupPath)/Contents.json"
        
        try! FileManager.default.createDirectory(
            atPath: corruptedGroupPath,
            withIntermediateDirectories: true
        )
        
        let corruptedJSON = "{ invalid json }"
        try! corruptedJSON.write(toFile: contentsPath, atomically: true, encoding: .utf8)
        
        createImageSet(name: "CorruptedGroup/test_icon")
        
        // 應該仍能處理，只是該群組會使用預設的 namespace 設定
        let rootNode = ImageAssetGenerator.collectImageAssets(from: testAssetsPath)
        let corruptedGroup = rootNode.children.first { $0.name == "CorruptedGroup" }
        
        XCTAssertNotNil(corruptedGroup)
        XCTAssertFalse(corruptedGroup!.providesNamespace) // 預設為 false（因為 JSON 無效）
        XCTAssertFalse(corruptedGroup!.isRoot)
    }
}

// MARK: - Performance Tests

extension ImageAssetGeneratorTests {
    
    func testPerformanceWithLargeAssetCatalog() {
        // 建立大量的資源進行效能測試
        for i in 1...100 {
            createImageSet(name: "performance_test_\(i)")
        }
        
        for i in 1...10 {
            createGroup(path: "Group\(i)", providesNamespace: true)
            for j in 1...10 {
                createImageSet(name: "Group\(i)/icon_\(j)")
            }
        }
        
        measure {
            let _ = ImageAssetGenerator.generateCode(from: testAssetsPath)
        }
    }
}

// MARK: - Edge Cases Tests

extension ImageAssetGeneratorTests {
    
    func testSpecialCharactersInNames() {
        createImageSet(name: "special-chars_test")
        createImageSet(name: "with spaces") // 這會被轉換為 with_spaces
        createImageSet(name: "123numeric")
        
        let generatedCode = ImageAssetGenerator.generateCode(from: testAssetsPath)
        
        XCTAssertTrue(generatedCode.baseEnum.contains("case specialCharsTest"))
        XCTAssertTrue(generatedCode.baseEnum.contains("case image123Numeric"))
    }
    
    func testEmptyGroupNames() {
        // 測試空的群組名稱處理
        let rootNode = ImageAssetGenerator.GroupNode.createRoot()
        let emptyNameChild = rootNode.childNode(named: "")
        emptyNameChild.images.append("test_image")
        
        let generatedCode = ImageAssetGenerator.generateEnumFiles(from: rootNode)
        
        // 應該能處理而不崩潰
        XCTAssertFalse(generatedCode.baseEnum.isEmpty)
    }
    
    func testRootNodeProperties() {
        let rootNode = ImageAssetGenerator.GroupNode.createRoot()
        let childNode = ImageAssetGenerator.GroupNode(name: "Child")
        
        // 測試根節點的特殊屬性
        XCTAssertTrue(rootNode.isRoot)
        XCTAssertTrue(rootNode.isRootLevelContent)
        XCTAssertEqual(rootNode.displayName, "<Root>")
        
        // 測試子節點的屬性
        XCTAssertFalse(childNode.isRoot)
        XCTAssertFalse(childNode.isRootLevelContent)
        XCTAssertEqual(childNode.displayName, "Child")
    }
}
