//
//  StakingTokenItem.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTokenItem: Hashable {
    public let network: StakeKitNetworkType
    public let contractAddress: String?

    public init(network: StakeKitNetworkType, contractAddress: String?) {
        self.network = network
        self.contractAddress = contractAddress
    }
}
