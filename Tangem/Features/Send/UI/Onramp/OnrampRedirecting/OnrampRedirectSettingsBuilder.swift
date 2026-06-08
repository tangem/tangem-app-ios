//
//  OnrampRedirectSettingsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampRedirectSettingsBuilder {
    func make(provider: OnrampProvider, theme: OnrampRedirectSettings.Theme) -> OnrampRedirectSettings {
        var redirectURL = URL(string: IncomingActionConstants.onrampRedirectURL)!
        redirectURL.appendPathComponent(provider.provider.id)

        return OnrampRedirectSettings(
            redirectURL: redirectURL,
            theme: theme,
            language: Locale.appLanguageCode
        )
    }
}
