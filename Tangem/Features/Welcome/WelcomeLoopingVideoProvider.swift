//
//  WelcomeLoopingVideoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class WelcomeLoopingVideoProvider: LoopingVideoBackgroundProvider {
    @Injected(\.welcomeAnalyticsProvider) private var analytics: WelcomeAnalyticsProvider

    private let urlProvider: WelcomeBackgroundVideoProviding
    private var didLogMissingAsset = false

    init(urlProvider: WelcomeBackgroundVideoProviding) {
        self.urlProvider = urlProvider
    }

    func videoURL() -> URL? {
        urlProvider.backgroundVideoURL()
    }

    func handleMissingAsset() {
        guard !didLogMissingAsset else { return }
        didLogMissingAsset = true

        analytics.logWelcomeMediaError(stage: .welcomeMediaStageLoad)
    }
}
