//
//  WelcomeStoryProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeStoryProviding {
    func welcomeStoryVideoURLs() -> [URL]
}

struct CommonWelcomeStoryProvider: WelcomeStoryProviding {
    private let urls: [URL] = Constants.resourceNames.compactMap {
        Bundle.main.url(forResource: $0, withExtension: Constants.resourceExtension)
    }

    func welcomeStoryVideoURLs() -> [URL] { urls }
}

// MARK: - Constants

private extension CommonWelcomeStoryProvider {
    enum Constants {
        static let resourceNames = ["WelcomeStory_01", "WelcomeStory_02", "WelcomeStory_03", "WelcomeStory_04"]
        static let resourceExtension = "mp4"
    }
}

// MARK: - DI

private struct WelcomeStoryProviderKey: InjectionKey {
    static var currentValue: WelcomeStoryProviding = CommonWelcomeStoryProvider()
}

extension InjectedValues {
    var welcomeStoryProvider: WelcomeStoryProviding {
        get { Self[WelcomeStoryProviderKey.self] }
        set { Self[WelcomeStoryProviderKey.self] = newValue }
    }
}
