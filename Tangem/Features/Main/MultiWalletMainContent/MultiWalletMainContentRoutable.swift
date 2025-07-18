//
//  MultiWalletMainContentRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

protocol MultiWalletMainContentRoutable: SingleTokenBaseRoutable {
    func openTokenDetails(for model: any WalletModel, userWalletModel: UserWalletModel)
    func openOrganizeTokens(for userWalletModel: UserWalletModel)
    func openOnboardingModal(with options: OnboardingCoordinator.Options)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openReferral(input: ReferralInputModel)
    func openHotFinishActivation()
}
