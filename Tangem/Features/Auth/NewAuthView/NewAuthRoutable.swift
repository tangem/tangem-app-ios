//
//  NewAuthRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol NewAuthRoutable: AnyObject {
    func openOnboarding(with input: OnboardingInput)
    func openMain(with userWalletModel: UserWalletModel)
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openAddWallet() // [REDACTED_TODO_COMMENT]
    func openScanCardManual()
}
