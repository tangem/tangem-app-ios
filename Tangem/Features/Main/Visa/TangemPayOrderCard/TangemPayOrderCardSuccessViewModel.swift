//
//  TangemPayOrderCardSuccessViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class TangemPayOrderCardSuccessViewModel: ObservableObject, Identifiable {
    let title = Localization.tangempayOrderDataSuccessTitle

    var deliveryNote: String? {
        deliveryEtaMaxDays.map(Localization.tangempayOrderSuccessDeliveryEta)
    }

    var emailNote: String? {
        guard !email.isEmpty else {
            return nil
        }

        return Localization.tangempayOrderSuccessEmailNote(email)
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
