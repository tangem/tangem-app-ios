//
//  TotalTokenBalanceFoldTable.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// One row of the total-balance fold spec: an (available, staking) state pair and the fold both the legacy
/// and the composite provider have to produce for it.
struct FoldRow: CustomTestStringConvertible {
    let available: TokenBalanceType
    let staking: TokenBalanceType
    let expected: ExpectedBalance

    var testDescription: String {
        "available=\(available), staking=\(staking)"
    }
}

enum ExpectedBalance {
    case exact(TokenBalanceType)
    /// For the arm that fabricates `date: .now`: assert the case and balance, ignore the date.
    case loadingWithBalanceAnyDate(Decimal)

    func verify(against actual: TokenBalanceType) {
        switch self {
        case .exact(let expected):
            #expect(actual == expected)
        case .loadingWithBalanceAnyDate(let balance):
            guard case .loading(.some(let cached)) = actual else {
                Issue.record("Expected .loading with cache, got \(actual)")
                return
            }
            #expect(cached.balance == balance)
        }
    }
}

/// The full state-pair table for the total-balance fold, shared by the characterization suite (legacy
/// provider) and the spec suite (composite provider), which have to agree on every row.
///
/// Values are chosen distinct so sums identify their sources: available loaded = 10, available cache = 7,
/// staking loaded = 3, staking cache = 5. Staking caches come in an older and a newer flavour so the rows
/// pin that the staking cache date never displaces the available one, whichever way they are ordered.
enum TotalTokenBalanceFoldTable {
    static let olderDate = Date(timeIntervalSince1970: 1_000)
    static let availableCacheDate = Date(timeIntervalSince1970: 2_000)
    static let newerDate = Date(timeIntervalSince1970: 3_000)

    static let availableCache = TokenBalanceType.Cached(balance: 7, date: availableCacheDate)
    static let stakingOlderCache = TokenBalanceType.Cached(balance: 5, date: olderDate)
    static let stakingNewerCache = TokenBalanceType.Cached(balance: 5, date: newerDate)

    static let rows: [FoldRow] = [
        // Available .empty absorbs; staking is never inspected
        FoldRow(available: .empty(.noData), staking: .empty(.noData), expected: .exact(.empty(.noData))),
        FoldRow(available: .empty(.noData), staking: .loading(nil), expected: .exact(.empty(.noData))),
        FoldRow(available: .empty(.noData), staking: .loading(stakingOlderCache), expected: .exact(.empty(.noData))),
        FoldRow(available: .empty(.noData), staking: .failure(nil), expected: .exact(.empty(.noData))),
        FoldRow(available: .empty(.noData), staking: .failure(stakingOlderCache), expected: .exact(.empty(.noData))),
        FoldRow(available: .empty(.noData), staking: .loaded(3), expected: .exact(.empty(.noData))),

        // The absorbing arm propagates the reason, not just the case
        FoldRow(available: .empty(.noDerivation), staking: .loaded(3), expected: .exact(.empty(.noDerivation))),
        FoldRow(available: .empty(.custom), staking: .loading(stakingOlderCache), expected: .exact(.empty(.custom))),
        FoldRow(available: .empty(.noAccount(message: "No account")), staking: .failure(nil), expected: .exact(.empty(.noAccount(message: "No account")))),

        // Available loading without cache: no payload is ever shown, whatever staking has
        FoldRow(available: .loading(nil), staking: .empty(.noData), expected: .exact(.loading(nil))),
        FoldRow(available: .loading(nil), staking: .loading(nil), expected: .exact(.loading(nil))),
        FoldRow(available: .loading(nil), staking: .loading(stakingOlderCache), expected: .exact(.loading(nil))),
        FoldRow(available: .loading(nil), staking: .failure(nil), expected: .exact(.loading(nil))),
        FoldRow(available: .loading(nil), staking: .failure(stakingOlderCache), expected: .exact(.loading(nil))),
        FoldRow(available: .loading(nil), staking: .loaded(3), expected: .exact(.loading(nil))),

        // Available loading with cache
        FoldRow(available: .loading(availableCache), staking: .empty(.noData), expected: .exact(.loading(availableCache))),
        FoldRow(available: .loading(availableCache), staking: .loading(nil), expected: .exact(.loading(availableCache))),
        FoldRow(available: .loading(availableCache), staking: .loading(stakingOlderCache), expected: .exact(.loading(.init(balance: 12, date: availableCacheDate)))),
        FoldRow(available: .loading(availableCache), staking: .failure(nil), expected: .exact(.loading(availableCache))),
        // Staking failure cache is ignored while available is healthy
        FoldRow(available: .loading(availableCache), staking: .failure(stakingOlderCache), expected: .exact(.loading(availableCache))),
        FoldRow(available: .loading(availableCache), staking: .loaded(3), expected: .exact(.loading(.init(balance: 10, date: availableCacheDate)))),

        // Available failure without cache
        FoldRow(available: .failure(nil), staking: .empty(.noData), expected: .exact(.failure(nil))),
        // Switch-order quirk: the cacheless-loading arm matches before the failure catch-all
        FoldRow(available: .failure(nil), staking: .loading(nil), expected: .exact(.loading(nil))),
        // ...but a cached-loading staking does NOT flip the state (no arm covers it)
        FoldRow(available: .failure(nil), staking: .loading(stakingOlderCache), expected: .exact(.failure(nil))),
        FoldRow(available: .failure(nil), staking: .failure(nil), expected: .exact(.failure(nil))),
        FoldRow(available: .failure(nil), staking: .failure(stakingOlderCache), expected: .exact(.failure(nil))),
        FoldRow(available: .failure(nil), staking: .loaded(3), expected: .exact(.failure(nil))),

        // Available failure with cache
        FoldRow(available: .failure(availableCache), staking: .empty(.noData), expected: .exact(.failure(availableCache))),
        FoldRow(available: .failure(availableCache), staking: .loading(nil), expected: .exact(.loading(availableCache))),
        FoldRow(available: .failure(availableCache), staking: .loading(stakingOlderCache), expected: .exact(.loading(.init(balance: 12, date: availableCacheDate)))),
        FoldRow(available: .failure(availableCache), staking: .failure(nil), expected: .exact(.failure(availableCache))),
        // The only pair where the staking failure cache is used: available failed too
        FoldRow(available: .failure(availableCache), staking: .failure(stakingOlderCache), expected: .exact(.failure(.init(balance: 12, date: availableCacheDate)))),
        FoldRow(available: .failure(availableCache), staking: .loaded(3), expected: .exact(.failure(.init(balance: 10, date: availableCacheDate)))),

        // Available loaded
        FoldRow(available: .loaded(10), staking: .empty(.noData), expected: .exact(.loaded(10))),
        // The only arm that fabricates a date (`.now`)
        FoldRow(available: .loaded(10), staking: .loading(nil), expected: .loadingWithBalanceAnyDate(10)),
        // The only arm that takes the staking date
        FoldRow(available: .loaded(10), staking: .loading(stakingOlderCache), expected: .exact(.loading(.init(balance: 15, date: olderDate)))),
        FoldRow(available: .loaded(10), staking: .failure(nil), expected: .exact(.loaded(10))),
        FoldRow(available: .loaded(10), staking: .failure(stakingOlderCache), expected: .exact(.loaded(10))),
        FoldRow(available: .loaded(10), staking: .loaded(3), expected: .exact(.loaded(13))),

        // The available cache dates the total whether the staking cache is older or newer
        FoldRow(available: .loading(availableCache), staking: .loading(stakingNewerCache), expected: .exact(.loading(.init(balance: 12, date: availableCacheDate)))),
        FoldRow(available: .failure(availableCache), staking: .loading(stakingNewerCache), expected: .exact(.loading(.init(balance: 12, date: availableCacheDate)))),
        FoldRow(available: .failure(availableCache), staking: .failure(stakingNewerCache), expected: .exact(.failure(.init(balance: 12, date: availableCacheDate)))),
    ]

    /// Cardano combines by replacement: a nonzero staked balance REPLACES the total, zero staked means
    /// staking is disabled and the available balance is used.
    static let cardanoRows: [FoldRow] = [
        FoldRow(available: .loaded(10), staking: .loaded(0), expected: .exact(.loaded(10))),
        FoldRow(available: .loaded(10), staking: .loaded(3), expected: .exact(.loaded(3))),
        FoldRow(available: .loading(availableCache), staking: .loaded(3), expected: .exact(.loading(.init(balance: 3, date: availableCacheDate)))),
        FoldRow(available: .loaded(10), staking: .loading(.init(balance: 0, date: olderDate)), expected: .exact(.loading(.init(balance: 10, date: olderDate)))),
        FoldRow(available: .loading(availableCache), staking: .loading(stakingOlderCache), expected: .exact(.loading(.init(balance: 5, date: availableCacheDate)))),
        // The staking failure cache substitutes for the base only here, instead of adding to it
        FoldRow(available: .failure(availableCache), staking: .failure(stakingOlderCache), expected: .exact(.failure(.init(balance: 5, date: availableCacheDate)))),
        // No base value, so the replacement never runs
        FoldRow(available: .failure(nil), staking: .loading(nil), expected: .exact(.loading(nil))),
    ]

    /// Rows whose expectation is exact, so the two providers' formatted output has to match too.
    /// Excludes the fabricated-date row: each provider stamps its own `.now`.
    static var exactExpectationRows: [FoldRow] {
        rows.filter { row in
            guard case .exact = row.expected else {
                return false
            }

            return true
        }
    }
}
