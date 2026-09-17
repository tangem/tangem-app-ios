//
//  MainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MainRoutable: AnyObject & WCTransactionRoutable {
    /// The main screen is up, which is the moment a deeplink first has somewhere to go. The main screen keeps
    /// its place in the chain for as long as the session lasts — whether it can show a link right now is a
    /// question it answers itself, screen by screen.
    func mainScreenDidAppear()

    func openDetails()
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openOnboardingModal(with options: OnboardingCoordinator.Options)
    func openScanCardManual()
    func openPushNotificationsAuthorization()
    func openQRScan()

    func popToRoot()
}
