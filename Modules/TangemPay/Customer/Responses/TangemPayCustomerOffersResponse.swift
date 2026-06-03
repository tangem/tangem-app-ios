//
//  TangemPayCustomerOffersResponse.swift
//  TangemPay
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public typealias TangemPayCustomerOffersResponse = [TangemPayCustomerOffer]

public struct TangemPayCustomerOffer: Decodable {
    public let type: TangemPayOrderType
    public let fee: Fee?
    public let data: Data?
}

public extension TangemPayCustomerOffer {
    struct Fee: Decodable {
        public let type: String
        public let amount: Decimal
        public let currency: String
        public let description: String?
    }

    struct Data: Decodable {
        public let specificationName: String
        public let orderType: String
    }
}
