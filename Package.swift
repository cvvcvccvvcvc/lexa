// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VocabularyTracker",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "VocabularyCore",
            targets: ["VocabularyCore"]
        ),
        .library(
            name: "VocabularyInfrastructure",
            targets: ["VocabularyInfrastructure"]
        ),
        .executable(
            name: "VocabularyApp",
            targets: ["VocabularyApp"]
        )
    ],
    targets: [
        .target(
            name: "VocabularyCore",
            exclude: [
                "Domain/README.md",
                "Domain/Dictionary/README.md",
                "Domain/Models/README.md",
                "Domain/Scheduling/README.md"
            ]
        ),
        .target(
            name: "VocabularyInfrastructure",
            dependencies: ["VocabularyCore"],
            exclude: [
                "README.md",
                "Dictionary/README.md",
                "Persistence/README.md",
                "Speech/README.md",
                "Translation/README.md"
            ]
        ),
        .executableTarget(
            name: "VocabularyApp",
            dependencies: [
                "VocabularyCore",
                "VocabularyInfrastructure"
            ],
            exclude: [
                "App/README.md",
                "Features/README.md",
                "Features/Learn/README.md",
                "Features/AddWord/README.md",
                "Features/Words/README.md"
            ]
        ),
        .testTarget(
            name: "VocabularyCoreTests",
            dependencies: ["VocabularyCore"],
            exclude: [
                "README.md"
            ]
        )
    ]
)
