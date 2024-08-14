//
//  ActionGenericRequest.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 14.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ActionGenericRequest {
    public let amount: Decimal
    public let address: String
    public let validator: String
    public let integrationId: String

    public init(amount: Decimal, address: String, validator: String, integrationId: String) {
        self.amount = amount
        self.address = address
        self.validator = validator
        self.integrationId = integrationId
    }
}
