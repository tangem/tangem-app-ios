//
//  TangemPayPlaceOrderRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayPlaceOrderRequest: Encodable {
    public static let firstCardSpecificationName = "SP_000004"

    public let data: Data

    public init(type: String, customerWalletAddress: String, specificationName: String) {
        data = Data(
            type: type,
            specificationName: specificationName,
            customerWalletAddress: customerWalletAddress
        )
    }
}

public extension TangemPayPlaceOrderRequest {
    struct Data: Encodable {
        public let type: String
        public let specificationName: String
        public let customerWalletAddress: String
    }
}
