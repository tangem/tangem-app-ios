//
//  PolymarketMapper+PlaceOrder.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension PolymarketMapper {
    func mapPlaceOrderRequest(_ signedOrder: PolymarketSignedOrder, apiKey: String) -> PolymarketDTO.PlaceOrderRequestBody {
        let order = signedOrder.order

        return PolymarketDTO.PlaceOrderRequestBody(
            order: PolymarketDTO.PlaceOrderRequestBody.Order(
                salt: order.salt,
                maker: order.maker.lowercased(),
                signer: order.signer.lowercased(),
                tokenId: order.tokenId,
                makerAmount: order.makerAmount,
                takerAmount: order.takerAmount,
                side: order.side.rawValue,
                signatureType: order.signatureType,
                timestamp: String(order.timestampMillis),
                expiration: Constants.noExpiration,
                metadata: order.metadata,
                builder: order.builder,
                signature: signedOrder.signature
            ),
            owner: apiKey,
            orderType: Constants.fillAndKill,
            postOnly: false,
            deferExec: false
        )
    }

    func mapPlaceOrder(_ response: PolymarketDTO.PlaceOrderResponse) -> PolymarketOrderPlacement {
        PolymarketOrderPlacement(
            orderId: response.orderID,
            status: response.status,
            makingAmount: response.makingAmount.flatMap { Decimal(stringValue: $0) },
            takingAmount: response.takingAmount.flatMap { Decimal(stringValue: $0) },
            transactionHashes: response.transactionsHashes ?? []
        )
    }
}

// MARK: - Constants

private extension PolymarketMapper {
    enum Constants {
        static let noExpiration = "0"
        static let fillAndKill = "FAK"
    }
}
