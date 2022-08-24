//
//  UserWalletListRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletListRoutable: AnyObject {
    func popToRoot()
    func didTapUserWallet(userWallet: UserWallet)
    func openMail(with dataCollector: EmailDataCollector)
    func openOnboarding(with input: OnboardingInput)
}
