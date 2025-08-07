//
//  HotOnboardingFlowRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotOnboardingFlowRoutable: AnyObject {
    func openMain()
    func openMain(userWalletModel: UserWalletModel)
    func openAccesCodeSkipAlert(onSkip: @escaping () -> Void)
    func openConfetti()
    func closeOnboarding()
}
