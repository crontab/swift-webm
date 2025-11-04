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
            name: "WebMBridge",
            targets: ["WebMBridge"]
        ),
        .executable(
            name: "CLITest",
            targets: ["CLITest"]
        )
    ],

    targets: [

        .executableTarget(
            name: "CLITest",
            dependencies: ["WebMBridge"],
            path: "Sources/CLITest"
        ),

        // MARK: - WebMBridge

        .target(
            name: "WebMBridge",
            dependencies: ["libwebm"],
            path: "Sources/WebMBridge",
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
            path: "Sources/libwebm",
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
