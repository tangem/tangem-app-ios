//
//  StakingWallet.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol StakingWallet {
    var blockchain: Blockchain { get }
    var defaultAddress: String { get }
}
