//
//  WalletModel+StakingWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension WalletModel: StakingWallet {
    var stakingTokenItem: TangemStaking.StakingTokenItem {
        tokenItem.stakingTokenItem
    }
}
