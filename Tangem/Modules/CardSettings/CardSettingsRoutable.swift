//
//  CardSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol CardSettingsRoutable: AnyObject {
    func openOnboarding(with input: OnboardingInput)
    func openSecurityMode(cardModel: CardViewModel)
    func openResetCardToFactoryWarning(with input: ResetToFactoryViewModel.Input)
    func openAccessCodeRecoverySettings(with recoveryInteractor: UserCodeRecovering)
    func dismiss()
    func popToRoot()
}
