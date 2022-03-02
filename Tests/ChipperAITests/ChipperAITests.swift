import XCTest
@testable import ChipperAI

final class ChipperAITests: XCTestCase {
    func testDuck() throws {
        let chipper = AI()
        chipper.ask("Please Say 'Duck'."){ answer in
            XCTAssert(answer.lowercased() == "duck")
        }
    }
}
