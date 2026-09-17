//
//  PolymarketDTO+PlaceOrder.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct PlaceOrderRequestBody: Encodable {
        let order: Order
        let owner: String
        let orderType: String
        let postOnly: Bool
        let deferExec: Bool

        struct Order: Encodable {
            let salt: UInt64
            let maker: String
            let signer: String
            let tokenId: String
            let makerAmount: String
            let takerAmount: String
            let side: String
            let signatureType: Int
            let timestamp: String
            let expiration: String
            let metadata: String
            let builder: String
            let signature: String
        }
    }

    struct OrderRecordResponse: Decodable {
        let status: PolymarketOrderRecordStatus
        let originalSize: String?
        let sizeMatched: String?
        let price: String?

        enum CodingKeys: String, CodingKey {
            case status
            case originalSize = "original_size"
            case sizeMatched = "size_matched"
            case price
        }
    }

    struct PlaceOrderResponse: Decodable {
        let success: Bool
        let orderID: String?
        let status: String?
        let makingAmount: String?
        let takingAmount: String?
        let transactionsHashes: [String]?
        let errorMsg: String?
    }
}
