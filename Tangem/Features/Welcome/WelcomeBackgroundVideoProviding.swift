//
//  WelcomeBackgroundVideoProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeBackgroundVideoProviding {
    func backgroundVideoURL() -> URL?
}

struct CommonWelcomeBackgroundVideoProvider: WelcomeBackgroundVideoProviding {
    private let url: URL? = Bundle.main.url(
        forResource: Constants.resourceName,
        withExtension: Constants.resourceExtension
    )

    func backgroundVideoURL() -> URL? { url }
}

// MARK: - Constants

private extension CommonWelcomeBackgroundVideoProvider {
    enum Constants {
        static let resourceName = "WelcomeBackground"
        static let resourceExtension = "mp4"
    }
}

// MARK: - DI

private struct WelcomeBackgroundVideoProviderKey: InjectionKey {
    static var currentValue: WelcomeBackgroundVideoProviding = CommonWelcomeBackgroundVideoProvider()
}

extension InjectedValues {
    var welcomeBackgroundVideoProvider: WelcomeBackgroundVideoProviding {
        get { Self[WelcomeBackgroundVideoProviderKey.self] }
        set { Self[WelcomeBackgroundVideoProviderKey.self] = newValue }
    }
}
