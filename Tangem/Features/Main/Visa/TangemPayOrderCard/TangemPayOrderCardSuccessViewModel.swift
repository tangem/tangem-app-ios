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
    let title = Localization.tangempayOrderDataSuccessTitle

    var deliveryNote: String? {
        deliveryEtaMaxDays.map(Localization.tangempayOrderSuccessDeliveryEta)
    }

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
    private let deliveryEtaMaxDays: Int?
    private weak var coordinator: TangemPayOrderCardSuccessRoutable?

    init(email: String, deliveryEtaMaxDays: Int?, coordinator: TangemPayOrderCardSuccessRoutable?) {
        self.email = email
        self.deliveryEtaMaxDays = deliveryEtaMaxDays
        self.coordinator = coordinator

        Analytics.log(.visaPlasticCardOrderedSuccessScreenShowed)
    }

    func showCard() {
        coordinator?.orderCardSuccessDidTapShowCard()
    }
}
