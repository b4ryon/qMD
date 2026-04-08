// qMD - HTMLTemplate tests
// Validates HTML template construction and resource loading.

import XCTest
import Foundation
@testable import qmd

final class HTMLTemplateTests: XCTestCase {

    func testContainsDoctype() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.hasPrefix("<!DOCTYPE html>"))
    }

    func testContainsMarkdownIt() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("markdownit"))
    }

    func testContainsHighlightJS() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("hljs"))
    }

    func testContainsRenderFunction() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("function renderMarkdown("))
    }

    func testContainsBase64Decoder() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("decodeBase64UTF8"))
    }

    func testContainsContentDiv() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("id=\"content\""))
    }

    func testSupportsDarkMode() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("prefers-color-scheme: dark"))
    }

    func testSupportsLightMode() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("prefers-color-scheme: light"))
    }

    func testHandlesTaskLists() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("task-item"))
    }

    func testContainsCustomStyles() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("font-family"))
    }

    func testValidHTMLStructure() {
        let template = HTMLTemplate()
        XCTAssertTrue(template.html.contains("<html>"))
        XCTAssertTrue(template.html.contains("</html>"))
        XCTAssertTrue(template.html.contains("<head>"))
        XCTAssertTrue(template.html.contains("</head>"))
        XCTAssertTrue(template.html.contains("<body>"))
        XCTAssertTrue(template.html.contains("</body>"))
    }

    func testSubstantialSize() {
        let template = HTMLTemplate()
        XCTAssertGreaterThan(template.html.count, 1000)
    }
}
