//
//  Localization+LanguageCode.swift
//  TangemLocalization
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension Localization {
    /// The language the UI strings are rendered in, as a language code with an optional script and without a region
    /// (e.g. `ru`, `pt`, `zh-Hans`), the format the backend expects for localized content.
    ///
    /// Resolved against this module's bundle rather than `Bundle.main`: the main bundle ships fewer localizations,
    /// so it would resolve e.g. German to `en` while the UI is in German. Unlike `Locale.deviceLanguageCode()`,
    /// it respects the per-app language chosen in iOS Settings.
    static let languageCode: String = {
        let identifier = Bundle.module.preferredLocalizations.first ?? "en"
        let components = Locale.Language.Components(identifier: identifier)

        guard let languageCode = components.languageCode?.identifier else {
            return identifier
        }

        return [languageCode, components.script?.identifier]
            .compactMap { $0 }
            .joined(separator: "-")
    }()
}
