//
//  PolymarketMapper+Positions.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension PolymarketMapper {
    func mapPositions(_ response: PolymarketDTO.PositionsResponse) -> PolymarketPositionsPage {
        PolymarketPositionsPage(
            positions: response.positions.compactMap { dto in
                do {
                    return try mapPosition(dto)
                } catch {
                    PolymarketLogger.error("Dropped a position that could not be read", error: error)
                    return nil
                }
            },
            receivedCount: response.positions.count,
            hasNext: response.hasNext ?? false
        )
    }

    func mapClosedPositions(_ response: PolymarketDTO.ClosedPositionsResponse) -> PolymarketClosedPositionsPage {
        PolymarketClosedPositionsPage(
            positions: response.positions.compactMap { dto in
                do {
                    return try mapClosedPosition(dto)
                } catch {
                    PolymarketLogger.error("Dropped a closed position that could not be read", error: error)
                    return nil
                }
            },
            receivedCount: response.positions.count,
            hasNext: response.hasNext ?? false
        )
    }

    func mapClosedPosition(_ dto: PolymarketDTO.ClosedPosition) throws -> PolymarketClosedPosition {
        try PolymarketClosedPosition(
            conditionId: dto.conditionId,
            assetId: dto.assetId,
            title: dto.title ?? "",
            slug: dto.slug,
            iconURL: url(from: dto.icon),
            closedAt: date(from: dto.closedAt),
            outcome: dto.outcome ?? "",
            outcomeIndex: dto.outcomeIndex,
            avgPrice: decimal(dto.avgPrice, field: "avgPrice"),
            curPrice: decimal(dto.curPrice, field: "curPrice"),
            totalBought: decimal(dto.totalBought, field: "totalBought"),
            realizedPnl: decimal(dto.realizedPnl, field: "realizedPnl"),
            status: closedStatus(from: dto.status)
        )
    }

    func mapPositionOutcome(_ response: PolymarketDTO.PositionOutcomeResponse) throws -> PolymarketPosition? {
        try response.position.map(mapPosition)
    }

    func mapPosition(_ dto: PolymarketDTO.Position) throws -> PolymarketPosition {
        try PolymarketPosition(
            conditionId: dto.conditionId,
            assetId: dto.assetId,
            marketId: dto.marketId,
            eventId: dto.eventId,
            eventTitle: dto.eventTitle,
            title: dto.title ?? "",
            iconURL: url(from: dto.icon),
            endDate: date(from: dto.endDate),
            outcome: dto.outcome ?? "",
            outcomeIndex: dto.outcomeIndex,
            size: decimal(dto.size, field: "size"),
            avgPrice: decimal(dto.avgPrice, field: "avgPrice"),
            curPrice: decimal(dto.curPrice, field: "curPrice"),
            initialValue: decimal(dto.initialValue, field: "initialValue"),
            currentValue: decimal(dto.currentValue, field: "currentValue"),
            cashPnl: decimal(dto.cashPnl, field: "cashPnl"),
            pnlRatio: decimal(dto.percentPnl, field: "percentPnl") / Constants.percentScale,
            realizedPnl: decimal(dto.realizedPnl, field: "realizedPnl"),
            isRedeemable: dto.redeemable ?? false,
            isNegRisk: dto.negRisk ?? false,
            isAcceptingOrders: dto.acceptingOrders ?? false,
            isLive: dto.live ?? false,
            resolutionStatus: resolutionStatus(from: dto.resolutionStatus),
            settlement: dto.status.flatMap(PolymarketPositionSettlement.init(rawValue:))
        )
    }
}

// MARK: - Private implementation

private extension PolymarketMapper {
    enum Constants {
        static let percentScale: Decimal = 100
    }

    func decimal(_ raw: String?, field: String) throws -> Decimal {
        guard let raw else { return 0 }

        guard let value = Decimal(stringValue: raw) else {
            throw PolymarketAPIError.decoding(field: field, value: raw)
        }

        return value
    }

    func closedStatus(from raw: String?) -> PolymarketClosedPositionStatus {
        guard let raw, let status = PolymarketClosedPositionStatus(rawValue: raw) else {
            return .unknown
        }

        return status
    }

    func resolutionStatus(from raw: String?) -> PolymarketResolutionStatus {
        guard let raw, let status = PolymarketResolutionStatus(rawValue: raw) else {
            return .unknown
        }

        return status
    }
}
