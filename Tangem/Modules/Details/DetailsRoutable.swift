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
    func openCurrencySelection(autoDismiss: Bool)
    func openDisclaimer()
    func openResetToFactory(action: @escaping (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void)
    func openScanCardSettings()
    func openAppSettings()
    func openSupportChat()
    func openInSafari(url: URL)
}
