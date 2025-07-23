//
//  MainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

protocol MainRoutable: AnyObject & WCTransactionRoutable & MainDeepLinkRoutable {
    func openDetails(for userWalletModel: UserWalletModel)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openOnboardingModal(with options: OnboardingCoordinator.Options)
    func openScanCardManual()
    func openPushNotificationsAuthorization()
    func openReferral(input: ReferralInputModel)
    func showWCTransactionRequest(with data: WCHandleTransactionData)
    func showWCTransactionRequest(with error: Error)
    func popToRoot()
}

protocol MainDeepLinkRoutable {
    func beginHandlingIncomingActions()
    func resignHandlingIncomingActions()
    func openDeepLink(_ deepLink: MainCoordinator.DeepLinkDestination)
}
