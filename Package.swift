// swift-tools-version: 5.9
// qMD - A simple macOS Markdown viewer application

import PackageDescription

let package = Package(
    name: "qmd",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "qmd",
            path: "Sources/qmd",
            resources: [
                .copy("Resources/web"),
                .copy("Resources/AppIcon.icns")
            ]
        ),
        .testTarget(
            name: "qmdTests",
            dependencies: ["qmd"],
            path: "Tests/qmdTests"
        )
    ]
)
