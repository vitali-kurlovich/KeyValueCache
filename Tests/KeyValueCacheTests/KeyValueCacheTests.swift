@testable import KeyValueCache
import NIO
import XCTest

final class KeyValueCacheTests: XCTestCase {
    func testExpire() throws {
        let valueCache = KeyValueCache<String, String>()

        let now = Date()

        valueCache.setValue("AAAAAA", forKey: "A", expireDate: now.addingTimeInterval(3))

        valueCache.setValue("BBBBBB", forKey: "B", expireDate: now.addingTimeInterval(6))

        valueCache.setValue("CCCCCC", forKey: "C")

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

        let expC = XCTestExpectation(description: "Read for 'C'")

        valueCache.value(forKey: "C").whenSuccess { value in
            XCTAssertEqual("CCCCCC", value)

            expC.fulfill()
        }

        wait(for: [expA2, expB2, expC], timeout: 1.0)
    }

    func testRemoveValue() throws {
        let valueCache = KeyValueCache<String, String>()

        let now = Date()

        valueCache.setValue("AAAAAA", forKey: "A", expireDate: now.addingTimeInterval(3))

        valueCache.setValue("BBBBBB", forKey: "B", expireDate: now.addingTimeInterval(6))

        valueCache.setValue("CCCCCC", forKey: "C")

        var expA = XCTestExpectation(description: "Read for 'A' key")
        var expB = XCTestExpectation(description: "Read for 'B' key")
        var expC = XCTestExpectation(description: "Read for 'C' key")

        valueCache.value(forKey: "A").whenSuccess { value in

            XCTAssertEqual("AAAAAA", value)
            expA.fulfill()
        }

        valueCache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        valueCache.value(forKey: "C").whenSuccess { value in

            XCTAssertEqual("CCCCCC", value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")
        expC = XCTestExpectation(description: "Read for 'C' key")

        valueCache.removeValue(forKey: "A")

        valueCache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA.fulfill()
        }

        valueCache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        valueCache.value(forKey: "C").whenSuccess { value in

            XCTAssertEqual("CCCCCC", value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")
        expC = XCTestExpectation(description: "Read for 'C' key")

        valueCache.removeValue(forKey: "C")

        valueCache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA.fulfill()
        }

        valueCache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        valueCache.value(forKey: "C").whenSuccess { value in

            XCTAssertNil(value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")
        expC = XCTestExpectation(description: "Read for 'C' key")

        valueCache.removeValue(forKey: "B")

        valueCache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA.fulfill()
        }

        valueCache.value(forKey: "B").whenSuccess { value in

            XCTAssertNil(value)
            expB.fulfill()
        }

        valueCache.value(forKey: "C").whenSuccess { value in

            XCTAssertNil(value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)
    }

    func testRemoveAll() throws {
        let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let valueCache = KeyValueCache<String, String>(eventLoopGroupProvider: .shared(eventGroup))

        let now = Date()

        valueCache.setValue("AAAAAA", forKey: "A", expireDate: now.addingTimeInterval(3))

        valueCache.setValue("BBBBBB", forKey: "B", expireDate: now.addingTimeInterval(6))

        valueCache.setValue("CCCCCC", forKey: "C")

        var expA = XCTestExpectation(description: "Read for 'A' key")
        var expB = XCTestExpectation(description: "Read for 'B' key")
        var expC = XCTestExpectation(description: "Read for 'C' key")

        valueCache.value(forKey: "A").whenSuccess { value in

            XCTAssertEqual("AAAAAA", value)
            expA.fulfill()
        }

        valueCache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        valueCache.value(forKey: "C").whenSuccess { value in

            XCTAssertEqual("CCCCCC", value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")
        expC = XCTestExpectation(description: "Read for 'C' key")

        valueCache.removeAllValues()

        valueCache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA.fulfill()
        }

        valueCache.value(forKey: "B").whenSuccess { value in

            XCTAssertNil(value)
            expB.fulfill()
        }

        valueCache.value(forKey: "C").whenSuccess { value in

            XCTAssertNil(value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        let shutdownExp = XCTestExpectation(description: "Shutdown shared event group")

        eventGroup.shutdownGracefully { error in
            XCTAssertNil(error)
            shutdownExp.fulfill()
        }

        wait(for: [shutdownExp], timeout: 1.0)
    }
}
