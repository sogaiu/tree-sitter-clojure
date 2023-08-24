// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "TreeSitterClojure",
    platforms: [.macOS(.v10_13), .iOS(.v11)],
    products: [.library(name: "TreeSitterClojure", targets: ["TreeSitterClojure"])],
    targets: [
        .target(
            name: "TreeSitterClojure",
            path: ".",
            exclude: [
            ],
            sources: [
                "src/parser.c",
            ],
            resources: [
                .copy("queries"),
            ],
            publicHeadersPath: "bindings/swift",
            cSettings: [.headerSearchPath("src")]
        ),
    ]
)
