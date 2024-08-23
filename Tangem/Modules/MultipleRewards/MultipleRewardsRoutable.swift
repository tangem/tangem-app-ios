//
//  MultipleRewardsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol MultipleRewardsRoutable: AnyObject {
    func openUnstakingFlow(balanceInfo: StakingBalanceInfo)
    func dismiss()
}
