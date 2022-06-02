//
//  Created by Vitali Kurlovich on 2.06.22.
//

import Foundation

public protocol PriorityComparator {
    func comparePriority(first: KeyValueCacheInfo, next: KeyValueCacheInfo) -> ComparisonResult
}

public
extension PriorityComparator {
    func comparePriority(first: KeyValueCacheInfo, next: KeyValueCacheInfo) -> ComparisonResult {
        if first.cost < next.cost {
            return .orderedAscending
        } else if first.cost > next.cost {
            return .orderedDescending
        }

        if first.readsCount < next.readsCount {
            return .orderedAscending
        } else if first.readsCount > next.readsCount {
            return .orderedDescending
        }

        return .orderedSame
    }
}
