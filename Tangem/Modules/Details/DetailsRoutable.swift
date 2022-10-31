//
//  DetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol DetailsRoutable: AnyObject {
    func openOnboardingModal(with input: OnboardingInput)
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openWalletConnect(with cardModel: CardViewModel)
    func openCurrencySelection()
    func openDisclaimer(at url: URL)
    func openScanCardSettings(with userWalletId: Data)
    func openAppSettings()
    func openSupportChat(cardId: String, dataCollector: EmailDataCollector)
    func openInSafari(url: URL)
    func openEnvironmentSetup()
}
