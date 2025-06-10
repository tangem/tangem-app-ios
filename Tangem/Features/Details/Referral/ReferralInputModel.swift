//
//  ReferralInputModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
struct ReferralInputModel {
    let userWalletId: Data
    let supportedBlockchains: SupportedBlockchainsSet
    let userTokensManager: UserTokensManager
}
