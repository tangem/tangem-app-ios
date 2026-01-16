//
//  MultiWalletMainContentRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk

protocol MultiWalletMainContentRoutable: SingleTokenBaseRoutable {
    func openTokenDetails(for walletModel: any WalletModel, userWalletModel: UserWalletModel)
    func openOrganizeTokens(for userWalletModel: UserWalletModel)
    func openOnboardingModal(with options: OnboardingCoordinator.Options)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openMobileUpgrade(userWalletModel: UserWalletModel, context: MobileWalletContext)
    func openMobileBackupOnboarding(userWalletModel: UserWalletModel)
    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory)
    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory)
    func openTangemPayIssuingYourCardPopup()
    func openTangemPayKYCInProgressPopup(tangemPayAccount: TangemPayAccount)
    func openTangemPayFailedToIssueCardPopup(userWalletModel: UserWalletModel)
    func openTangemPayMainView(userWalletInfo: UserWalletInfo, tangemPayAccount: TangemPayAccount)
    func openGetTangemPay()
}
