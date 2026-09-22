//
//  TangemPayOrderResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct TangemPayOrderResponse: Decodable {
    public let id: String
    public let customerId: String
    public let type: String
    public let status: Status
    public let step: String?
    public let data: Data?
    public let stepChangeCode: Int?
    public let createdAt: Date?
    public let updatedAt: Date?
}

public extension TangemPayOrderResponse {
    enum Status: String, Decodable {
        case new = "NEW"
        case processing = "PROCESSING"
        case completed = "COMPLETED"
        case canceled = "CANCELED"
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
    }

    struct Data: Decodable {
        public let type: String?
        public let specificationName: String?
        public let customerWalletAddress: String?
        public let embossName: String?
        public let productInstanceId: String?
        public let paymentAccountId: String?
        public let transactionHash: String?
        public let targetTariffPlanId: String?
        public let chainId: Int?
        public let depositAddress: String?
        public let bankAccountId: String?
        public let withdrawData: WithdrawData?
    }

    enum Step: String {
        case awaitingDeposit = "AWAITING_DEPOSIT"
        case awaitingSignature = "AWAITING_SIGNATURE"
    }

    var isAwaitingDeposit: Bool {
        step == Step.awaitingDeposit.rawValue
    }

    var isAwaitingSignature: Bool {
        step == Step.awaitingSignature.rawValue
    }

    var targetTariffPlanId: String? {
        data?.targetTariffPlanId
    }
}

// MARK: - Withdraw data

public extension TangemPayOrderResponse.Data {
    struct WithdrawData: Decodable {
        public let hash: String
        public let salt: String
        public let senderAddress: String
        public let structuredData: EIP712TypedData
    }
}
