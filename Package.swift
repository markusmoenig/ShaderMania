// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ShaderMania",
    platforms: [
        .macOS(.v11)
    ],
    products: [],
    targets: [
        .target(
            name: "ShaderManiaCore",
            path: "Shared",
            exclude: [
                "AppIcon.icon",
                "Assets.xcassets",
                "Classes",
                "Files",
                "Fonts",
                "Metal.h",
                "Metal.metal",
                "Asset.swift",
                "ContentView.swift",
                "Core.swift",
                "File.swift",
                "Library.swift",
                "MathLibrary.swift",
                "MetalDrawables.swift",
                "MetalStates.swift",
                "MetalView.swift",
                "NodesWidget.swift",
                "Project.swift",
                "ScriptEditor.swift",
                "ShaderCompiler.swift",
                "ShaderManiaApp.swift",
                "ShaderManiaDocument.swift",
                "StoreManager.swift",
                "Utils.swift",
                "Views.swift"
            ],
            sources: [
                "GraphDependencyResolver.swift",
                "LibraryQuality.swift",
                "ShaderAnnotationScanner.swift"
            ]
        ),
        .testTarget(
            name: "ShaderManiaCoreTests",
            dependencies: ["ShaderManiaCore"],
            path: "ShaderManiaTests"
        )
    ]
)
