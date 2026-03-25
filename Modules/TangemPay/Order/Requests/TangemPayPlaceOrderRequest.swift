//
//  TangemPayPlaceOrderRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayPlaceOrderRequest: Encodable {
    let data: Data

    init(customerWalletAddress: String) {
        data = .init(customerWalletAddress: customerWalletAddress)
    }
}

extension TangemPayPlaceOrderRequest {
    struct Data: Encodable {
        let type: String = "CARD_ISSUE_VIRTUAL_RAIN_KYC"
        let specificationName: String = "SP_000004"
        let customerWalletAddress: String

        enum CodingKeys: String, CodingKey {
            case type
            case specificationName = "specification_name"
            case customerWalletAddress = "customer_wallet_address"
        }
    }
}
