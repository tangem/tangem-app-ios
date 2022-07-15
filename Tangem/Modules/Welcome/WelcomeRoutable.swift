//
//  WelcomeRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeRoutable: AnyObject {
    func openTokensList()
    func openOnboardingModal(with input: OnboardingInput)
    func openMail(with dataCollector: EmailDataCollector)
    func openDisclaimer()
    func openShop()
    func openOnboarding(with input: OnboardingInput)
    func openMain(with cardModel: CardViewModel)
}
