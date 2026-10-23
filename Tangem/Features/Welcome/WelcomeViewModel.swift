//
//  WelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUI.TangemSnackbar
import class TangemUI.Toast
import TangemAssets

final class WelcomeViewModel: ObservableObject {
    @Injected(\.welcomeEntryReasonProvider)
    private var entryReasonProvider: WelcomeEntryReasonProviding

    @Injected(\.welcomeAnalyticsProvider)
    private var analytics: WelcomeAnalyticsProvider

    /// `nil` while the background hands one episode over to the next and no text belongs on screen.
    @Published private(set) var scene: WelcomeScene?

    @Published private(set) var isProcessing = false

    let videoBackground: VideoBackground

    private weak var coordinator: WelcomeRoutable?

    init(
        coordinator: WelcomeRoutable,
        videoProvider: WelcomeBackgroundVideoProviding
    ) {
        self.coordinator = coordinator

        if FeatureProvider.isAvailable(.payBundleIntroduction) {
            videoBackground = .shared(
                LoopingVideoBackgroundViewModel(provider: WelcomeLoopingVideoProvider(urlProvider: videoProvider))
            )
        } else {
            videoBackground = .legacy(WelcomeVideoBackgroundViewModel(videoProvider: videoProvider))
        }

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

    func set(isProcessing: Bool) {
        self.isProcessing = isProcessing
    }

    func showSnackbar(withMessage message: String) {
        let snackbar = TangemSnackbar(title: message)
            .icon(DesignSystem.Icons.Warning.filled20)
            .iconColor(DesignSystem.Color.iconStatusError)
        Toast(view: snackbar).present(layout: .top(padding: 8), type: .temporary())
    }

    private func bind() {
        videoBackground.playbackTime
            .map(WelcomeScene.scene(at:))
            .removeDuplicates()
            .assign(to: &$scene)
    }
}

// MARK: - VideoBackground

extension WelcomeViewModel {
    enum VideoBackground {
        case legacy(WelcomeVideoBackgroundViewModel)
        case shared(LoopingVideoBackgroundViewModel)

        var playbackTime: AnyPublisher<TimeInterval, Never> {
            switch self {
            case .legacy(let viewModel): viewModel.playbackTime
            case .shared(let viewModel): viewModel.playbackTime
            }
        }
    }
}
