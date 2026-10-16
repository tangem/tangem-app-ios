//
//  PromoCampaignWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PromoCampaignWallet: Hashable {
    let userWalletId: UserWalletId
    let identity: PromoCampaignIdentity
}
