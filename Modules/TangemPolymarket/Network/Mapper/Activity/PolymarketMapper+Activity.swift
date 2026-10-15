//
//  PolymarketMapper+Activity.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension PolymarketMapper {
    func mapActivity(_ response: PolymarketDTO.ActivityResponse) -> PolymarketActivityPage {
        PolymarketActivityPage(
            records: response.items.compactMap { dto in
                do {
                    return try mapActivityRecord(dto)
                } catch {
                    PolymarketLogger.error("Dropped an activity row that could not be read", error: error)
                    return nil
                }
            },
            receivedCount: response.items.count,
            nextCursor: response.nextCursor.flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    func mapDepositsScan(_ response: PolymarketDTO.DepositsReconcileResponse) -> PolymarketDepositsScan {
        PolymarketDepositsScan(
            state: response.state.flatMap(PolymarketDepositsScan.State.init(rawValue:)) ?? .unknown,
            retryAfter: TimeInterval(response.retryAfterSeconds ?? ActivityConstants.defaultRetryAfter)
        )
    }
}

// MARK: - A single row

private extension PolymarketMapper {
    func mapActivityRecord(_ dto: PolymarketDTO.ActivityItem) throws -> PolymarketActivityRecord {
        guard let type = PolymarketActivityType(rawValue: dto.type) else {
            throw PolymarketAPIError.decoding(field: "type", value: dto.type)
        }

        guard let occurredAt = date(from: dto.occurredAt) else {
            throw PolymarketAPIError.decoding(field: "occurredAt", value: dto.occurredAt ?? "")
        }

        return try PolymarketActivityRecord(
            id: dto.id,
            type: type,
            occurredAt: occurredAt,
            amount: decimal(dto.amount, field: "amount"),
            transactionHash: dto.transactionHash,
            market: dto.market.map(mapActivityMarket),
            order: dto.order.map(mapActivityOrder),
            redeemResult: dto.redeem?.result.flatMap(PolymarketRedeemResult.init(rawValue:))
        )
    }

    func mapActivityMarket(_ dto: PolymarketDTO.ActivityMarket) throws -> PolymarketActivityMarket {
        try PolymarketActivityMarket(
            conditionId: dto.conditionId,
            outcomeIndex: dto.outcomeIndex ?? 0,
            shares: decimal(dto.shares, field: "shares"),
            outcome: dto.outcome,
            marketId: dto.marketId,
            slug: dto.slug,
            title: dto.title,
            iconURL: url(from: dto.icon),
            imageURL: url(from: dto.image),
            endDate: date(from: dto.endDate),
            isNegRisk: dto.negRisk ?? false,
            event: dto.event.map(mapActivityEvent)
        )
    }

    func mapActivityEvent(_ dto: PolymarketDTO.ActivityEvent) -> PolymarketActivityEvent {
        PolymarketActivityEvent(
            eventId: dto.eventId,
            slug: dto.slug,
            title: dto.title ?? "",
            iconURL: url(from: dto.icon),
            imageURL: url(from: dto.image),
            endDate: date(from: dto.endDate)
        )
    }

    func mapActivityOrder(_ dto: PolymarketDTO.ActivityOrder) throws -> PolymarketActivityOrder {
        try PolymarketActivityOrder(
            assetId: dto.assetId ?? "",
            averagePrice: decimal(dto.averagePrice, field: "averagePrice"),
            platformFee: decimal(dto.platformFee, field: "platformFee"),
            builderFee: decimal(dto.builderFee, field: "builderFee"),
            notional: decimal(dto.notional, field: "notional"),
            tradeCount: dto.tradeCount ?? ActivityConstants.defaultTradeCount
        )
    }

    enum ActivityConstants {
        static let defaultRetryAfter = 30
        static let defaultTradeCount = 1
    }
}
