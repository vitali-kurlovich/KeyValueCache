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
    internal var _cache: [Key: ValueType<Value>] = [:]
    internal var _totalCost: Int = 0

    public var countLimit: Int = 0 {
        didSet {
            releaseIfNeeds(byCount: 0)
        }
    }

    public var totalCostLimit: Int = 0 {
        didSet {
            releaseIfNeeds(byCost: 0)
        }
    }

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

            self._cache[key] = .init(value: value, info: info)

            self._totalCost += info.cost
        }
    }

    func value(forKey key: Key) -> EventLoopFuture<Value?> {
        let promise = eventLoop.makePromise(of: Value?.self)

        eventLoop.execute {
            guard let cachedValue = self._cache[key] else {
                promise.succeed(nil)
                return
            }

            let now = Date()

            if let expireDate = cachedValue.expireDate, expireDate <= now {
                self._cache.removeValue(forKey: key)
                self._totalCost -= cachedValue.cost

                promise.succeed(nil)

            } else {
                self._cache[key] = cachedValue.retainReads(now)

                promise.succeed(cachedValue.value)
            }
        }

        return promise.futureResult
    }

    func removeValue(forKey key: Key) {
        eventLoop.execute {
            guard let cachedValue = self._cache[key] else {
                return
            }

            self._cache.removeValue(forKey: key)
            self._totalCost -= cachedValue.cost
        }
    }

    func removeAllValues() {
        eventLoop.execute {
            self._cache.removeAll()
            self._totalCost = 0
        }
    }
}

internal
extension KeyValueCache {
    func releaseIfNeeds() {
        removeAllExpired()

        releaseIfNeeds(byCost: 0)
        releaseIfNeeds(byCount: 0)
    }

    func releaseIfNeeds(for info: KeyValueCacheInfo) {
        removeAllExpired()

        releaseIfNeeds(byCost: info.cost)
        releaseIfNeeds(byCount: 1)
    }

    func releaseIfNeeds(byCost addedCost: Int) {
        precondition(addedCost >= 0)

        if totalCostLimit > 0, totalCostLimit < _totalCost + addedCost {
            release(cost: _totalCost + addedCost - totalCostLimit)
        }
    }

    func releaseIfNeeds(byCount addedCount: Int) {
        precondition(addedCount >= 0)

        if countLimit > 0, countLimit < _cache.count + addedCount {
            release(count: _cache.count + addedCount - countLimit)
        }
    }

    func removeAllExpired() {
        let now = Date()

        let containsExpired = _cache.contains(where: { (_, value: ValueType<Value>) in
            guard let expireDate = value.expireDate else {
                return false
            }

            return expireDate >= now
        })

        guard containsExpired else {
            return
        }

        _cache = _cache.filter { (_, value: ValueType<Value>) in
            guard let expireDate = value.expireDate else {
                return false
            }

            return expireDate >= now
        }

        _totalCost = 0

        for (_, value) in _cache {
            _totalCost += value.cost
        }
    }
}

private
extension KeyValueCache {
    func release(count: Int) {
        precondition(count > 0)

        var count = count

        while count > 0 {
            var iterator = _cache.makeIterator()

            guard var lowestPriority = iterator.next() else {
                return
            }

            while let next = iterator.next() {
                let result = priority.comparePriority(first: lowestPriority.value.info, next: next.value.info)

                if result == .orderedDescending {
                    lowestPriority = next
                }
            }

            let key = lowestPriority.key
            let value = lowestPriority.value
            _cache.removeValue(forKey: key)

            _totalCost -= value.cost

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
}
