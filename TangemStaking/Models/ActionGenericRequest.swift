//
//  ActionGenericRequest.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ActionGenericRequest {
    public let amount: Decimal
    public let address: String
    public let additionalAddresses: AdditionalAddresses?
    public let token: StakingTokenItem
    public let validator: String
    public let integrationId: String

    public init(
        amount: Decimal,
        address: String,
        additionalAddresses: AdditionalAddresses?,
        token: StakingTokenItem,
        validator: String,
        integrationId: String
    ) {
        self.amount = amount
        self.address = address
        self.additionalAddresses = additionalAddresses
        self.token = token
        self.validator = validator
        self.integrationId = integrationId
    }
}
