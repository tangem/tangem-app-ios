//
//  PolymarketActivityClaimGrouping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

enum PolymarketActivityClaimGrouping {
    static func group(_ records: [PolymarketActivityRecord]) -> [PolymarketActivityRecord] {
        var order: [GroupKey] = []
        var groups: [GroupKey: [PolymarketActivityRecord]] = [:]

        for record in records {
            let key = GroupKey(record: record)

            if groups[key] == nil {
                order.append(key)
            }

            groups[key, default: []].append(record)
        }

        return order.compactMap { key in groups[key].flatMap(merge) }
    }
}

// MARK: - Private implementation

private extension PolymarketActivityClaimGrouping {
    enum GroupKey: Hashable {
        case single(id: String)
        case claim(transactionHash: String, conditionId: String)

        init(record: PolymarketActivityRecord) {
            guard
                record.type == .redeem,
                let transactionHash = record.transactionHash?.lowercased(),
                !transactionHash.isEmpty,
                let conditionId = record.market?.conditionId.lowercased()
            else {
                self = .single(id: record.id)
                return
            }

            self = .claim(transactionHash: transactionHash, conditionId: conditionId)
        }
    }

    static func merge(_ records: [PolymarketActivityRecord]) -> PolymarketActivityRecord? {
        guard let first = records.first else { return nil }

        guard records.count > 1 else { return first }

        let paying = records.max { rank($0) < rank($1) } ?? first

        return PolymarketActivityRecord(
            id: first.id,
            type: first.type,
            occurredAt: first.occurredAt,
            amount: records.reduce(0) { $0 + $1.amount },
            transactionHash: first.transactionHash,
            market: paying.market,
            order: nil,
            redeemResult: result(of: records)
        )
    }

    static func result(of records: [PolymarketActivityRecord]) -> PolymarketRedeemResult? {
        let results = Set(records.compactMap(\.redeemResult))

        if results.contains(.won) { return .won }
        if results.contains(.split) { return .split }
        if results.contains(.lost) { return .lost }

        return nil
    }

    static func rank(_ record: PolymarketActivityRecord) -> (Int, Decimal) {
        let resultRank = switch record.redeemResult {
        case .won: 2
        case .split: 1
        case .lost, .none: 0
        }

        return (resultRank, record.amount)
    }
}
