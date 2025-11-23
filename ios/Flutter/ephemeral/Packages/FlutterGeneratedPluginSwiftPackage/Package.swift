// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "audio_session", path: "/Users/koji4104/.pub-cache/hosted/pub.dev/audio_session-0.1.25/ios/audio_session"),
        .package(name: "battery_plus", path: "/Users/koji4104/.pub-cache/hosted/pub.dev/battery_plus-6.2.1/ios/battery_plus"),
        .package(name: "camera_avfoundation", path: "/Users/koji4104/.pub-cache/hosted/pub.dev/camera_avfoundation-0.9.18+11/ios/camera_avfoundation"),
        .package(name: "network_info_plus", path: "/Users/koji4104/.pub-cache/hosted/pub.dev/network_info_plus-6.1.3/ios/network_info_plus"),
        .package(name: "package_info_plus", path: "/Users/koji4104/.pub-cache/hosted/pub.dev/package_info_plus-8.3.0/ios/package_info_plus"),
        .package(name: "path_provider_foundation", path: "/Users/koji4104/.pub-cache/hosted/pub.dev/path_provider_foundation-2.4.1/darwin/path_provider_foundation"),
        .package(name: "shared_preferences_foundation", path: "/Users/koji4104/.pub-cache/hosted/pub.dev/shared_preferences_foundation-2.5.4/darwin/shared_preferences_foundation"),
        .package(name: "integration_test", path: "/Users/koji4104/a/pg/flutter/3.29.0/packages/integration_test/ios/integration_test")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "battery-plus", package: "battery_plus"),
                .product(name: "camera-avfoundation", package: "camera_avfoundation"),
                .product(name: "network-info-plus", package: "network_info_plus"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "integration-test", package: "integration_test")
            ]
        )
    ]
)
