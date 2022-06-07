//
//  Created by Vitali Kurlovich on 1.06.22.
//

import Foundation

internal
struct ValueType<Value> {
    let value: Value

    let info: KeyValueCacheInfo
}

extension ValueType {
    var cost: Int {
        info.cost
    }

    var expireDate: Date? {
        info.expireDate
    }

    var readsCount: Int {
        info.readsCount
    }

    var lastReadDate: Date? {
        info.lastReadDate
    }
}

extension ValueType {
    init(value: Value, expireDate: Date?, cost: Int) {
        self.init(value: value, info: .init(cost: cost, expireDate: expireDate))
    }
}

extension ValueType {
    func set(_ newinfo: KeyValueCacheInfo) -> Self {
        precondition(cost == newinfo.cost)

        precondition(readsCount <= newinfo.readsCount)

        precondition(lastReadDate == nil || newinfo.lastReadDate == nil || lastReadDate! <= newinfo.lastReadDate!)

        return .init(value: value, info: newinfo)
    }
}

extension ValueType {
    func retainReads(_ time: Date) -> Self {
        set(KeyValueCacheInfo(cost: cost, expireDate: expireDate, lastReadDate: time, readsCount: readsCount + 1))
    }
}
