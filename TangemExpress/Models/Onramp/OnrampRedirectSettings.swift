//
//  OnrampRedirectSettings.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampRedirectSettings: Hashable {
    public let redirectURL: String
    public let theme: Theme
    public let language: String

    public init(redirectURL: String, theme: Theme, language: String) {
        self.redirectURL = redirectURL
        self.theme = theme
        self.language = language
    }
}

public extension OnrampRedirectSettings {
    enum Theme: String, Hashable {
        case light
        case dark
    }
}
