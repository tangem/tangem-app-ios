//
//  StakingWallet.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingWallet {
    var item: StakingTokenItem { get }
    var defaultAddress: String { get }
}

public struct StakingTokenItem: Hashable {
    let network: String
    let contractAdress: String?
}
