//
//  OnrampRedirectSettings.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampRedirectSettings: Hashable {
    public let successURL: String
    public let theme: Theme
    public let language: String

    public init(successURL: String, theme: Theme, language: String) {
        self.successURL = successURL
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
