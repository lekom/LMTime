import XCTest
@testable import LMTime

final class LMTimeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(LMTime().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
