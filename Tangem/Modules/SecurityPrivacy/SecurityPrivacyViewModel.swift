//
//  SecurityPrivacyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SecurityPrivacyViewModel: ObservableObject {
    private unowned let coordinator: SecurityPrivacyRoutable

    private let cardModel: CardViewModel

    init(
        cardModel: CardViewModel,
        coordinator: SecurityPrivacyRoutable
    ) {
        self.cardModel = cardModel
        self.coordinator = coordinator
    }

    // MARK: View Output

    func viewDidRequestChangePassword() {
        coordinator.didRequestChangePassword()
    }

    func viewDidRequestSecurityManagement() {
        coordinator.didRequestSecurityManagement(cardModel: cardModel)
    }

    func viewDidRequestTokenSynchronization() {
        coordinator.didRequestTokenSynchronization()
    }

    func viewDidRequestResetSavedCards() {
        coordinator.didRequestResetSavedCards()
    }
}
