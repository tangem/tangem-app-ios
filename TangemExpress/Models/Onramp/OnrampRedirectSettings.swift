//
//  OnrampRedirectSettings.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampRedirectSettings: Hashable {
    public let successURL: String
    public let theme: String
    public let language: String

    public init(successURL: String, theme: String, language: String) {
        self.successURL = successURL
        self.theme = theme
        self.language = language
    }
}
