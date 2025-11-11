//
//  HardwareCreateWalletRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HardwareCreateWalletRoutable: AnyObject {
    func openOnboarding(input: OnboardingInput)
    func openMain(userWalletModel: UserWalletModel)
    func openMail(dataCollector: EmailDataCollector, recipient: String)
}
