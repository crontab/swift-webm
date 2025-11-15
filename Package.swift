// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "swift-webm",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],

    products: [
        .library(
            name: "WebM",
            targets: ["WebM"]
        ),
        .library(
            name: "CWebM",
            targets: ["CWebM"]
        ),
        .executable(
            name: "CLITest",
            targets: ["CLITest"]
        )
    ],

    dependencies: [
        .package(url: "https://github.com/alta/swift-opus.git", from: "0.0.2")
    ],

    targets: [

        .executableTarget(
            name: "CLITest",
            dependencies: [
                "WebM",
                .product(name: "Opus", package: "swift-opus"),
            ],
        ),

        // MARK: - WebM

        .target(
            name: "WebM",
            dependencies: ["CWebM"],
        ),

        // MARK: - CWebM

        .target(
            name: "CWebM",
            dependencies: ["libwebm"],
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("../libwebm"),
                .headerSearchPath("../libwebm/mkvparser"),
                .headerSearchPath("../libwebm/mkvmuxer"),
                .headerSearchPath("../libwebm/common"),
                .define("MKVPARSER_HEADER_ONLY", to: "0"),
                .define("MKVMUXER_HEADER_ONLY", to: "0"),
                .define("_LIBCPP_DISABLE_AVAILABILITY", to: "1"),
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),

        // MARK: - libwebm

        .target(
            name: "libwebm",
            dependencies: [],
            sources: [
                "mkvparser/mkvparser.cc",
                "mkvparser/mkvreader.cc",
                "mkvmuxer/mkvmuxer.cc",
                "mkvmuxer/mkvmuxerutil.cc",
                "mkvmuxer/mkvwriter.cc",
                "common/webm_endian.cc",
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("mkvparser"),
                .headerSearchPath("mkvmuxer"),
                .headerSearchPath("common"),
                .define("MKVPARSER_HEADER_ONLY", to: "0"),
                .define("MKVMUXER_HEADER_ONLY", to: "0"),
                .define("_LIBCPP_DISABLE_AVAILABILITY", to: "1"),
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
    ],

    cxxLanguageStandard: .cxx14
)
