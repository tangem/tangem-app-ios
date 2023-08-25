//
//  DetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol DetailsRoutable: AnyObject {
    func openOnboardingModal(with input: OnboardingInput)
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openWalletConnect(with disabledLocalizedReason: String?)
    func openCurrencySelection()
    func openDisclaimer(at url: URL)
    func openScanCardSettings(with userWalletId: Data, sdk: TangemSdk)
    func openAppSettings(userWallet: CardViewModel)
    func openSupportChat(input: SupportChatInputModel)
    func openInSafari(url: URL)
    func openEnvironmentSetup(with cardId: String)
    func openReferral(with cardModel: CardViewModel, userWalletId: Data)
}
