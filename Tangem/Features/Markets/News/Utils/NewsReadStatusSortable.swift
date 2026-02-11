//
//  NewsReadStatusSortable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol NewsReadStatusSortable {
    var isRead: Bool { get }
}

extension Array where Element: NewsReadStatusSortable {
    func sortedByReadStatus() -> [Element] {
        enumerated()
            .sorted { lhs, rhs in
                if lhs.element.isRead != rhs.element.isRead {
                    return !lhs.element.isRead
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
