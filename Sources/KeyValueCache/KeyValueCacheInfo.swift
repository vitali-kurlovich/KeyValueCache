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
}
