//
//  WelcomeV2ViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class WelcomeV2ViewModel: ObservableObject {
    let videoBackground: WelcomeV2VideoBackgroundViewModel

    private weak var coordinator: WelcomeV2Routable?

    init(
        coordinator: WelcomeV2Routable,
        videoProvider: WelcomeV2BackgroundVideoProviding
    ) {
        self.coordinator = coordinator
        videoBackground = WelcomeV2VideoBackgroundViewModel(videoProvider: videoProvider)
    }

    func onCreateWalletTap() {
        coordinator?.openCreateWallet()
    }

    func onExistingWalletTap() {
        coordinator?.openExistingWallet()
    }

    func onLegalLinkTap(_ url: URL) {
        coordinator?.openLegal(url: url)
    }
}
