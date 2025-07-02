//
//  WelcomeRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeRoutable: AnyObject {
    func openPromotion()
    func openTokensList()
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openShop()
    func openOnboarding(with input: OnboardingInput)
    func openNewWalletSelector(with input: NewWalletSelectorInput)
    func openMain(with userWalletModel: UserWalletModel)
    func openScanCardManual()
}
