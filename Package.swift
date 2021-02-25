// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Prance",
    platforms: [
      .macOS(.v10_14),
    ],
    products: [
      .executable(
        name: "Prance",
        targets: ["Prance"]),
      .library(
        name: "PranceCore",
        type: .static,
        targets: ["PranceCore"])
    ],
    dependencies: [
      .package(name:"LLVM", url: "https://github.com/trill-lang/LLVMSwift.git", .branch("master"))
    ],
    targets: [
        .target(
          name: "PranceCore",
          dependencies:["LLVM"]),
        .target(
            name: "Prance",
            dependencies: ["PranceCore"])
    ]
)
