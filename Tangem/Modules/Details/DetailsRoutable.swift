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
    func openWalletSettings(options: WalletDetailsCoordinator.Options)

    func openOnboardingModal(with input: OnboardingInput)

    func openAppSettings()
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openSupportChat(input: SupportChatInputModel)
    func openDisclaimer(at url: URL)
    func openScanCardManual()
    func openInSafari(url: URL)

    func openEnvironmentSetup()
    func dismiss()
}
