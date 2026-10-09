//
//  WelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class WelcomeViewModel: ObservableObject {
    @Injected(\.welcomeEntryReasonProvider)
    private var entryReasonProvider: WelcomeEntryReasonProviding

    @Injected(\.welcomeAnalyticsProvider)
    private var analytics: WelcomeAnalyticsProvider

    /// `nil` while the background hands one episode over to the next and no text belongs on screen.
    @Published private(set) var scene: WelcomeScene?

    let videoBackground: WelcomeVideoBackgroundViewModel

    private weak var coordinator: WelcomeRoutable?

    init(
        coordinator: WelcomeRoutable,
        videoProvider: WelcomeBackgroundVideoProviding
    ) {
        self.coordinator = coordinator
        videoBackground = WelcomeVideoBackgroundViewModel(videoProvider: videoProvider)

        bind()
    }

    func onFirstAppear() {
        if let entryReason = entryReasonProvider.consumeEntryReason() {
            analytics.logIntroductionProcessScreenOpened(entryReason: entryReason)
        }
    }

    func onCreateWalletTap() {
        analytics.logCreateWalletButton()
        coordinator?.openCreateWallet()
    }

    func onExistingWalletTap() {
        analytics.logIHaveWalletButton()
        coordinator?.openExistingWallet()
    }

    func onBuyTangemTap() {
        coordinator?.openBuyTangem()
    }

    func onLegalLinkTap(_ url: URL) {
        let document = WelcomeLegalDocument(url: url)
        analytics.logLegalOpened(document: document.analyticsValue)
        coordinator?.openLegal(document: document)
    }

    private func bind() {
        videoBackground.playbackTime
            .map(WelcomeScene.scene(at:))
            .removeDuplicates()
            .assign(to: &$scene)
    }
}
