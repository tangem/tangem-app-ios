//
//  MultiWalletMainContentRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemMobileWalletSdk

protocol MultiWalletMainContentRoutable: SingleTokenBaseRoutable {
    func openTokenDetails(for model: any WalletModel, userWalletModel: UserWalletModel)
    func openOrganizeTokens(for userWalletModel: UserWalletModel)
    func openOnboardingModal(with options: OnboardingCoordinator.Options)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openReferral(input: ReferralInputModel)
    func openMobileFinishActivation(userWalletModel: UserWalletModel)
    func openMobileUpgrade(userWalletModel: UserWalletModel, context: MobileWalletContext)
    func openMobileBackupOnboarding(userWalletModel: UserWalletModel)
    func openTangemPayMainView(tangemPayAccount: TangemPayAccount)
    func openYieldModuleActiveInfo(walletModel: any WalletModel, signer: any TangemSigner)
    func openYieldModulePromoView(walletModel: any WalletModel, apy: Decimal, signer: any TangemSigner)
}
