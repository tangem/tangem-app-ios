//
//  AuthRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@MainActor
protocol AuthRoutable: AnyObject {
    func openOnboarding(with input: OnboardingInput)
    func openMain(with userWalletModel: UserWalletModel)
    func openAddWallet()
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openScanCardManual()
}
