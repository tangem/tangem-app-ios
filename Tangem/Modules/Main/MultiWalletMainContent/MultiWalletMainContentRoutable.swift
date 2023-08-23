//
//  MultiWalletMainContentRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MultiWalletMainContentRoutable: AnyObject {
    func openTokenDetails(for model: WalletModel, userWalletModel: UserWalletModel)
    func openOrganizeTokens(for userWalletModel: UserWalletModel)
    func openOnboardingModal(with input: OnboardingInput)
}
