// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let cxxSettings: [CXXSetting] = [
    .headerSearchPath("../"),
    .headerSearchPath("./xdelta"),
    .headerSearchPath("./adapters"),
    .define("HAVE_CONFIG_H"),
    .define("SECONDARY_FGK", to: "1"),
    .define("SECONDARY_DJW", to: "1")
]

let cSettings: [CSetting] = [
    .headerSearchPath("../"),
    .headerSearchPath("./xdelta"),
    .headerSearchPath("../flips"),
    .headerSearchPath("./adapters"),
    .define("HAVE_CONFIG_H"),
    .define("SECONDARY_FGK", to: "1"),
    .define("SECONDARY_DJW", to: "1")
]

let linkerSettings: [LinkerSetting] = [
    .linkedFramework("Foundation"),
    .linkedFramework("CoreFoundation"),
    .linkedLibrary("lzma"),
    .linkedLibrary("bz2"),
    .linkedLibrary("z")
]

var linkerSettingsApp: [LinkerSetting] = linkerSettings
linkerSettingsApp.append(.linkedFramework("AppKit"))
linkerSettingsApp.append(.linkedFramework("Cocoa"))
linkerSettingsApp.append(.linkedFramework("ApplicationServices"))
linkerSettingsApp.append(.linkedFramework("Sparkle"))

var products: [Product] = [
		.library(name: "MultiPatcherShared", type: .dynamic, targets: ["MultiPatcherShared"]),
		.library(name: "librup", type: .static, targets: ["librup"]),
		.library(name: "bsdiff", type: .static, targets: ["bsdiff"]),
		.library(name: "ppfdev", type: .static, targets: ["ppfdev"]),
		.library(name: "flips", type: .static, targets: ["flips"]),
]

#if HAVE_XDELTA
    products.append(.library(name: "xdelta", type: .static, targets: ["xdelta"]))
#endif

#if os(macOS)
    // products.append(.executable(name: "MultiPatcher", targets: ["MultiPatcher"]))
    products.append(.executable(name: "cmdMultiPatch", targets: ["cmdMultiPatch"]))
#endif

var targets: [Target] = [
    .target(name: "MultiPatcherShared",
            dependencies: ["flips", "librup", "ppfdev", "bsdiff"],
            path: "Shared",
            exclude: ["en.lproj"],
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
                // "XDeltaAdapter.h",
                "xdelta/xdelta3.h",
                // "XDeltaAdapter.m",
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
            exclude: [
                "BSdiffAdapter.m",
                "BSdiffAdapter.h"],
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
            path: "xdelta",
            sources: [
                "xdelta3.h",
                "xdelta3.m"
            ],
            publicHeadersPath: "",
            cSettings: cSettings,
            cxxSettings: cxxSettings,
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("CoreFoundation")
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
// targets.append(.executableTarget(
//     name: "MultiPatcher",
//     dependencies: [
//         "MultiPatcherShared",
//         // "Sparkle"
//     ],
//     path: "App",
//     exclude: ["en.lproj"],
//     sources: [
//         "main.m",
//         "MPPatchWindow.mm",
//         "MPFileTextField.m",
//         "mbFlipWindow.m",
//         "MPCreationWindow.mm",
//         "MultiPatchController.m"
//     ],
//     cSettings: cSettings,
//     cxxSettings: cxxSettings,
//     linkerSettings: linkerSettingsApp
// //         // resources: [
// //         //     .process("text.txt"),
// //         //     .process("example.png"),
// //         //     .copy("settings.plist")
// //         // ]
//     )
// )
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
        // .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.0.0")
    ],
    targets: targets,
    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .cxx11
)
