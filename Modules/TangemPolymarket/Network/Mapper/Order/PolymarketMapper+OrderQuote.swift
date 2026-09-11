//
//  PolymarketMapper+OrderQuote.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension PolymarketMapper {
    func mapOrderQuoteRequest(_ request: PolymarketOrderQuoteRequest) -> PolymarketDTO.OrderQuoteRequestBody {
        PolymarketDTO.OrderQuoteRequestBody(
            marketId: request.marketId,
            assetId: request.assetId,
            side: request.side.rawValue,
            amount: request.amount.stringValue,
            slippage: request.slippagePercent.stringValue
        )
    }

    func mapOrderQuote(_ response: PolymarketDTO.OrderQuoteResponse) throws -> PolymarketOrderQuote {
        guard let side = PolymarketOrderSide(rawValue: response.side) else {
            throw PolymarketAPIError.decoding(field: "side", value: response.side)
        }

        guard PolymarketBuilderCode.isWellFormed(response.builderCode) else {
            throw PolymarketAPIError.decoding(field: PolymarketBuilderCode.field, value: response.builderCode)
        }

        return try PolymarketOrderQuote(
            status: quoteStatus(from: response.status),
            side: side,
            shares: decimal(response.shares, field: "shares"),
            notional: decimal(response.notional, field: "notional"),
            expectedExecutionAmount: decimal(response.expectedExecutionAmount, field: "expectedExecutionAmount"),
            averagePrice: decimal(response.averagePrice, field: "averagePrice"),
            worstCasePrice: decimal(response.worstCasePrice, field: "worstCasePrice"),
            fees: PolymarketOrderFees(
                market: decimal(response.fees.market, field: "fees.market"),
                builder: decimal(response.fees.builder, field: "fees.builder"),
                total: decimal(response.fees.total, field: "fees.total")
            ),
            total: decimal(response.total, field: "total"),
            builderCode: response.builderCode,
            minOrderSize: decimal(response.minOrderSize, field: "minOrderSize"),
            minOrderAmount: response.minOrderAmount.map { try decimal($0, field: "minOrderAmount") },
            tickSize: decimal(response.tickSize, field: "tickSize"),
            isLive: response.live
        )
    }
}

// MARK: - Private implementation

private extension PolymarketMapper {
    func quoteStatus(from raw: String) -> PolymarketQuoteStatus {
        guard let status = PolymarketQuoteStatus(rawValue: raw) else {
            PolymarketLogger.warning("Quote status '\(raw)' is unknown to this build, falling back to \(PolymarketQuoteStatus.undefined.rawValue)")
            return .undefined
        }

        return status
    }

    func decimal(_ raw: String, field: String) throws -> Decimal {
        guard let value = Decimal(stringValue: raw) else {
            throw PolymarketAPIError.decoding(field: field, value: raw)
        }

        return value
    }
}
