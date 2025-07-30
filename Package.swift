// swift-tools-version:5.9

import PackageDescription

extension String {
    static let urlFormCoding: Self = "URLFormCoding"
}

extension Target.Dependency {
    static var urlFormCoding: Self { .target(name: .urlFormCoding) }
}

let package = Package(
    name: "swift-url-form-coding",
    products: [
        .library(name: .urlFormCoding, targets: [.urlFormCoding])
    ],
    dependencies: [],
    targets: [
        .target(
            name: .urlFormCoding,
            dependencies: []
        ),
        .testTarget(
            name: .urlFormCoding.tests,
            dependencies: [
                .urlFormCoding
            ]
        )
    ]
)

extension String { var tests: Self { self + " Tests" } }
