//
//  Created by Vitali Kurlovich on 7.06.22.
//

import Foundation
import NIO

internal
struct OneValueType<Value> {
    let value: Value

    let cost: Int
    let expireDate: Date?
}

public
final class OneValueCache<Value> {
    internal var _cache: OneValueType<Value>?
    internal var _totalCost: Int {
        _cache?.cost ?? 0
    }

    public var totalCostLimit: Int = 0 {
        didSet {
            precondition(totalCostLimit >= 0)

            eventLoop.execute {
                if self._totalCost > self.totalCostLimit {
                    self._cache = nil
                }
            }
        }
    }

    private let groupProvider: EventLoopGroupProvider
    private let eventLoop: EventLoop
    private let eventLoopGroup: EventLoopGroup

    public init(eventLoopGroupProvider: EventLoopGroupProvider = .createNew) {
        groupProvider = eventLoopGroupProvider

        switch groupProvider {
        case let .shared(eventLoopGroup):
            self.eventLoopGroup = eventLoopGroup
            eventLoop = eventLoopGroup.any()
        case .createNew:
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            eventLoop = eventLoopGroup.any()
        }
    }
}

public
extension OneValueCache {
    func setValue(_ value: Value,
                  expireDate: Date?,
                  cost: Int = 1)
    {
        precondition(cost >= 0)

        guard totalCostLimit >= cost || totalCostLimit == 0 else {
            return
        }

        if let expare = expireDate, expare <= Date() {
            return
        }

        eventLoop.execute {
            self._cache = .init(value: value, cost: cost, expireDate: expireDate)
        }
    }

    func value() -> EventLoopFuture<Value?> {
        let promise = eventLoop.makePromise(of: Value?.self)

        eventLoop.execute {
            guard let cachedValue = self._cache else {
                promise.succeed(nil)
                return
            }

            let now = Date()

            if let expireDate = cachedValue.expireDate, expireDate <= now {
                self._cache = nil

                promise.succeed(nil)

            } else {
                promise.succeed(cachedValue.value)
            }
        }

        return promise.futureResult
    }

    func removeValue() {
        eventLoop.execute {
            self._cache = nil
        }
    }

    func removeAllValues() {
        removeValue()
    }
}
