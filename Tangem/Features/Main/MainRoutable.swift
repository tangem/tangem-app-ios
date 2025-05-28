//
//  MainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

protocol MainRoutable: AnyObject, MainDeepLinkRoutable {
    func openDetails(for userWalletModel: UserWalletModel)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openOnboardingModal(with input: OnboardingInput)
    func openScanCardManual()
    func openPushNotificationsAuthorization()
    func popToRoot()
}

protocol MainDeepLinkRoutable {
    var isOnMainView: Bool { get }

    func openReferral(input: ReferralInputModel)
    func openTokenDetails(for model: any WalletModel, userWalletModel: UserWalletModel)
    func openBuy(userWalletModel: some UserWalletModel)
    func openSell(userWalletModel: some UserWalletModel)
    func openMarketsTokenDetails(tokenModel: MarketsTokenModel)
}
