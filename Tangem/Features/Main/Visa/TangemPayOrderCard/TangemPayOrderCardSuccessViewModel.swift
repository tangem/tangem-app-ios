//
//  TangemPayOrderCardSuccessViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

final class TangemPayOrderCardSuccessViewModel: ObservableObject, Identifiable {
    let title = Constants.title
    let deliveryNote = Localization.tangempayOrderSuccessDeliveryEta(Constants.deliveryDays)

    var emailNote: AttributedString? {
        guard !email.isEmpty else {
            return nil
        }

        var note = AttributedString(Localization.tangempayOrderSuccessEmailNote(email))

        if let emailRange = note.range(of: email) {
            note[emailRange].foregroundColor = DesignSystem.Color.textPrimary
        }

        return note
    }

    private let email: String
    private weak var coordinator: TangemPayOrderCardSuccessRoutable?

    init(email: String, coordinator: TangemPayOrderCardSuccessRoutable?) {
        self.email = email
        self.coordinator = coordinator
    }

    func showCard() {
        coordinator?.orderCardSuccessDidTapShowCard()
    }
}

// MARK: - Constants

private extension TangemPayOrderCardSuccessViewModel {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let title = "Card successfully ordered"

        // [REDACTED_TODO_COMMENT]
        static let deliveryDays = 20
    }
}
