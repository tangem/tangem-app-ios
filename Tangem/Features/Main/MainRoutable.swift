//
//  MainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MainRoutable: AnyObject & WCTransactionRoutable & MainDeepLinkRoutable {
    func openDetails()
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openOnboardingModal(with options: OnboardingCoordinator.Options)
    func openScanCardManual()
    func openPushNotificationsAuthorization()
    func openQRScan()

    func popToRoot()
}

protocol MainDeepLinkRoutable {
    func beginHandlingIncomingActions()
    func resignHandlingIncomingActions()
    func openDeepLink(_ deepLink: MainCoordinator.DeepLinkDestination)
}
