//
//  WelcomeV2ViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class WelcomeV2ViewModel: ObservableObject {
    @Injected(\.welcomeV2EntryReasonProvider)
    private var entryReasonProvider: WelcomeV2EntryReasonProviding

    @Injected(\.welcomeV2AnalyticsProvider)
    private var analytics: WelcomeV2AnalyticsProvider

    /// `nil` while the background hands one episode over to the next and no text belongs on screen.
    @Published private(set) var scene: WelcomeV2Scene?

    let videoBackground: WelcomeV2VideoBackgroundViewModel

    private weak var coordinator: WelcomeV2Routable?

    init(
        coordinator: WelcomeV2Routable,
        videoProvider: WelcomeV2BackgroundVideoProviding
    ) {
        self.coordinator = coordinator
        videoBackground = WelcomeV2VideoBackgroundViewModel(videoProvider: videoProvider)

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

    func onLegalLinkTap(_ url: URL) {
        let document: Analytics.ParameterValue = url == AppConstants.tosURL
            ? .welcomeV2DocumentTerms
            : .welcomeV2DocumentPrivacy
        analytics.logLegalOpened(document: document)
        coordinator?.openLegal(url: url)
    }

    private func bind() {
        videoBackground.playbackTime
            .map(WelcomeV2Scene.scene(at:))
            .removeDuplicates()
            .assign(to: &$scene)
    }
}
