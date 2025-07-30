//
//  DetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol DetailsRoutable: AnyObject {
    func openWalletConnect(with disabledLocalizedReason: String?)
    func openWalletSettings(options: UserWalletSettingsCoordinator.Options)

    func openOnboardingModal(with input: OnboardingInput)

    func openCreateWallet()
    func openImportWallet()

    func openAppSettings()
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openSupportChat(input: SupportChatInputModel)
    func openTOS()
    func openScanCardManual()
    func openShop()
    func openSocialNetwork(url: URL)

    func openEnvironmentSetup()
    func openLogs()
    func dismiss()
}
