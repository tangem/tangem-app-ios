//
//  StakingTransactionInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTransactionInfo: Hashable {
    public let id: String
    public let actionId: String
    public let network: String
    public let unsignedTransactionData: String
    public let fee: Decimal

    public init(
        id: String,
        actionId: String,
        network: String,
        unsignedTransactionData: String,
        fee: Decimal
    ) {
        self.id = id
        self.actionId = actionId
        self.network = network
        self.unsignedTransactionData = unsignedTransactionData
        self.fee = fee
    }
}
