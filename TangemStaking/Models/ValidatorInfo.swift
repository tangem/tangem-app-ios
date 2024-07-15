//
//  ValidatorInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ValidatorInfo: Hashable {
    public let address: String
    public let name: String
    public let iconURL: URL
    public let apr: Decimal?

    public init(address: String, name: String, iconURL: URL, apr: Decimal?) {
        self.address = address
        self.name = name
        self.iconURL = iconURL
        self.apr = apr
    }
}
