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
    func openMail(with dataCollector: EmailDataCollector, support: EmailSupport, emailType: EmailType)
    func openWalletConnect(with cardModel: CardViewModel)
    func openDisclaimer()
    func openCardTOU(url: URL)
    func openScanCardSettings()
    func openAppSettings()
    func openSupportChat(cardID: String)
    func openInSafari(url: URL)
}
