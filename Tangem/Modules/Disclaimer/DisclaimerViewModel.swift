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
    let webViewModel: WebViewContainerViewModel
    var showAccept: Bool { acceptanceHandler != nil }

    private unowned let coordinator: DisclaimerRoutable?
    private var acceptanceHandler: ((Bool) -> Void)?
    private var accepted: Bool = false

    init(url: URL,
         style: DisclaimerView.Style,
         coordinator: DisclaimerRoutable?,
         acceptanceHandler: ((Bool) -> Void)? = nil) {
        self.style = style
        self.coordinator = coordinator
        self.acceptanceHandler = acceptanceHandler
        self.webViewModel = .init(url: url,
                                  title: "",
                                  addLoadingIndicator: true,
                                  withCloseButton: false,
                                  withNavigationBar: false)
    }

    func onAccept() {
        accepted = true
        dismissAccepted()
    }

    func onDisappear() {
        acceptanceHandler?(accepted)
    }
}

// MARK: - Navigation
extension DisclaimerViewModel {
    private func dismissAccepted() {
        coordinator?.dismissDisclaimer()
    }
}
