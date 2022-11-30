//
//  CardSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol CardSettingsRoutable: AnyObject {
    func openOnboarding(with input: OnboardingInput, isSavingCards: Bool)
    func openSecurityMode(cardModel: CardViewModel)
    func openResetCardToFactoryWarning(mainButtonAction: @escaping () -> Void)
    func dismiss()
    func popToRoot()
}
