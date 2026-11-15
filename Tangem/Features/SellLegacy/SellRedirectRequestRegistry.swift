//
//  SellRedirectRequestRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class SellRedirectRequestRegistry {
    struct Key: Hashable {
        let userWalletId: UserWalletId
        let currencyCode: String
        let networkCode: String
        let contractAddress: String?
    }

    private struct Entry {
        let requestId: String
        let createdAt: Date
    }

    private let lifetime: TimeInterval
    private let dateProvider: DateProvider
    private let entries = OSAllocatedUnfairLock(initialState: [Key: Entry]())

    init(lifetime: TimeInterval = 60 * 60, dateProvider: DateProvider = SystemDateProvider()) {
        self.lifetime = lifetime
        self.dateProvider = dateProvider
    }

    func requestId(for key: Key) -> String {
        let date = dateProvider.now

        return entries.withLock { entries in
            entries = entries.filter { !isExpired($0.value, at: date) }

            if let entry = entries[key], date.timeIntervalSince(entry.createdAt) < lifetime / 2 {
                return entry.requestId
            }

            let requestId = UUID().uuidString
            entries[key] = Entry(requestId: requestId, createdAt: date)
            return requestId
        }
    }

    func isValid(requestId: String, for key: Key) -> Bool {
        let date = dateProvider.now

        return entries.withLock { entries in
            guard let entry = entries[key], !isExpired(entry, at: date) else {
                return false
            }

            return entry.requestId == requestId
        }
    }

    private func isExpired(_ entry: Entry, at date: Date) -> Bool {
        date.timeIntervalSince(entry.createdAt) >= lifetime
    }
}
