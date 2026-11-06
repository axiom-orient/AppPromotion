// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppPromotion",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AppPromotion", targets: ["AppPromotion"]),
        .library(name: "AppPromotionRemote", targets: ["AppPromotionRemote"]),
        .library(name: "AppPromotionUI", targets: ["AppPromotionUI"]),
        .library(name: "AppPromotionExamples", targets: ["AppPromotionExamples"])
    ],
    targets: [
        .target(name: "AppPromotion"),
        .target(name: "AppPromotionRemote", dependencies: ["AppPromotion"]),
        .target(name: "AppPromotionUI", dependencies: ["AppPromotion"]),
        .target(name: "AppPromotionExamples", dependencies: ["AppPromotion"], resources: [.process("Resources")])
    ],
    swiftLanguageModes: [.v6]
)
