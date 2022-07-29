//
//  DisclaimerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class DisclaimerViewModel: Identifiable {
    let id: UUID = .init()

    let style: DisclaimerView.Style
    let showAccept: Bool

    private unowned let coordinator: DisclaimerRoutable?

    init(style: DisclaimerView.Style, showAccept: Bool, coordinator: DisclaimerRoutable?) {
        self.style = style
        self.showAccept = showAccept
        self.coordinator = coordinator
    }

    func onAccept() {
        AppSettings.shared.isTermsOfServiceAccepted = true
        dismissAccepted()
    }
}

// MARK: - Navigation
extension DisclaimerViewModel {
    private func dismissAccepted() {
        coordinator?.dismissAcceptedDisclaimer()
    }
}
