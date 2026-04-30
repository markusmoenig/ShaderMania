//
//  LibraryQualityTests.swift
//  ShaderManiaTests
//
//  Created by Codex on 30/4/26.
//

import XCTest
@testable import ShaderManiaCore

final class LibraryQualityTests: XCTestCase {

    func testRejectsDefaultPlaceholderShaderForUploadAndDisplay() {
        let summary = LibraryProjectSummary(
            name: "Default Shader",
            description: "A placeholder upload that should not be public.",
            tags: "test",
            assets: [
                LibraryAssetSummary(
                    type: .shader,
                    name: "Shader",
                    source: "void mainImage(thread Data &data) { data.outColor = float4(1, 0, 0, 1); }"
                )
            ]
        )

        XCTAssertFalse(LibraryQuality.isUploadable(summary))
        XCTAssertFalse(LibraryQuality.isDisplayable(summary))
        XCTAssertTrue(LibraryQuality.displayIssues(for: summary).contains(.placeholderShader))
    }

    func testRequiresUsefulMetadataForUpload() {
        let summary = LibraryProjectSummary(
            name: "FX",
            description: "",
            tags: "",
            assets: [
                LibraryAssetSummary(
                    type: .shader,
                    name: "Wave",
                    source: "void mainImage(thread Data &data) { data.outColor = float4(sin(data.time), 0, 1, 1); }"
                )
            ]
        )

        XCTAssertFalse(LibraryQuality.isUploadable(summary))
        XCTAssertTrue(LibraryQuality.uploadIssues(for: summary).contains(.missingName))
        XCTAssertTrue(LibraryQuality.uploadIssues(for: summary).contains(.missingDescription))
    }

    func testAcceptsMeaningfulShaderWithMetadata() {
        let summary = LibraryProjectSummary(
            name: "Animated Waves",
            description: "A procedural animated wave shader.",
            tags: "waves procedural",
            assets: [
                LibraryAssetSummary(
                    type: .shader,
                    name: "Wave",
                    source: "void mainImage(thread Data &data) { float v = sin(data.time + data.uv.x * 10.0); data.outColor = float4(v, data.uv.x, data.uv.y, 1); }"
                )
            ]
        )

        XCTAssertTrue(LibraryQuality.isUploadable(summary))
        XCTAssertTrue(LibraryQuality.isDisplayable(summary))
    }
}
