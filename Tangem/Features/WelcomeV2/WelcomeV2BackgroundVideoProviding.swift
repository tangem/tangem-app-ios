//
//  WelcomeV2BackgroundVideoProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeV2BackgroundVideoProviding {
    func backgroundVideoURL() -> URL?
}

struct CommonWelcomeV2BackgroundVideoProvider: WelcomeV2BackgroundVideoProviding {
    private let url: URL? = Bundle.main.url(
        forResource: Constants.resourceName,
        withExtension: Constants.resourceExtension
    )

    func backgroundVideoURL() -> URL? { url }
}

// MARK: - Constants

private extension CommonWelcomeV2BackgroundVideoProvider {
    enum Constants {
        static let resourceName = "WelcomeV2Background"
        static let resourceExtension = "mp4"
    }
}

// MARK: - DI

private struct WelcomeV2BackgroundVideoProviderKey: InjectionKey {
    static var currentValue: WelcomeV2BackgroundVideoProviding = CommonWelcomeV2BackgroundVideoProvider()
}

extension InjectedValues {
    var welcomeV2BackgroundVideoProvider: WelcomeV2BackgroundVideoProviding {
        get { Self[WelcomeV2BackgroundVideoProviderKey.self] }
        set { Self[WelcomeV2BackgroundVideoProviderKey.self] = newValue }
    }
}
