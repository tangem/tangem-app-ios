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
    func mapPositions(_ response: PolymarketDTO.PositionsResponse) throws -> PolymarketPositionsPage {
        PolymarketPositionsPage(
            positions: try response.positions.map(mapPosition),
            hasNext: response.hasNext ?? false
        )
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

    func resolutionStatus(from raw: String?) -> PolymarketResolutionStatus {
        guard let raw, let status = PolymarketResolutionStatus(rawValue: raw) else {
            return .unknown
        }

        return status
    }
}
