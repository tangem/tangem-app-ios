//
//  WelcomeRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeRoutable: AnyObject {
    func openLearning()
    func openTokensList()
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openShop()
    func openOnboarding(with input: OnboardingInput)
    func openMain(with cardModel: CardViewModel)
}
