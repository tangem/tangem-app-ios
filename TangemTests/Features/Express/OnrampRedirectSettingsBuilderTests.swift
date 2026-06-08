//
//  OnrampRedirectSettingsBuilderTests.swift
//  TangemTests
//
//  Created on 28.04.2026.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem
@testable import TangemExpress

@Suite("OnrampRedirectSettingsBuilder")
struct OnrampRedirectSettingsBuilderTests {
    @Test("Redirect URL is built from IncomingActionConstants.onrampRedirectURL with provider id appended")
    func redirectURLIsBuiltFromOnrampRedirectURL() {
        let builder = OnrampRedirectSettingsBuilder()
        let provider = OnrampTestFixtures.makeProvider(providerId: "moonpay")

        let settings = builder.make(provider: provider, theme: .light)

        #expect(settings.redirectURL.absoluteString == "\(IncomingActionConstants.onrampRedirectURL)/moonpay")
    }

    @Test("Light theme is forwarded as-is")
    func lightThemeIsForwarded() {
        let builder = OnrampRedirectSettingsBuilder()
        let provider = OnrampTestFixtures.makeProvider()

        let settings = builder.make(provider: provider, theme: .light)

        #expect(settings.theme == .light)
    }

    @Test("Dark theme is forwarded as-is")
    func darkThemeIsForwarded() {
        let builder = OnrampRedirectSettingsBuilder()
        let provider = OnrampTestFixtures.makeProvider()

        let settings = builder.make(provider: provider, theme: .dark)

        #expect(settings.theme == .dark)
    }

    @Test("Language equals Locale.appLanguageCode")
    func languageEqualsAppLanguageCode() {
        let builder = OnrampRedirectSettingsBuilder()
        let provider = OnrampTestFixtures.makeProvider()

        let settings = builder.make(provider: provider, theme: .light)

        #expect(settings.language == Locale.appLanguageCode)
    }
}
