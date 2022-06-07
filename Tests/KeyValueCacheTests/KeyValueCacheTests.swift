@testable import KeyValueCache
import NIO
import XCTest

final class KeyValueCacheTests: XCTestCase {
    func testExpire() throws {
        let cache = KeyValueCache<String, String>()

        let now = Date()

        cache.setValue("AAAAAA", forKey: "A", expireDate: now.addingTimeInterval(3))

        cache.setValue("BBBBBB", forKey: "B", expireDate: now.addingTimeInterval(6))

        cache.setValue("CCCCCC", forKey: "C")

        let expA = XCTestExpectation(description: "Read for 'A' key")

        cache.value(forKey: "A").whenSuccess { value in
            XCTAssertEqual("AAAAAA", value)

            expA.fulfill()
        }

        let expB = XCTestExpectation(description: "Read for 'B' key")
        cache.value(forKey: "B").whenSuccess { value in
            XCTAssertEqual("BBBBBB", value)

            expB.fulfill()
        }

        wait(for: [expA, expB], timeout: 1.0)

        Thread.sleep(forTimeInterval: 4)

        let expA1 = XCTestExpectation(description: "Read for 'A' key after deadline")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA1.fulfill()
        }

        let expB1 = XCTestExpectation(description: "Read for 'B' key")
        cache.value(forKey: "B").whenSuccess { value in
            XCTAssertEqual("BBBBBB", value)

            expB1.fulfill()
        }

        wait(for: [expA1, expB1], timeout: 1.0)

        Thread.sleep(forTimeInterval: 3)

        let expA2 = XCTestExpectation(description: "Read for 'A' key after deadline")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA2.fulfill()
        }

        let expB2 = XCTestExpectation(description: "Read for 'B' key after deadline")
        cache.value(forKey: "B").whenSuccess { value in
            XCTAssertNil(value)

            expB2.fulfill()
        }

        let expC = XCTestExpectation(description: "Read for 'C'")

        cache.value(forKey: "C").whenSuccess { value in
            XCTAssertEqual("CCCCCC", value)

            expC.fulfill()
        }

        wait(for: [expA2, expB2, expC], timeout: 1.0)
    }

    func testRemoveValue() throws {
        let cache = KeyValueCache<String, String>()

        let now = Date()

        cache.setValue("AAAAAA", forKey: "A", expireDate: now.addingTimeInterval(3))

        cache.setValue("BBBBBB", forKey: "B", expireDate: now.addingTimeInterval(6))

        cache.setValue("CCCCCC", forKey: "C")

        var expA = XCTestExpectation(description: "Read for 'A' key")
        var expB = XCTestExpectation(description: "Read for 'B' key")
        var expC = XCTestExpectation(description: "Read for 'C' key")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertEqual("AAAAAA", value)
            expA.fulfill()
        }

        cache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        cache.value(forKey: "C").whenSuccess { value in

            XCTAssertEqual("CCCCCC", value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")
        expC = XCTestExpectation(description: "Read for 'C' key")

        cache.removeValue(forKey: "A")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA.fulfill()
        }

        cache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        cache.value(forKey: "C").whenSuccess { value in

            XCTAssertEqual("CCCCCC", value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")
        expC = XCTestExpectation(description: "Read for 'C' key")

        cache.removeValue(forKey: "C")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA.fulfill()
        }

        cache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        cache.value(forKey: "C").whenSuccess { value in

            XCTAssertNil(value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")
        expC = XCTestExpectation(description: "Read for 'C' key")

        cache.removeValue(forKey: "B")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA.fulfill()
        }

        cache.value(forKey: "B").whenSuccess { value in

            XCTAssertNil(value)
            expB.fulfill()
        }

        cache.value(forKey: "C").whenSuccess { value in

            XCTAssertNil(value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)
    }

    func testRemoveAll() throws {
        let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let cache = KeyValueCache<String, String>(eventLoopGroupProvider: .shared(eventGroup))

        let now = Date()

        cache.setValue("AAAAAA", forKey: "A", expireDate: now.addingTimeInterval(3))

        cache.setValue("BBBBBB", forKey: "B", expireDate: now.addingTimeInterval(6))

        cache.setValue("CCCCCC", forKey: "C")

        var expA = XCTestExpectation(description: "Read for 'A' key")
        var expB = XCTestExpectation(description: "Read for 'B' key")
        var expC = XCTestExpectation(description: "Read for 'C' key")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertEqual("AAAAAA", value)
            expA.fulfill()
        }

        cache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        cache.value(forKey: "C").whenSuccess { value in

            XCTAssertEqual("CCCCCC", value)
            expC.fulfill()
        }

        wait(for: [expA, expB, expC], timeout: 1.0)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")
        expC = XCTestExpectation(description: "Read for 'C' key")

        cache.removeAllValues()

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertNil(value)
            expA.fulfill()
        }

        cache.value(forKey: "B").whenSuccess { value in

            XCTAssertNil(value)
            expB.fulfill()
        }

        cache.value(forKey: "C").whenSuccess { value in

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

    func testCountLimit() throws {
        let cache = KeyValueCache<String, String>()

        cache.countLimit = 2

        let now = Date()

        cache.setValue("AAAAAA", forKey: "A", expireDate: now.addingTimeInterval(10))

        cache.setValue("BBBBBB", forKey: "B", expireDate: now.addingTimeInterval(10))

        cache.setValue("CCCCCC", forKey: "C")

        Thread.sleep(forTimeInterval: 1)

        XCTAssertEqual(cache._cache.count, 2)

        cache.countLimit = 1

        Thread.sleep(forTimeInterval: 1)

        XCTAssertEqual(cache._cache.count, 1)

        cache.setValue("DDDDDD", forKey: "D")

        Thread.sleep(forTimeInterval: 1)

        XCTAssertEqual(cache._cache.count, 1)

        cache.countLimit = 0

        cache.setValue("EEEEEE", forKey: "E")
        cache.setValue("FFFFFF", forKey: "F")

        Thread.sleep(forTimeInterval: 1)

        XCTAssertEqual(cache._cache.count, 3)
    }

    func testCostLimit() throws {
        let cache = KeyValueCache<String, String>()

        cache.totalCostLimit = 100

        cache.setValue("AAAAAA", forKey: "A", cost: 20)
        cache.setValue("BBBBBB", forKey: "B", cost: 50)
        cache.setValue("CCCCCC", forKey: "C", cost: 50)

        Thread.sleep(forTimeInterval: 1)

        XCTAssertEqual(cache._totalCost, cache.totalCost)
        XCTAssertLessThanOrEqual(cache.totalCost, 100)

        cache.totalCostLimit = 50
        Thread.sleep(forTimeInterval: 1)

        XCTAssertEqual(cache._totalCost, cache.totalCost)
        XCTAssertLessThanOrEqual(cache.totalCost, 50)

        cache.setValue("DDDDD", forKey: "D", cost: 60)
        Thread.sleep(forTimeInterval: 1)

        XCTAssertEqual(cache._totalCost, cache.totalCost)
        XCTAssertLessThanOrEqual(cache.totalCost, 50)
    }

    func testReplace() throws {
        let cache = KeyValueCache<String, String>()

        cache.setValue("AAAAAA", forKey: "A", cost: 20)
        cache.setValue("BBBBBB", forKey: "B", cost: 50)

        var expA = XCTestExpectation(description: "Read for 'A' key")
        var expB = XCTestExpectation(description: "Read for 'B' key")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertEqual("AAAAAA", value)
            expA.fulfill()
        }

        cache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        wait(for: [expA, expB], timeout: 1.0)

        XCTAssertEqual(cache._totalCost, cache.totalCost)

        cache.setValue("AAAAAAA", forKey: "A", cost: 200)

        expA = XCTestExpectation(description: "Read for 'A' key")
        expB = XCTestExpectation(description: "Read for 'B' key")

        cache.value(forKey: "A").whenSuccess { value in

            XCTAssertEqual("AAAAAAA", value)
            expA.fulfill()
        }

        cache.value(forKey: "B").whenSuccess { value in

            XCTAssertEqual("BBBBBB", value)
            expB.fulfill()
        }

        wait(for: [expA, expB], timeout: 1.0)

        XCTAssertEqual(cache._totalCost, cache.totalCost)
    }
}

extension KeyValueCache {
    var totalCost: Int {
        _cache.values.reduce(0) { cost, value in
            cost + value.cost
        }
    }
}
