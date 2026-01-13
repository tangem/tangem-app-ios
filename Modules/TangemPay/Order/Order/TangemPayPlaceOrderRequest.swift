//
//  TangemPayPlaceOrderRequest.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayPlaceOrderRequest: Encodable {
    let customerWalletAddress: String

    enum CodingKeys: String, CodingKey {
        case customerWalletAddress = "wallet_address"
    }
}
