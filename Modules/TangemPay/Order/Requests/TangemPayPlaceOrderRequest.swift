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

    /// To be removed in following PRs after breaking changes.
    init(customerWalletAddress: String) {
        data = Data(customerWalletAddress: customerWalletAddress)
    }

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

        enum CodingKeys: String, CodingKey {
            case type
            case specificationName = "specification_name"
            case customerWalletAddress = "customer_wallet_address"
        }

        init(customerWalletAddress: String) {
            type = TangemPayOrderType.cardIssueVirtualRainKyc.rawValue
            specificationName = TangemPayPlaceOrderRequest.firstCardSpecificationName
            self.customerWalletAddress = customerWalletAddress
        }

        init(type: String, specificationName: String, customerWalletAddress: String) {
            self.type = type
            self.specificationName = specificationName
            self.customerWalletAddress = customerWalletAddress
        }
    }
}
