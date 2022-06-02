@testable import KeyValueCache
import XCTest

final class KeyValueCacheTests: XCTestCase {
    func testKeyValueCache() throws {
        let valueCache = KeyValueCache<String, String>()

        let now = Date()

        valueCache.setValue("AAAAAA", forKey: "A", expireDate: now.addingTimeInterval(3))

        valueCache.setValue("BBBBBB", forKey: "B", expireDate: now.addingTimeInterval(6))

        let expA = XCTestExpectation(description: "Read for 'A' key")

        valueCache.value(forKey: "A").whenSuccess { value in
            XCTAssertEqual("AAAAAA", value)

            expA.fulfill()
        }

        let expB = XCTestExpectation(description: "Read for 'B' key")
        valueCache.value(forKey: "B").whenSuccess { value in
            XCTAssertEqual("BBBBBB", value)

            expB.fulfill()
        }

        wait(for: [expA, expB], timeout: 1.0)

        Thread.sleep(forTimeInterval: 4)

        let expA1 = XCTestExpectation(description: "Read for 'A' key after deadline")

        valueCache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA1.fulfill()
        }

        let expB1 = XCTestExpectation(description: "Read for 'B' key")
        valueCache.value(forKey: "B").whenSuccess { value in
            XCTAssertEqual("BBBBBB", value)

            expB1.fulfill()
        }

        wait(for: [expA1, expB1], timeout: 1.0)

        Thread.sleep(forTimeInterval: 3)

        let expA2 = XCTestExpectation(description: "Read for 'A' key after deadline")

        valueCache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA2.fulfill()
        }

        let expB2 = XCTestExpectation(description: "Read for 'B' key after deadline")
        valueCache.value(forKey: "B").whenSuccess { value in
            XCTAssertNil(value)

            expB2.fulfill()
        }

        wait(for: [expA2, expB2], timeout: 1.0)
    }
}
