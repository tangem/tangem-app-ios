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
    public let preferred: Bool
    public let partner: Bool
    public let iconURL: URL?
    public let rewardType: RewardType
    public let rewardRate: Decimal
    public let status: ValidatorInfoStatus

    public init(
        address: String,
        name: String,
        preferred: Bool,
        partner: Bool,
        iconURL: URL?,
        rewardType: RewardType,
        rewardRate: Decimal,
        status: ValidatorInfoStatus
    ) {
        self.address = address
        self.name = name
        self.partner = partner
        self.preferred = preferred
        self.iconURL = iconURL
        self.rewardType = rewardType
        self.rewardRate = rewardRate
        self.status = status
    }
}
