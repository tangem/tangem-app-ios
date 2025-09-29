//
//  TangemPayPlaceOrderRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayPlaceOrderRequest: Encodable {
    let walletAddress: String

    enum CodingKeys: String, CodingKey {
        case walletAddress = "wallet_address"
    }
}
