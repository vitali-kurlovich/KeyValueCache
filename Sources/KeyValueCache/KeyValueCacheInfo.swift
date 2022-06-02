//
//  Created by Vitali Kurlovich on 1.06.22.
//

import Foundation

public
struct KeyValueCacheInfo {
    public let readsCount: Int
    public let cost: Int

    public let lastReadDate: Date?
    public let expireDate: Date?

    public
    init(cost: Int,
         expireDate: Date? = nil,
         lastReadDate: Date? = nil,
         readsCount: Int = 0)
    {
        precondition(readsCount >= 0)
        precondition(cost >= 0)

        self.lastReadDate = lastReadDate
        self.readsCount = readsCount
        self.expireDate = expireDate
        self.cost = cost
    }

    func set(lastReadDate: Date, readsCount: Int) -> Self {
        precondition(self.readsCount <= readsCount)
        precondition(self.lastReadDate == nil || self.lastReadDate! < lastReadDate)

        return .init(cost: cost, expireDate: expireDate, lastReadDate: lastReadDate, readsCount: readsCount)
    }

    func set(lastReadDate: Date) -> Self {
        return set(lastReadDate: lastReadDate, readsCount: readsCount)
    }

    func set(readsCount: Int) -> Self {
        return .init(cost: cost, expireDate: expireDate, lastReadDate: lastReadDate, readsCount: readsCount)
    }
}
