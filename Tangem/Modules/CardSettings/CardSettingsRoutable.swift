//
//  CardSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol CardSettingsRoutable: AnyObject {
    func openOnboarding(with input: OnboardingInput, hasOtherCards: Bool)
    func openSecurityMode(cardModel: CardViewModel)
    func openResetCardToFactoryWarning(cardModel: CardViewModel)
    func openAccessCodeRecoverySettings(using provider: AccessCodeRecoverySettingsProvider)
    func dismiss()
    func popToRoot()
}
