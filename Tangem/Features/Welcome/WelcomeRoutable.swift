//
//  WelcomeRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeRoutable: AnyObject {
    func openCreateWallet()
    func openExistingWallet()
    func openBuyTangem()
    func openLegal(document: WelcomeLegalDocument)
    func openMain(with userWalletModel: UserWalletModel)
    func openOnboarding(with input: OnboardingInput)
}
