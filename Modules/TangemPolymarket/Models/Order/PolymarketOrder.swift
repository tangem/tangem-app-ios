//
//  PolymarketOrder.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketOrder: Hashable, Sendable {
    public let salt: UInt64
    public let maker: String
    public let signer: String

    public let tokenId: String
    public let makerAmount: String
    public let takerAmount: String

    public let side: PolymarketOrderSide
    public let signatureType: Int
    public let timestampMillis: UInt64

    public let metadata: String
    public let builder: String

    public init(
        salt: UInt64,
        maker: String,
        signer: String,
        tokenId: String,
        makerAmount: String,
        takerAmount: String,
        side: PolymarketOrderSide,
        signatureType: Int = PolymarketExchange.depositWalletSignatureType,
        timestampMillis: UInt64,
        metadata: String = PolymarketExchange.emptyWord,
        builder: String
    ) {
        self.salt = salt
        self.maker = maker
        self.signer = signer
        self.tokenId = tokenId
        self.makerAmount = makerAmount
        self.takerAmount = takerAmount
        self.side = side
        self.signatureType = signatureType
        self.timestampMillis = timestampMillis
        self.metadata = metadata
        self.builder = builder
    }
}

// MARK: - Signed

public struct PolymarketSignedOrder: Hashable, Sendable {
    public let order: PolymarketOrder
    public let signature: String

    public init(order: PolymarketOrder, signature: String) {
        self.order = order
        self.signature = signature
    }
}
