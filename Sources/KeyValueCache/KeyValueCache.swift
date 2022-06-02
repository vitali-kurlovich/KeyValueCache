import Foundation
import NIO

public
struct DefaultPriorityComparator: PriorityComparator {}

public enum EventLoopGroupProvider {
    /// `EventLoopGroup` will be provided by the user. Owner of this group is responsible for its lifecycle.
    case shared(EventLoopGroup)
    /// `EventLoopGroup` will be created by the client. When `syncShutdown` is called, created `EventLoopGroup` will be shut down as well.
    case createNew
}

public
final class KeyValueCache<Key: Hashable, Value> {
    private var cache: [Key: ValueType<Value>] = [:]
    private var _totalCost: Int = 0

    public var countLimit: Int = 0
    public var totalCostLimit: Int = 0

    private let priority: PriorityComparator
    private let groupProvider: EventLoopGroupProvider
    private let eventLoop: EventLoop
    private let eventLoopGroup: EventLoopGroup

    public init<Priority: PriorityComparator>(eventLoopGroupProvider: EventLoopGroupProvider = .createNew,
                                              priority priorityComparator: Priority)
    {
        priority = priorityComparator
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

    public convenience init(eventLoopGroupProvider: EventLoopGroupProvider = .createNew) {
        self.init(eventLoopGroupProvider: eventLoopGroupProvider, priority: DefaultPriorityComparator())
    }

    deinit {
        switch groupProvider {
        case .shared:
            break
        case .createNew:
            let queue: DispatchQueue = .global()
            self.eventLoopGroup.shutdownGracefully(queue: queue) { _ in
            }
        }
    }
}

public
extension KeyValueCache {
    func setValue(_ value: Value,
                  forKey key: Key,
                  cost: Int = 1)
    {
        setValue(value, forKey: key, expireDate: nil, cost: cost)
    }

    func setValue(_ value: Value,
                  forKey key: Key,
                  expireDate: Date?,
                  cost: Int = 1)
    {
        precondition(cost >= 0)

        if let expare = expireDate, expare <= Date() {
            return
        }

        eventLoop.execute {
            let info = KeyValueCacheInfo(cost: cost,
                                         expireDate: expireDate)

            self.releaseIfNeeds(for: info)

            self.cache[key] = .init(value: value, info: info)

            self._totalCost += info.cost
        }
    }

    func value(forKey key: Key) -> EventLoopFuture<Value?> {
        let promise = eventLoop.makePromise(of: Value?.self)

        eventLoop.execute {
            guard let cachedValue = self.cache[key] else {
                promise.succeed(nil)
                return
            }

            let now = Date()

            if let expireDate = cachedValue.expireDate, expireDate <= now {
                self.cache.removeValue(forKey: key)
                self._totalCost -= cachedValue.cost

                promise.succeed(nil)

            } else {
                self.cache[key] = cachedValue.retainReads(now)

                promise.succeed(cachedValue.value)
            }
        }

        return promise.futureResult
    }

    func removeValue(forKey key: Key) {
        eventLoop.execute {
            guard let cachedValue = self.cache[key] else {
                return
            }

            self.cache.removeValue(forKey: key)
            self._totalCost -= cachedValue.cost
        }
    }

    func removeAllValues() {
        eventLoop.execute {
            self.cache.removeAll()
            self._totalCost = 0
        }
    }
}

internal
extension KeyValueCache {
    func releaseIfNeeds(for info: KeyValueCacheInfo) {
        removeAllExpired()

        if countLimit > 0, countLimit >= cache.count {
            release(count: cache.count + 1 - countLimit)
        }

        if totalCostLimit > 0, totalCostLimit < _totalCost + info.cost {
            release(cost: _totalCost + info.cost - totalCostLimit)
        }
    }

    func release(count: Int) {
        precondition(count > 0)

        var count = count

        while count > 0 {
            count -= 1
        }
    }

    func release(cost: Int) {
        precondition(cost > 0)

        var cost = cost

        while cost > 0 {
            cost -= 1
        }
    }

    func removeAllExpired() {
        let now = Date()

        let oldCount = cache.count

        cache = cache.filter { (_, value: ValueType<Value>) in
            guard let expireDate = value.expireDate else {
                return false
            }

            return expireDate >= now
        }

        guard oldCount != cache.count else {
            return
        }

        _totalCost = 0

        for (_, value) in cache {
            _totalCost += value.cost
        }
    }
}
