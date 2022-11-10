// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let cxxSettings: [CXXSetting] = [
    .headerSearchPath("./"),
    .headerSearchPath("./xdelta"),
    .headerSearchPath("./adapters"),
    .define("HAVE_CONFIG_H"),
    .define("SECONDARY_FGK", to: "1"),
    .define("SECONDARY_DJW", to: "1")
]

let cSettings: [CSetting] = [
    .headerSearchPath("./"),
    .headerSearchPath("./xdelta"),
    .headerSearchPath("./flips"),
    .headerSearchPath("./adapters"),
    .define("HAVE_CONFIG_H"),
    .define("SECONDARY_FGK", to: "1"),
    .define("SECONDARY_DJW", to: "1")
]

let package = Package(
    name: "MultiPatcher",
	defaultLocalization: "en",
	platforms: [
		// .iOS(.v13),
		// .tvOS(.v13),
        .macOS(.v11)
	],
    products: [
        .executable(name: "cmdMultiPatch", targets: ["cmdMultiPatch"]),
		// .library(name: "MultiPatcherLib", targets: ["MultiPatcherLib", ""]),
		.library(name: "librup", targets: ["librup"]),
		.library(name: "bsdiff", targets: ["bsdiff"]),
		.library(name: "ppfdev", targets: ["ppfdev"]),
		.library(name: "flips", targets: ["flips"]),
        // .library(name: "xdelta", targets: ["xdelta"]),
    ],
    dependencies: [
    ],
    targets: [
		.executableTarget(  name: "cmdMultiPatch",
                            dependencies: ["flips", "librup", "ppfdev", "bsdiff"],
                            path: "./",
                            exclude: ["en.lproj"],
                            sources: [
                                "cmdMultiPatch/main.m",
                                "MPSettings.m",
                                "adapters/PPFAdapter.m",
                                "adapters/BPSAdapter.mm",
                                "adapters/UPSAdapter.mm",
                                "adapters/RUPAdapter.m",
                                "adapters/IPSAdapter.mm",
                                "adapters/flips-support.mm",
                                "bsdiff/BSdiffAdapter.m",
                                "bsdiff/BSdiffAdapter.h",
                                "MPPatchResult.h",
                                "MPPatchResult.m",
                                // "XDeltaAdapter.h",
                                "xdelta/xdelta3.h",
                                // "XDeltaAdapter.m",
                                ],
                                cSettings: cSettings,
                                cxxSettings: cxxSettings,
                                linkerSettings: [
                                    .linkedFramework("Foundation"),
                                    .linkedFramework("CoreFoundation"),
                                    .linkedLibrary("lzma"),
                                    .linkedLibrary("bz2")]
                               ),
		// .target(name: "MultiPatcherLib", dependencies: []),
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
)
