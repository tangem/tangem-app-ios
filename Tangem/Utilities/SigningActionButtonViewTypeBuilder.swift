//
//  SigningActionButtonViewTypeBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct SigningActionButtonViewTypeBuilder {
    func build(config: UserWalletConfig) -> SigningActionButtonViewType {
        config.hasFeature(.nfcInteraction) ? .requiredNFCInteraction : .holdToConfirm
    }

    func build(userWalletInfo: UserWalletInfo) -> SigningActionButtonViewType {
        build(config: userWalletInfo.config)
    }
}
