//
//  StakingWallet.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingWallet {
    var stakingTokenItem: StakingTokenItem { get }
    var defaultAddress: String { get }
}

public struct StakingTokenItem: Hashable {
    let coinId: String
    let contractAdress: String?

    public init(coinId: String, contractAdress: String?) {
        self.coinId = coinId
        self.contractAdress = contractAdress
    }
}
