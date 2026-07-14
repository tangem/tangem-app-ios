//
//  TangemPayPlaceOrderRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayPlaceOrderRequest: Encodable {
    public static let firstCardSpecificationName = "SP_000004"
    public static let virtualAccountSpecificationName = "SP_000006"

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

    /// Virtual Account issue order (`ACCOUNT_ISSUE_VIRTUAL_RAIN`). The VA is bound to the card's
    /// existing collateral contract, so nothing is derived on the client and no `wallet_address` is
    /// sent: `depositAddress` is the card's existing collateral (deposit) address.
    public init(depositAddress: String) {
        data = Data(
            type: TangemPayOrderType.accountIssueVirtualRain.rawValue,
            specificationName: TangemPayPlaceOrderRequest.virtualAccountSpecificationName,
            depositAddress: depositAddress
        )
    }
}

public extension TangemPayPlaceOrderRequest {
    struct Data: Encodable {
        public let type: String
        public let specificationName: String
        public let customerWalletAddress: String?
        public let depositAddress: String?

        enum CodingKeys: String, CodingKey {
            case type
            case specificationName = "specification_name"
            case customerWalletAddress = "customer_wallet_address"
            case depositAddress = "deposit_address"
        }

        init(customerWalletAddress: String) {
            type = TangemPayOrderType.cardIssueVirtualRainKyc.rawValue
            specificationName = TangemPayPlaceOrderRequest.firstCardSpecificationName
            self.customerWalletAddress = customerWalletAddress
            depositAddress = nil
        }

        init(type: String, specificationName: String, customerWalletAddress: String) {
            self.type = type
            self.specificationName = specificationName
            self.customerWalletAddress = customerWalletAddress
            depositAddress = nil
        }

        init(type: String, specificationName: String, depositAddress: String) {
            self.type = type
            self.specificationName = specificationName
            customerWalletAddress = nil
            self.depositAddress = depositAddress
        }
    }
}
