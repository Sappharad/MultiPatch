// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

// build:
//  - macos: swift build
//  - iOS: swift build -Xswiftc "-sdk" -Xswiftc "`xcrun --sdk iphonesimulator --show-sdk-path`" -Xswiftc "-target" -Xswiftc "x86_64-apple-ios13.0-simulator"

import PackageDescription

let cxxSettings: [CXXSetting] = [
    .headerSearchPath("../"),
    .headerSearchPath("../xdelta"),
    .headerSearchPath("adapters"),
    .define("HAVE_CONFIG_H"),
    .define("SECONDARY_FGK", to: "1"),
    .define("SECONDARY_DJW", to: "1")
]

let cSettings: [CSetting] = [
    .headerSearchPath("../"),
    .headerSearchPath("../xdelta"),
    .headerSearchPath("../flips"),
    .headerSearchPath("adapters"),
    .define("HAVE_CONFIG_H"),
    .define("SECONDARY_FGK", to: "1"),
    .define("SECONDARY_DJW", to: "1"),
    .define("SECONDARY_LZMA", to: "0", .when(platforms: [.iOS, .tvOS]))
]

let linkerSettings: [LinkerSetting] = [
    .linkedFramework("Foundation"),
    .linkedFramework("CoreFoundation"),
    .linkedLibrary("lzma", .when(platforms: [.macOS, .linux])),
    .linkedLibrary("bz2"),
    .linkedLibrary("z"),
    .linkedLibrary("ssl", .when(platforms: [.linux])),
    .linkedLibrary("crypto", .when(platforms: [.linux]))
]

var linkerSettingsApp: [LinkerSetting] = linkerSettings
linkerSettingsApp.append(.linkedFramework("AppKit", .when(platforms: [.macOS])))
linkerSettingsApp.append(.linkedFramework("Cocoa", .when(platforms: [.macOS])))
linkerSettingsApp.append(.linkedFramework("ApplicationServices", .when(platforms: [.macOS])))
linkerSettingsApp.append(.linkedFramework("Sparkle", .when(platforms: [.macOS])))
linkerSettingsApp.append(.linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])))

var products: [Product] = [
		.library(name: "MultiPatcherShared", type: .dynamic, targets: ["MultiPatcherShared"]),
		.library(name: "librup", type: .static, targets: ["librup"]),
		.library(name: "bsdiff", type: .static, targets: ["bsdiff"]),
		.library(name: "ppfdev", type: .static, targets: ["ppfdev"]),
		.library(name: "flips", type: .static, targets: ["flips"]),
        .library(name: "xdelta", type: .static, targets: ["xdelta"]),
]

#if os(macOS)
    products.append(.executable(name: "MultiPatcher", targets: ["MultiPatcher"]))
    products.append(.executable(name: "cmdMultiPatch", targets: ["cmdMultiPatch"]))
#endif

var targets: [Target] = [
    .target(name: "MultiPatcherShared",
            dependencies: ["flips", "librup", "ppfdev", "bsdiff", "xdelta"],
            path: "Shared",
            sources: [
                "MPSettings.m",
                "adapters/PPFAdapter.m",
                "adapters/BPSAdapter.mm",
                "adapters/UPSAdapter.mm",
                "adapters/RUPAdapter.m",
                "adapters/IPSAdapter.mm",
                "adapters/flips-support.mm",
                "adapters/BSdiffAdapter.m",
                "adapters/BSdiffAdapter.h",
                "MPPatchResult.h",
                "MPPatchResult.m",
                "adapters/XDeltaAdapter.h",
                "adapters/XDeltaAdapter.m"
            ],
            publicHeadersPath: "",
            cSettings: cSettings,
            cxxSettings: cxxSettings,
            linkerSettings: linkerSettings
            ),

    .target(name: "librup",
            path: "librup",
            publicHeadersPath: ""),

    .target(name: "bsdiff",
            path: "bsdiff",
            publicHeadersPath: "",
            cSettings: [.headerSearchPath("../")]),

    .target(name: "ppfdev",
            path: "ppfdev",
            publicHeadersPath: ""),

    .target(name: "flips",
            path: "flips",
            sources: [
                "flips.cpp",
                "flips.h",
                "divsufsort.c",
                "libbps.cpp",
                "libbps.h",
                "libups.cpp",
                "libups.h",
                "libips.cpp",
                "libips.h",
                "crc32.cpp",
                "libbps-suf.cpp"
            ],
            publicHeadersPath: "include"),

    .target(name: "xdelta",
            dependencies: [.product(name: "liblzma", package: "liblzma.swift", condition: .when(platforms: [.iOS, .tvOS]))],
            path: "xdelta",
            exclude: ["examples", "testing", "m4", "go", "include", "cpp-btree"],
            sources: [
                "xdelta3.h",
                "xdelta3.m"
            ],
            publicHeadersPath: "include",
            cSettings: cSettings,
            cxxSettings: cxxSettings,
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("CoreFoundation"),
                .linkedLibrary("lzma", .when(platforms: [.linux])),
            ])
]

#if os(macOS)
// cmdMultiPatch command line app
targets.append(.executableTarget(
    name: "cmdMultiPatch",
    dependencies: ["MultiPatcherShared"],
    path: "cmdMultiPatch",
    sources: [
        "main.mm"
    ],
    cSettings: [
        .headerSearchPath("../"),
        .headerSearchPath("../xdelta"),
        .headerSearchPath("../flips"),
        .headerSearchPath("../Shared/adapters"),
        .define("HAVE_CONFIG_H"),
        .define("SECONDARY_FGK", to: "1"),
        .define("SECONDARY_DJW", to: "1")
    ],
    cxxSettings: [
        .headerSearchPath("./"),
        .headerSearchPath("../xdelta"),
        .headerSearchPath("../flips"),
        .headerSearchPath("../Shared/adapters"),
        .define("HAVE_CONFIG_H"),
        .define("SECONDARY_FGK", to: "1"),
        .define("SECONDARY_DJW", to: "1")
    ],
    linkerSettings: linkerSettings
    )
)

// MultiPatcher.app
// TODO: Fix Sparkle and C++ support
targets.append(.executableTarget(
    name: "MultiPatcher",
    dependencies: [
        "MultiPatcherShared",
        "Sparkle"
    ],
    path: "App",
    // exclude: ["en.lproj"],
    sources: [
        "main.m",
        "MPPatchWindow.mm",
        "MPFileTextField.m",
        "mbFlipWindow.m",
        "MPCreationWindow.mm",
        "MultiPatchController.m"
    ],
    resources: [
        .process("../Base.lproj/MainMenu.xib"),
        .process("../en.lproj/InfoPlist.strings"),
        .process("../Media.xcassets"),
        .copy("Credits.rtf")
    ],
    cSettings: [
        .headerSearchPath("../"),
        .headerSearchPath("../xdelta"),
        .headerSearchPath("../flips"),
        .headerSearchPath("../Shared/adapters"),
        .define("HAVE_CONFIG_H"),
        .define("SECONDARY_FGK", to: "1"),
        .define("SECONDARY_DJW", to: "1")
    ],
    cxxSettings: [
        .headerSearchPath("./"),
        .headerSearchPath("../xdelta"),
        .headerSearchPath("../flips"),
        .headerSearchPath("../Shared/adapters"),
        .define("HAVE_CONFIG_H"),
        .define("SECONDARY_FGK", to: "1"),
        .define("SECONDARY_DJW", to: "1")
    ],
    linkerSettings: linkerSettingsApp
    )
)
#endif

let package = Package(
    name: "MultiPatcher",
	defaultLocalization: "en",

	platforms: [
		.iOS(.v13),
		.tvOS(.v13),
        .macOS(.v11)
	],
    products: products,
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.0.0"),
        .package(url: "https://github.com/awxkee/liblzma.swift.git", from: "1.0.0")
    ],
    targets: targets,
    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .cxx11
)
