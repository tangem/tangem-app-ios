//
//  LocaleWebLanguageCodeTests.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite("Locale.webLanguageCode")
struct LocaleWebLanguageCodeTests {
    @Test(
        "Russian-speaking device languages map to `ru` with or without a region",
        arguments: ["ru", "ru-RU", "ru-UA", "be", "be-BY", "by", "RU-RU"]
    )
    func russianVariants(deviceLanguage: String) {
        #expect(Locale.webLanguageCode(deviceLanguage: deviceLanguage) == Locale.ruLanguageCode)
    }

    @Test(
        "Everything else falls back to `en`",
        arguments: ["en", "en-US", "en-GB", "de-DE", "zh-Hans-CN", "uk-UA", "kk-KZ", ""]
    )
    func otherLanguagesFallBackToEnglish(deviceLanguage: String) {
        #expect(Locale.webLanguageCode(deviceLanguage: deviceLanguage) == Locale.enLanguageCode)
    }
}
