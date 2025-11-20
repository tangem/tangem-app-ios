//
//  StakingTransactionInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct StakingTransactionInfo {
    public let id: String
    public let actionId: String
    public let network: String
    public let unsignedTransactionData: any UnsignedTransactionData
    public let fee: Decimal
    public let type: String
    public let status: String
    public let stepIndex: Int

    public init(
        id: String,
        actionId: String,
        network: String,
        unsignedTransactionData: any UnsignedTransactionData,
        fee: Decimal,
        type: String,
        status: String,
        stepIndex: Int
    ) {
        self.id = id
        self.actionId = actionId
        self.network = network
        self.unsignedTransactionData = unsignedTransactionData
        self.fee = fee
        self.type = type
        self.status = status
        self.stepIndex = stepIndex
    }
}

extension StakingTransactionInfo: Hashable {
    public static func == (lhs: StakingTransactionInfo, rhs: StakingTransactionInfo) -> Bool {
        lhs.unsignedTransactionData.hashValue == rhs.unsignedTransactionData.hashValue && lhs.fee == rhs.fee
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(unsignedTransactionData.hashValue)
        hasher.combine(fee)
    }
}
