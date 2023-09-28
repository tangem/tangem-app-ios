//
//  MultiWalletMainContentRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MultiWalletMainContentRoutable: SingleTokenBaseRoutable {
    func openTokenDetails(for model: WalletModel, mainCurrencyWalletModel: WalletModel?, userWalletModel: UserWalletModel)
    func openOrganizeTokens(for userWalletModel: UserWalletModel)
    func openOnboardingModal(with input: OnboardingInput)
    func openManageTokens(with settings: LegacyManageTokensSettings, userTokensManager: UserTokensManager)
}
