//
//  LibraryQuality.swift
//  ShaderMania
//
//  Created by Codex on 30/4/26.
//

import Foundation

struct LibraryAssetSummary {
    enum AssetType {
        case shader
        case image
        case audio
        case texture
        case other
    }

    let type: AssetType
    let name: String
    let source: String
}

struct LibraryProjectSummary {
    let name: String
    let description: String
    let tags: String
    let assets: [LibraryAssetSummary]
}

enum LibraryQualityIssue: Equatable {
    case missingName
    case missingDescription
    case missingShader
    case placeholderShader
}

enum LibraryQuality {

    static func uploadIssues(for summary: LibraryProjectSummary) -> [LibraryQualityIssue] {
        var issues = displayIssues(for: summary)

        if summary.description.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
            issues.append(.missingDescription)
        }

        return unique(issues)
    }

    static func displayIssues(for summary: LibraryProjectSummary) -> [LibraryQualityIssue] {
        var issues: [LibraryQualityIssue] = []

        if summary.name.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
            issues.append(.missingName)
        }

        let shaderAssets = summary.assets.filter { $0.type == .shader }
        if shaderAssets.isEmpty {
            issues.append(.missingShader)
        }

        if shaderAssets.contains(where: isMeaningfulShader) == false {
            issues.append(.placeholderShader)
        }

        return unique(issues)
    }

    static func isUploadable(_ summary: LibraryProjectSummary) -> Bool {
        uploadIssues(for: summary).isEmpty
    }

    static func isDisplayable(_ summary: LibraryProjectSummary) -> Bool {
        displayIssues(for: summary).isEmpty
    }

    private static func isMeaningfulShader(_ asset: LibraryAssetSummary) -> Bool {
        let source = asset.source
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .lowercased()

        guard source.contains("voidmainimage") else {
            return false
        }

        let placeholderShaders = [
            "voidmainimage(threaddata&data){data.outcolor=float4(1,0,0,1);}",
            "voidmainimage(threaddata&data){data.outcolor=float4(0,0,0,1);}"
        ]

        return placeholderShaders.contains(source) == false
    }

    private static func unique(_ issues: [LibraryQualityIssue]) -> [LibraryQualityIssue] {
        var result: [LibraryQualityIssue] = []
        for issue in issues {
            if result.contains(issue) == false {
                result.append(issue)
            }
        }
        return result
    }
}
