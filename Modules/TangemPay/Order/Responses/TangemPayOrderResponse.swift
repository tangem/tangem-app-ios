//
//  TangemPayOrderResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayOrderResponse: Decodable {
    public let id: String
    public let customerId: String
    public let type: String
    public let status: Status
    public let step: String?
    public let data: Data?
    public let stepChangeCode: Int?
}

public extension TangemPayOrderResponse {
    enum Status: String, Decodable {
        case new = "NEW"
        case processing = "PROCESSING"
        case completed = "COMPLETED"
        case canceled = "CANCELED"
    }

    struct Data: Decodable {
        public let type: String?
        public let specificationName: String?
        public let customerWalletAddress: String?
        public let embossName: String?
        public let productInstanceId: String?
        public let paymentAccountId: String?
    }
}
