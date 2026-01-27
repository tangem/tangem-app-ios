//
//  DetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol DetailsRoutable: AnyObject {
    func openWalletConnect(with disabledLocalizedReason: String?)
    func openWalletSettings(options: UserWalletSettingsCoordinator.InputOptions)

    func openOnboardingModal(with input: OnboardingInput)

    func openAddWallet() // [REDACTED_TODO_COMMENT]

    func openAppSettings()
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openSupportChat(input: SupportChatInputModel)
    func openTOS()
    func openScanCardManual()
    func openShop()
    func openSocialNetwork(url: URL)

    func openGetTangemPay()
    func openEnvironmentSetup()
    func openLogs()
    func dismiss()
}
