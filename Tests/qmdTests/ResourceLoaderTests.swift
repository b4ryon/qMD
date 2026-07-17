// qMD - ResourceLoader tests
// Regression guard for the v1.7.2 launch crash: SwiftPM's Bundle.module
// accessor could not resolve resources from the packaged .app layout and
// trapped with fatalError. These tests run in an environment where
// Bundle.main is NOT the app (the xctest runner), which is the same failure
// class: resources must still resolve, and misses must return nil rather
// than crash.

import XCTest
import Foundation
@testable import qmd

final class ResourceLoaderTests: XCTestCase {

    func testResolvesAllWebResourcesOutsideAppBundle() {
        let resources: [(String, String)] = [
            ("markdown-it.min", "js"),
            ("highlight.min", "js"),
            ("github.min", "css"),
            ("github-dark.min", "css"),
            ("style", "css"),
        ]
        for (name, ext) in resources {
            XCTAssertNotNil(
                ResourceLoader.url(forResource: name, ext: ext, subdirectory: "web"),
                "web/\(name).\(ext) must resolve when Bundle.main has no resources"
            )
        }
    }

    func testResolvesWelcomeImage() {
        XCTAssertNotNil(ResourceLoader.url(forResource: "qmd.welcome", ext: "png"))
    }

    func testMissingResourceReturnsNilInsteadOfTrapping() {
        XCTAssertNil(ResourceLoader.url(forResource: "does-not-exist", ext: "xyz", subdirectory: "web"))
        XCTAssertNil(ResourceLoader.string(forResource: "does-not-exist", ext: "xyz"))
    }

    func testStringLoadsActualContent() {
        let css = ResourceLoader.string(forResource: "style", ext: "css", subdirectory: "web")
        XCTAssertNotNil(css)
        XCTAssertTrue(css?.contains("font-family") ?? false, "style.css should define font-family")
    }
}
