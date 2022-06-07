//
//  OneValueCacheTests.swift
//
//
//  Created by Vitali Kurlovich on 8.06.22.
//

@testable import KeyValueCache
import NIO
import XCTest

class OneValueCacheTests: XCTestCase {
    func testExpire() throws {
        let cache = OneValueCache<String>()

        let now = Date()

        cache.setValue("AAAAAA", expireDate: now.addingTimeInterval(3))

        let expA = XCTestExpectation(description: "Read for 'A' key")

        cache.value().whenSuccess { value in
            XCTAssertEqual("AAAAAA", value)

            expA.fulfill()
        }

        wait(for: [expA], timeout: 1.0)

        Thread.sleep(forTimeInterval: 4)

        let expA1 = XCTestExpectation(description: "Read for 'A' key after deadline")

        cache.value().whenSuccess { value in

            XCTAssertNil(value)
            expA1.fulfill()
        }

        wait(for: [expA1], timeout: 1.0)
    }
}
