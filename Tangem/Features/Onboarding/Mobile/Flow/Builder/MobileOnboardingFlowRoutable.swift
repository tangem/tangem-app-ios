//
//  MobileOnboardingFlowRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileOnboardingFlowRoutable: AnyObject {
    func openMain()
    func openMain(userWalletModel: UserWalletModel)
    func openConfetti()
    func completeOnboarding()
    func closeOnboarding()
}
