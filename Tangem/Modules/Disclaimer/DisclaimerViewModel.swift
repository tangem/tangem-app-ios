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

    let url: URL
    let style: DisclaimerView.Style
    let showAccept: Bool

    private unowned let coordinator: DisclaimerRoutable?

    init(url: URL = Constants.defaultDocumentURL, style: DisclaimerView.Style, showAccept: Bool, coordinator: DisclaimerRoutable?) {
        self.url = url
        self.style = style
        self.showAccept = showAccept
        self.coordinator = coordinator
    }

    func onAccept() {
        AppSettings.shared.isTermsOfServiceAccepted = true
        dismissAccepted()
    }
}

extension DisclaimerViewModel {
    enum Constants {
        static var defaultDocumentURL: URL {
            Bundle.main.url(forResource: "T&C", withExtension: "pdf")!
        }
    }
}

// MARK: - Navigation
extension DisclaimerViewModel {
    private func dismissAccepted() {
        coordinator?.dismissAcceptedDisclaimer()
    }
}
