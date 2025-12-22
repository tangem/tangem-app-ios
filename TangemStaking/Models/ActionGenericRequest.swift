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
    public let target: String?
    public let integrationId: String
    public let tronResource: String?

    public init(
        amount: Decimal,
        address: String,
        additionalAddresses: AdditionalAddresses?,
        token: StakingTokenItem,
        target: String?,
        integrationId: String,
        tronResource: String?
    ) {
        self.amount = amount
        self.address = address
        self.additionalAddresses = additionalAddresses
        self.token = token
        self.target = target
        self.integrationId = integrationId
        self.tronResource = tronResource
    }
}
